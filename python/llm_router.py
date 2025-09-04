#!/usr/bin/env python3

"""
llm_router.py - LLM backend router for KruRooAI
Handles routing to different LLM backends (local, OpenAI)
"""

import json
import sys
from typing import Dict, Any, Optional
from local_llm import LocalLLMClient
from api_llm import OpenAIClient
from privacy_utils import apply_privacy_preprocessing


def route_to_llm(text: str, context: Dict[str, Any], backend: str = "local", config: Optional[Dict] = None) -> Dict[str, Any]:
    """
    Route text and context to appropriate LLM backend
    
    Args:
        text: Student submission text
        context: Assignment context from markdown
        backend: Backend type ("local", "openai", "hybrid")
        config: Backend configuration
    
    Returns:
        Dictionary with grading results
    """
    if config is None:
        config = {}
    
    try:
        # Apply privacy preprocessing if using API backend
        if backend in ["openai", "hybrid"]:
            text = apply_privacy_preprocessing(text, config.get("privacy_rules", {}))
        
        # Route to appropriate backend
        if backend == "local":
            return route_to_local(text, context, config.get("local", {}))
        elif backend == "openai":
            return route_to_openai(text, context, config.get("openai", {}))
        elif backend == "hybrid":
            return route_to_hybrid(text, context, config)
        else:
            raise ValueError(f"Unknown backend: {backend}")
            
    except Exception as e:
        return {
            "error": True,
            "message": str(e),
            "total_score": 0,
            "confidence": 0.0
        }


def route_to_local(text: str, context: Dict[str, Any], config: Dict) -> Dict[str, Any]:
    """Route to local LLM (Ollama)"""
    client = LocalLLMClient(config)
    return client.grade_submission(text, context)


def route_to_openai(text: str, context: Dict[str, Any], config: Dict) -> Dict[str, Any]:
    """Route to OpenAI API"""
    client = OpenAIClient(config)
    return client.grade_submission(text, context)


def route_to_hybrid(text: str, context: Dict[str, Any], config: Dict) -> Dict[str, Any]:
    """Use both local and API, return averaged results"""
    local_result = route_to_local(text, context, config.get("local", {}))
    api_result = route_to_openai(text, context, config.get("openai", {}))
    
    # Average scores and combine feedback
    avg_score = (local_result.get("total_score", 0) + api_result.get("total_score", 0)) / 2
    
    combined_feedback = f"Local LLM: {local_result.get('feedback', 'No feedback')}\n\n"
    combined_feedback += f"API LLM: {api_result.get('feedback', 'No feedback')}"
    
    return {
        "total_score": avg_score,
        "feedback": combined_feedback,
        "confidence": (local_result.get("confidence", 0) + api_result.get("confidence", 0)) / 2,
        "model_used": "hybrid",
        "local_result": local_result,
        "api_result": api_result
    }


def extract_feedback(response: str) -> Dict[str, Any]:
    """
    Extract structured feedback from LLM response
    
    Args:
        response: Raw LLM response text
        
    Returns:
        Dictionary with extracted feedback components
    """
    # Try to parse JSON response first
    try:
        if response.strip().startswith('{'):
            return json.loads(response)
    except json.JSONDecodeError:
        pass
    
    # Fallback to text parsing
    lines = response.split('\n')
    result = {
        "total_score": 0,
        "feedback": response,
        "confidence": 0.5
    }
    
    # Look for score patterns
    for line in lines:
        if 'score' in line.lower() or 'คะแนน' in line:
            try:
                score = extract_score_from_line(line)
                if score is not None:
                    result["total_score"] = score
            except:
                continue
    
    return result


def extract_score_from_line(line: str) -> Optional[float]:
    """Extract numeric score from a line of text"""
    import re
    
    # Look for patterns like "Score: 85/100" or "คะแนน: 85"
    patterns = [
        r'(\d+(?:\.\d+)?)\s*/\s*\d+',  # 85/100
        r'(\d+(?:\.\d+)?)\s*(?:points?|คะแนน|pts)',  # 85 points
        r'(?:score|คะแนน).*?(\d+(?:\.\d+)?)'  # score: 85
    ]
    
    for pattern in patterns:
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            return float(match.group(1))
    
    return None


def calculate_confidence(response: Dict[str, Any]) -> float:
    """
    Calculate confidence score based on response characteristics
    
    Args:
        response: LLM response dictionary
        
    Returns:
        Confidence score between 0.0 and 1.0
    """
    confidence = 0.5  # Base confidence
    
    # Higher confidence if score is provided
    if "total_score" in response and response["total_score"] > 0:
        confidence += 0.2
    
    # Higher confidence if detailed feedback is provided
    if "feedback" in response and len(response["feedback"]) > 100:
        confidence += 0.2
    
    # Lower confidence if error occurred
    if response.get("error", False):
        confidence -= 0.3
    
    return max(0.0, min(1.0, confidence))


def main():
    """CLI interface for testing the router"""
    if len(sys.argv) < 4:
        print("Usage: python llm_router.py <text> <context_json> <backend> [config_json]")
        sys.exit(1)
    
    text = sys.argv[1]
    context = json.loads(sys.argv[2])
    backend = sys.argv[3]
    config = json.loads(sys.argv[4]) if len(sys.argv) > 4 else {}
    
    result = route_to_llm(text, context, backend, config)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()