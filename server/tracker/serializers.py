from rest_framework import serializers
from .models import (
    MAX_ITEM_IMAGES, Category, Entry, ShoppingItem, ShoppingItemImage, ShoppingList, Subscription,
)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "pub_date", "category_type"]


class EntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Entry
        fields = [
            "id", "amount", "category", "added_date", "notes", "created_date", "subscription",
            "currency", "original_amount",
        ]

    def validate(self, attrs):
        # Clients that only send `amount` (older app versions) are paying in
        # HUF, so keep `original_amount` in step with it.
        currency = attrs.get("currency", getattr(self.instance, "currency", None) or "HUF")
        if "amount" in attrs and "original_amount" not in attrs and currency == "HUF":
            attrs["original_amount"] = attrs["amount"]
        return attrs

    def to_representation(self, instance):
        # Accept a category id on write, but expose the full category on read.
        ret = super().to_representation(instance)
        ret["category"] = CategorySerializer(instance.category).data
        if ret["original_amount"] is None:
            ret["original_amount"] = instance.amount
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


class ShoppingItemImageSerializer(serializers.ModelSerializer):
    # absolute, so native clients can load it as a network image as-is
    url = serializers.SerializerMethodField()

    class Meta:
        model = ShoppingItemImage
        fields = ["id", "item", "image", "url", "created_date"]
        extra_kwargs = {"image": {"write_only": True}}

    def get_url(self, instance):
        url = instance.image.url
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request else url

    def validate_item(self, item):
        if self.instance is None and item.images.count() >= MAX_ITEM_IMAGES:
            raise serializers.ValidationError(f"An item can have at most {MAX_ITEM_IMAGES} images.")
        return item


class ShoppingItemSerializer(serializers.ModelSerializer):
    # Images are added and removed through their own endpoint.
    images = serializers.SerializerMethodField()

    class Meta:
        model = ShoppingItem
        fields = [
            "id", "shopping_list", "name", "description", "expected_price", "currency", "buying_goal",
            "is_bought", "position", "created_date", "images",
        ]
        # changed through the list's reorder action, new items go last
        read_only_fields = ["position"]

    def get_images(self, instance):
        # oldest first; sorted in Python so a prefetched list is reused
        images = sorted(instance.images.all(), key=lambda i: (i.created_date, i.id))
        return ShoppingItemImageSerializer(images, many=True, context=self.context).data


class ShoppingListSerializer(serializers.ModelSerializer):
    # Items are written through their own endpoint.
    items = serializers.SerializerMethodField()

    class Meta:
        model = ShoppingList
        fields = ["id", "name", "created_date", "items"]

    def get_items(self, instance):
        # in the user's order; sorted in Python so a prefetched list is reused
        items = sorted(instance.items.all(), key=lambda i: (i.position, i.created_date))
        return ShoppingItemSerializer(items, many=True, context=self.context).data
