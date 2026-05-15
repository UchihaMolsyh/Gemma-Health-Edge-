"""Gemma Health Edge — Data API.

Persistent REST endpoints for:
  - Chat sessions   (CRUD)
  - Mood tracking   (monthly history + upsert)
  - Clinical profile (get + save)

All data is persisted to the local SQLite database via database.py.
"""
import uuid
from typing import List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from database import ClinicalProfile, MoodTracker, SessionManager

data_router = APIRouter(prefix="/data", tags=["data"])


# ── Pydantic Schemas ──────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    id:        str
    role:      str = Field(..., pattern="^(user|assistant|system)$")
    content:   str
    timestamp: str = ""


class CreateSessionRequest(BaseModel):
    id:       Optional[str]           = None
    title:    Optional[str]           = "New Chat"
    messages: List[ChatMessage]       = []


class UpdateSessionRequest(BaseModel):
    title:    Optional[str]           = None
    messages: Optional[List[ChatMessage]] = None


class MoodEntryRequest(BaseModel):
    date: str
    mood: int  = Field(..., ge=1, le=5)
    note: str  = ""


class ClinicalProfileRequest(BaseModel):
    allergies:   str = ""
    conditions:  str = ""
    medications: str = ""
    age:         str = ""
    weight:      str = ""
    notes:       str = ""


# ── Session Endpoints ─────────────────────────────────────────────────────────

@data_router.get("/sessions")
async def get_sessions():
    return SessionManager.get_all_sessions()


@data_router.get("/sessions/{session_id}")
async def get_session(session_id: str):
    session = SessionManager.get_session(session_id)
    if not session:
        raise HTTPException(404, "Session not found")
    return session


@data_router.post("/sessions", status_code=201)
async def create_session(req: CreateSessionRequest):
    session = {
        "id":       req.id or str(uuid.uuid4()),
        "title":    req.title or "New Chat",
        "messages": [m.model_dump() for m in req.messages],
    }
    if not SessionManager.save_session(session):
        raise HTTPException(500, "Failed to create session")
    return session


@data_router.put("/sessions/{session_id}")
async def update_session(session_id: str, req: UpdateSessionRequest):
    existing = SessionManager.get_session(session_id)
    if not existing:
        raise HTTPException(404, "Session not found")
    if req.title is not None:
        existing["title"] = req.title
    if req.messages is not None:
        existing["messages"] = [m.model_dump() for m in req.messages]
    if not SessionManager.save_session(existing):
        raise HTTPException(500, "Failed to update session")
    return existing


@data_router.delete("/sessions/{session_id}")
async def delete_session(session_id: str):
    if not SessionManager.delete_session(session_id):
        raise HTTPException(500, "Failed to delete session")
    return {"status": "deleted"}


# ── Mood Endpoints ────────────────────────────────────────────────────────────

@data_router.get("/moods")
async def get_moods(year: int, month: int):
    return MoodTracker.get_history(year, month)


@data_router.post("/moods", status_code=201)
async def save_mood(req: MoodEntryRequest):
    if not MoodTracker.save_mood(req.date, req.mood, req.note):
        raise HTTPException(500, "Failed to save mood entry")
    return {"status": "saved"}


# ── Clinical Profile Endpoints ────────────────────────────────────────────────

@data_router.get("/profile")
async def get_profile():
    return ClinicalProfile.get() or {}


@data_router.post("/profile")
async def save_profile(req: ClinicalProfileRequest):
    if not ClinicalProfile.save(req.model_dump()):
        raise HTTPException(500, "Failed to save clinical profile")
    return {"status": "saved"}