"""Financial analysis functions."""
import polars as pl
from typing import Dict, Any


def compute_monthly_summary(df: pl.DataFrame) -> pl.DataFrame:
    """Compute monthly income, expenses, and savings rate."""
    # Ensure date column is datetime
    if "date" in df.columns:
        df = df.with_columns(pl.col("date").str.to_datetime().alias("date"))

    monthly = df.group_by(
        pl.col("date").dt.year().alias("year"),
        pl.col("date").dt.month().alias("month")
    ).agg([
        pl.col("amount").filter(pl.col("amount") > 0).sum().alias("income"),
        pl.col("amount").filter(pl.col("amount") < 0).sum().abs().alias("expenses"),
    ]).with_columns(
        ((pl.col("income") - pl.col("expenses")) / pl.col("income") * 100)
        .alias("savings_rate")
    ).sort(["year", "month"])

    return monthly


def compute_category_breakdown(df: pl.DataFrame) -> pl.DataFrame:
    """Compute spending by category."""
    expenses = df.filter(pl.col("amount") < 0)

    by_category = expenses.group_by("category").agg([
        pl.col("amount").sum().abs().alias("total"),
        pl.col("amount").count().alias("count")
    ]).sort("total", descending=True)

    total_expenses = by_category["total"].sum()
    by_category = by_category.with_columns(
        (pl.col("total") / total_expenses * 100).alias("percent")
    )

    return by_category


def generate_insights(monthly: pl.DataFrame, categories: pl.DataFrame) -> Dict[str, Any]:
    """Generate key financial insights."""
    latest_month = monthly.tail(1)

    return {
        "current_month": {
            "income": float(latest_month["income"][0]) if len(latest_month) > 0 else 0,
            "expenses": float(latest_month["expenses"][0]) if len(latest_month) > 0 else 0,
            "savings_rate": float(latest_month["savings_rate"][0]) if len(latest_month) > 0 else 0,
        },
        "top_categories": categories.head(5).to_dicts(),
        "trend": "improving" if len(monthly) > 1 and monthly["savings_rate"][-1] > monthly["savings_rate"][-2] else "stable"
    }
