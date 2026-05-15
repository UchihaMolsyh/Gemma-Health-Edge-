"""Gemma Health Edge — Pydantic Request/Response Schemas."""
from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator


class ImageData(BaseModel):
    base64: str = Field(..., max_length=10_000_000)
    mime:   Literal["image/jpeg", "image/png", "image/webp", "image/gif"]


class Message(BaseModel):
    role:    Literal["system", "user", "assistant"]
    content: str | list

    @field_validator("content")
    @classmethod
    def _validate_content_size(cls, v):
        if isinstance(v, str):
            if len(v) > 20_000:
                raise ValueError("Message content too long (max 20 000 characters).")
            return v
        if isinstance(v, list):
            if len(v) > 50:
                raise ValueError("Message content has too many parts (max 50).")
            total = sum(
                len(item.get("text", "")) if isinstance(item, dict) and isinstance(item.get("text"), str)
                else len(item) if isinstance(item, str)
                else 0
                for item in v
            )
            if total > 20_000:
                raise ValueError("Message content too long (max 20 000 characters).")
        return v


class ChatRequest(BaseModel):
    messages:    list[Message]   = Field(..., min_length=1)
    model:       Optional[str]   = None
    temperature: float           = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens:  int             = Field(default=8192, ge=1, le=32_000)
    mode:        Literal["local", "ollama", "google", "openrouter"] = "local"
    api_key:     Optional[str]   = None
    image:       Optional[ImageData] = None
    research:    bool            = False

    @field_validator("messages")
    @classmethod
    def _limit_message_count(cls, v):
        if len(v) > 60:
            raise ValueError("Too many messages (max 60).")
        return v


class CritiqueInfo(BaseModel):
    issues:       list[str]   = []
    severity:     Literal["none", "low", "medium", "high", "critical"] = "none"
    was_blocked:  Optional[bool] = None
    block_reason: Optional[str]  = None


class ChatResponse(BaseModel):
    content:    str
    model:      str
    latency_ms: int
    ttft_ms:    Optional[float] = None
    tps:        Optional[float] = None
    total_time_ms: Optional[float] = None
    critique:   Optional[CritiqueInfo] = None


class VoteRequest(BaseModel):
    msg_id:     Optional[int] = None
    message_id: Optional[str] = None
    session_id: str
    vote:       Literal["up", "down"]
    prompt:     str
    response:   str


class ReportImportRequest(BaseModel):
    text: str = Field(..., min_length=100)


class ReportImportResponse(BaseModel):
    sessions_found:   int
    messages_indexed: int
    date_range:       str
    status:           str


class HealthResponse(BaseModel):
    status:             str
    version:            str
    backend_status:     str
    ollama_status:      str
    research_available: bool
    vision_supported:   bool = True
    uptime_seconds:     float
    gpu:                str
    vram_gb:            int
    accelerator:        str
    threads:            int
    guardrail_circuit:  dict