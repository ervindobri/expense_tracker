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


# Recurring cost (phone, streaming...). Removing one only marks it inactive so
# its linked entries keep their history.
class Subscription(models.Model):
    name = models.CharField(max_length=100)
    # expected cost per period; the actual spend comes from the linked entries
    amount = models.FloatField(default=0)
    period = models.CharField(
        max_length=1,
        choices=SubscriptionPeriod.choices,
        default=SubscriptionPeriod.MONTHLY,
    )
    is_active = models.BooleanField(default=True)
    created_date = models.DateTimeField("date subscription was created", auto_now_add=True)


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



# Total balance: income, expenses, saved will be calculated from all entries filtered by date