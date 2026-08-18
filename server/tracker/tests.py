import json
from django.test import TestCase, RequestFactory
from django.urls import reverse
from django.contrib.auth.models import User
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework.authtoken.models import Token
from .models import Category, CategoryType, Entry
from .serializers import CategorySerializer, EntrySerializer
import datetime


class ExpenseTrackerAPITests(TestCase):
    """Tests for the ExpenseTracker API using DRF"""

    def setUp(self):
        self.factory = RequestFactory()
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpass")
        
        # Create categories for testing
        self.expense_category = Category.objects.create(
            name="Groceries",
            pub_date=datetime.datetime.now(),
            category_type=CategoryType.EXPENSE
        )
        
        self.income_category = Category.objects.create(
            name="Salary",
            pub_date=datetime.datetime.now(),
            category_type=CategoryType.INCOME
        )
        
        self.entry = Entry.objects.create(
            amount=100.50,
            category=self.expense_category,
            added_date=datetime.datetime.now(),
            notes="Test expense"
        )

        # Entries are behind auth; authenticate by default and let the
        # specific "no token" tests drop credentials themselves.
        self.client.force_authenticate(user=self.user)

    # ==================== Category Tests ====================
    
    def test_category_list(self):
        """Test listing all categories"""
        response = self.client.get("/api/categories/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)

    def test_category_retrieve(self):
        """Test retrieving a single category"""
        response = self.client.get(f"/api/categories/{self.expense_category.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Groceries")
        self.assertEqual(response.data["category_type"], "E")

    def test_category_create(self):
        """Test creating a new category"""
        data = {
            "name": "Utilities",
            "pub_date": datetime.datetime.now().isoformat(),
            "category_type": "E"
        }
        response = self.client.post("/api/categories/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["name"], "Utilities")

    def test_category_update(self):
        """Test updating an existing category"""
        data = {"name": "Updated Groceries"}
        response = self.client.put(f"/api/categories/{self.expense_category.id}/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Updated Groceries")

    def test_category_partial_update(self):
        """Test partial update of a category"""
        data = {"category_type": "I"}
        response = self.client.patch(f"/api/categories/{self.expense_category.id}/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["category_type"], "I")

    def test_category_delete(self):
        """Test deleting a category"""
        response = self.client.delete(f"/api/categories/{self.expense_category.id}/")
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Category.objects.filter(id=self.expense_category.id).exists())

    def test_category_filter_by_type(self):
        """Test filtering categories by type"""
        response = self.client.get("/api/categories/?category_type=E")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(all(item["category_type"] == "E" for item in response.data))

    # ==================== Entry Tests ====================
    
    def test_entry_list(self):
        """Test listing all entries"""
        response = self.client.get("/api/entries/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)

    def test_entry_retrieve(self):
        """Test retrieving a single entry"""
        response = self.client.get(f"/api/entries/{self.entry.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["amount"], 100.50)
        self.assertEqual(response.data["category"]["id"], self.expense_category.id)

    def test_entry_create(self):
        """Test creating a new entry"""
        data = {
            "amount": 75.00,
            "category": self.expense_category.id,
            "added_date": datetime.datetime.now().isoformat()
        }
        response = self.client.post("/api/entries/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["amount"], 75.00)

    def test_entry_create_with_notes(self):
        """Test creating an entry with notes"""
        data = {
            "amount": 50.00,
            "category": self.expense_category.id,
            "added_date": datetime.datetime.now().isoformat(),
            "notes": "Dinner with friends"
        }
        response = self.client.post("/api/entries/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["notes"], "Dinner with friends")

    def test_entry_update(self):
        """Test updating an existing entry"""
        data = {"amount": 150.75}
        response = self.client.put(f"/api/entries/{self.entry.id}/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["amount"], 150.75)

    def test_entry_partial_update(self):
        """Test partial update of an entry"""
        data = {"notes": "Updated notes"}
        response = self.client.patch(f"/api/entries/{self.entry.id}/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["notes"], "Updated notes")

    def test_entry_delete(self):
        """Test deleting an entry"""
        response = self.client.delete(f"/api/entries/{self.entry.id}/")
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Entry.objects.filter(id=self.entry.id).exists())

    def test_entry_filter_by_year(self):
        """Test filtering entries by year"""
        # Create entries with different years
        Entry.objects.create(
            amount=200.00,
            category=self.income_category,
            added_date=datetime.datetime(2023, 1, 15),
            notes="2023 entry"
        )
        Entry.objects.create(
            amount=300.00,
            category=self.income_category,
            added_date=datetime.datetime(2024, 1, 15),
            notes="2024 entry"
        )
        
        response = self.client.get("/api/entries/?year=2024")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["notes"], "2024 entry")

    def test_entry_filter_invalid_year(self):
        """Test filtering entries with invalid year returns empty list"""
        response = self.client.get("/api/entries/?year=invalid")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, [])

    # ==================== Authentication Tests ====================
    
    def test_login(self):
        """Test user login"""
        data = {"username": "testuser", "password": "testpass"}
        response = self.client.post("/api/auth/login/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("token", response.data)

    def test_login_invalid_credentials(self):
        """Test login with invalid credentials"""
        data = {"username": "testuser", "password": "wrongpass"}
        response = self.client.post("/api/auth/login/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_protected_endpoint_without_token(self):
        """Test accessing a protected endpoint without authentication"""
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/entries/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_protected_endpoint_with_token(self):
        """Test accessing a protected endpoint with valid token"""
        self.client.force_authenticate(user=None)
        token, _ = Token.objects.get_or_create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")
        response = self.client.get("/api/entries/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_create_entry_as_authenticated_user(self):
        """Test creating an entry as an authenticated user"""
        self.client.force_authenticate(user=None)
        token, _ = Token.objects.get_or_create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

        data = {
            "amount": 250.00,
            "category": self.income_category.id,
            "added_date": datetime.datetime.now().isoformat()
        }
        response = self.client.post("/api/entries/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    # ==================== Serializer Tests ====================
    
    def test_category_serializer_fields(self):
        """Test that CategorySerializer includes all required fields"""
        serializer = CategorySerializer(self.expense_category)
        expected_fields = ["id", "name", "pub_date", "category_type"]
        self.assertEqual(set(serializer.fields.keys()), set(expected_fields))

    def test_entry_serializer_fields(self):
        """Test that EntrySerializer includes all required fields"""
        serializer = EntrySerializer(self.entry)
        expected_fields = ["id", "amount", "category", "added_date", "notes", "created_date"]
        self.assertEqual(set(serializer.fields.keys()), set(expected_fields))

    def test_category_serializer_validation(self):
        """Test CategorySerializer validation"""
        serializer = CategorySerializer(data={})
        self.assertFalse(serializer.is_valid())
        self.assertIn("name", serializer.errors)

    def test_entry_serializer_validation(self):
        """Test EntrySerializer validation"""
        serializer = EntrySerializer(data={})
        self.assertFalse(serializer.is_valid())
        self.assertIn("amount", serializer.errors)

    def test_entry_serializer_with_valid_data(self):
        """Test EntrySerializer validation with valid data"""
        serializer = EntrySerializer(data={
            "amount": 50.00,
            "category": self.expense_category.id,
            "added_date": datetime.datetime.now().isoformat()
        })
        self.assertTrue(serializer.is_valid())
        self.assertEqual(serializer.validated_data["amount"], 50.00)