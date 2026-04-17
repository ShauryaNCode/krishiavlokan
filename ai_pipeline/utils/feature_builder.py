"""Production feature preparation helpers for the diagnosis pipeline."""

from __future__ import annotations

import math
import re
from datetime import date, datetime
from difflib import get_close_matches
from typing import Any, Dict, Iterable, List, Mapping, Sequence


DATE_FORMAT = "%Y-%m-%d"
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")

DEFAULT_MODEL_FEATURES = (
    "crop_encoded",
    "rain_anomaly",
    "temp_anomaly",
    "humidity_anomaly",
    "symptom_score",
)

CROP_ALIASES = {
    "cotton": "Cotton(lint)",
    "kapas": "Cotton(lint)",
    "paddy": "Rice",
    "rice": "Rice",
    "dhan": "Rice",
    "mustard": "Rapeseed &Mustard",
    "rapeseedmustard": "Rapeseed &Mustard",
    "arhar": "Arhar/Tur",
    "tur": "Arhar/Tur",
    "pigeonpea": "Arhar/Tur",
    "moong": "Moong(Green Gram)",
    "greengram": "Moong(Green Gram)",
    "cowpea": "Cowpea(Lobia)",
    "lobia": "Cowpea(Lobia)",
    "chilli": "Dry chillies",
    "chili": "Dry chillies",
    "drychilli": "Dry chillies",
    "groundnut": "Groundnut",
    "peanut": "Groundnut",
    "wheat": "Wheat",
    "maize": "Maize",
    "corn": "Maize",
    "jowar": "Jowar",
    "bajra": "Bajra",
    "gram": "Gram",
    "chana": "Gram",
    "soybean": "Soyabean",
    "soyabean": "Soyabean",
    "sugarcane": "Sugarcane",
    "onion": "Onion",
    "potato": "Potato",
    "tomato": "Other Summer Pulses",
}


class FeatureValidationError(ValueError):
    """Raised when user input cannot be converted into diagnosis features."""


def normalize_text(value: Any) -> str:
    """Return a trimmed display string."""

    text = str(value or "").strip()
    return text if text else "Unknown"


def normalize_key(value: Any) -> str:
    """Normalize text for alias and fuzzy matching."""

    return re.sub(r"[^a-z0-9]+", "", str(value or "").casefold())


def normalize_symptom(symptom: Any) -> str:
    """Lowercase a symptom and remove whitespace, hyphens, and underscores."""

    if symptom is None:
        return ""
    return re.sub(r"[\s_-]+", "", str(symptom).strip().casefold())


def normalize_symptoms(raw_symptoms: Iterable[Any] | str | None) -> List[str]:
    """Normalize, de-duplicate, and preserve the order of incoming symptoms."""

    if raw_symptoms is None:
        return []
    if isinstance(raw_symptoms, str):
        raw_symptoms = [raw_symptoms]

    normalized: List[str] = []
    seen = set()
    for symptom in raw_symptoms:
        value = normalize_symptom(symptom)
        if value and value not in seen:
            normalized.append(value)
            seen.add(value)
    return normalized


def validate_sowing_date(sowingDate: str | date) -> date:
    """Validate and return a YYYY-MM-DD sowing date."""

    if isinstance(sowingDate, date):
        return sowingDate
    if not isinstance(sowingDate, str) or not DATE_PATTERN.match(sowingDate):
        raise FeatureValidationError("sowingDate must use YYYY-MM-DD format")

    try:
        return datetime.strptime(sowingDate, DATE_FORMAT).date()
    except ValueError as exc:
        raise FeatureValidationError("sowingDate must be a valid calendar date") from exc


def validate_coordinate(value: Any, name: str) -> float | None:
    """Return a coordinate as float, or None when it is not provided."""

    if value in (None, ""):
        return None
    try:
        coordinate = float(value)
    except (TypeError, ValueError) as exc:
        raise FeatureValidationError(f"{name} must be a number") from exc

    if name == "latitude" and not -90 <= coordinate <= 90:
        raise FeatureValidationError("latitude must be between -90 and 90")
    if name == "longitude" and not -180 <= coordinate <= 180:
        raise FeatureValidationError("longitude must be between -180 and 180")
    return coordinate


def infer_season(sowing_date: date) -> str:
    """Infer a broad Indian crop season from the sowing month."""

    month = sowing_date.month
    if 6 <= month <= 10:
        return "kharif"
    if month in (11, 12, 1, 2, 3):
        return "rabi"
    return "zaid"


def canonicalize_crop(crop: Any, known_crops: Sequence[str] | None = None) -> str:
    """Map farmer-facing crop names to the label encoder vocabulary."""

    display = normalize_text(crop)
    crop_key = normalize_key(display)
    alias = CROP_ALIASES.get(crop_key)

    if not known_crops:
        return alias or display

    known_by_key = {normalize_key(item): item for item in known_crops}
    if crop_key in known_by_key:
        return known_by_key[crop_key]
    if alias and normalize_key(alias) in known_by_key:
        return known_by_key[normalize_key(alias)]

    matches = get_close_matches(crop_key, known_by_key.keys(), n=1, cutoff=0.82)
    if matches:
        return known_by_key[matches[0]]

    return alias or display


def calculate_symptom_score(symptoms: Iterable[Any] | str | None) -> float:
    """Create the compact symptom signal expected by the trained XGBoost model."""

    normalized = normalize_symptoms(symptoms)
    if not normalized:
        return 0.0
    return round(min(len(normalized) / 5.0, 1.0), 3)


def build_model_feature_vector(
    crop_encoded: int,
    anomalies: Mapping[str, Any],
    symptom_score: float,
    feature_names: Sequence[str] | None = None,
) -> Dict[str, float]:
    """Build the exact feature vector expected by the saved XGBoost model."""

    values = {
        "crop_encoded": float(crop_encoded),
        "rain_anomaly": float(anomalies.get("rain_anomaly", 0.0)),
        "temp_anomaly": float(anomalies.get("temp_anomaly", 0.0)),
        "humidity_anomaly": float(anomalies.get("humidity_anomaly", 0.0)),
        "symptom_score": float(symptom_score),
    }
    ordered_names = tuple(feature_names or DEFAULT_MODEL_FEATURES)
    return {name: values.get(name, 0.0) for name in ordered_names}


def build_features(
    crop: str,
    state: str,
    district: str,
    sowingDate: str | date,
    symptoms: Iterable[Any] | str | None,
    latitude: Any = None,
    longitude: Any = None,
    lat: Any = None,
    lon: Any = None,
    offlineMode: bool = False,
) -> Dict[str, Any]:
    """Convert raw request fields into stable production features."""

    parsed_sowing_date = validate_sowing_date(sowingDate)
    resolved_latitude = validate_coordinate(latitude if latitude is not None else lat, "latitude")
    resolved_longitude = validate_coordinate(longitude if longitude is not None else lon, "longitude")
    normalized_symptoms = normalize_symptoms(symptoms)

    return {
        "crop": normalize_text(crop).lower(),
        "cropDisplay": normalize_text(crop),
        "state": normalize_text(state).lower(),
        "stateDisplay": normalize_text(state),
        "district": normalize_text(district).lower(),
        "districtDisplay": normalize_text(district),
        "sowingDate": parsed_sowing_date.isoformat(),
        "sowingDateObject": parsed_sowing_date,
        "sowingMonth": parsed_sowing_date.month,
        "season": infer_season(parsed_sowing_date),
        "symptoms": normalized_symptoms,
        "symptomScore": calculate_symptom_score(normalized_symptoms),
        "latitude": resolved_latitude,
        "longitude": resolved_longitude,
        "hasCoordinates": resolved_latitude is not None and resolved_longitude is not None,
        "offlineMode": bool(offlineMode),
    }


def finite_or_default(value: Any, default: float = 0.0) -> float:
    """Convert numeric feature values while guarding against NaN/inf."""

    try:
        number = float(value)
    except (TypeError, ValueError):
        return default
    return number if math.isfinite(number) else default
