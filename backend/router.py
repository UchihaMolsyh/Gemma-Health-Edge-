"""Gemma Health Edge — MiddleMan Router.

Core API endpoints for:
- Chat streaming (local llama.cpp, Google API, OpenRouter, Ollama)
- Health checks and system status
- Session management and syncing
- Report import/export
- RLHF voting
- Emergency detection and greeting handling
- Content critique and guardrails
"""
import asyncio, base64, datetime, json, logging, random, re, time, uuid
from pathlib import Path
from typing import AsyncGenerator
from cachetools import TTLCache
import httpx
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
from models import ChatRequest, ChatResponse, HealthResponse, VoteRequest, ReportImportRequest, ReportImportResponse, Message
from config import settings, get_http_client, validate_api_key
from research import fetch_research_context
from auth import limiter
from critic import critique_response, ResponseCritic
from llm_guardrail import validate_with_llm, LLMGuardrail, get_guardrail_circuit_status
from database import ClinicalProfile
from hardware_detector import HardwareDetector
from model_manager import get_vision_supported


logger = logging.getLogger("ghe.middleman")
api_router = APIRouter()
_start_time = time.time()

GEMMA4_PREFIXES = ("gemma-4", "google/gemma-4")
DEFAULT_MODEL = "gemma-4-e4b-it"

SYSTEM_PROMPT = """You are Gemma Health Edge, a caring health information assistant.
RULES:
1. You are NOT a doctor. ALWAYS remind users to consult a healthcare professional.
2. Provide clear, structured, step-by-step health information.
3. For images: describe ONLY what you can explicitly see. Never invent details.
4. ANATOMICAL ACCURACY: carefully distinguish foot/hand, toe/finger, left/right.
5. NEVER diagnose diseases or prescribe medications.
6. If unsure, say so instead of guessing.
7. Use severity indicators: 🟢 Minor | 🟡 Monitor | 🔴 Urgent
EMERGENCY NUMBERS: USA/Canada 911 | UK 999 | EU 112 | AU 000 | NZ 111 | Japan 119 | SK 119 | China 120 | India 112 | Brazil 192 | Mexico 911
Mental health: USA 988 | UK 116 123 | AU 13 11 14
Poison: USA 1-800-222-1222 | UK 111 | AU 13 11 26
⚕️ Always consult a qualified healthcare professional for proper diagnosis and treatment."""

def _enforce_gemma4(model: str | None) -> str:
    """Validate that the requested model is a Gemma 4 model.
    
    Args:
        model: Model name or identifier
        
    Returns:
        Validated model name
        
    Raises:
        HTTPException: If model is not a Gemma 4 model
    """
    if model is None: return DEFAULT_MODEL
    if not any(model.lower().startswith(p) for p in GEMMA4_PREFIXES):
        logger.warning(f"Rejected non-Gemma4 model: {model}")
        raise HTTPException(400, f"Model '{model}' rejected. Only Gemma 4 models supported.")
    return model

def _extract_text(content: str | list) -> str:
    if isinstance(content, str): return content
    if isinstance(content, list):
        return " ".join(item.get("text", "") if isinstance(item, dict) and "text" in item else (item if isinstance(item, str) else "") for item in content)
    return str(content)

GREETING_PATTERNS = frozenset({
    "hello", "hi", "hey", "greetings", "good morning", "good afternoon", "good evening", "good day", "what's up", "howdy", "sup", "how are you", "how do you do",
    "hola", "buenos dias", "buenas tardes", "buenas noches", "que tal", "como estas", "bonjour", "bonsoir", "salut", "ca va", "comment allez-vous",
    "guten tag", "guten morgen", "guten abend", "hallo", "wie geht's", "ciao", "buongiorno", "buonasera", "come stai", "ola", "bom dia", "boa tarde", "boa noite", "como vai",
    "ni hao", "zao shang hao", "wan shang hao", "nin hao", "konnichiwa", "ohayou", "konbanwa", "moshi moshi", "annyeong", "annyeonghaseyo", "jal jinesseoyo",
    "privet", "zdravstvuyte", "dobroe utro", "dobryy den", "dobryy vecher", "namaste", "namaskar", "kaise ho", "suprabhat", "marhaba", "as-salamu alaykum", "sabah al-khair", "masa al-khair",
    "shalom", "salam", "jambo", "sawubona", "merhaba",
})

MEDICAL_KEYWORDS = {"pain", "symptom", "doctor", "medicine", "headache", "fever", "cough", "disease", "sick", "hurt", "injury", "prescription", "treatment", "diagnosis", "health", "medical", "hospital", "clinic", "drug", "pill", "medication", "allergy", "vaccine", "virus", "infection", "heart", "attack", "cardiac", "chest", "breathing", "breathe", "overdose", "overdosed", "pills", "poison", "poisoned", "suicide", "suicidal", "kill", "harm", "stroke", "unconscious", "unresponsive", "bleeding", "anaphylaxis", "allergic", "reaction", "choking", "emergency"}

def _is_greeting(text: str) -> bool:
    if not text: return False
    text_clean = text.lower().strip().rstrip(".!?,:;")
    words = set(text_clean.split())
    if words & MEDICAL_KEYWORDS: return False
    for g in GREETING_PATTERNS:
        if text_clean == g or text_clean.startswith(g + " ") or text_clean.startswith(g + ","):
            remainder = text_clean[len(g):].strip(" ,.:;!?").lower()
            if not remainder or (len(remainder.split()) <= 3 and not set(remainder.split()) & MEDICAL_KEYWORDS): return True
    return len(text_clean.split()) == 1 and len(text_clean) <= 10 and text_clean in GREETING_PATTERNS

def _get_greeting_response() -> str:
    return random.choice([
        "Hello! Welcome to Gemma Health Edge. I'm here to provide health information and support. How can I help you today?",
        "Hi there! I'm your health assistant. I can answer questions about symptoms, nutrition, mental health, and more. What would you like to know?",
        "Welcome! I'm Gemma, your private health AI. Remember, I'm here to provide information — not medical advice. What's on your mind?",
        "Good day! I'm ready to help with your health questions. Whether it's about diet, exercise, symptoms, or general wellness, feel free to ask!",
        "Hello! I'm here to support your health journey. While I can provide helpful information, please consult a healthcare professional for medical decisions.",
    ])

_EMERGENCY_KEYWORDS = re.compile(r'\b(heart\s*attack|cardiac\s*arrest|chest\s*(?:is\s+)?(?:pain|pressure|tightness|squeezing|crushing)|left\s+arm\s+(?:pain|numb|going\s+numb)|jaw\s+pain|my\s+heart\s+(?:stopped|is\s+stopping)|heart\s+(?:racing|pounding|skipping|feels?\s+weird)|feel\s*like\s+(?:i\'?m\s+)?dying|pressure\s+on\s+my\s+chest|squeezing\s+in\s+my\s+chest|palpitations\s+won\'?t\s+stop|my\s+pulse\s+(?:is\s+)?(?:gone|stopped)|i\s+think\s+i\'?m\s+having\s+a\s+heart|not\s*breathing|stopped\s*breathing|can\'?t\s*breathe|choking|gasping\s+for\s+air|throat\s+(?:is\s+)?(?:closing|swelling\s+shut)|airway\s+(?:is\s+)?blocked|lips?\s+are\s+blue|turning\s+blue|suffocating|can\'?t\s+get\s+air|shortness\s+of\s+breath\s+suddenly|overdose|overdosed|took\s+too\s+many|too\s+many\s+pills|took\s+all\s+(?:my|the)\s+(?:pills|meds|medication)|took\s+a\s+whole\s+bottle|i\s+think\s+i\s+overdosed|swallowed\s+(?:too\s+much|poison|bleach|chemicals?)|drank\s+(?:bleach|poison|chemicals?|cleaning)|ate\s+something\s+poisonous|ingested\s+(?:poison|medication|pills)|poison(?:ed|ing)?|poison\s+control|drug\s+overdose|opioid\s+overdose|fentanyl\s+overdose|heroin\s+overdose|narcan|naloxone|unresponsive\s+after\s+(?:drugs?|pills?)|not\s+breathing\s+after\s+(?:drugs?|pills?|medication)|suicid(?:e|al)|want\s+to\s+(?:hurt|kill|harm)\s+(?:my)?self|kill\s+myself|end\s+my\s+life|don\'?t\s+want\s+to\s+live|want\s+to\s+die|no\s+reason\s+to\s+live|thinking\s+(?:about\s+)?ending\s+it|nobody\s+would\s+miss\s+me|cutting\s+myself|self[\s\-]?harm|i\'?ve\s+been\s+cutting|want\s+to\s+disappear|planning\s+to\s+kill\s+myself|going\s+to\s+end\s+it|no\s+point\s+in\s+living|want\s+to\s+end\s+it\s+all|life\s+(?:is\s+)?not\s+worth\s+living|thinking\s+of\s+(?:jumping|hanging|overdosing)|i\s+slit\s+(?:my\s+)?wrists?|i\s+(?:cut|hurt|harmed|injured)\s+myself|hurting\s+myself\s+tonight|took\s+pills\s+to\s+(?:end|die|kill)|i\s+want\s+to\s+be\s+dead|i\s+feel\s+like\s+ending\s+everything|wrote\s+a\suicide\s+note|gave\s+away\s+my\s+things|anaphyla(?:xis|ctic)|severe\s+allergic\s+reaction|throat\s+(?:is\s+)?closing|tongue\s+(?:is\s+)?swelling|lips?\s+(?:are\s+)?swelling\s+fast|bee\s+sting\s+reaction|epipen|epinephrine|allergic\s+reaction\s+(?:getting\s+worse|severe)|hives\s+and\s+can\'?t\s+breathe|stroke(?:\s+symptoms?)?|having\s+a\s+stroke|face\s+drooping|arm\s+weakness|can\'?t\s+speak\s+suddenly|sudden\s+confusion|sudden\s+severe\s+headache|sudden\s+loss\s+of\s+vision|sudden\s+numbness|speech\s+(?:is\s+)?slurred\s+suddenly|one\s+side\s+of\s+(?:my\s+)?body\s+not\s+working|unconscious|unresponsive|not\s+waking|passed\s+out\s+and|won\'?t\s+wake\s+up|fainted\s+and\s+won\'?t\s+wake|collapsed\s+and\s+not\s+responding|heavy\s+bleeding|bleeding\s+(?:out|heavily|profusely)|can\'?t\s+stop\s+bleeding|gushing\s+blood|blood\s+everywhere|cut\s+an\s+artery|hemorrhaging|losing\s+too\s+much\s+blood)\b', re.IGNORECASE)

def _is_emergency(text: str) -> bool: return bool(_EMERGENCY_KEYWORDS.search(text))

def _get_emergency_response(text: str) -> str:
    text_lower = text.lower()
    if re.search(r'suicid|kill\s+myself|hurt\s+myself|harm\s+myself|end\s+my\s+life|want\s+to\s+die|don\'t\s+want\s+to\s+live|self[\s\-]?harm|cutting\s+myself|i\'ve\s+been\s+cutting|planning\s+to\s+kill|took\s+pills\s+to\s+(?:end|die|kill)|i\s+want\s+to\s+be\s+dead', text_lower):
        return "💙 **You are not alone. Please reach out for help right now.**\n\n**Crisis Hotlines:**\n- 🇺🇸 USA: **988** (Suicide & Crisis Lifeline)\n- 🇬🇧 UK: **116 123** (Samaritans)\n- 🇦🇺 Australia: **13 11 14** (Lifeline)\n- 🇪🇺 EU: **116 123**\n- International: www.findahelpline.com\n\nIf in immediate danger: **call 911/999/112/000 now.**\nI care about your safety. Please talk to a crisis counselor."
    if re.search(r'overdose|overdosed|too\s+many\s+pills|took\s+a\s+whole\s+bottle|took\s+all\s+(?:my|the)\s+(?:pills|meds|medication)|swallowed\s+(?:poison|bleach|chemicals?)|drank\s+(?:bleach|poison|chemicals?|cleaning)|ate\s+something\s+poisonous|poisoned?|drug\s+overdose|opioid\s+overdose', text_lower):
        return "🚨 **CALL EMERGENCY SERVICES + POISON CONTROL IMMEDIATELY**\n\n- 🇺🇸 USA: **911** + Poison Control: **1-800-222-1222**\n- 🇬🇧 UK: **999** or **111**\n- 🇪🇺 EU: **112**\n- 🇦🇺 Australia: **000** + Poisons Info: **13 11 26**\n\nDo NOT wait. Tell them: what substance, how much, when."
    return "🚨 **CALL EMERGENCY SERVICES NOW**\n\n- 🇺🇸 USA / Canada: **911**\n- 🇬🇧 UK: **999**\n- 🇪🇺 EU: **112**\n- 🇦🇺 Australia: **000**\n- 🇳🇿 New Zealand: **111**\n- 🇯🇵 Japan: **119**\n- 🇰🇷 South Korea: **119**\n\nDo not wait. Call emergency services first, then continue this conversation."

def _build_gemma_prompt(messages: list, extra_context: str = "") -> str:
    prompt, system_injected = "", False

    clinical_context = ClinicalProfile.to_prompt()

    for msg in messages:
        content = _extract_text(msg.content)
        if msg.role == "system":
            if not system_injected:
                content = content + clinical_context + (extra_context or "")
                system_injected = True
            prompt += f"<start_of_turn>system\n{content}<end_of_turn>\n"
        elif msg.role == "user": prompt += f"<start_of_turn>user\n{content}<end_of_turn>\n"
        elif msg.role == "assistant": prompt += f"<start_of_turn>model\n{content}<end_of_turn>\n"
    return prompt + "<start_of_turn>model\n"


async def _stream_local(request: ChatRequest, extra_context: str = "", backend_url: str | None = None) -> AsyncGenerator[str, None]:
    target_url = backend_url or settings.backend_url
    messages = list(request.messages)
    if not messages or messages[0].role != "system": messages.insert(0, Message(role="system", content=SYSTEM_PROMPT))
    prompt = _build_gemma_prompt(messages, extra_context)

    # Extract image from OpenAI-style vision content if present and no explicit image field
    image_b64 = None
    image_mime = "image/jpeg"
    if request.image:
        image_b64 = request.image.base64
        image_mime = request.image.mime
    else:
        # Scan messages for image_url content parts (OpenAI vision format)
        for msg in reversed(messages):
            if isinstance(msg.content, list):
                for part in msg.content:
                    if isinstance(part, dict) and part.get("type") == "image_url":
                        url = part.get("image_url", {}).get("url", "")
                        if url.startswith("data:"):
                            try:
                                # data:image/jpeg;base64,<b64>
                                header, b64 = url.split(",", 1)
                                image_mime = header.split(":")[1].split(";")[0]
                                image_b64 = b64
                            except Exception:
                                pass
                        break
                if image_b64:
                    break

    if image_b64:
        if not get_vision_supported():
            yield 'data: {"error": "Cannot read image input (this model does not support image input)."}\n\n'
            yield "data: [DONE]\n\n"
            return
        prompt = "[img-0]\n" + prompt
    body = {"prompt": prompt, "stream": True, "temperature": request.temperature, "top_p": 0.9, "min_p": 0.05, "max_tokens": request.max_tokens, "cache_prompt": True, "repeat_penalty": 1.05}
    if image_b64:
        try:
            img_bytes = base64.b64decode(image_b64)
            if len(img_bytes) > settings.max_image_size:
                yield 'data: {"error": "Image too large. Max size: ' + str(settings.max_image_size // (1024*1024)) + 'MB"}\n\n'; yield "data: [DONE]\n\n"; return
        except Exception: yield 'data: {"error": "Invalid image data"}\n\n'; yield "data: [DONE]\n\n"; return
        body["image_data"] = [{"data": image_b64, "id": 0}]

    client = await get_http_client()
    timing = {}
    try:
        async with client.stream("POST", f"{target_url}/v1/completions", json=body, timeout=httpx.Timeout(connect=5.0, read=settings.backend_timeout, write=30.0, pool=5.0)) as resp:
            if resp.status_code != 200:
                error = (await resp.aread()).decode()[:200]
                if resp.status_code == 503: yield 'data: {"error": "Local model is still loading. Please retry in a few seconds."}\n\n'
                else: yield f'data: {{"error": "Backend returned {resp.status_code}: {error}"}}\n\n'; return
            async for line in resp.aiter_lines():
                if not line.startswith("data: ") or line.strip() == "data: [DONE]": continue
                try:
                    data = json.loads(line[6:]); choices = data.get("choices", []); text = choices[0].get("text", "") if len(choices) > 0 else ""
                    if text: yield f"data: {json.dumps({'choices': [{'delta': {'content': text}, 'index': 0}]})}\n\n"
                    if "timings" in data: timing.update(data["timings"])
                except (json.JSONDecodeError, KeyError, IndexError) as e:
                    logger.debug("Failed to parse streaming line: %s", e)
                    continue
    except httpx.ConnectError: yield 'data: {"error": "Cannot connect to llama-server. Is it running?"}\n\n'
    except httpx.TimeoutException: yield f'data: {{"error": "Request timed out after {settings.backend_timeout}s"}}\n\n'
    except Exception as e: logger.error("Local backend error: %s", type(e).__name__); yield 'data: {"error": "Local backend error"}\n\n'
    finally:
        if timing:
            yield f"data: {json.dumps({'timing': timing})}\n\n"
        yield "data: [DONE]\n\n"

async def _stream_google(request: ChatRequest, api_key: str, extra_context: str = "") -> AsyncGenerator[str, None]:
    model = request.model or "gemma-4-e4b-it"
    if not api_key or api_key.strip() == "":
        yield 'data: {"error": "Google API key is required. Please set GHE_GOOGLE_API_KEY environment variable."}\n\n'
        yield "data: [DONE]\n\n"
        return
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?key={api_key.strip()}"
    contents, system_injected = [], False
    for msg in request.messages:
        content = _extract_text(msg.content)
        if msg.role == "system":
            if not system_injected and extra_context: content = content + extra_context; system_injected = True
            contents.extend([{"role": "user", "parts": [{"text": content}]}, {"role": "model", "parts": [{"text": "Understood. I will follow these guidelines."}]}])
        elif msg.role == "user":
            parts = [{"text": content}]
            if request.image: parts.insert(0, {"inline_data": {"mime_type": request.image.mime, "data": request.image.base64}})
            contents.append({"role": "user", "parts": parts})
        elif msg.role == "assistant": contents.append({"role": "model", "parts": [{"text": content}]})
    body = {"contents": contents, "generationConfig": {"temperature": request.temperature, "maxOutputTokens": request.max_tokens}, "safetySettings": [{"category": c, "threshold": "BLOCK_ONLY_HIGH"} for c in ["HARM_CATEGORY_HARASSMENT", "HARM_CATEGORY_HATE_SPEECH", "HARM_CATEGORY_SEXUALLY_EXPLICIT", "HARM_CATEGORY_DANGEROUS_CONTENT"]]}
    client = await get_http_client()
    try:
        timeout = httpx.Timeout(30.0, connect=30.0, read=600.0, write=30.0, pool=30.0)
        async with client.stream("POST", url, json=body, timeout=timeout) as resp:
            if resp.status_code != 200: yield f'data: {{"error": "Google API {resp.status_code}: {(await resp.aread()).decode()[:200]}"}}\n\n'; return
            buffer = ""
            last_match_end = 0
            async for chunk_text in resp.aiter_text():
                buffer += chunk_text
                for match in re.finditer(r'"text"\s*:\s*("(?:\\.|[^"\\])*")', buffer):
                    try:
                        text_value = json.loads(match.group(1))
                        if text_value: yield f"data: {json.dumps({'choices': [{'delta': {'content': text_value}, 'index': 0}]})}\n\n"
                    except (json.JSONDecodeError, KeyError) as e:
                        logger.debug("Failed to parse Google API response: %s", e)
                        continue
                    last_match_end = match.end()
                buffer = buffer[last_match_end:]
                if len(buffer) > 65536: buffer = buffer[-32768:]
    except httpx.TimeoutException: yield 'data: {"error": "Google API request timed out"}\n\n'
    except Exception as e: logger.error("Google API error: %s", type(e).__name__); yield 'data: {"error": "Google API error"}\n\n'
    finally: yield "data: [DONE]\n\n"

async def _stream_openrouter(request: ChatRequest, api_key: str, extra_context: str = "") -> AsyncGenerator[str, None]:
    if not api_key or api_key.strip() == "":
        yield 'data: {"error": "OpenRouter API key is required."}\n\n'
        yield "data: [DONE]\n\n"
        return
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {"Authorization": f"Bearer {api_key.strip()}", "HTTP-Referer": "https://github.com/gemma-health-edge", "X-Title": "Gemma Health Edge", "Content-Type": "application/json"}
    messages, system_injected = [], False
    for msg in request.messages:
        if msg.role == "system":
            content = _extract_text(msg.content)
            if not system_injected and extra_context: content += extra_context; system_injected = True
            messages.append({"role": msg.role, "content": content})
        else:
            # Preserve list content (vision payloads) as-is for OpenRouter
            messages.append({"role": msg.role, "content": msg.content})
    if not messages or len(messages) == 0 or messages[0]["role"] != "system": messages.insert(0, {"role": "system", "content": SYSTEM_PROMPT + extra_context})
    body = {"model": request.model or "google/gemma-4-27b-it", "messages": messages, "stream": True, "temperature": request.temperature, "max_tokens": request.max_tokens}

    client = await get_http_client()
    try:
        timeout = httpx.Timeout(30.0, connect=30.0, read=600.0, write=30.0, pool=30.0)
        async with client.stream("POST", url, headers=headers, json=body, timeout=timeout) as resp:
            if resp.status_code != 200: yield f'data: {{"error": "OpenRouter {resp.status_code}: {(await resp.aread()).decode()[:200]}"}}\n\n'; return
            async for line in resp.aiter_lines():
                line = line.strip()
                if line.startswith("data: ") and line != "data: [DONE]": yield f"{line}\n\n"
    except httpx.TimeoutException: yield 'data: {"error": "OpenRouter request timed out"}\n\n'
    except Exception as e: logger.error("OpenRouter error: %s", type(e).__name__); yield 'data: {"error": "OpenRouter error"}\n\n'
    finally: yield "data: [DONE]\n\n"

async def _stream_ollama(request: ChatRequest, extra_context: str = "") -> AsyncGenerator[str, None]:
    url = f"{settings.ollama_url}/v1/chat/completions"
    messages, system_injected = [], False
    for msg in request.messages:
        content = _extract_text(msg.content)
        if msg.role == "system":
            if not system_injected and extra_context: content += extra_context; system_injected = True
        messages.append({"role": msg.role, "content": content})
    if not messages or messages[0]["role"] != "system": messages.insert(0, {"role": "system", "content": SYSTEM_PROMPT + extra_context})
    model = request.model or "gemma4"
    if not any(x in model.lower() for x in ["gemma4", "gemma-4"]): model = "gemma4"
    body = {"model": model, "messages": messages, "stream": True, "temperature": request.temperature, "max_tokens": request.max_tokens}
    client = await get_http_client()
    try:
        timeout = httpx.Timeout(connect=2.0, read=settings.backend_timeout, write=10.0, pool=30.0)
        async with client.stream("POST", url, json=body, timeout=timeout) as resp:
            if resp.status_code != 200: yield f'data: {{"error": "Ollama {resp.status_code}: {(await resp.aread()).decode()[:200]}"}}\n\n'; return
            async for line in resp.aiter_lines():
                line = line.strip()
                if line.startswith("data: ") and line != "data: [DONE]": yield f"{line}\n\n"
    except (httpx.ConnectError, httpx.ConnectTimeout): yield 'data: {"error": "Cannot connect to Ollama. Is it running on port 11434?"}\n\n'
    except httpx.TimeoutException: yield f'data: {{"error": "Ollama request timed out after {settings.backend_timeout}s"}}\n\n'
    except Exception as e: logger.error("Ollama error: %s", type(e).__name__); yield 'data: {"error": "Ollama backend error"}\n\n'
    finally: yield "data: [DONE]\n\n"

@api_router.post("/chat/stream")
@limiter.limit(settings.rate_limit)
async def stream_chat(request: Request, body: ChatRequest):
    body.model = _enforce_gemma4(body.model)
    if body.mode in ("google", "openrouter"):
        key = body.api_key or getattr(settings, f"{body.mode}_api_key", "")
        if not key or key.strip() == "":
            raise HTTPException(400, f"API key required for {body.mode} mode. Please set GHE_{body.mode.upper()}_API_KEY environment variable.")
        if not validate_api_key(key, body.mode):
            raise HTTPException(400, f"Invalid {body.mode} API key format. Please check your API key.")
    else: key = ""
    async def event_stream():
        extra_context = ClinicalProfile.to_prompt()
        
        if body.messages:
            last_message = body.messages[-1]
            if last_message.role == "user":
                query_text = _extract_text(last_message.content)
                if _is_emergency(query_text):
                    yield f"data: {json.dumps({'choices': [{'delta': {'content': _get_emergency_response(query_text)}, 'index': 0}]})}\n\n"; yield "data: [DONE]\n\n"; return
                if _is_greeting(query_text):
                    yield f"data: {json.dumps({'choices': [{'delta': {'content': _get_greeting_response()}, 'index': 0}]})}\n\n"; yield "data: [DONE]\n\n"; return
        if body.research and body.messages:
            query = _extract_text(body.messages[-1].content)
            if query:
                try:
                    research_context = await fetch_research_context(query)
                    if research_context: extra_context += f"\n\n[Research Context]\n{research_context}"
                except Exception as e: logger.warning("Research fetch failed: %s", e)
        match body.mode:
            case "local":
                async for chunk in _stream_local(body, extra_context):
                    yield chunk
            case "ollama":
                async for chunk in _stream_ollama(body, extra_context):
                    yield chunk
            case "google":
                async for chunk in _stream_google(body, key, extra_context):
                    yield chunk
            case "openrouter":
                async for chunk in _stream_openrouter(body, key, extra_context):
                    yield chunk
    return StreamingResponse(event_stream(), media_type="text/event-stream", headers={"Cache-Control": "no-cache", "Connection": "keep-alive", "X-Accel-Buffering": "no"})

@api_router.post("/chat", response_model=ChatResponse)
@limiter.limit(settings.rate_limit)
async def complete_chat(request: Request, body: ChatRequest):
    body.model = _enforce_gemma4(body.model)
    start = time.time()
    full_text, error_text = "", ""
    if body.mode in ("google", "openrouter"):
        key = body.api_key or getattr(settings, f"{body.mode}_api_key", "")
        if not key or key.strip() == "":
            raise HTTPException(400, f"API key required for {body.mode} mode. Please set GHE_{body.mode.upper()}_API_KEY environment variable.")
        if not validate_api_key(key, body.mode):
            raise HTTPException(400, f"Invalid {body.mode} API key format. Please check your API key.")
    else: key = ""
    extra_context = ClinicalProfile.to_prompt()

    rescue_text = ""
    if body.messages:
        last_message = body.messages[-1]
        if last_message.role == "user":
            rescue_text = _extract_text(last_message.content)
            if _is_emergency(rescue_text):
                return ChatResponse(content=_get_emergency_response(rescue_text), model=body.model or DEFAULT_MODEL, latency_ms=round((time.time() - start) * 1000))
            if _is_greeting(rescue_text):
                return ChatResponse(content=_get_greeting_response(), model=body.model or DEFAULT_MODEL, latency_ms=round((time.time() - start) * 1000))

    if body.research and rescue_text:
        try:
            research_context = await fetch_research_context(rescue_text)
            if research_context:
                extra_context += f"\n\n[Research Context]\n{research_context}"
        except Exception as e:
            logger.warning("Research fetch failed: %s", e)
    match body.mode:
        case "local": gen = _stream_local(body, extra_context)
        case "ollama": gen = _stream_ollama(body, extra_context)
        case "google": gen = _stream_google(body, key, extra_context)
        case "openrouter": gen = _stream_openrouter(body, key, extra_context)
    ttft_ms = None
    tps = None
    total_time_ms = None
    async for chunk_line in gen:
        line = chunk_line.strip()
        if line.startswith("data: ") and line != "data: [DONE]":
            try:
                data = json.loads(line[6:])
                if "error" in data: error_text = data["error"]
                elif "timing" in data:
                    ttft_ms = data["timing"].get("prompt_ms")
                    pred_per_token = data["timing"].get("predicted_per_token_ms")
                    if pred_per_token and pred_per_token > 0: tps = round(1000 / pred_per_token, 1)
                    total_time_ms = data["timing"].get("predicted_ms")
                else:
                    choices = data.get("choices", []); delta = choices[0].get("delta", {}) if len(choices) > 0 else {}; full_text += delta.get("content", "")
            except (json.JSONDecodeError, KeyError, IndexError) as e:
                logger.debug("Failed to parse chat completion response: %s", e)
    if error_text and not full_text: raise HTTPException(503, f"Backend error: {error_text}")
    critique = critique_response(full_text)
    llm_critique = await validate_with_llm(full_text, query="")
    combined_critique = LLMGuardrail.combine_with_regex_critique(critique, llm_critique)
    if combined_critique["severity"] in ("critical", "high"): logger.warning("Response critique: %s issues", len(combined_critique["issues"]))
    should_block, block_reason = ResponseCritic.should_block_response(combined_critique)
    if should_block:
        full_text = "I apologize, but I cannot provide the previous response as it may contain potentially harmful or inaccurate medical information. Please consult a qualified healthcare professional for medical advice."
        combined_critique["was_blocked"] = True; combined_critique["block_reason"] = block_reason
    return ChatResponse(content=full_text, model=body.model or DEFAULT_MODEL, latency_ms=round((time.time() - start) * 1000), ttft_ms=ttft_ms, tps=tps, total_time_ms=total_time_ms, critique=combined_critique if combined_critique["issues"] else None)

@api_router.post("/chat/title")
@limiter.limit(settings.rate_limit)
async def generate_chat_title(request: Request, body: dict):
    message = body.get("message", "")
    if not message or not message.strip(): return {"title": "New Conversation"}
    title_prompt = f"Generate a very short title (max 5 words) for this health-related conversation: {message[:200]}\nRespond with ONLY the title, no punctuation, no explanation."
    try:
        body_req = {"prompt": f"<start_of_turn>system\n{title_prompt}<end_of_turn>\n<start_of_turn>model\n", "stream": False, "temperature": 0.7, "max_tokens": 20, "top_p": 0.9}
        client = await get_http_client()
        resp = await client.post(f"{settings.backend_url}/v1/completions", json=body_req, timeout=10.0)
        if resp.status_code == 200:
            choices = resp.json().get("choices", [])
            title = choices[0].get("text", "") if len(choices) > 0 else ""
            title = title.strip().replace("<start_of_turn>", "").replace("<end_of_turn>", "").replace("\n", " ").strip().strip('"\'')
            if title and len(title) > 3: return {"title": title[:50]}
    except Exception as e: logger.warning("Title generation failed: %s", e)
    return {"title": message.strip()[:40] or "New Conversation"}

@api_router.post("/rlhf/vote")
async def record_vote(vote: VoteRequest):
    rlhf_dir = Path(__file__).parent / "rlhf"
    rlhf_dir.mkdir(parents=True, exist_ok=True)
    votes_file = rlhf_dir / "votes.jsonl"
    max_size = 50 * 1024 * 1024  # 50 MB cap
    if votes_file.exists() and votes_file.stat().st_size > max_size:
        logger.warning("votes.jsonl exceeds 50 MB — rotating")
        votes_file.rename(votes_file.with_suffix(".jsonl.old"))
    msg_id = vote.msg_id or vote.message_id
    entry = {"msg_id": msg_id, "session_id": vote.session_id, "vote": vote.vote, "prompt": vote.prompt, "response": vote.response, "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()}
    with open(votes_file, "a", encoding="utf-8") as f: f.write(json.dumps(entry) + "\n")
    return {"status": "recorded", "msg_id": msg_id}

@api_router.post("/datasets/import-report", response_model=ReportImportResponse)
async def import_report(body: ReportImportRequest):
    if "gemma health edge" not in body.text[:500].lower(): raise HTTPException(400, "Not a valid Gemma Health Edge report")
    lines = body.text.splitlines()
    sessions_found = sum(1 for line in lines if line.lstrip().lower().startswith("## session:") or line.lstrip().lower().startswith("session:"))
    messages_indexed = sum(1 for line in lines if line.lstrip().lower().startswith("**user:**") or line.lstrip().lower().startswith("**assistant:**"))
    dates = [match.group() for match in re.finditer(r'(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])', body.text)]
    date_range = f"{min(dates)} to {max(dates)}" if dates else "unknown"
    return ReportImportResponse(sessions_found=max(sessions_found, 1), messages_indexed=max(messages_indexed, 1), date_range=date_range, status="indexed")


_sync_store: TTLCache[str, dict] = TTLCache(maxsize=1000, ttl=3600)
_sync_lock = asyncio.Lock()

@api_router.post("/sync/session")
async def sync_session(body: dict):
    sync_id = body.get("sync_id") or body.get("id") or str(uuid.uuid4())
    async with _sync_lock: _sync_store[sync_id] = body
    return {"status": "stored", "sync_id": sync_id}

@api_router.get("/sync/session/{sync_id}")
async def get_synced_session(sync_id: str):
    if not sync_id: raise HTTPException(400, "Invalid sync ID")
    async with _sync_lock: payload = _sync_store.get(sync_id)
    if payload is None: raise HTTPException(404, "Session not found or expired")
    return payload

@api_router.get("/health", response_model=HealthResponse)
@api_router.options("/health")
async def get_health():
    backend_ok = ollama_ok = False
    client = await get_http_client()
    async def _check(url, timeout=5.0):
        try:
            resp = await client.get(url, timeout=timeout)
            return resp.status_code == 200
        except Exception:
            return False
    backend_ok, ollama_ok = await asyncio.gather(
        _check(f"{settings.backend_url}/health"),
        _check(f"{settings.ollama_url}/api/tags", timeout=1.5)
    )
    try:
        hw = HardwareDetector.detect()
    except Exception as e:
        logger.error("Hardware detection failed: %s", e)
        hw = {"gpu": "Unknown", "vram_gb": 0, "accelerator": "cpu", "max_threads": 1}
    return {
        "status": "healthy" if backend_ok else "degraded",
        "version": "2.0.0",
        "backend_status": "online" if backend_ok else "offline",
        "ollama_status": "online" if ollama_ok else "offline",
        "research_available": True,
        "vision_supported": get_vision_supported(),
        "uptime_seconds": time.time() - _start_time,
        "gpu": hw.get("gpu", "Unknown"),
        "vram_gb": hw.get("vram_gb", 0),
        "accelerator": hw.get("accelerator", "cpu"),
        "threads": hw.get("max_threads", 1),
        "guardrail_circuit": get_guardrail_circuit_status()
    }

@api_router.post("/critique")
async def critique_text(request: Request, body: dict):
    text = body.get("response") or body.get("text", "")
    query = body.get("query", "")
    if not text: raise HTTPException(400, "No text provided for critique")
    regex_critique = critique_response(text, query)
    llm_result = await validate_with_llm(text, query)
    combined = LLMGuardrail.combine_with_regex_critique(regex_critique, llm_result)
    return combined

@api_router.get("/config")
async def get_config():
    client = await get_http_client()
    async def _check(url):
        try:
            resp = await client.get(url, timeout=1.0)
            return resp.status_code == 200
        except (httpx.RequestError, httpx.TimeoutException):
            return False
    backend_ok, ollama_ok = await asyncio.gather(
        _check(f"{settings.backend_url}/health"),
        _check(f"{settings.ollama_url}/api/tags")
    )
    try:
        hw = HardwareDetector.detect()
    except Exception as e:
        logger.error("Hardware detection failed: %s", e)
        hw = {"gpu": "Unknown", "vram_gb": 0, "accelerator": "cpu"}
    return {
        "available_modes": ["local", "ollama", "google", "openrouter"],
        "local_server_status": "online" if backend_ok else "offline",
        "ollama_status": "online" if ollama_ok else "offline",
        "model_policy": "gemma-4-only",
        "supported_models": {
            "local": ["gemma-4-e4b-it-Q4_K_M"],
            "ollama": ["gemma-4-e4b-it", "gemma-4-9b-it"],
            "google": ["gemma-4-e4b-it", "gemma-4-9b-it", "gemma-4-27b-it"],
            "openrouter": ["google/gemma-4-9b-it", "google/gemma-4-27b-it"]
        },
        "research_sources": ["wikipedia", "pubmed"],
        "max_tokens": 32000,
        "critique_enabled": True,
        "llm_guardrail_circuit": get_guardrail_circuit_status(),
        "hardware": {
            "gpu": hw.get("gpu", "Unknown"),
            "vram": hw.get("vram_gb", 0),
            "accelerator": hw.get("accelerator", "cpu")
        }
    }