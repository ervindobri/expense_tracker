from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _



class CategoryType:
    EXPENSE = "E"
    INCOME = "I"

    choices = [
        (EXPENSE, _("Expense")),
        (INCOME, _("Income")),
    ]


# 12 default expense categories + 3 income categories:
# Rent & bills
# Groceries
# Supplies & home
# Dining Out
# Drinking Out
# Electronics & digital
# Health & medicine
# Fashion
# Vacation
# Transport
# Subscriptions
# Gifts & dates
# Entertainment
# Others

# Salary
# Gifts
# Others
class Category(models.Model):
    name = models.CharField(max_length=100)
    pub_date = models.DateTimeField("date published")
    category_type = models.CharField(
        max_length=1,
        choices=CategoryType.choices,
        default=CategoryType.EXPENSE
    )


class SubscriptionPeriod:
    DAILY = "D"
    WEEKLY = "W"
    BIWEEKLY = "B"
    MONTHLY = "M"
    QUARTERLY = "Q"
    YEARLY = "Y"

    choices = [
        (DAILY, _("Daily")),
        (WEEKLY, _("Weekly")),
        (BIWEEKLY, _("Bi-weekly")),
        (MONTHLY, _("Monthly")),
        (QUARTERLY, _("Quarterly")),
        (YEARLY, _("Yearly")),
    ]


class Currency:
    HUF = "HUF"
    EUR = "EUR"
    USD = "USD"

    choices = [
        (HUF, "HUF"),
        (EUR, "EUR"),
        (USD, "USD"),
    ]


# Recurring cost (phone, streaming...). Removing one only marks it inactive so
# its linked entries keep their history.
class Subscription(models.Model):
    name = models.CharField(max_length=100)
    # expected cost per period, in `currency`; the actual spend comes from the
    # linked entries (always HUF)
    amount = models.FloatField(default=0)
    currency = models.CharField(max_length=3, choices=Currency.choices, default=Currency.HUF)
    period = models.CharField(
        max_length=1,
        choices=SubscriptionPeriod.choices,
        default=SubscriptionPeriod.MONTHLY,
    )
    is_active = models.BooleanField(default=True)
    # set by the user (a subscription may have started on an earlier day);
    # renewals are counted from it
    created_date = models.DateTimeField("date subscription was created", default=timezone.now)


# Expense or income entry
class Entry(models.Model):
    amount = models.FloatField(max_length=10)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    added_date = models.DateTimeField("date published")
    created_date = models.DateTimeField("date entry was created", auto_now_add=True)
    notes = models.CharField(max_length=100,blank=True, default="")
    subscription = models.ForeignKey(
        Subscription,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="entries",
    )
    # What was actually paid. `amount` stays in HUF so totals never need a
    # conversion; these keep the original currency and value next to it.
    currency = models.CharField(max_length=3, choices=Currency.choices, default=Currency.HUF)
    original_amount = models.FloatField(null=True, blank=True)



# Total balance: income, expenses, saved will be calculated from all entries filtered by date

# Named checklist of things to buy (groceries, house...).
class ShoppingList(models.Model):
    name = models.CharField(max_length=100)
    created_date = models.DateTimeField("date list was created", default=timezone.now)


# Something to buy, checked off once bought.
class ShoppingItem(models.Model):
    shopping_list = models.ForeignKey(
        ShoppingList,
        on_delete=models.CASCADE,
        related_name="items",
    )
    name = models.CharField(max_length=100)
    # free-form notes: product details, links to where to buy it
    description = models.TextField(blank=True, default="")
    # estimate in `currency`
    expected_price = models.FloatField(default=0)
    currency = models.CharField(max_length=3, choices=Currency.choices, default=Currency.HUF)
    # day it should be bought by, if any
    buying_goal = models.DateField(null=True, blank=True)
    is_bought = models.BooleanField(default=False)
    created_date = models.DateTimeField("date item was created", default=timezone.now)
