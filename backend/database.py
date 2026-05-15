"""Gemma Health Edge — SQLite Database Layer.

Provides three data managers for the platform's local SQLite store:
  - SessionManager   — encrypted chat sessions
  - MoodTracker      — daily mood entries (1–5 scale)
  - ClinicalProfile  — single-row patient PHI record
"""
import json
import logging
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger("ghe.database")

DB_PATH = Path(__file__).parent / "ghe_data.db"


# ── Schema ────────────────────────────────────────────────────────────────────

def init_database() -> None:
    """Create all tables on first run (idempotent)."""
    with sqlite3.connect(str(DB_PATH), timeout=30.0) as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS chat_sessions (
                id          TEXT PRIMARY KEY,
                title       TEXT NOT NULL,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                messages    TEXT NOT NULL,
                is_archived BOOLEAN DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS mood_entries (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                date       DATE NOT NULL UNIQUE,
                mood       INTEGER NOT NULL CHECK(mood >= 1 AND mood <= 5),
                note       TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS clinical_profiles (
                id          INTEGER PRIMARY KEY CHECK(id = 1),
                allergies   TEXT DEFAULT '',
                conditions  TEXT DEFAULT '',
                medications TEXT DEFAULT '',
                age         TEXT DEFAULT '',
                weight      TEXT DEFAULT '',
                notes       TEXT DEFAULT '',
                updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        # Ensure the single clinical profile row always exists
        conn.execute("INSERT OR IGNORE INTO clinical_profiles (id) VALUES (1)")
        conn.commit()
    logger.info("[Database] Initialised at %s (WAL mode).", DB_PATH)


def _get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(str(DB_PATH), timeout=30.0)
    conn.row_factory = sqlite3.Row
    return conn


# ── Session Manager ───────────────────────────────────────────────────────────

class SessionManager:
    _COLUMNS = "id, title, created_at, updated_at, messages"

    @staticmethod
    def _row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
        return {
            "id":         row["id"],
            "title":      row["title"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
            "messages":   json.loads(row["messages"]),
        }

    @staticmethod
    def get_all_sessions() -> List[Dict]:
        with _get_connection() as conn:
            rows = conn.execute(
                f"SELECT {SessionManager._COLUMNS} "
                "FROM chat_sessions WHERE is_archived = 0 "
                "ORDER BY updated_at DESC LIMIT 50"
            ).fetchall()
            return [SessionManager._row_to_dict(r) for r in rows]

    @staticmethod
    def get_session(session_id: str) -> Optional[Dict]:
        with _get_connection() as conn:
            row = conn.execute(
                f"SELECT {SessionManager._COLUMNS} "
                "FROM chat_sessions WHERE id = ? AND is_archived = 0",
                (session_id,),
            ).fetchone()
            return SessionManager._row_to_dict(row) if row else None

    @staticmethod
    def save_session(session: Dict) -> bool:
        try:
            with _get_connection() as conn:
                conn.execute(
                    """
                    INSERT INTO chat_sessions (id, title, messages, updated_at)
                    VALUES (?, ?, ?, CURRENT_TIMESTAMP)
                    ON CONFLICT(id) DO UPDATE SET
                        title      = excluded.title,
                        messages   = excluded.messages,
                        updated_at = CURRENT_TIMESTAMP
                    """,
                    (
                        session.get("id"),
                        session.get("title", "Untitled Chat"),
                        json.dumps(session.get("messages", [])),
                    ),
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error("save_session failed: %s", e)
            return False

    @staticmethod
    def delete_session(session_id: str) -> bool:
        """Soft-delete by setting is_archived = 1."""
        try:
            with _get_connection() as conn:
                conn.execute(
                    "UPDATE chat_sessions SET is_archived = 1 WHERE id = ?",
                    (session_id,),
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error("delete_session failed: %s", e)
            return False


# ── Mood Tracker ──────────────────────────────────────────────────────────────

class MoodTracker:
    @staticmethod
    def get_history(year: int, month: int) -> Dict:
        with _get_connection() as conn:
            rows = conn.execute(
                "SELECT date, mood FROM mood_entries "
                "WHERE strftime('%Y', date) = ? AND strftime('%m', date) = ?",
                (str(year), f"{month:02d}"),
            ).fetchall()

        history: Dict[int, int] = {}
        for row in rows:
            try:
                day = int(row["date"].split("-")[2])
                history[day] = row["mood"]
            except (IndexError, ValueError):
                logger.warning("Invalid date format in mood entry: %s", row["date"])

        return {"history": history, "total": len(history)}

    @staticmethod
    def save_mood(date: str, mood: int, note: str = "") -> bool:
        try:
            with _get_connection() as conn:
                conn.execute(
                    """
                    INSERT INTO mood_entries (date, mood, note)
                    VALUES (?, ?, ?)
                    ON CONFLICT(date) DO UPDATE SET
                        mood = excluded.mood,
                        note = excluded.note
                    """,
                    (date, mood, note),
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error("save_mood failed: %s", e)
            return False


# ── Clinical Profile ──────────────────────────────────────────────────────────

class ClinicalProfile:
    _FIELDS = ("allergies", "conditions", "medications", "age", "weight", "notes")

    @staticmethod
    def get() -> Optional[Dict]:
        with _get_connection() as conn:
            row = conn.execute(
                "SELECT * FROM clinical_profiles WHERE id = 1"
            ).fetchone()
            return dict(row) if row else None

    @staticmethod
    def save(profile: Dict) -> bool:
        try:
            with _get_connection() as conn:
                conn.execute(
                    """
                    INSERT INTO clinical_profiles
                        (id, allergies, conditions, medications, age, weight, notes)
                    VALUES (1, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        allergies   = excluded.allergies,
                        conditions  = excluded.conditions,
                        medications = excluded.medications,
                        age         = excluded.age,
                        weight      = excluded.weight,
                        notes       = excluded.notes,
                        updated_at  = CURRENT_TIMESTAMP
                    """,
                    tuple(profile.get(f, "") for f in ClinicalProfile._FIELDS),
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error("save_profile failed: %s", e)
            return False

    @staticmethod
    def to_prompt() -> str:
        """Return a compact clinical context string for injection into LLM prompts."""
        p = ClinicalProfile.get()
        if not p:
            return ""
        labels = {
            "allergies":   "Allergies",
            "conditions":  "Conditions",
            "medications": "Medications",
            "age":         "Age",
            "weight":      "Weight (kg)",
            "notes":       "Notes",
        }
        parts = [f"{label}: {p[field]}" for field, label in labels.items() if p.get(field)]
        return f"\n\nPatient Profile: {', '.join(parts)}" if parts else ""


if __name__ == "__main__":
    init_database()