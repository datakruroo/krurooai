#!/usr/bin/env python3

"""
privacy_utils.py - Privacy utility functions
Handles data sanitization and privacy protection
"""

import re
import json
from typing import Dict, Any, List, Tuple


def apply_privacy_preprocessing(text: str, privacy_rules: Dict[str, Any]) -> str:
    """
    Apply privacy preprocessing to text before sending to API
    
    Args:
        text: Input text to process
        privacy_rules: Privacy rules configuration
        
    Returns:
        Privacy-filtered text safe for API transmission
    """
    if not privacy_rules:
        return text
    
    filtered_text = text
    
    # Apply sensitive pattern filters
    sensitive_patterns = privacy_rules.get("sensitive_patterns", [])
    for pattern in sensitive_patterns:
        filtered_text = re.sub(pattern, "[REDACTED]", filtered_text, flags=re.IGNORECASE)
    
    # Apply specific redaction rules
    redaction_rules = privacy_rules.get("redaction_rules", {})
    
    # Replace names
    if redaction_rules.get("replace_names"):
        name_patterns = [
            r"ชื่อ\s*[:：]\s*\S+",
            r"นาย\s+\S+",
            r"นางสาว\s+\S+",
            r"นาง\s+\S+",
            r"เด็กชาย\s+\S+",
            r"เด็กหญิง\s+\S+"
        ]
        
        for pattern in name_patterns:
            filtered_text = re.sub(pattern, redaction_rules["replace_names"], 
                                 filtered_text, flags=re.IGNORECASE)
    
    # Replace IDs
    if redaction_rules.get("replace_ids"):
        id_patterns = [
            r"รหัส\s*[:：]\s*\d+",
            r"เลขที่\s*[:：]\s*\d+",
            r"รหัสนักเรียน\s*[:：]\s*\d+",
            r"\b\d{8,}\b"  # Long numeric IDs
        ]
        
        for pattern in id_patterns:
            filtered_text = re.sub(pattern, redaction_rules["replace_ids"], 
                                 filtered_text, flags=re.IGNORECASE)
    
    return filtered_text


def detect_personal_info(text: str) -> List[Dict[str, Any]]:
    """
    Detect potential personal information in text
    
    Args:
        text: Text to analyze
        
    Returns:
        List of detected personal information with locations
    """
    detections = []
    
    # Thai name patterns
    name_patterns = [
        (r"ชื่อ\s*[:：]\s*(\S+)", "name_field"),
        (r"(นาย\s+\S+)", "thai_name_male"),
        (r"(นางสาว\s+\S+)", "thai_name_female"),
        (r"(นาง\s+\S+)", "thai_name_married"),
        (r"(เด็กชาย\s+\S+)", "child_name_male"),
        (r"(เด็กหญิง\s+\S+)", "child_name_female")
    ]
    
    for pattern, category in name_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            detections.append({
                "type": "personal_name",
                "category": category,
                "text": match.group(1),
                "start": match.start(),
                "end": match.end(),
                "confidence": 0.9
            })
    
    # ID patterns
    id_patterns = [
        (r"รหัส\s*[:：]\s*(\d+)", "student_id"),
        (r"เลขที่\s*[:：]\s*(\d+)", "number_id"),
        (r"รหัสนักเรียน\s*[:：]\s*(\d+)", "student_code"),
        (r"\b(\d{13})\b", "thai_national_id"),
        (r"\b(\d{8,12})\b", "numeric_id")
    ]
    
    for pattern, category in id_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            confidence = 0.9 if category != "numeric_id" else 0.6
            detections.append({
                "type": "identifier",
                "category": category,
                "text": match.group(1),
                "start": match.start(),
                "end": match.end(),
                "confidence": confidence
            })
    
    # School/Institution patterns
    school_patterns = [
        (r"โรงเรียน(\S+)", "school_name"),
        (r"มหาวิทยาลัย(\S+)", "university_name"),
        (r"วิทยาลัย(\S+)", "college_name")
    ]
    
    for pattern, category in school_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            detections.append({
                "type": "institution",
                "category": category,
                "text": match.group(0),
                "start": match.start(),
                "end": match.end(),
                "confidence": 0.8
            })
    
    return detections


def create_privacy_report(text: str, filtered_text: str, privacy_rules: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a report on privacy filtering applied
    
    Args:
        text: Original text
        filtered_text: Privacy-filtered text
        privacy_rules: Applied privacy rules
        
    Returns:
        Privacy report dictionary
    """
    detections = detect_personal_info(text)
    
    report = {
        "original_length": len(text),
        "filtered_length": len(filtered_text),
        "bytes_redacted": len(text) - len(filtered_text),
        "detections_count": len(detections),
        "detections": detections,
        "rules_applied": list(privacy_rules.keys()) if privacy_rules else [],
        "privacy_score": calculate_privacy_score(detections, privacy_rules)
    }
    
    # Group detections by type
    report["summary"] = {}
    for detection in detections:
        detection_type = detection["type"]
        if detection_type not in report["summary"]:
            report["summary"][detection_type] = 0
        report["summary"][detection_type] += 1
    
    return report


def calculate_privacy_score(detections: List[Dict], privacy_rules: Dict) -> float:
    """
    Calculate a privacy score (0-1) based on detected information and rules
    
    Args:
        detections: List of detected personal information
        privacy_rules: Privacy rules configuration
        
    Returns:
        Privacy score where 1.0 is most private, 0.0 is least private
    """
    if not detections:
        return 1.0
    
    # Base score reduction for each detection
    score = 1.0
    
    for detection in detections:
        confidence = detection.get("confidence", 0.5)
        detection_type = detection.get("type", "unknown")
        
        # Different penalties for different types
        penalties = {
            "personal_name": 0.3,
            "identifier": 0.4,
            "institution": 0.2,
            "unknown": 0.1
        }
        
        penalty = penalties.get(detection_type, 0.1) * confidence
        score -= penalty
    
    # Bonus for having privacy rules
    if privacy_rules and privacy_rules.get("redaction_rules"):
        score += 0.2
    
    return max(0.0, min(1.0, score))


def validate_api_safety(text: str, threshold: float = 0.7) -> Tuple[bool, Dict[str, Any]]:
    """
    Validate if text is safe to send to external API
    
    Args:
        text: Text to validate
        threshold: Privacy score threshold (0-1)
        
    Returns:
        Tuple of (is_safe, privacy_report)
    """
    detections = detect_personal_info(text)
    privacy_score = calculate_privacy_score(detections, {})
    
    report = {
        "privacy_score": privacy_score,
        "is_safe": privacy_score >= threshold,
        "threshold": threshold,
        "detections_count": len(detections),
        "high_risk_detections": [
            d for d in detections 
            if d.get("confidence", 0) > 0.8 and d.get("type") in ["personal_name", "identifier"]
        ]
    }
    
    return report["is_safe"], report


def anonymize_for_api(text: str, method: str = "placeholder") -> str:
    """
    Anonymize text for API transmission using specified method
    
    Args:
        text: Text to anonymize
        method: Anonymization method ("placeholder", "hash", "remove")
        
    Returns:
        Anonymized text
    """
    if method == "placeholder":
        return apply_privacy_preprocessing(text, {
            "redaction_rules": {
                "replace_names": "[STUDENT]",
                "replace_ids": "[ID]"
            }
        })
    elif method == "hash":
        # Replace with deterministic hashes (simplified)
        import hashlib
        
        text_with_hashes = text
        detections = detect_personal_info(text)
        
        for detection in reversed(detections):  # Reverse to maintain positions
            original = detection["text"]
            hash_value = hashlib.md5(original.encode()).hexdigest()[:8]
            placeholder = f"[{detection['type'].upper()}_{hash_value}]"
            
            start, end = detection["start"], detection["end"]
            text_with_hashes = text_with_hashes[:start] + placeholder + text_with_hashes[end:]
        
        return text_with_hashes
    
    elif method == "remove":
        # Remove detected personal information entirely
        filtered_text = text
        detections = detect_personal_info(text)
        
        for detection in reversed(detections):
            start, end = detection["start"], detection["end"]
            filtered_text = filtered_text[:start] + filtered_text[end:]
        
        return filtered_text
    
    else:
        raise ValueError(f"Unknown anonymization method: {method}")


def main():
    """CLI interface for testing privacy utilities"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python privacy_utils.py <text> [method]")
        sys.exit(1)
    
    text = sys.argv[1]
    method = sys.argv[2] if len(sys.argv) > 2 else "detect"
    
    if method == "detect":
        detections = detect_personal_info(text)
        print(json.dumps(detections, indent=2, ensure_ascii=False))
    
    elif method in ["placeholder", "hash", "remove"]:
        anonymized = anonymize_for_api(text, method)
        print(f"Original: {text}")
        print(f"Anonymized: {anonymized}")
    
    elif method == "validate":
        is_safe, report = validate_api_safety(text)
        print(json.dumps(report, indent=2, ensure_ascii=False))
    
    else:
        print("Unknown method. Use: detect, placeholder, hash, remove, or validate")


if __name__ == "__main__":
    main()