# Create your views here.
from django.http import HttpResponse
from rest_framework import status, viewsets
from rest_framework.response import Response
from .models import Category, Entry, Subscription
from .serializers import CategorySerializer, EntrySerializer, SubscriptionSerializer

def index(request):
    return HttpResponse("Hello, world. You're at the tracker index.")

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
