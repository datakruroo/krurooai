#!/usr/bin/env python3

"""
api_llm.py - OpenAI API integration
Handles communication with OpenAI GPT models
"""

import os
import json
import requests
from typing import Dict, Any, Optional


class OpenAIClient:
    """Client for OpenAI API"""
    
    def __init__(self, config: Dict[str, Any]):
        self.model = config.get("model", "gpt-3.5-turbo")
        self.api_key = self._get_api_key(config.get("api_key_env", "OPENAI_API_KEY"))
        self.temperature = config.get("temperature", 0.3)
        self.max_tokens = config.get("max_tokens", 2000)
        self.timeout = config.get("timeout", 60)
        self.base_url = config.get("base_url", "https://api.openai.com/v1")
        self.privacy_mode = config.get("privacy_mode", True)
        
    def _get_api_key(self, env_var: str) -> str:
        """Get API key from environment variable"""
        api_key = os.getenv(env_var)
        if not api_key:
            raise ValueError(f"API key not found in environment variable: {env_var}")
        return api_key
    
    def grade_submission(self, text: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Grade a student submission using OpenAI API
        
        Args:
            text: Student submission (should be privacy-filtered)
            context: Assignment context
            
        Returns:
            Grading results dictionary
        """
        try:
            messages = self._build_messages(text, context)
            response = self._call_openai(messages)
            return self._parse_response(response)
            
        except Exception as e:
            return {
                "error": True,
                "message": f"OpenAI API error: {str(e)}",
                "total_score": 0,
                "confidence": 0.0,
                "model_used": self.model
            }
    
    def _build_messages(self, text: str, context: Dict[str, Any]) -> list:
        """Build chat messages for OpenAI API"""
        system_message = """You are an educational AI assistant for grading student work. 
You should provide objective, constructive feedback and accurate scoring based on the given criteria.
Always respond in Thai and provide scores in JSON format."""
        
        user_content = "กรุณาตรวจและให้คะแนนงานนี้ตามเกณฑ์ที่กำหนด\n\n"
        
        if context.get("question"):
            user_content += f"## คำถาม:\n{context['question']}\n\n"
        
        if context.get("grading_criteria"):
            user_content += f"## เกณฑ์การประเมิน:\n{context['grading_criteria']}\n\n"
        
        if context.get("standard_answer"):
            user_content += f"## คำตอบมาตรฐาน:\n{context['standard_answer']}\n\n"
        
        user_content += f"## งานของนักเรียน:\n{text}\n\n"
        
        user_content += """## รูปแบบการตอบ:
กรุณาตอบในรูปแบบ JSON ดังนี้:
{
    "total_score": <คะแนนรวม 0-100>,
    "breakdown": {
        "accuracy": <คะแนนความถูกต้อง>,
        "method": <คะแนนวิธีการ>,
        "presentation": <คะแนนการนำเสนอ>
    },
    "feedback": "<ข้อเสนอแนะรายละเอียดภาษาไทย>",
    "strengths": "<จุดเด่นของงาน>",
    "improvements": "<ข้อเสนอแนะการพัฒนา>"
}"""
        
        return [
            {"role": "system", "content": system_message},
            {"role": "user", "content": user_content}
        ]
    
    def _call_openai(self, messages: list) -> Dict[str, Any]:
        """Make API call to OpenAI"""
        url = f"{self.base_url}/chat/completions"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens
        }
        
        response = requests.post(
            url,
            json=payload,
            headers=headers,
            timeout=self.timeout
        )
        
        if response.status_code != 200:
            raise Exception(f"OpenAI API error: {response.status_code} - {response.text}")
        
        return response.json()
    
    def _parse_response(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """Parse OpenAI API response"""
        try:
            content = response["choices"][0]["message"]["content"]
            
            # Extract JSON from response
            start = content.find('{')
            end = content.rfind('}') + 1
            
            if start != -1 and end > start:
                json_str = content[start:end]
                parsed = json.loads(json_str)
                
                # Add metadata
                parsed["model_used"] = self.model
                parsed["confidence"] = self._calculate_confidence(parsed, response)
                parsed["usage"] = response.get("usage", {})
                
                return parsed
            else:
                return self._fallback_parse(content)
                
        except (KeyError, json.JSONDecodeError, IndexError) as e:
            return self._fallback_parse(str(e))
    
    def _fallback_parse(self, content: str) -> Dict[str, Any]:
        """Fallback parsing when structured extraction fails"""
        import re
        
        # Try to extract score
        score_patterns = [
            r'(\d+(?:\.\d+)?)\s*/\s*100',
            r'คะแนน[:\s]*(\d+(?:\.\d+)?)',
            r'score[:\s]*(\d+(?:\.\d+)?)'
        ]
        
        score = 50.0  # Default score
        for pattern in score_patterns:
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                score = float(match.group(1))
                break
        
        return {
            "total_score": min(100.0, score),
            "feedback": content,
            "confidence": 0.3,
            "model_used": self.model,
            "parsing_method": "fallback"
        }
    
    def _calculate_confidence(self, parsed_result: Dict[str, Any], raw_response: Dict[str, Any]) -> float:
        """Calculate confidence based on response quality"""
        confidence = 0.6  # Base confidence for API
        
        # Higher confidence if structured response
        if "breakdown" in parsed_result:
            confidence += 0.2
        
        if "feedback" in parsed_result and len(parsed_result["feedback"]) > 100:
            confidence += 0.1
        
        # Check token usage efficiency
        usage = raw_response.get("usage", {})
        if usage.get("completion_tokens", 0) > 50:
            confidence += 0.1
        
        return min(1.0, confidence)
    
    def test_connection(self) -> bool:
        """Test connection to OpenAI API"""
        try:
            url = f"{self.base_url}/models"
            headers = {"Authorization": f"Bearer {self.api_key}"}
            response = requests.get(url, headers=headers, timeout=10)
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> list:
        """List available models"""
        try:
            url = f"{self.base_url}/models"
            headers = {"Authorization": f"Bearer {self.api_key}"}
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                models = response.json().get("data", [])
                return [model["id"] for model in models if "gpt" in model["id"]]
            return []
        except:
            return []


def main():
    """CLI interface for testing"""
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python api_llm.py <text> <context_json>")
        sys.exit(1)
    
    config = {
        "model": "gpt-3.5-turbo",
        "api_key_env": "OPENAI_API_KEY",
        "temperature": 0.3
    }
    
    try:
        client = OpenAIClient(config)
        text = sys.argv[1]
        context = json.loads(sys.argv[2])
        
        result = client.grade_submission(text, context)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(json.dumps({"error": True, "message": str(e)}, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()