#!/usr/bin/env python3

"""
local_llm.py - Local LLM integration via Ollama
Handles communication with local LLM models
"""

import requests
import json
from typing import Dict, Any, Optional


class LocalLLMClient:
    """Client for local LLM via Ollama"""
    
    def __init__(self, config: Dict[str, Any]):
        self.model = config.get("model", "gpt-oss:20b")
        self.endpoint = config.get("endpoint", "http://localhost:11434")
        self.temperature = config.get("temperature", 0.3)
        self.timeout = config.get("timeout", 60)
        
    def grade_submission(self, text: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Grade a student submission using local LLM
        
        Args:
            text: Student submission
            context: Assignment context
            
        Returns:
            Grading results dictionary
        """
        try:
            prompt = self._build_grading_prompt(text, context)
            response = self._call_ollama(prompt)
            return self._parse_response(response)
            
        except Exception as e:
            return {
                "error": True,
                "message": f"Local LLM error: {str(e)}",
                "total_score": 0,
                "confidence": 0.0,
                "model_used": self.model
            }
    
    def _build_grading_prompt(self, text: str, context: Dict[str, Any]) -> str:
        """Build grading prompt from context and submission"""
        prompt = "คุณเป็นผู้ช่วยอาจารย์ในการตรวจงานการศึกษา กรุณาตรวจและให้คะแนนงานนี้\n\n"
        
        if context.get("question"):
            prompt += f"## คำถาม:\n{context['question']}\n\n"
        
        if context.get("grading_criteria"):
            prompt += f"## เกณฑ์การประเมิน:\n{context['grading_criteria']}\n\n"
        
        if context.get("standard_answer"):
            prompt += f"## คำตอบมาตรฐาน:\n{context['standard_answer']}\n\n"
        
        prompt += f"## งานของนักเรียน:\n{text}\n\n"
        
        prompt += """## คำสั่ง:
กรุณาให้คะแนนและข้อเสนอแนะในรูปแบบ JSON ดังนี้:
{
    "total_score": <คะแนนรวม 0-100>,
    "breakdown": {
        "accuracy": <คะแนนความถูกต้อง>,
        "method": <คะแนนวิธีการ>,
        "presentation": <คะแนนการนำเสนอ>
    },
    "feedback": "<ข้อเสนอแนะรายละเอียด>",
    "strengths": "<จุดเด่น>",
    "improvements": "<ข้อเสนอแนะปรับปรุง>"
}"""
        
        return prompt
    
    def _call_ollama(self, prompt: str) -> str:
        """Make API call to Ollama"""
        url = f"{self.endpoint}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": self.temperature
            }
        }
        
        response = requests.post(
            url,
            json=payload,
            timeout=self.timeout
        )
        
        if response.status_code != 200:
            raise Exception(f"Ollama API error: {response.status_code} - {response.text}")
        
        result = response.json()
        return result.get("response", "")
    
    def _parse_response(self, response: str) -> Dict[str, Any]:
        """Parse LLM response into structured format"""
        try:
            # Try to extract JSON from response
            start = response.find('{')
            end = response.rfind('}') + 1
            
            if start != -1 and end > start:
                json_str = response[start:end]
                parsed = json.loads(json_str)
                parsed["model_used"] = self.model
                parsed["confidence"] = self._calculate_confidence(parsed)
                return parsed
            else:
                # Fallback parsing
                return self._fallback_parse(response)
                
        except json.JSONDecodeError:
            return self._fallback_parse(response)
    
    def _fallback_parse(self, response: str) -> Dict[str, Any]:
        """Fallback parsing when JSON extraction fails"""
        # Simple score extraction
        import re
        score_match = re.search(r'(\d+(?:\.\d+)?)\s*/\s*100', response)
        score = float(score_match.group(1)) if score_match else 50.0
        
        return {
            "total_score": score,
            "feedback": response,
            "confidence": 0.3,
            "model_used": self.model,
            "parsing_method": "fallback"
        }
    
    def _calculate_confidence(self, parsed_result: Dict[str, Any]) -> float:
        """Calculate confidence based on response completeness"""
        confidence = 0.5
        
        if "total_score" in parsed_result:
            confidence += 0.2
        
        if "breakdown" in parsed_result:
            confidence += 0.2
        
        if "feedback" in parsed_result and len(parsed_result["feedback"]) > 50:
            confidence += 0.1
        
        return min(1.0, confidence)
    
    def test_connection(self) -> bool:
        """Test connection to Ollama server"""
        try:
            url = f"{self.endpoint}/api/tags"
            response = requests.get(url, timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> list:
        """List available models"""
        try:
            url = f"{self.endpoint}/api/tags"
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                return [model["name"] for model in response.json().get("models", [])]
            return []
        except:
            return []


def main():
    """CLI interface for testing"""
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python local_llm.py <text> <context_json>")
        sys.exit(1)
    
    config = {
        "model": "gpt-oss:20b",
        "endpoint": "http://localhost:11434",
        "temperature": 0.3
    }
    
    client = LocalLLMClient(config)
    text = sys.argv[1]
    context = json.loads(sys.argv[2])
    
    result = client.grade_submission(text, context)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()