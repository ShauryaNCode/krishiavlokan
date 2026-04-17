"""FastAPI entrypoint for the KrishiAvalokan backend."""

from __future__ import annotations

import os
import sys
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

try:
    from dotenv import load_dotenv
except Exception:  # pragma: no cover - python-dotenv is optional
    load_dotenv = None


def load_root_environment() -> None:
    """Load GEMINI_API_KEY and other settings from the project root .env file."""

    env_path = PROJECT_ROOT / ".env"
    if load_dotenv is not None:
        load_dotenv(env_path)
        return

    if not env_path.exists():
        return

    for line in env_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_root_environment()

from backend.routes.diagnosis import router as diagnosis_router  # noqa: E402


app = FastAPI(
    title="KrishiAvalokan Backend",
    version="1.0.0",
    description="Crop failure diagnosis API backed by live weather, XGBoost, and Gemini.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(diagnosis_router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
