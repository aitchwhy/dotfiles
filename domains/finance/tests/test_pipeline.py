"""Tests for finance pipeline."""
import pytest
import polars as pl
from pathlib import Path

# Add parent to path for imports
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from pipeline.analyze import compute_monthly_summary, compute_category_breakdown


@pytest.fixture
def sample_transactions():
    """Create sample transaction data."""
    return pl.DataFrame({
        "date": ["2025-01-15", "2025-01-20", "2025-02-10"],
        "description": ["Salary", "Groceries", "Rent"],
        "amount": [5000.0, -200.0, -2000.0],
        "category": ["Income", "Food", "Housing"],
        "account": ["Checking", "Credit Card", "Checking"]
    })


def test_compute_monthly_summary(sample_transactions):
    """Test monthly summary computation."""
    result = compute_monthly_summary(sample_transactions)
    assert len(result) == 2  # Jan and Feb
    assert "income" in result.columns
    assert "expenses" in result.columns
    assert "savings_rate" in result.columns


def test_compute_category_breakdown(sample_transactions):
    """Test category breakdown computation."""
    result = compute_category_breakdown(sample_transactions)
    assert len(result) == 2  # Food and Housing (expenses only)
    assert "total" in result.columns
    assert "percent" in result.columns
