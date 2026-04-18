"""Voice API routes."""

from __future__ import annotations

import mimetypes
from functools import lru_cache
from typing import List

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field

from backend.services.voice_service import VoiceProcessingService


router = APIRouter(prefix="/voice", tags=["voice"])


class VoiceTranscribeResponse(BaseModel):
    transcript: str


class VoiceExtractRequest(BaseModel):
    text: str = Field(..., min_length=1)
    sessionId: str | None = None


class VoiceExtractResponse(BaseModel):
    symptoms: List[str] = Field(default_factory=list)


@lru_cache(maxsize=1)
def get_voice_service() -> VoiceProcessingService:
    return VoiceProcessingService()


@router.post("/transcribe", response_model=VoiceTranscribeResponse)
async def transcribe_voice(
    audio: UploadFile = File(...),
    languageCode: str | None = Form(default=None),
    sessionId: str | None = Form(default=None),
) -> VoiceTranscribeResponse:
    del sessionId  # Reserved for future tracing / analytics.

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Audio payload is empty.")

    mime_type = audio.content_type or mimetypes.guess_type(audio.filename or "")[0] or "audio/m4a"

    try:
        transcript = get_voice_service().transcribe_audio(
            audio_bytes=audio_bytes,
            mime_type=mime_type,
            language_code=languageCode,
        )
        return VoiceTranscribeResponse(transcript=transcript)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Voice transcription failed.") from exc


@router.post("/extract", response_model=VoiceExtractResponse)
def extract_voice_symptoms(request: VoiceExtractRequest) -> VoiceExtractResponse:
    text = request.text.strip()
    if not text:
        return VoiceExtractResponse(symptoms=[])

    try:
        symptoms = get_voice_service().extract_symptoms(text)
        return VoiceExtractResponse(symptoms=symptoms)
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Voice extraction failed.") from exc
