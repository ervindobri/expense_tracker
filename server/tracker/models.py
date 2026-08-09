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


# Expense or income entry
class Entry(models.Model):
    amount = models.FloatField(max_length=10)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    added_date = models.DateTimeField("date published")
    created_date = models.DateTimeField("date entry was created", auto_now_add=True)
    notes = models.CharField(max_length=100,blank=True, default="")



# Total balance: income, expenses, saved will be calculated from all entries filtered by date