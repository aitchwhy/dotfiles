"""Simple tests for stopwatch OCR functionality."""

import sys
from pathlib import Path
from unittest.mock import patch

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))
import main


def test_extract_all_numbers():
    """Test number extraction from text."""
    # Test stopwatch format
    assert main.extract_all_numbers("00:00.60") == [("00:00.60", 600.0)]
    assert main.extract_all_numbers("01:30.50") == [("01:30.50", 90500.0)]
    
    # Test mixed content
    results = main.extract_all_numbers("Time: 00:15.25 and also 42")
    assert len(results) == 2
    assert results[0] == ("00:15.25", 15250.0)
    assert results[1] == ("42", 42.0)
    
    # Test plain numbers
    assert main.extract_all_numbers("just 123") == [("123", 123.0)]
    
    # Test no numbers
    assert main.extract_all_numbers("no numbers here") == []


def test_get_capture_timestamp(tmp_path):
    """Test timestamp extraction."""
    test_file = tmp_path / "test.png"
    test_file.write_text("dummy")
    
    timestamp = main.get_capture_timestamp(test_file)
    assert timestamp.endswith('Z')
    assert 'T' in timestamp


@patch('main.pytesseract.image_to_string')
@patch('main.cv2.imread')
def test_extract_reading_always_returns_value(mock_imread, mock_ocr, tmp_path):
    """Test that extract_reading always returns at least one value."""
    # Mock image read
    mock_imread.return_value = np.zeros((1334, 750, 3), dtype=np.uint8)
    
    # Mock OCR returns nothing
    mock_ocr.return_value = ""
    
    test_file = tmp_path / "test.png"
    test_file.write_text("dummy")
    
    results = main.extract_reading(test_file)
    assert len(results) >= 1
    assert results[0] == ("0", 0.0)


@patch('main.pytesseract.image_to_string')
@patch('main.cv2.imread')
def test_extract_reading_multiple_values(mock_imread, mock_ocr, tmp_path):
    """Test extracting multiple values from one image."""
    mock_imread.return_value = np.zeros((1334, 750, 3), dtype=np.uint8)
    mock_ocr.return_value = "00:00.60 and also 42 and 00:15.30"
    
    test_file = tmp_path / "test.png"
    test_file.write_text("dummy")
    
    results = main.extract_reading(test_file)
    assert len(results) == 3
    assert ("00:00.60", 600.0) in results
    assert ("42", 42.0) in results
    assert ("00:15.30", 15300.0) in results


@patch('main.extract_reading')
def test_process_dir(mock_extract, tmp_path):
    """Test directory processing."""
    # Create test images
    img1 = tmp_path / "img1.png"
    img2 = tmp_path / "img2.jpg"
    img1.write_text("dummy")
    img2.write_text("dummy")
    
    # Mock different readings for each image
    mock_extract.side_effect = [
        [("00:00.60", 600.0), ("42", 42.0)],  # img1 has 2 readings
        [("01:30.50", 90500.0)]  # img2 has 1 reading
    ]
    
    csv_path = tmp_path / "output.csv"
    main.process_dir(tmp_path, csv_path)
    
    assert csv_path.exists()
    
    with open(csv_path) as f:
        lines = f.readlines()
        assert len(lines) == 4  # header + 3 readings
        assert "capture_ts,reading_raw,reading_ms" in lines[0]
        
    # Check log file was created
    log_path = tmp_path / "extract_log.jsonl"
    assert log_path.exists()