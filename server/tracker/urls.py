from rest_framework.routers import DefaultRouter
from .views import CategoryViewSet, EntryViewSet

router = DefaultRouter()
router.register(r"categories", CategoryViewSet)
router.register(r"entries", EntryViewSet)

urlpatterns = router.urls