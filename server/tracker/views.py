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