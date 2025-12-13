#!/usr/bin/env python3
"""
Quick entry point for running the health analysis pipeline.

Usage:
    ./run_analysis.py           # Run full pipeline
    ./run_analysis.py --force   # Force regeneration
    ./run_analysis.py --help    # Show all options
"""

import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from pipeline.main import main

if __name__ == "__main__":
    main()
