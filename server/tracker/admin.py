from django.contrib import admin

from .models import Category, Entry, ShoppingItem, ShoppingItemImage, ShoppingList, Subscription

admin.site.register(Category)
admin.site.register(Entry)
admin.site.register(Subscription)
admin.site.register(ShoppingList)
admin.site.register(ShoppingItem)
admin.site.register(ShoppingItemImage)
