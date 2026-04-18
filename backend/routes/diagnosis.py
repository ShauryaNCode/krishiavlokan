"""Diagnosis API routes."""

from __future__ import annotations

from functools import lru_cache
from typing import Any

from fastapi import APIRouter, HTTPException

from backend.schemas import DiagnosisRequest, DiagnosisResponse
from backend.storage import JSONStorage


router = APIRouter(tags=["diagnosis"])
storage = JSONStorage()


@lru_cache(maxsize=1)
def get_engine() -> Any:
    from ai_pipeline.diagnosis_engine import DiagnosisEngine

    return DiagnosisEngine()


def request_to_dict(request: DiagnosisRequest) -> dict[str, Any]:
    if hasattr(request, "model_dump"):
        return request.model_dump()
    return request.dict()


@router.post("/diagnose", response_model=DiagnosisResponse)
def diagnose(request: DiagnosisRequest) -> dict[str, Any]:
    """Run the AI pipeline, save the diagnosis, and return the result."""

    try:
        result = get_engine().diagnose(
            crop=request.crop,
            state=request.state,
            district=request.district,
            sowingDate=request.sowingDate,
            symptoms=request.symptoms,
            lat=request.lat,
            lon=request.lon,
        )
        storage.save_diagnosis(
            request_payload=request_to_dict(request),
            response_payload=result,
        )
        return result
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Diagnosis engine failed") from exc


@router.get("/history")
def history() -> list[dict[str, Any]]:
    """Return saved diagnosis events, newest first."""

    saved_history = storage.get_history()
    return saved_history[::-1]
