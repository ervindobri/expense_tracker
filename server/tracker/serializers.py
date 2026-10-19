from rest_framework import serializers
from .models import Category, Entry, Subscription


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "pub_date", "category_type"]


class EntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Entry
        fields = ["id", "amount", "category", "added_date", "notes", "created_date", "subscription"]

    def to_representation(self, instance):
        # Accept a category id on write, but expose the full category on read.
        ret = super().to_representation(instance)
        ret["category"] = CategorySerializer(instance.category).data
        return ret


class SubscriptionSerializer(serializers.ModelSerializer):
    # Linked entries are read-only here: an entry is linked by setting its
    # own `subscription` field.
    entries = serializers.SerializerMethodField()
    total_spent = serializers.SerializerMethodField()

    class Meta:
        model = Subscription
        fields = ["id", "name", "amount", "currency", "period", "is_active", "created_date", "entries", "total_spent"]

    def _entries(self, instance):
        # newest first; sorted in Python so a prefetched list is reused
        return sorted(instance.entries.all(), key=lambda e: e.added_date, reverse=True)

    def get_entries(self, instance):
        return EntrySerializer(self._entries(instance), many=True).data

    def get_total_spent(self, instance):
        return sum(e.amount for e in instance.entries.all())
