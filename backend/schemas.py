"""Pydantic request and response models for the backend API."""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class DiagnosisRequest(BaseModel):
    crop: str = Field(..., min_length=1)
    state: str = Field(..., min_length=1)
    district: str = Field(..., min_length=1)
    sowingDate: str = Field(..., description="YYYY-MM-DD")
    symptoms: List[str] = Field(default_factory=list)
    lat: Optional[float] = None
    lon: Optional[float] = None


class Recommendation(BaseModel):
    title: str
    detail: str
    priority: str = Field(
        ...,
        description="Urgency level: High, Medium, or Low",
    )
    effort_level: str = Field(
        ...,
        description="Implementation effort: Easy, Medium, or Hard",
    )
    category: str = Field(
        ...,
        description=(
            "Action type: 'Immediate' (take action today) or "
            "'Preventive' (longer-term safeguard)"
        ),
    )

    class Config:
        extra = "allow"


class WeatherPhase(BaseModel):
    phase: str
    status: str
    rainfallMm: Optional[float] = None
    expectedRainfallMm: Optional[float] = None
    rainAnomaly: Optional[float] = None
    rainfallDeviationPct: Optional[float] = None
    avgTempC: Optional[float] = None
    expectedTempC: Optional[float] = None
    tempAnomaly: Optional[float] = None
    temperatureDeviationPct: Optional[float] = None
    avgHumidityPct: Optional[float] = None
    expectedHumidityPct: Optional[float] = None
    humidityAnomaly: Optional[float] = None
    humidityDeviationPct: Optional[float] = None
    isolationScore: Optional[float] = None
    dataDays: Optional[int] = None
    startDate: Optional[str] = None
    endDate: Optional[str] = None
    idealStatus: Optional[str] = None
    metric: Optional[str] = None
    matchScore: Optional[float] = None
    source: Optional[str] = None
    summary: Optional[str] = None

    class Config:
        extra = "allow"


class DiagnosisResponse(BaseModel):
    causeKey: str
    causeTitle: str
    confidenceScore: float
    explanation: str
    weatherPhases: List[WeatherPhase]
    recommendations: List[Recommendation]
    inputSummary: Optional[Dict[str, Any]] = None
    modelDetails: Optional[Dict[str, Any]] = None

    class Config:
        extra = "allow"
