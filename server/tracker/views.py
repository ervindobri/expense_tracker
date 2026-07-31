# Create your views here.
from django.http import HttpResponse
from rest_framework import viewsets
from .models import Category, Entry
from .serializers import CategorySerializer, EntrySerializer

def index(request):
    return HttpResponse("Hello, world. You're at the tracker index.")

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer


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