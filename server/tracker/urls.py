from django.urls import path
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.routers import DefaultRouter
from .views import (
    CategoryViewSet, EntryViewSet, ShoppingItemViewSet, ShoppingListViewSet, SubscriptionViewSet,
)

router = DefaultRouter()
router.register(r"categories", CategoryViewSet)
router.register(r"entries", EntryViewSet)
router.register(r"subscriptions", SubscriptionViewSet)
router.register(r"shopping-lists", ShoppingListViewSet)
router.register(r"shopping-items", ShoppingItemViewSet)

urlpatterns = [
    path("auth/login/", ObtainAuthToken.as_view(), name="api-login"),
] + router.urls