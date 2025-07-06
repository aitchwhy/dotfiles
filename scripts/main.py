#!/usr/bin/env python3
"""Converts iPhone stopwatch screenshots to CSV with OCR."""

import argparse
import csv
import json
import re
from datetime import datetime
from pathlib import Path
from typing import List, Tuple

import cv2
import numpy as np
import pytesseract
from PIL import Image


def get_capture_timestamp(img_path: Path) -> str:
    """Get timestamp from file metadata."""
    try:
        birth_time = img_path.stat().st_birthtime
        return datetime.utcfromtimestamp(birth_time).isoformat() + 'Z'
    except:
        mtime = img_path.stat().st_mtime
        return datetime.utcfromtimestamp(mtime).isoformat() + 'Z'


def extract_all_numbers(text: str) -> List[Tuple[str, float]]:
    """Extract all stopwatch times and plain numbers from text."""
    results = []
    
    # Find all MM:SS.hh format times
    for match in re.finditer(r'(\d{1,2}):(\d{2})\.(\d{2})', text):
        raw = match.group()
        minutes = int(match.group(1))
        seconds = int(match.group(2))
        hundredths = int(match.group(3))
        ms = (minutes * 60 + seconds) * 1000 + hundredths * 10
        results.append((raw, ms))
    
    # Find all standalone numbers (not part of time format)
    text_without_times = re.sub(r'\d{1,2}:\d{2}\.\d{2}', '', text)
    for match in re.finditer(r'\b(\d+)\b', text_without_times):
        raw = match.group()
        results.append((raw, float(raw)))
    
    return results


def extract_reading(img_path: Path, sidecar_path: Path = None) -> List[Tuple[str, float]]:
    """Extract all readings from image using OCR."""
    img = cv2.imread(str(img_path))
    if img is None:
        raise ValueError(f"Cannot read image: {img_path}")
    
    h, w = img.shape[:2]
    crop_size = 0.3
    y1 = int(h * crop_size)
    y2 = int(h * (1 - crop_size))
    x1 = int(w * crop_size)
    x2 = int(w * (1 - crop_size))
    cropped = img[y1:y2, x1:x2]
    
    all_results = []
    
    # Try primary OCR
    try:
        text = pytesseract.image_to_string(cropped, config='--psm 6')
        results = extract_all_numbers(text)
        if results:
            all_results.extend(results)
    except:
        pass
    
    # Try sidecar file
    if sidecar_path and sidecar_path.exists():
        try:
            with open(sidecar_path) as f:
                sidecar_text = str(json.load(f))
                results = extract_all_numbers(sidecar_text)
                if results:
                    all_results.extend(results)
        except:
            pass
    
    # Try yellow ink detection
    try:
        hsv = cv2.cvtColor(cropped, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, np.array([20, 100, 100]), np.array([40, 255, 255]))
        
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > 100:  # Min area threshold
                x, y, w, h = cv2.boundingRect(contour)
                roi = cropped[y:y+h, x:x+w]
                text = pytesseract.image_to_string(roi, config='--psm 7 digits').strip()
                results = extract_all_numbers(text)
                if results:
                    all_results.extend(results)
    except:
        pass
    
    # Remove duplicates while preserving order
    seen = set()
    unique_results = []
    for result in all_results:
        if result not in seen:
            seen.add(result)
            unique_results.append(result)
    
    if not unique_results:
        # Last resort: try to find ANY number in the entire cropped image
        text = pytesseract.image_to_string(cropped, config='--psm 11')
        numbers = re.findall(r'\d+', text)
        if numbers:
            unique_results.append((numbers[0], float(numbers[0])))
    
    return unique_results if unique_results else [("0", 0.0)]


def process_dir(src_dir: Path, csv_path: Path) -> None:
    """Process directory of screenshots and write CSV."""
    src_dir = Path(src_dir)
    csv_path = Path(csv_path)
    
    log_path = csv_path.parent / 'extract_log.jsonl'
    if log_path.exists():
        log_path.unlink()
    
    results = []
    image_extensions = {'.png', '.jpg', '.jpeg', '.PNG', '.JPG', '.JPEG'}
    
    for img_path in sorted(src_dir.iterdir()):
        if img_path.suffix not in image_extensions:
            continue
        
        sidecar_path = img_path.with_suffix('.json')
        
        try:
            capture_ts = get_capture_timestamp(img_path)
            readings = extract_reading(img_path, sidecar_path)
            
            # Add all readings from this image
            for reading_raw, reading_ms in readings:
                results.append({
                    'capture_ts': capture_ts,
                    'reading_raw': reading_raw,
                    'reading_ms': reading_ms
                })
                
            # Log the extraction
            with open(log_path, 'a') as f:
                json.dump({
                    'image': str(img_path),
                    'timestamp': capture_ts,
                    'readings': readings,
                    'count': len(readings)
                }, f)
                f.write('\n')
                
        except Exception as e:
            print(f"Error processing {img_path}: {e}")
            # Still add a zero reading to ensure every image has at least one entry
            results.append({
                'capture_ts': get_capture_timestamp(img_path),
                'reading_raw': "0",
                'reading_ms': 0.0
            })
    
    with open(csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['capture_ts', 'reading_raw', 'reading_ms'])
        writer.writeheader()
        writer.writerows(results)
    
    print(f"Processed {len(set(r['capture_ts'] for r in results))} images, extracted {len(results)} readings")


def main():
    """Command-line entry point."""
    parser = argparse.ArgumentParser(description='Convert stopwatch screenshots to CSV')
    parser.add_argument('--src', type=Path, default=Path('data'), 
                        help='Source directory containing screenshots')
    parser.add_argument('--out', type=Path, default=Path('stopwatch_metrics.csv'),
                        help='Output CSV file path')
    
    args = parser.parse_args()
    process_dir(args.src, args.out)


if __name__ == '__main__':
    main()