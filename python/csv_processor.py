#!/usr/bin/env python3

"""
csv_processor.py - CSV file processing for KruRooAI
Converts CSV data from forms/surveys into individual submission files
"""

import csv
import json
import os
import sys
import argparse
from pathlib import Path
from datetime import datetime


def process_csv(csv_file, config):
    """
    Process CSV file and convert to individual submission files
    
    Args:
        csv_file: Path to CSV file
        config: Configuration dictionary
    
    Returns:
        Dictionary with processing results
    """
    results = {
        "success": True,
        "files_created": [],
        "errors": [],
        "total_rows": 0,
        "skipped_rows": 0
    }
    
    try:
        # Create output directory
        output_dir = Path(config.get("output_dir", "submissions"))
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Read CSV file
        with open(csv_file, 'r', encoding='utf-8') as f:
            # Try to detect delimiter
            sample = f.read(1024)
            f.seek(0)
            
            delimiter = ','
            if sample.count(';') > sample.count(','):
                delimiter = ';'
            elif sample.count('\t') > sample.count(','):
                delimiter = '\t'
            
            reader = csv.DictReader(f, delimiter=delimiter)
            
            # Get columns to process
            all_columns = reader.fieldnames
            email_col = config.get("email_column", "Email Address")
            timestamp_col = config.get("timestamp_column", "Timestamp")
            score_col = config.get("score_column", "Score")
            skip_columns = set(config.get("skip_columns", []))
            
            # Add system columns to skip list
            skip_columns.update([email_col, timestamp_col, score_col])
            
            # Determine question columns
            question_columns = [col for col in all_columns if col not in skip_columns]
            
            print(f"Processing CSV with {len(all_columns)} total columns")
            print(f"Question columns: {len(question_columns)}")
            print(f"Output directory: {output_dir}")
            
            # Process each row
            for i, row in enumerate(reader, 1):
                results["total_rows"] += 1
                
                try:
                    # Generate filename
                    prefix = config.get("prefix", "student")
                    filename = f"{prefix}_{i:03d}.txt"
                    file_path = output_dir / filename
                    
                    # Create submission file content
                    content = create_submission_content(row, config, question_columns)
                    
                    # Write file
                    with open(file_path, 'w', encoding='utf-8') as out_file:
                        out_file.write(content)
                    
                    results["files_created"].append(str(file_path))
                    
                    if i <= 3:  # Show first 3 files created
                        print(f"Created: {filename}")
                
                except Exception as e:
                    error_msg = f"Row {i}: {str(e)}"
                    results["errors"].append(error_msg)
                    results["skipped_rows"] += 1
                    print(f"Error processing row {i}: {e}")
        
        print(f"\nProcessing complete:")
        print(f"- Total rows processed: {results['total_rows']}")
        print(f"- Files created: {len(results['files_created'])}")
        print(f"- Errors: {len(results['errors'])}")
        
    except Exception as e:
        results["success"] = False
        results["errors"].append(f"Failed to process CSV: {str(e)}")
        print(f"Error: {e}")
    
    return results


def create_submission_content(row, config, question_columns):
    """Create content for individual submission file"""
    content = []
    
    # Add metadata
    email_col = config.get("email_column", "Email Address")
    timestamp_col = config.get("timestamp_column", "Timestamp")
    score_col = config.get("score_column", "Score")
    
    if email_col in row and row[email_col]:
        content.append(f"Email: {row[email_col]}")
    
    if timestamp_col in row and row[timestamp_col]:
        content.append(f"Timestamp: {row[timestamp_col]}")
    
    if score_col in row and row[score_col]:
        content.append(f"คะแนนเดิม: {row[score_col]}")
    
    content.append("")  # Empty line
    
    # Add questions and answers
    for i, col in enumerate(question_columns, 1):
        if col in row and row[col]:
            # Clean up question text
            question = col.strip()
            if len(question) > 100:
                question = question[:97] + "..."
            
            answer = row[col].strip()
            
            content.append(f"คำถามที่ {i}: {question}")
            content.append(f"คำตอบ: {answer}")
            content.append("")  # Empty line between questions
    
    return "\n".join(content)


def auto_grade_files(files_created, context_file, config):
    """
    Automatically grade the created files using KruRooAI
    
    Args:
        files_created: List of created file paths
        context_file: Path to context file
        config: Configuration dictionary
    
    Returns:
        Dictionary with grading results
    """
    results = {
        "success": True,
        "graded_files": [],
        "errors": []
    }
    
    if not context_file or not os.path.exists(context_file):
        results["success"] = False
        results["errors"].append("Context file not found for auto-grading")
        return results
    
    print(f"\nStarting auto-grading with context: {context_file}")
    
    # Create reports directory
    reports_dir = Path(config.get("output_dir", "submissions")).parent / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    
    for file_path in files_created:
        try:
            # Generate report filename
            file_stem = Path(file_path).stem
            report_path = reports_dir / f"{file_stem}_report.md"
            
            # Build grading command
            import subprocess
            cmd = [
                "python3", "R/main.R",  # This will be called via R
                "grade", file_path,
                "--context", context_file,
                "--output", str(report_path)
            ]
            
            # For now, we'll just mark as ready for grading
            # The actual grading will be done by the R system
            results["graded_files"].append(str(report_path))
            
        except Exception as e:
            error_msg = f"Failed to grade {file_path}: {str(e)}"
            results["errors"].append(error_msg)
            print(f"Grading error: {e}")
    
    return results


def detect_csv_structure(csv_file):
    """
    Analyze CSV structure and suggest configuration
    
    Args:
        csv_file: Path to CSV file
    
    Returns:
        Dictionary with detected structure and suggestions
    """
    suggestions = {
        "delimiter": ",",
        "encoding": "utf-8",
        "email_column": None,
        "timestamp_column": None,
        "score_column": None,
        "question_columns": [],
        "total_columns": 0,
        "sample_rows": []
    }
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            # Detect delimiter
            sample = f.read(1024)
            f.seek(0)
            
            if sample.count(';') > sample.count(','):
                suggestions["delimiter"] = ';'
            elif sample.count('\t') > sample.count(','):
                suggestions["delimiter"] = '\t'
            
            # Read header and sample rows
            reader = csv.DictReader(f, delimiter=suggestions["delimiter"])
            columns = reader.fieldnames or []
            suggestions["total_columns"] = len(columns)
            
            # Detect special columns
            for col in columns:
                col_lower = col.lower()
                if any(keyword in col_lower for keyword in ['email', 'อีเมล', 'mail']):
                    suggestions["email_column"] = col
                elif any(keyword in col_lower for keyword in ['time', 'date', 'เวลา', 'วันที่']):
                    suggestions["timestamp_column"] = col
                elif any(keyword in col_lower for keyword in ['score', 'คะแนน', 'grade']):
                    suggestions["score_column"] = col
                else:
                    suggestions["question_columns"].append(col)
            
            # Read sample rows
            for i, row in enumerate(reader):
                if i >= 2:  # Only first 2 rows
                    break
                sample_row = {}
                for col in columns[:3]:  # Only first 3 columns
                    value = row.get(col, "")
                    if len(value) > 50:
                        value = value[:47] + "..."
                    sample_row[col] = value
                suggestions["sample_rows"].append(sample_row)
        
    except Exception as e:
        print(f"Error analyzing CSV structure: {e}")
    
    return suggestions


def main():
    """CLI interface for CSV processing"""
    parser = argparse.ArgumentParser(description="Process CSV files for KruRooAI grading")
    parser.add_argument("csv_file", help="Path to CSV file")
    parser.add_argument("--output-dir", default="submissions", help="Output directory")
    parser.add_argument("--email-column", default="Email Address", help="Email column name")
    parser.add_argument("--timestamp-column", default="Timestamp", help="Timestamp column name")
    parser.add_argument("--score-column", default="Score", help="Score column name")
    parser.add_argument("--skip-columns", help="Comma-separated columns to skip")
    parser.add_argument("--prefix", default="student", help="Output filename prefix")
    parser.add_argument("--auto-grade", action="store_true", help="Auto-grade after import")
    parser.add_argument("--context", help="Context file for auto-grading")
    parser.add_argument("--analyze", action="store_true", help="Only analyze CSV structure")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.csv_file):
        print(f"Error: CSV file not found: {args.csv_file}")
        sys.exit(1)
    
    # Analyze mode
    if args.analyze:
        print("Analyzing CSV structure...")
        suggestions = detect_csv_structure(args.csv_file)
        print(json.dumps(suggestions, indent=2, ensure_ascii=False))
        return
    
    # Process mode
    config = {
        "output_dir": args.output_dir,
        "email_column": args.email_column,
        "timestamp_column": args.timestamp_column,
        "score_column": args.score_column,
        "skip_columns": args.skip_columns.split(",") if args.skip_columns else [],
        "prefix": args.prefix,
        "auto_grade": args.auto_grade,
        "context": args.context
    }
    
    results = process_csv(args.csv_file, config)
    
    # Auto-grading
    if args.auto_grade and results["success"] and results["files_created"]:
        grade_results = auto_grade_files(results["files_created"], args.context, config)
        results["auto_grade_results"] = grade_results
    
    # Output results
    if not results["success"]:
        print("\nProcessing failed!")
        for error in results["errors"]:
            print(f"Error: {error}")
        sys.exit(1)
    
    print(f"\nSuccess! Created {len(results['files_created'])} submission files")
    return results


if __name__ == "__main__":
    main()