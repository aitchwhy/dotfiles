import pandas as pd
import numpy as np


def clean_csv(
    input_file="todoistprojectsreadmerged.csv", output_file="cleaned_merged.csv"
):
    """
    Clean up a merged CSV file from an online service by:
    1. Removing duplicate headers
    2. Standardizing column types
    3. Handling missing values
    4. Removing completely duplicate rows
    5. Standardizing date formats

    Args:
        input_file: Path to the input CSV file
        output_file: Path to the output cleaned CSV file
    """
    print(f"Reading file: {input_file}")

    try:
        # First pass - read the file to detect potential header rows in the middle
        with open(input_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        # Get the header from the first line
        header = lines[0].strip()

        # Find lines that match the header pattern (duplicate headers)
        header_indices = [i for i, line in enumerate(lines) if line.strip() == header]

        if len(header_indices) > 1:
            print(f"Found {len(header_indices)} potential header rows")

            # Create a clean file without the duplicate headers
            clean_lines = [lines[0]]  # Keep first header
            current_idx = 1

            for idx in header_indices[1:]:
                # Add lines between current position and next header (excluding the header)
                clean_lines.extend(lines[current_idx:idx])
                current_idx = idx + 1

            # Add remaining lines after the last duplicate header
            clean_lines.extend(lines[current_idx:])

            # Write temporary clean file
            temp_file = "temp_cleaned.csv"
            with open(temp_file, "w", encoding="utf-8") as f:
                f.writelines(clean_lines)

            # Now read the cleaned file
            df = pd.read_csv(temp_file, dtype=str)
        else:
            # No duplicate headers, read directly
            df = pd.read_csv(input_file, dtype=str)

    except Exception as e:
        print(f"Error in initial processing: {str(e)}")
        # Try reading directly as fallback
        df = pd.read_csv(input_file, dtype=str)

    original_rows = len(df)
    print(f"Original row count: {original_rows}")

    # Step 1: Remove completely duplicate rows
    df = df.drop_duplicates()
    print(f"After removing duplicates: {len(df)} rows")

    # Step 2: Standardize column names (lowercase, no spaces)
    df.columns = [col.strip().upper() for col in df.columns]

    # Step 3: Process the data types
    try:
        # Convert numeric columns
        numeric_columns = ["PRIORITY", "INDENT", "DURATION"]
        for col in numeric_columns:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors="coerce")

        # Convert date columns - handle different formats
        date_columns = ["DATE", "DEADLINE"]
        for col in date_columns:
            if col in df.columns:
                # Try to standardize dates - handle both explicit dates and timestamps
                df[col] = pd.to_datetime(df[col], errors="coerce")
    except Exception as e:
        print(f"Warning when converting data types: {str(e)}")

    # Step 4: Handle missing values appropriately
    # Fill missing numeric values with 0 or NaN depending on context
    if "PRIORITY" in df.columns:
        df["PRIORITY"] = df["PRIORITY"].fillna(0)

    if "INDENT" in df.columns:
        df["INDENT"] = df["INDENT"].fillna(0)

    # Empty strings for text fields with NaN
    text_columns = ["TYPE", "CONTENT", "DESCRIPTION", "AUTHOR", "RESPONSIBLE"]
    for col in text_columns:
        if col in df.columns:
            df[col] = df[col].fillna("")

    # Step 5: Remove rows with critical data missing
    # If you want to remove rows with missing TYPE or CONTENT:
    # df = df.dropna(subset=['TYPE', 'CONTENT'])

    # Step 6: Save the cleaned data
    df.to_csv(output_file, index=False, date_format="%Y-%m-%d")

    print(f"Successfully cleaned data and saved to {output_file}")
    print(f"Removed {original_rows - len(df)} duplicate or invalid rows")
    print(f"Final row count: {len(df)}")

    # Return statistics about the cleanup
    return {
        "original_rows": original_rows,
        "final_rows": len(df),
        "removed_rows": original_rows - len(df),
        "columns": list(df.columns),
    }


# Execute the function
if __name__ == "__main__":
    stats = clean_csv()
    print("\nColumn Summary:")
    for col in stats["columns"]:
        print(f"- {col}")
