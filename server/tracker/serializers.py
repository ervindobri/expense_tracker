from rest_framework import serializers
from .models import Category, Entry


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "pub_date", "category_type"]


class EntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Entry
        fields = ["id", "amount", "category", "added_date", "notes", "created_date"]

    def to_representation(self, instance):
        # Accept a category id on write, but expose the full category on read.
        ret = super().to_representation(instance)
        ret["category"] = CategorySerializer(instance.category).data
        return ret