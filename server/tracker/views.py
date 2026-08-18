# Create your views here.
from django.http import HttpResponse
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Category, Entry
from .serializers import CategorySerializer, EntrySerializer

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


class EntryViewSet(viewsets.ModelViewSet):
    queryset = Entry.objects.all()
    serializer_class = EntrySerializer
    permission_classes = [IsAuthenticated]

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