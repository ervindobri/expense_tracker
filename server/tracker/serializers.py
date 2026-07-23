from rest_framework import serializers
from .models import Category, Entry


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "pub_date", "category_type"]


class EntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Entry
        fields = ["id", "amount", "category", "added_date"]