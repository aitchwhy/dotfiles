"""Generate financial reports."""
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, Any
import hashlib


def generate_manifest(
    inputs: Dict[str, str],
    outputs: list,
    domain: str = "finance"
) -> Dict[str, Any]:
    """Generate a manifest for the analysis run."""
    content = json.dumps({"inputs": inputs, "outputs": outputs}, sort_keys=True)
    content_hash = f"sha256:{hashlib.sha256(content.encode()).hexdigest()}"

    return {
        "version": "1.0",
        "domain": domain,
        "timestamp": datetime.now().isoformat(),
        "contentHash": content_hash,
        "inputs": inputs,
        "outputs": outputs
    }


def generate_markdown_report(insights: Dict[str, Any], output_path: Path) -> None:
    """Generate a markdown report from insights."""
    report = f"""# Financial Analysis Report

**Generated**: {datetime.now().strftime("%Y-%m-%d %H:%M")}

## Current Month Summary

| Metric | Value |
|--------|-------|
| Income | ${insights['current_month']['income']:,.2f} |
| Expenses | ${insights['current_month']['expenses']:,.2f} |
| Savings Rate | {insights['current_month']['savings_rate']:.1f}% |

## Top Spending Categories

| Category | Amount | % of Total |
|----------|--------|------------|
"""

    for cat in insights['top_categories']:
        report += f"| {cat['category']} | ${cat['total']:,.2f} | {cat['percent']:.1f}% |\n"

    report += f"\n## Trend\n\n{insights['trend'].title()}\n"

    output_path.write_text(report)
