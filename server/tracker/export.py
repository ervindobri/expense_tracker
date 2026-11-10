"""Exports every category, entry and subscription, plus statistics computed
from the entries, as a spreadsheet that opens as-is in Excel, Numbers or
Google Sheets.

- xlsx: one workbook, a sheet per table (filterable Excel tables) and native
  charts on the statistics sheets.
- csv: a zip with one UTF-8 CSV per table (CSV holds a single table and no
  charts).

All money in the statistics is in HUF, like `Entry.amount`. Values are written
as plain numbers rather than formulas, so every app shows them without having
to recalculate first.
"""
import csv
import io
import zipfile
from collections import defaultdict
from datetime import datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from django.utils import timezone
from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.styles import Font
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.table import Table, TableStyleInfo

from .models import Category, CategoryType, Entry, Subscription

XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

# Series colors: validated categorical slots 1 and 2 (blue, orange), kept
# apart from status red/green so neither reads as good/bad.
INCOME_COLOR = "2A78D6"
EXPENSE_COLOR = "EB6834"

HUF_FORMAT = '#,##0 "Ft"'
MONEY_FORMAT = "#,##0.00"
PERCENT_FORMAT = "0.0%"
DATETIME_FORMAT = "yyyy-mm-dd hh:mm"
DATE_FORMAT = "yyyy-mm-dd"

_TYPE_LABELS = dict(CategoryType.choices)
_PERIOD_LABELS = {
    "D": "Daily", "W": "Weekly", "B": "Bi-weekly", "M": "Monthly", "Q": "Quarterly", "Y": "Yearly",
}


def resolve_timezone(name):
    """The zone dates are shown in: `name` when it's a valid IANA zone,
    otherwise the server's."""
    if name:
        try:
            return ZoneInfo(name)
        except (ZoneInfoNotFoundError, ValueError):
            pass
    return timezone.get_default_timezone()


class _Sheet:
    """A table to export: its columns, rows and per-column cell formats."""

    def __init__(self, title, columns, rows):
        # columns: [(header, number_format or None)]
        self.title = title
        self.headers = [c[0] for c in columns]
        self.formats = [c[1] for c in columns]
        self.rows = rows


def _local(value, tz):
    """`value` in `tz` without tzinfo (spreadsheets don't store zones)."""
    if value is None:
        return None
    if timezone.is_aware(value):
        value = value.astimezone(tz)
    return value.replace(tzinfo=None, microsecond=0)


def _type_label(category_type):
    return str(_TYPE_LABELS.get(category_type, category_type))


def collect(tz):
    """Every table that goes into the export, in sheet order."""
    categories = list(Category.objects.order_by("category_type", "name"))
    subscriptions = list(Subscription.objects.order_by("-is_active", "name"))
    entries = list(
        Entry.objects.select_related("category", "subscription").order_by("added_date", "id")
    )

    by_category = defaultdict(lambda: [0.0, 0])  # id -> [total, count]
    by_subscription = defaultdict(lambda: [0.0, 0])
    monthly = defaultdict(lambda: [0.0, 0.0])  # "YYYY-MM" -> [income, expenses]
    yearly = defaultdict(lambda: [0.0, 0.0, 0])  # year -> [income, expenses, count]
    entry_rows = []
    for e in entries:
        when = _local(e.added_date, tz)
        is_income = e.category.category_type == CategoryType.INCOME
        by_category[e.category_id][0] += e.amount
        by_category[e.category_id][1] += 1
        if e.subscription_id:
            by_subscription[e.subscription_id][0] += e.amount
            by_subscription[e.subscription_id][1] += 1
        month = monthly[f"{when.year:04d}-{when.month:02d}"]
        year = yearly[when.year]
        month[0 if is_income else 1] += e.amount
        year[0 if is_income else 1] += e.amount
        year[2] += 1
        entry_rows.append([
            e.id,
            when,
            _type_label(e.category.category_type),
            e.category.name,
            e.amount,
            e.original_amount if e.original_amount is not None else e.amount,
            e.currency,
            e.notes,
            e.subscription.name if e.subscription else "",
            _local(e.created_date, tz),
        ])

    # every month between the first and last entry, empty ones as 0, so the
    # charts don't skip gaps
    monthly_rows = []
    if monthly:
        first, last = min(monthly), max(monthly)
        y, m = int(first[:4]), int(first[5:])
        while f"{y:04d}-{m:02d}" <= last:
            key = f"{y:04d}-{m:02d}"
            income, expenses = monthly.get(key, (0.0, 0.0))
            monthly_rows.append([key, income, expenses, income - expenses])
            y, m = (y + 1, 1) if m == 12 else (y, m + 1)

    yearly_rows = []
    for year in sorted(yearly):
        income, expenses, count = yearly[year]
        rate = (income - expenses) / income if income else None
        yearly_rows.append([year, income, expenses, income - expenses, rate, count])

    def category_breakdown(category_type):
        rows = [
            [c.name, by_category[c.id][0], by_category[c.id][1]]
            for c in categories
            if c.category_type == category_type and by_category[c.id][1]
        ]
        rows.sort(key=lambda r: r[1], reverse=True)
        total = sum(r[1] for r in rows)
        return [[name, amount, amount / total if total else 0, count] for name, amount, count in rows]

    money_cols = [("Income (HUF)", HUF_FORMAT), ("Expenses (HUF)", HUF_FORMAT), ("Savings (HUF)", HUF_FORMAT)]
    breakdown_cols = [
        ("Category", None), ("Total (HUF)", HUF_FORMAT), ("Share", PERCENT_FORMAT), ("Entries", None),
    ]
    return {
        "yearly": _Sheet(
            "Yearly summary",
            [("Year", "0")] + money_cols + [("Savings rate", PERCENT_FORMAT), ("Entries", None)],
            yearly_rows,
        ),
        "monthly": _Sheet("Monthly summary", [("Month", None)] + money_cols, monthly_rows),
        "expense_categories": _Sheet("Expenses by category", breakdown_cols, category_breakdown(CategoryType.EXPENSE)),
        "income_categories": _Sheet("Income by category", breakdown_cols, category_breakdown(CategoryType.INCOME)),
        "entries": _Sheet(
            "Entries",
            [
                ("ID", None), ("Date", DATETIME_FORMAT), ("Type", None), ("Category", None),
                ("Amount (HUF)", HUF_FORMAT), ("Original amount", MONEY_FORMAT), ("Currency", None),
                ("Notes", None), ("Subscription", None), ("Created", DATETIME_FORMAT),
            ],
            entry_rows,
        ),
        "categories": _Sheet(
            "Categories",
            [
                ("ID", None), ("Name", None), ("Type", None), ("Created", DATE_FORMAT),
                ("Entries", None), ("Total (HUF)", HUF_FORMAT),
            ],
            [
                [
                    c.id, c.name, _type_label(c.category_type), _local(c.pub_date, tz),
                    by_category[c.id][1], by_category[c.id][0],
                ]
                for c in categories
            ],
        ),
        "subscriptions": _Sheet(
            "Subscriptions",
            [
                ("ID", None), ("Name", None), ("Price per period", MONEY_FORMAT), ("Currency", None),
                ("Period", None), ("Active", None), ("Started", DATE_FORMAT),
                ("Payments", None), ("Total spent (HUF)", HUF_FORMAT),
            ],
            [
                [
                    s.id, s.name, s.amount, s.currency, _PERIOD_LABELS.get(s.period, s.period),
                    "Yes" if s.is_active else "No", _local(s.created_date, tz),
                    by_subscription[s.id][1], by_subscription[s.id][0],
                ]
                for s in subscriptions
            ],
        ),
    }


# ---------------------------------------------------------------- xlsx


def _write_table(ws, sheet, top=1, left=1, name=None):
    """Writes `sheet` at (top, left) as a filterable Excel table and returns
    the last row it used."""
    for col, header in enumerate(sheet.headers, start=left):
        cell = ws.cell(row=top, column=col, value=header)
        cell.font = Font(bold=True)
    for r, row in enumerate(sheet.rows, start=top + 1):
        for c, (value, fmt) in enumerate(zip(row, sheet.formats), start=left):
            cell = ws.cell(row=r, column=c, value=value)
            if fmt and value is not None:
                cell.number_format = fmt
    last_row = top + len(sheet.rows)
    # Excel rejects a table without data rows ("repair" prompt), so an empty
    # one stays a plain header row
    if sheet.rows:
        ref = f"{get_column_letter(left)}{top}:{get_column_letter(left + len(sheet.headers) - 1)}{last_row}"
        table = Table(displayName=name or sheet.title.replace(" ", ""), ref=ref)
        table.tableStyleInfo = TableStyleInfo(name="TableStyleMedium2", showRowStripes=True)
        ws.add_table(table)
    for col, header in enumerate(sheet.headers, start=left):
        values = [header] + [row[col - left] for row in sheet.rows]
        width = max(len(_display(v)) for v in values) + 3
        letter = get_column_letter(col)
        ws.column_dimensions[letter].width = max(ws.column_dimensions[letter].width or 0, min(width, 50))
    return last_row


def _display(value):
    if isinstance(value, datetime):
        return "yyyy-mm-dd hh:mm"
    if isinstance(value, float):
        return f"{value:,.0f} Ft"
    return "" if value is None else str(value)


def _style_chart(chart, title, y_title=None, width=24, height=9):
    chart.title = title
    chart.y_axis.title = y_title
    chart.y_axis.numFmt = "#,##0"
    chart.width, chart.height = width, height
    # openpyxl hides axes unless told otherwise
    chart.x_axis.delete = False
    chart.y_axis.delete = False


def _color(series, hex_color, line=False):
    if line:
        series.graphicalProperties.line.solidFill = hex_color
        series.graphicalProperties.line.width = 25400  # 2pt
        series.smooth = False
    else:
        series.graphicalProperties.solidFill = hex_color
        series.graphicalProperties.line.solidFill = hex_color


def build_workbook(tables):
    wb = Workbook()

    # Summary: yearly totals
    ws = wb.active
    ws.title = "Summary"
    ws["A1"] = "Expense tracker export"
    ws["A1"].font = Font(bold=True, size=14)
    ws["A2"] = f"Exported {timezone.now():%Y-%m-%d %H:%M} UTC · amounts in HUF"
    ws["A2"].font = Font(italic=True, color="666666")
    yearly = tables["yearly"]
    last = _write_table(ws, yearly, top=4, name="YearlySummary")
    if yearly.rows:
        chart = BarChart()
        chart.type = "col"
        chart.grouping = "clustered"
        _style_chart(chart, "Income and expenses per year", width=18)
        chart.add_data(Reference(ws, min_col=2, max_col=3, min_row=4, max_row=last), titles_from_data=True)
        chart.set_categories(Reference(ws, min_col=1, min_row=5, max_row=last))
        _color(chart.series[0], INCOME_COLOR)
        _color(chart.series[1], EXPENSE_COLOR)
        ws.add_chart(chart, f"A{last + 3}")

    # Monthly: table, income vs expenses, savings
    ws = wb.create_sheet("Monthly")
    monthly = tables["monthly"]
    last = _write_table(ws, monthly, name="MonthlySummary")
    ws.freeze_panes = "A2"
    if monthly.rows:
        months = Reference(ws, min_col=1, min_row=2, max_row=last)
        # wider charts for long histories so month labels stay readable
        width = max(24, min(len(monthly.rows) * 1.2, 60))

        chart = BarChart()
        chart.type = "col"
        chart.grouping = "clustered"
        chart.gapWidth = 60
        _style_chart(chart, "Income and expenses per month", width=width)
        chart.add_data(Reference(ws, min_col=2, max_col=3, min_row=1, max_row=last), titles_from_data=True)
        chart.set_categories(months)
        _color(chart.series[0], INCOME_COLOR)
        _color(chart.series[1], EXPENSE_COLOR)
        chart.legend.position = "t"
        ws.add_chart(chart, "F2")

        # its own chart: one y-axis per chart, and savings go negative
        savings = LineChart()
        _style_chart(savings, "Savings per month (income − expenses)", width=width)
        savings.add_data(Reference(ws, min_col=4, min_row=1, max_row=last), titles_from_data=True)
        savings.set_categories(months)
        _color(savings.series[0], INCOME_COLOR, line=True)
        savings.legend = None
        ws.add_chart(savings, "F21")

    # By category: expense and income breakdowns, side by side
    ws = wb.create_sheet("By category")
    for left, key, color, name in (
        (1, "expense_categories", EXPENSE_COLOR, "ExpensesByCategory"),
        (7, "income_categories", INCOME_COLOR, "IncomeByCategory"),
    ):
        sheet = tables[key]
        ws.cell(row=1, column=left, value=sheet.title).font = Font(bold=True, size=12)
        last = _write_table(ws, sheet, top=2, left=left, name=name)
        if not sheet.rows:
            continue
        chart = BarChart()
        chart.type = "bar"  # horizontal: long category names stay readable
        _style_chart(chart, sheet.title, width=14, height=max(6, len(sheet.rows) * 0.9))
        chart.add_data(Reference(ws, min_col=left + 1, min_row=2, max_row=last), titles_from_data=True)
        chart.set_categories(Reference(ws, min_col=left, min_row=3, max_row=last))
        # largest on top
        chart.x_axis.scaling.orientation = "maxMin"
        chart.gapWidth = 40
        _color(chart.series[0], color)
        chart.legend = None
        ws.add_chart(chart, f"{get_column_letter(left)}{max(last, 2) + 3}")

    for key in ("entries", "categories", "subscriptions"):
        sheet = tables[key]
        ws = wb.create_sheet(sheet.title)
        _write_table(ws, sheet)
        ws.freeze_panes = "A2"

    out = io.BytesIO()
    wb.save(out)
    return out.getvalue()


# ---------------------------------------------------------------- csv


def _csv_value(value):
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M")
    if isinstance(value, float):
        # no float noise like 0.30000000000000004
        return f"{value:.2f}".rstrip("0").rstrip(".")
    return "" if value is None else value


def build_csv_zip(tables):
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
        for key in (
            "entries", "categories", "subscriptions",
            "monthly", "yearly", "expense_categories", "income_categories",
        ):
            sheet = tables[key]
            buffer = io.StringIO()
            writer = csv.writer(buffer)
            writer.writerow(sheet.headers)
            writer.writerows([_csv_value(v) for v in row] for row in sheet.rows)
            filename = sheet.title.lower().replace(" ", "_") + ".csv"
            # BOM so Excel opens it as UTF-8 (accented names stay intact)
            zf.writestr(filename, "﻿" + buffer.getvalue())
    return out.getvalue()
