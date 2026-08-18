from django.urls import path
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.routers import DefaultRouter
from .views import CategoryViewSet, EntryViewSet

router = DefaultRouter()
router.register(r"categories", CategoryViewSet)
router.register(r"entries", EntryViewSet)

urlpatterns = [
    path("auth/login/", ObtainAuthToken.as_view(), name="api-login"),
] + router.urls