"""Voice transcription and symptom extraction services."""

from __future__ import annotations

import base64
import os
import re
from typing import Any, Mapping

try:
    import requests
except Exception:  # pragma: no cover - optional runtime dependency
    requests = None

from ai_pipeline.voice_symptom_extractor import VoiceSymptomExtractor


GEMINI_AUDIO_MODEL = os.getenv("VOICE_TRANSCRIBE_MODEL", "gemini-2.5-flash")
GEMINI_GENERATE_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent?key={api_key}"
)


class VoiceProcessingService:
    """Coordinates audio transcription and text-to-symptom extraction."""

    def __init__(self, extractor: VoiceSymptomExtractor | None = None) -> None:
        self.extractor = extractor or VoiceSymptomExtractor()

    def transcribe_audio(
        self,
        audio_bytes: bytes,
        mime_type: str,
        language_code: str | None = None,
    ) -> str:
        if not audio_bytes:
            raise ValueError("Audio payload is empty.")
        if len(audio_bytes) > 18_000_000:
            raise ValueError("Audio payload is too large for inline transcription.")

        api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        if requests is None:
            raise RuntimeError(
                "Audio transcription is unavailable: install the 'requests' package in the backend environment."
            )
        if not api_key:
            raise RuntimeError(
                "Audio transcription is unavailable: GEMINI_API_KEY or GOOGLE_API_KEY is not set in the root .env."
            )

        prompt = (
            "Transcribe this farmer audio clip faithfully. "
            "Return only the transcript text in lowercase. "
            "Do not summarize. Do not infer symptoms. "
            "Keep Hindi, Hinglish, and English words exactly as spoken where possible."
        )
        if language_code:
            prompt += f" Expected language code: {language_code}."

        normalized_mime_type = self._normalize_audio_mime_type(mime_type)

        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inlineData": {
                                "mimeType": normalized_mime_type,
                                "data": base64.b64encode(audio_bytes).decode("utf-8"),
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 200,
            },
        }

        try:
            response = requests.post(
                GEMINI_GENERATE_URL.format(model=GEMINI_AUDIO_MODEL, api_key=api_key),
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            payload = response.json()
        except Exception as exc:  # pragma: no cover - network/runtime dependent
            raise RuntimeError(f"Gemini audio transcription failed: {exc}") from exc

        transcript = self._response_text(payload)
        transcript = re.sub(r"\s+", " ", transcript.casefold()).strip()
        if not transcript:
            raise RuntimeError("Transcription did not return text.")
        return transcript

    def extract_symptoms(self, text: str) -> list[str]:
        return self.extractor.extract(text)

    def _response_text(self, payload: Mapping[str, Any]) -> str:
        texts: list[str] = []
        for candidate in payload.get("candidates", []) or []:
            content = candidate.get("content", {}) or {}
            for part in content.get("parts", []) or []:
                text = str(part.get("text", "")).strip()
                if text:
                    texts.append(text)
        return "\n".join(texts).strip()

    def _normalize_audio_mime_type(self, mime_type: str) -> str:
        normalized = (mime_type or "").strip().lower()
        mime_aliases = {
            "audio/x-wav": "audio/wav",
            "audio/wave": "audio/wav",
            "audio/vnd.wave": "audio/wav",
            "audio/mpga": "audio/mp3",
            "audio/mpeg": "audio/mp3",
            "audio/x-m4a": "audio/aac",
            "audio/m4a": "audio/aac",
        }
        return mime_aliases.get(normalized, normalized or "audio/wav")
