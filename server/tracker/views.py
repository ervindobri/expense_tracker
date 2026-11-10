# Create your views here.
from django.db.models import Max
from django.http import HttpResponse, JsonResponse
from django.utils import timezone
from django.views.decorators.http import require_GET
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from . import export
from .models import Category, Entry, ShoppingItem, ShoppingItemImage, ShoppingList, Subscription
from .serializers import (
    CategorySerializer, EntrySerializer, ShoppingItemImageSerializer, ShoppingItemSerializer,
    ShoppingListSerializer, SubscriptionSerializer,
)

def index(request):
    return HttpResponse("Hello, world. You're at the tracker index.")


# A plain Django view rather than DRF: DRF claims the `format` query param,
# and a browser opening this URL should get the file, not a browsable page.
@require_GET
def export_data(request):
    """Every category, entry and subscription plus statistics, as a download.

    `?file_format=xlsx` (default): one workbook with charts.
    `?file_format=csv`: a zip of CSV files.
    `?tz=Europe/Budapest`: zone dates are written in (default: the server's).
    """
    file_format = request.GET.get("file_format", "xlsx").lower()
    if file_format not in ("xlsx", "csv"):
        return JsonResponse({"file_format": ["Expected 'xlsx' or 'csv'."]}, status=400)
    tables = export.collect(export.resolve_timezone(request.GET.get("tz")))
    stamp = timezone.now().strftime("%Y-%m-%d")
    if file_format == "xlsx":
        body, content_type, ext = export.build_workbook(tables), export.XLSX_CONTENT_TYPE, "xlsx"
    else:
        body, content_type, ext = export.build_csv_zip(tables), "application/zip", "zip"
    response = HttpResponse(body, content_type=content_type)
    response["Content-Disposition"] = f'attachment; filename="expense-tracker-{stamp}.{ext}"'
    # lets a web client read the file name on a cross-origin fetch
    response["Access-Control-Expose-Headers"] = "Content-Disposition"
    return response

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

    def get_queryset(self):
        queryset = Category.objects.all()
        category_type = self.request.query_params.get("category_type")
        if category_type:
            queryset = queryset.filter(category_type=category_type)
        return queryset

    def update(self, request, *args, **kwargs):
        # Treat PUT like PATCH: allow updating a subset of fields.
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)


# No login required: the API is only reachable from the tailnet, and the app
# doesn't send credentials.
class EntryViewSet(viewsets.ModelViewSet):
    queryset = Entry.objects.all()
    serializer_class = EntrySerializer

    def get_queryset(self):
        queryset = Entry.objects.all()
        year = self.request.query_params.get("year")
        if year is not None:
            try:
                queryset = queryset.filter(added_date__year=int(year))
            except ValueError:
                queryset = queryset.none()  # or raise a 400
        return queryset

    def update(self, request, *args, **kwargs):
        # Treat PUT like PATCH: allow updating a subset of fields.
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)


class SubscriptionViewSet(viewsets.ModelViewSet):
    queryset = Subscription.objects.all()
    serializer_class = SubscriptionSerializer

    def get_queryset(self):
        queryset = Subscription.objects.prefetch_related("entries__category")
        active = self.request.query_params.get("active")
        if active is not None:
            queryset = queryset.filter(is_active=active.lower() in ("1", "true"))
        return queryset.order_by("-created_date")

    def update(self, request, *args, **kwargs):
        # Treat PUT like PATCH: allow updating a subset of fields.
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        # Soft delete: keep the row (and its entries' link) but mark it inactive.
        subscription = self.get_object()
        subscription.is_active = False
        subscription.save(update_fields=["is_active"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ShoppingListViewSet(viewsets.ModelViewSet):
    queryset = ShoppingList.objects.all()
    serializer_class = ShoppingListSerializer

    def get_queryset(self):
        return ShoppingList.objects.prefetch_related("items__images").order_by("created_date")

    def update(self, request, *args, **kwargs):
        # Treat PUT like PATCH: allow updating a subset of fields.
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)

    @action(detail=True, methods=["post"])
    def reorder(self, request, pk=None):
        """Sets the item order from `items`, a list of this list's item ids.
        Items left out keep their relative order after the given ones."""
        shopping_list = self.get_object()
        ids = request.data.get("items")
        if not isinstance(ids, list) or not all(isinstance(i, int) for i in ids):
            return Response({"items": ["Expected a list of item ids."]}, status=status.HTTP_400_BAD_REQUEST)
        if len(set(ids)) != len(ids):
            return Response({"items": ["Duplicate item ids."]}, status=status.HTTP_400_BAD_REQUEST)
        items = {i.id: i for i in shopping_list.items.all()}
        unknown = [i for i in ids if i not in items]
        if unknown:
            return Response(
                {"items": [f"Not in this list: {unknown}"]}, status=status.HTTP_400_BAD_REQUEST
            )
        rest = sorted(
            (i for i in items.values() if i.id not in set(ids)),
            key=lambda i: (i.position, i.created_date),
        )
        ordered = [items[i] for i in ids] + rest
        for position, item in enumerate(ordered):
            item.position = position
        ShoppingItem.objects.bulk_update(ordered, ["position"])
        shopping_list = self.get_queryset().get(pk=shopping_list.pk)
        return Response(self.get_serializer(shopping_list).data)


class ShoppingItemViewSet(viewsets.ModelViewSet):
    queryset = ShoppingItem.objects.all()
    serializer_class = ShoppingItemSerializer

    def get_queryset(self):
        queryset = ShoppingItem.objects.prefetch_related("images")
        shopping_list = self.request.query_params.get("list")
        if shopping_list is not None:
            try:
                queryset = queryset.filter(shopping_list=int(shopping_list))
            except ValueError:
                queryset = queryset.none()
        return queryset.order_by("position", "created_date")

    def perform_create(self, serializer):
        # new items go to the end of their list
        last = ShoppingItem.objects.filter(
            shopping_list=serializer.validated_data["shopping_list"]
        ).aggregate(last=Max("position"))["last"]
        serializer.save(position=0 if last is None else last + 1)

    def update(self, request, *args, **kwargs):
        # Treat PUT like PATCH: allow updating a subset of fields.
        kwargs["partial"] = True
        return super().update(request, *args, **kwargs)


class ShoppingItemImageViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.DestroyModelMixin,
    mixins.ListModelMixin,
    viewsets.GenericViewSet,
):
    """Photos on shopping items: upload one as multipart form data with
    `item` (the item id) and `image` (the file), or delete one. Items list
    their own images, so there is nothing to update."""

    queryset = ShoppingItemImage.objects.all()
    serializer_class = ShoppingItemImageSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        queryset = ShoppingItemImage.objects.all()
        item = self.request.query_params.get("item")
        if item is not None:
            try:
                queryset = queryset.filter(item=int(item))
            except ValueError:
                queryset = queryset.none()
        return queryset.order_by("created_date", "id")
