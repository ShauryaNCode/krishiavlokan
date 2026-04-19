"""Production diagnosis engine for KrishiAvalokan.

Primary path:
1. Fetch 120 days of farm-level weather from Open-Meteo Archive.
2. Convert the weather into Early, Mid, and Late growth-stage anomalies.
3. Feed crop, weather anomalies, and symptom score into the saved XGBoost model.
4. Generate a 2-sentence Hinglish explanation with a current Gemini Flash model.

Fallback path:
If live weather, model loading, or model inference fails, the engine returns the
same README contract using the local rule-based scorer.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import pickle
import re
import warnings
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Sequence

try:
    import pandas as pd
except Exception:  # pragma: no cover - optional runtime dependency
    pd = None

try:
    import requests
except Exception:  # pragma: no cover - optional runtime dependency
    requests = None

try:
    from sklearn.ensemble import IsolationForest
except Exception:  # pragma: no cover - optional runtime dependency
    IsolationForest = None

try:
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", category=FutureWarning)
        import google.generativeai as genai
except Exception:  # pragma: no cover - optional runtime dependency
    genai = None

try:  # Supports both module and direct script execution.
    from ai_pipeline.utils.feature_builder import (
        DEFAULT_MODEL_FEATURES,
        build_features,
        build_model_feature_vector,
        canonicalize_crop,
        finite_or_default,
        normalize_key,
        normalize_symptoms,
    )
except ImportError:  # pragma: no cover - direct script fallback
    from utils.feature_builder import (
        DEFAULT_MODEL_FEATURES,
        build_features,
        build_model_feature_vector,
        canonicalize_crop,
        finite_or_default,
        normalize_key,
        normalize_symptoms,
    )


LOGGER = logging.getLogger("krishiavalokan.ai_pipeline")

BASE_DIR = Path(__file__).resolve().parent
DEFAULT_RULES_PATH = BASE_DIR / "rules" / "diagnosis_rules.json"
DEFAULT_TEMPLATES_PATH = BASE_DIR / "templates" / "explanation_templates.json"
DEFAULT_MODELS_DIR = BASE_DIR / "models"

OPEN_METEO_ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"
SEASON_DAYS = 120
REQUEST_TIMEOUT_SECONDS = 8.0
GEMINI_MODEL_CANDIDATES = (
    "gemini-2.5-flash",
    "gemini-flash-latest",
    "gemini-2.0-flash",
    "gemini-2.5-flash-lite",
)

PHASES = ("Early", "Mid", "Late")
GROWTH_STAGES = (
    ("Early", 0, 40),
    ("Mid", 40, 80),
    ("Late", 80, 120),
)

STATUS_ORDER = ("veryLow", "low", "normal", "high", "veryHigh")
STATUS_RANK = {status: index for index, status in enumerate(STATUS_ORDER)}

MODEL_LABEL_TO_CAUSE = {
    "drought": "drought",
    "flood": "waterlogging",
    "heat_stress": "heat",
    "normal": "normal",
}

WEATHER_METRIC_BY_CAUSE = {
    "drought": "rainfallStatus",
    "waterlogging": "rainfallStatus",
    "pest": "humidityStatus",
    "fungal": "humidityStatus",
    "heat": "temperatureStatus",
    "nutrient": "rainfallStatus",
}

CAUSE_SYMPTOM_ALIASES = {
    "drought": ("drought", "dryness", "sukha", "waterstress"),
    "waterlogging": ("waterlogging", "flood", "flooding", "excesswater"),
    "pest": ("pest", "insect", "insects", "larvae"),
    "fungal": ("fungal", "fungus", "mold", "mildew"),
    "heat": ("heat", "heatstress", "sunburn"),
    "nutrient": ("nutrient", "deficiency", "nutrition"),
}

STATUS_TO_RAINFALL_MM = {
    "veryLow": 8,
    "low": 24,
    "normal": 58,
    "high": 96,
    "veryHigh": 142,
}

STATUS_TO_TEMP_C = {
    "veryLow": 18,
    "low": 23,
    "normal": 29,
    "high": 35,
    "veryHigh": 41,
}

STATUS_TO_HUMIDITY = {
    "veryLow": 28,
    "low": 42,
    "normal": 58,
    "high": 74,
    "veryHigh": 88,
}

NORMAL_CAUSE = {
    "cause_title": "No Major Failure Signal",
    "recommendations": [
        {
            "title": "Keep monitoring the crop",
            "detail": "No strong failure signal was detected, so continue weekly field checks.",
            "priority": "Low",
            "effort_level": "Easy",
        },
        {
            "title": "Verify with local advisory",
            "detail": "If symptoms spread, confirm with a local extension worker before treatment.",
            "priority": "Medium",
            "effort_level": "Easy",
        },
    ],
}

RECOMMENDATION_PRIORITIES = ("High", "Medium", "Low")
RECOMMENDATION_EFFORT_LEVELS = ("Easy", "Medium", "Hard")
DEFAULT_RECOMMENDATION_PRIORITIES = ("High", "Medium", "Low")
DEFAULT_RECOMMENDATION_EFFORT_LEVELS = ("Easy", "Medium", "Hard")


class WeatherFetchError(RuntimeError):
    """Raised when live weather cannot be fetched or parsed."""


class ModelInferenceError(RuntimeError):
    """Raised when the saved XGBoost components cannot produce a prediction."""


@dataclass(frozen=True)
class DailyWeather:
    observed_date: date
    precipitation_mm: float
    temp_max_c: float
    temp_min_c: float
    humidity_pct: float

    @property
    def temp_mean_c(self) -> float:
        return (self.temp_max_c + self.temp_min_c) / 2.0


@dataclass(frozen=True)
class WeatherFetchResult:
    daily: List[DailyWeather]
    source: str
    message: str


class DiagnosisEngine:
    """Hybrid production engine with live weather, XGBoost, Gemini, and fallback."""

    def __init__(
        self,
        rules_path: str | Path = DEFAULT_RULES_PATH,
        templates_path: str | Path = DEFAULT_TEMPLATES_PATH,
        models_dir: str | Path = DEFAULT_MODELS_DIR,
        request_timeout_s: float = REQUEST_TIMEOUT_SECONDS,
        gemini_model_name: str | None = None,
    ) -> None:
        self.rules_path = Path(rules_path)
        self.templates_path = Path(templates_path)
        self.models_dir = Path(models_dir)
        self.request_timeout_s = request_timeout_s
        self.gemini_model_names = self._gemini_model_candidates(gemini_model_name)
        self.gemini_model_name = self.gemini_model_names[0]

        self.rules = self._load_json(self.rules_path)
        self.templates = self._load_json(self.templates_path)
        self.causes: Mapping[str, Mapping[str, Any]] = self.rules["causes"]

        self.xgb_model = self._load_pickle(self.models_dir / "xgb_crop_model.pkl")
        self.crop_encoder = self._load_pickle(self.models_dir / "crop_encoder.pkl")
        self.failure_encoder = self._load_pickle(self.models_dir / "failure_encoder.pkl")
        self.gemini_models = self._build_gemini_models(self.gemini_model_names)
        self.gemini_model = self.gemini_models[0] if self.gemini_models else None
        self.session = requests.Session() if requests is not None else None

    def diagnose(
        self,
        crop: str,
        state: str,
        district: str,
        sowingDate: str | date,
        symptoms: Iterable[str] | str,
        latitude: float | str | None = None,
        longitude: float | str | None = None,
        lat: float | str | None = None,
        lon: float | str | None = None,
    ) -> Dict[str, Any]:
        """Return a README-compatible diagnosis response."""

        features = build_features(
            crop=crop,
            state=state,
            district=district,
            sowingDate=sowingDate,
            symptoms=symptoms,
            latitude=latitude,
            longitude=longitude,
            lat=lat,
            lon=lon,
            offlineMode=False,
        )

        if not features["hasCoordinates"]:
            return self._diagnose_with_rules(features, "Missing latitude/longitude")

        try:
            weather = self._fetch_weather_data(
                latitude=features["latitude"],
                longitude=features["longitude"],
                sowing_date=features["sowingDateObject"],
            )
            anomaly_result = self._process_weather_anomalies(weather.daily)
            prediction = self._predict_with_xgboost(features, anomaly_result["modelFeatures"])
        except Exception as exc:
            LOGGER.warning("Production diagnosis path failed; using rule fallback: %s", exc)
            return self._diagnose_with_rules(features, str(exc))

        cause_key = prediction["causeKey"]
        cause_meta = self._cause_metadata(cause_key)
        explanation = self._generate_explanation(
            cause_key=cause_key,
            cause_title=cause_meta["cause_title"],
            crop=features["cropDisplay"],
            district=features["districtDisplay"],
            weather_phases=anomaly_result["weatherPhases"],
            recommendations=cause_meta["recommendations"],
            model_label=prediction["rawLabel"],
        )

        return {
            "causeKey": cause_key,
            "causeTitle": cause_meta["cause_title"],
            "confidenceScore": prediction["confidenceScore"],
            "explanation": explanation,
            "weatherPhases": anomaly_result["weatherPhases"],
            "recommendations": cause_meta["recommendations"],
            "inputSummary": self._input_summary(features),
            "modelDetails": {
                "mode": "xgboost_live_weather",
                "rawModelLabel": prediction["rawLabel"],
                "cropEncoderValue": prediction["cropEncoded"],
                "cropModelValue": prediction["cropModelValue"],
                "featureVector": prediction["featureVector"],
                "weatherSource": weather.source,
                "weatherMessage": weather.message,
            },
        }

    def diagnose_from_payload(self, payload: Mapping[str, Any]) -> Dict[str, Any]:
        """Convenience wrapper for FastAPI handlers that receive a dict body."""

        return self.diagnose(
            crop=payload.get("crop", ""),
            state=payload.get("state", ""),
            district=payload.get("district", ""),
            sowingDate=payload.get("sowingDate", ""),
            symptoms=payload.get("symptoms", []),
            latitude=payload.get("latitude"),
            longitude=payload.get("longitude"),
            lat=payload.get("lat"),
            lon=payload.get("lon"),
        )

    def _fetch_weather_data(
        self,
        latitude: float,
        longitude: float,
        sowing_date: date,
    ) -> WeatherFetchResult:
        """Fetch 120 days of daily weather from the Open-Meteo Archive API."""

        if self.session is None:
            raise WeatherFetchError("requests library is unavailable")

        start_date = sowing_date
        planned_end_date = sowing_date + timedelta(days=SEASON_DAYS - 1)
        latest_archive_date = date.today() - timedelta(days=1)
        end_date = min(planned_end_date, latest_archive_date)

        if end_date < start_date:
            raise WeatherFetchError("sowingDate is outside available historical weather range")

        params = {
            "latitude": latitude,
            "longitude": longitude,
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "daily": (
                "precipitation_sum,temperature_2m_max,temperature_2m_min,"
                "relative_humidity_2m_mean"
            ),
            "timezone": "auto",
        }

        try:
            payload = self._request_open_meteo(params)
        except WeatherFetchError as exc:
            if "relative_humidity" not in str(exc):
                raise
            fallback_params = dict(params)
            fallback_params["daily"] = "precipitation_sum,temperature_2m_max,temperature_2m_min"
            fallback_params["hourly"] = "relative_humidity_2m"
            payload = self._request_open_meteo(fallback_params)

        daily = self._parse_open_meteo_daily(payload)
        if len(daily) < 10:
            raise WeatherFetchError("Open-Meteo returned too few weather days")

        message = f"Fetched {len(daily)} daily records from {start_date} to {end_date}"
        if end_date < planned_end_date:
            message += "; season window was clipped to available historical data"

        return WeatherFetchResult(
            daily=daily,
            source="Open-Meteo Archive API",
            message=message,
        )

    def _request_open_meteo(self, params: Mapping[str, Any]) -> Mapping[str, Any]:
        try:
            response = self.session.get(
                OPEN_METEO_ARCHIVE_URL,
                params=params,
                timeout=self.request_timeout_s,
            )
            response.raise_for_status()
            payload = response.json()
        except Exception as exc:
            raise WeatherFetchError(f"Open-Meteo request failed: {exc}") from exc

        if payload.get("error"):
            raise WeatherFetchError(payload.get("reason", "Open-Meteo returned an error"))
        return payload

    def _parse_open_meteo_daily(self, payload: Mapping[str, Any]) -> List[DailyWeather]:
        daily = payload.get("daily") or {}
        dates = daily.get("time") or []
        precipitation = daily.get("precipitation_sum") or []
        temp_max = daily.get("temperature_2m_max") or []
        temp_min = daily.get("temperature_2m_min") or []
        humidity = daily.get("relative_humidity_2m_mean")

        if humidity is None:
            hourly_humidity = self._daily_humidity_from_hourly(payload.get("hourly") or {})
            humidity = [
                hourly_humidity.get(day, self._estimate_humidity_from_rain(precipitation[index]))
                for index, day in enumerate(dates)
            ]

        record_count = min(len(dates), len(precipitation), len(temp_max), len(temp_min), len(humidity))
        records: List[DailyWeather] = []

        for index in range(record_count):
            try:
                records.append(
                    DailyWeather(
                        observed_date=date.fromisoformat(dates[index]),
                        precipitation_mm=finite_or_default(precipitation[index]),
                        temp_max_c=finite_or_default(temp_max[index]),
                        temp_min_c=finite_or_default(temp_min[index]),
                        humidity_pct=min(max(finite_or_default(humidity[index], 60.0), 0.0), 100.0),
                    )
                )
            except ValueError:
                continue

        return records

    def _daily_humidity_from_hourly(self, hourly: Mapping[str, Any]) -> Dict[str, float]:
        times = hourly.get("time") or []
        values = hourly.get("relative_humidity_2m") or []
        grouped: Dict[str, List[float]] = {}

        for timestamp, value in zip(times, values):
            day = str(timestamp).split("T", 1)[0]
            grouped.setdefault(day, []).append(finite_or_default(value, 60.0))

        return {day: self._mean(day_values) for day, day_values in grouped.items()}

    def _process_weather_anomalies(self, daily: Sequence[DailyWeather]) -> Dict[str, Any]:
        averages = self._period_averages(daily)
        isolation_scores = self._isolation_scores(daily)
        weather_phases: List[Dict[str, Any]] = []

        for phase_name, start_index, end_index in GROWTH_STAGES:
            segment = list(daily[start_index:end_index])
            segment_scores = isolation_scores[start_index:end_index]
            weather_phases.append(
                self._summarize_growth_stage(
                    phase_name=phase_name,
                    segment=segment,
                    isolation_scores=segment_scores,
                    averages=averages,
                )
            )

        model_features = {
            "rain_anomaly": self._strongest_value(weather_phases, "rainAnomaly"),
            "temp_anomaly": self._strongest_value(weather_phases, "tempAnomaly"),
            "humidity_anomaly": self._strongest_value(weather_phases, "humidityAnomaly"),
        }

        return {
            "weatherPhases": weather_phases,
            "modelFeatures": model_features,
        }

    def _summarize_growth_stage(
        self,
        phase_name: str,
        segment: Sequence[DailyWeather],
        isolation_scores: Sequence[float],
        averages: Mapping[str, float],
    ) -> Dict[str, Any]:
        if not segment:
            return {
                "phase": phase_name,
                "status": "Unavailable",
                "dataDays": 0,
                "rainfallMm": 0.0,
                "expectedRainfallMm": 0.0,
                "rainAnomaly": 0.0,
                "avgTempC": 0.0,
                "expectedTempC": round(averages["temp_mean"], 2),
                "tempAnomaly": 0.0,
                "avgHumidityPct": 0.0,
                "expectedHumidityPct": round(averages["humidity_mean"], 2),
                "humidityAnomaly": 0.0,
                "isolationScore": 0.0,
            }

        data_days = len(segment)
        rainfall = sum(day.precipitation_mm for day in segment)
        expected_rainfall = averages["rainfall_per_day"] * data_days
        avg_temp = self._mean(day.temp_mean_c for day in segment)
        avg_humidity = self._mean(day.humidity_pct for day in segment)
        isolation_score = self._mean(isolation_scores) if isolation_scores else 0.0

        rain_anomaly = self._deviation_ratio(rainfall, expected_rainfall)
        temp_anomaly = self._deviation_ratio(avg_temp, averages["temp_mean"])
        humidity_anomaly = self._deviation_ratio(avg_humidity, averages["humidity_mean"])

        strongest_deviation = max(abs(rain_anomaly), abs(temp_anomaly), abs(humidity_anomaly))

        return {
            "phase": phase_name,
            "startDate": segment[0].observed_date.isoformat(),
            "endDate": segment[-1].observed_date.isoformat(),
            "status": self._anomaly_status(strongest_deviation, isolation_score),
            "dataDays": data_days,
            "rainfallMm": round(rainfall, 2),
            "expectedRainfallMm": round(expected_rainfall, 2),
            "rainAnomaly": round(rain_anomaly, 4),
            "rainfallDeviationPct": round(rain_anomaly * 100, 1),
            "avgTempC": round(avg_temp, 2),
            "expectedTempC": round(averages["temp_mean"], 2),
            "tempAnomaly": round(temp_anomaly, 4),
            "temperatureDeviationPct": round(temp_anomaly * 100, 1),
            "avgHumidityPct": round(avg_humidity, 2),
            "expectedHumidityPct": round(averages["humidity_mean"], 2),
            "humidityAnomaly": round(humidity_anomaly, 4),
            "humidityDeviationPct": round(humidity_anomaly * 100, 1),
            "isolationScore": round(isolation_score, 4),
        }

    def _period_averages(self, daily: Sequence[DailyWeather]) -> Dict[str, float]:
        return {
            "rainfall_per_day": sum(day.precipitation_mm for day in daily) / max(len(daily), 1),
            "temp_mean": self._mean(day.temp_mean_c for day in daily),
            "humidity_mean": self._mean(day.humidity_pct for day in daily),
        }

    def _isolation_scores(self, daily: Sequence[DailyWeather]) -> List[float]:
        if IsolationForest is None or len(daily) < 10:
            return [0.0 for _ in daily]

        matrix = [
            [day.precipitation_mm, day.temp_mean_c, day.humidity_pct]
            for day in daily
        ]
        detector = IsolationForest(n_estimators=100, contamination="auto", random_state=42)
        detector.fit(matrix)
        return [float(score) for score in detector.decision_function(matrix)]

    def _predict_with_xgboost(
        self,
        features: Mapping[str, Any],
        anomaly_features: Mapping[str, float],
    ) -> Dict[str, Any]:
        if self.xgb_model is None or self.crop_encoder is None or self.failure_encoder is None:
            raise ModelInferenceError("XGBoost model or encoders are missing")

        known_crops = list(getattr(self.crop_encoder, "classes_", []))
        crop_model_value = canonicalize_crop(features["cropDisplay"], known_crops)
        if crop_model_value not in known_crops:
            crop_model_value = self._fallback_crop_value(known_crops)

        try:
            crop_encoded = int(self.crop_encoder.transform([crop_model_value])[0])
        except Exception as exc:
            raise ModelInferenceError(f"Crop encoding failed for {crop_model_value}") from exc

        feature_names = self._model_feature_names()
        feature_vector = build_model_feature_vector(
            crop_encoded=crop_encoded,
            anomalies=anomaly_features,
            symptom_score=features["symptomScore"],
            feature_names=feature_names,
        )
        model_input = self._model_input_frame(feature_vector, feature_names)

        try:
            prediction_id = int(self.xgb_model.predict(model_input)[0])
            raw_label = str(self.failure_encoder.inverse_transform([prediction_id])[0])
            confidence = self._prediction_confidence(model_input)
        except Exception as exc:
            raise ModelInferenceError(f"XGBoost prediction failed: {exc}") from exc

        cause_key = self._map_model_label_to_cause(
            raw_label=raw_label,
            symptoms=features["symptoms"],
            anomaly_features=anomaly_features,
        )

        return {
            "causeKey": cause_key,
            "rawLabel": raw_label,
            "confidenceScore": round(confidence, 2),
            "cropEncoded": crop_encoded,
            "cropModelValue": crop_model_value,
            "featureVector": feature_vector,
        }

    def _generate_explanation(
        self,
        cause_key: str,
        cause_title: str,
        crop: str,
        district: str,
        weather_phases: Sequence[Mapping[str, Any]],
        recommendations: Sequence[Mapping[str, Any]],
        model_label: str,
    ) -> str:
        easy_step = self._easy_recommendation_step(recommendations)
        gemini_text = self._generate_gemini_explanation(
            cause_title=cause_title,
            crop=crop,
            district=district,
            weather_phases=weather_phases,
            easy_step=easy_step,
            model_label=model_label,
        )
        if gemini_text:
            return gemini_text
        return self._fallback_explanation(
            cause_key,
            cause_title,
            crop,
            district,
            weather_phases,
            easy_step,
        )

    def _generate_gemini_explanation(
        self,
        cause_title: str,
        crop: str,
        district: str,
        weather_phases: Sequence[Mapping[str, Any]],
        easy_step: str | None,
        model_label: str,
    ) -> str | None:
        if not self.gemini_models:
            return None

        strongest = self._strongest_phase_summary(weather_phases)
        easy_step_text = easy_step or "field me affected plants ko inspect karein"
        prompt = (
            f"{district} ke farmer ke liye 2 short Hinglish sentences likho. "
            f"Crop: {crop}. Problem: {cause_title}. Weather reason: {strongest}. "
            "Second sentence exactly 'Aaj ka Easy step:' se start ho aur "
            f"farmer ko aaj ye kaam bataye: {easy_step_text}. "
            "Markdown mat use karo."
        )

        last_error: Exception | None = None
        for model_name, model in self.gemini_models:
            try:
                response = model.generate_content(
                    prompt,
                    generation_config={"temperature": 0.35, "max_output_tokens": 120},
                )
                text = getattr(response, "text", "") or ""
                generated = self._two_sentence_text(text.strip())
                if generated:
                    self.gemini_model_name = model_name
                    return self._explanation_with_easy_step(generated, easy_step)
            except Exception as exc:
                last_error = exc
                LOGGER.warning("Gemini model %s failed; trying fallback: %s", model_name, exc)

        if last_error is not None:
            LOGGER.warning("All Gemini models failed; using template fallback: %s", last_error)
        return None

    def _fallback_explanation(
        self,
        cause_key: str,
        cause_title: str,
        crop: str,
        district: str,
        weather_phases: Sequence[Mapping[str, Any]],
        easy_step: str | None = None,
    ) -> str:
        if cause_key in self.templates:
            templated = self.templates[cause_key].format(crop=crop, district=district)
            return self._explanation_with_easy_step(templated, easy_step)
        strongest = self._strongest_phase_summary(weather_phases)
        explanation = (
            f"{district} me {crop} ke liye {cause_title} ka signal mila hai. "
            f"{strongest}, isliye field ko closely monitor karein aur local advisory se confirm karein."
        )
        return self._explanation_with_easy_step(explanation, easy_step)

    def _diagnose_with_rules(self, features: Mapping[str, Any], reason: str) -> Dict[str, Any]:
        weather_snapshot = self._generate_mock_weather_phases(
            sowing_date=features["sowingDate"],
            state=features["state"],
            district=features["district"],
        )
        ranked_causes = sorted(
            (
                self._score_rule_cause(
                    cause_key=cause_key,
                    rule=rule,
                    symptoms=features["symptoms"],
                    weather_snapshot=weather_snapshot,
                    season=features["season"],
                )
                for cause_key, rule in self.causes.items()
            ),
            key=lambda item: item["score"],
            reverse=True,
        )
        top = ranked_causes[0]
        cause_meta = self._cause_metadata(top["causeKey"])

        return {
            "causeKey": top["causeKey"],
            "causeTitle": cause_meta["cause_title"],
            "confidenceScore": top["score"],
            "explanation": self._fallback_explanation(
                cause_key=top["causeKey"],
                cause_title=cause_meta["cause_title"],
                crop=features["cropDisplay"],
                district=features["districtDisplay"],
                weather_phases=[],
                easy_step=self._easy_recommendation_step(cause_meta["recommendations"]),
            ),
            "weatherPhases": self._mock_weather_phase_response(top["causeKey"], cause_meta, weather_snapshot),
            "recommendations": cause_meta["recommendations"],
            "inputSummary": self._input_summary(features),
            "modelDetails": {
                "mode": "rule_fallback",
                "reason": reason,
                "matchedSymptoms": top["matchedSymptoms"],
            },
        }

    def _score_rule_cause(
        self,
        cause_key: str,
        rule: Mapping[str, Any],
        symptoms: Sequence[str],
        weather_snapshot: Mapping[str, Mapping[str, Any]],
        season: str,
    ) -> Dict[str, Any]:
        triggers = normalize_symptoms(rule.get("trigger_symptoms", []))
        matched_symptoms = self._match_symptoms(symptoms, triggers)
        alias_matches = self._match_symptoms(symptoms, CAUSE_SYMPTOM_ALIASES.get(cause_key, ()))
        for symptom in alias_matches:
            if symptom not in matched_symptoms:
                matched_symptoms.append(symptom)
        match_ratio = min(len(matched_symptoms) / 3.0, 1.0)

        base_weight = float(rule.get("base_weight", 0.12))
        symptom_component = min(0.64, match_ratio * 0.64)
        weather_component = self._rule_weather_component(cause_key, rule, weather_snapshot)
        season_component = 0.04 if season in rule.get("season_hints", []) else 0.0

        score = base_weight + symptom_component + weather_component + season_component
        if not symptoms:
            score = min(score, 0.55)
        elif not matched_symptoms:
            score = min(score, 0.62)

        return {
            "causeKey": cause_key,
            "score": round(min(score, 0.97), 2),
            "matchedSymptoms": matched_symptoms,
        }

    def _rule_weather_component(
        self,
        cause_key: str,
        rule: Mapping[str, Any],
        weather_snapshot: Mapping[str, Mapping[str, Any]],
    ) -> float:
        metric = WEATHER_METRIC_BY_CAUSE.get(cause_key, "rainfallStatus")
        weather_scores = [
            self._status_match_score(weather_snapshot[phase][metric], rule["weather_ideal_status"][phase])
            for phase in PHASES
        ]
        return (sum(weather_scores) / len(weather_scores)) * 0.26

    def _mock_weather_phase_response(
        self,
        cause_key: str,
        cause_meta: Mapping[str, Any],
        weather_snapshot: Mapping[str, Mapping[str, Any]],
    ) -> List[Dict[str, Any]]:
        metric = WEATHER_METRIC_BY_CAUSE.get(cause_key, "rainfallStatus")
        metric_label = {
            "rainfallStatus": "rainfall / soil moisture",
            "temperatureStatus": "temperature",
            "humidityStatus": "humidity",
        }[metric]
        phases: List[Dict[str, Any]] = []

        for phase in PHASES:
            rule = self.causes.get(cause_key, {})
            ideal_status = rule.get("weather_ideal_status", {}).get(phase, "normal")
            actual_status = weather_snapshot[phase][metric]
            phases.append(
                {
                    "phase": phase,
                    "status": actual_status,
                    "idealStatus": ideal_status,
                    "metric": metric_label,
                    "matchScore": round(self._status_match_score(actual_status, ideal_status), 2),
                    "rainfallMm": weather_snapshot[phase]["rainfallMm"],
                    "avgTempC": weather_snapshot[phase]["temperatureC"],
                    "avgHumidityPct": weather_snapshot[phase]["humidityPct"],
                    "source": "mock_fallback",
                    "summary": (
                        f"{phase} fallback {metric_label} is {actual_status}; "
                        f"the {cause_meta['cause_title']} rule expects {ideal_status}."
                    ),
                }
            )
        return phases

    def _generate_mock_weather_phases(
        self,
        sowing_date: str,
        state: str,
        district: str,
    ) -> Dict[str, Dict[str, Any]]:
        parsed_sowing_date = date.fromisoformat(sowing_date)
        location_seed = f"{state}:{district}".lower()
        phases: Dict[str, Dict[str, Any]] = {}

        for phase, offset in zip(PHASES, (0, 45, 90)):
            phase_date = parsed_sowing_date + timedelta(days=offset)
            baseline = self._seasonal_baseline(phase_date.month)
            rainfall_status = self._shift_status(
                baseline["rainfallStatus"],
                self._stable_shift(location_seed, phase, "rainfall"),
            )
            temperature_status = self._shift_status(
                baseline["temperatureStatus"],
                self._stable_shift(location_seed, phase, "temperature"),
            )
            humidity_status = self._shift_status(
                baseline["humidityStatus"],
                self._stable_shift(location_seed, phase, "humidity"),
            )
            phases[phase] = {
                "date": phase_date.isoformat(),
                "rainfallStatus": rainfall_status,
                "temperatureStatus": temperature_status,
                "humidityStatus": humidity_status,
                "rainfallMm": STATUS_TO_RAINFALL_MM[rainfall_status],
                "temperatureC": STATUS_TO_TEMP_C[temperature_status],
                "humidityPct": STATUS_TO_HUMIDITY[humidity_status],
            }
        return phases

    def _seasonal_baseline(self, month: int) -> Dict[str, str]:
        if month in (12, 1, 2):
            return {"rainfallStatus": "veryLow", "temperatureStatus": "low", "humidityStatus": "low"}
        if month in (3, 4, 5):
            return {
                "rainfallStatus": "low",
                "temperatureStatus": "high" if month != 5 else "veryHigh",
                "humidityStatus": "low",
            }
        if month in (6, 7, 8, 9):
            return {
                "rainfallStatus": "high" if month in (6, 9) else "veryHigh",
                "temperatureStatus": "normal",
                "humidityStatus": "high" if month in (6, 9) else "veryHigh",
            }
        return {"rainfallStatus": "normal", "temperatureStatus": "normal", "humidityStatus": "normal"}

    def _map_model_label_to_cause(
        self,
        raw_label: str,
        symptoms: Sequence[str],
        anomaly_features: Mapping[str, float],
    ) -> str:
        label_key = raw_label.strip().lower()
        if label_key == "pest_disease":
            fungal_triggers = normalize_symptoms(self.causes["fungal"].get("trigger_symptoms", []))
            if self._match_symptoms(symptoms, fungal_triggers):
                return "fungal"
            if anomaly_features.get("humidity_anomaly", 0.0) > 0.2:
                return "fungal"
            return "pest"
        return MODEL_LABEL_TO_CAUSE.get(label_key, label_key)

    def _cause_metadata(self, cause_key: str) -> Mapping[str, Any]:
        if cause_key in self.causes:
            metadata = dict(self.causes[cause_key])
        elif cause_key == "normal":
            metadata = dict(NORMAL_CAUSE)
        else:
            metadata = {
                "cause_title": cause_key.replace("_", " ").title(),
                "recommendations": [
                    {
                        "title": "Confirm diagnosis locally",
                        "detail": "The model returned an uncommon label, so verify before taking treatment action.",
                        "priority": "High",
                        "effort_level": "Easy",
                    }
                ],
            }
        metadata["recommendations"] = self._recommendation_plan(metadata.get("recommendations", []))
        return metadata

    def _recommendation_plan(self, recommendations: Any) -> List[Dict[str, str]]:
        if isinstance(recommendations, str):
            raw_recommendations = [recommendations]
        elif isinstance(recommendations, Mapping):
            raw_recommendations = [recommendations]
        else:
            raw_recommendations = list(recommendations or [])

        plan: List[Dict[str, str]] = []
        for index, recommendation in enumerate(raw_recommendations):
            default_priority = DEFAULT_RECOMMENDATION_PRIORITIES[
                min(index, len(DEFAULT_RECOMMENDATION_PRIORITIES) - 1)
            ]
            default_effort = DEFAULT_RECOMMENDATION_EFFORT_LEVELS[
                min(index, len(DEFAULT_RECOMMENDATION_EFFORT_LEVELS) - 1)
            ]

            if isinstance(recommendation, Mapping):
                title = str(recommendation.get("title") or f"Step {index + 1}").strip()
                detail = str(
                    recommendation.get("detail")
                    or recommendation.get("description")
                    or recommendation.get("action")
                    or title
                ).strip()
                priority = self._recommendation_choice(
                    recommendation.get("priority"),
                    RECOMMENDATION_PRIORITIES,
                    default_priority,
                )
                effort_level = self._recommendation_choice(
                    recommendation.get("effort_level") or recommendation.get("effortLevel"),
                    RECOMMENDATION_EFFORT_LEVELS,
                    default_effort,
                )
            else:
                title = f"Step {index + 1}"
                detail = str(recommendation).strip()
                priority = default_priority
                effort_level = default_effort

            if not detail:
                continue
            plan.append(
                {
                    "advice_key": self._recommendation_key(title=title, detail=detail, index=index),
                    "title": title or f"Step {index + 1}",
                    "detail": detail,
                    "priority": priority,
                    "effort_level": effort_level,
                }
            )

        if plan:
            return plan
        return [
            {
                "advice_key": "confirm_diagnosis_locally",
                "title": "Confirm diagnosis locally",
                "detail": "Verify the crop symptoms with a local extension worker before treatment.",
                "priority": "High",
                "effort_level": "Easy",
            }
        ]

    def _recommendation_key(self, title: str, detail: str, index: int) -> str:
        source = title.strip() or detail.strip() or f"step_{index + 1}"
        slug = re.sub(r"[^a-z0-9]+", "_", source.lower()).strip("_")
        return slug or f"step_{index + 1}"

    def _recommendation_choice(self, value: Any, allowed_values: Sequence[str], default: str) -> str:
        candidate = str(value or "").replace("_", " ").strip()
        for allowed in allowed_values:
            if candidate.lower() == allowed.lower():
                return allowed
        return default

    def _easy_recommendation_step(self, recommendations: Sequence[Mapping[str, Any]]) -> str | None:
        for recommendation in recommendations:
            if str(recommendation.get("effort_level", "")).lower() == "easy":
                title = str(recommendation.get("title", "")).strip()
                detail = str(recommendation.get("detail", "")).strip()
                if title and detail and title != detail:
                    return f"{title}: {detail}"
                return title or detail
        return None

    def _model_feature_names(self) -> List[str]:
        names = getattr(self.xgb_model, "feature_names_in_", None)
        if names is None:
            return list(DEFAULT_MODEL_FEATURES)
        return [str(name) for name in names]

    def _model_input_frame(self, feature_vector: Mapping[str, float], feature_names: Sequence[str]) -> Any:
        if pd is not None:
            return pd.DataFrame([feature_vector], columns=feature_names)
        return [[feature_vector[name] for name in feature_names]]

    def _prediction_confidence(self, model_input: Any) -> float:
        if not hasattr(self.xgb_model, "predict_proba"):
            return 0.7
        probabilities = self.xgb_model.predict_proba(model_input)[0]
        return float(max(probabilities))

    def _fallback_crop_value(self, known_crops: Sequence[str]) -> str:
        if not known_crops:
            raise ModelInferenceError("Crop encoder has no classes")
        other = canonicalize_crop("other oilseeds", known_crops)
        return other if other in known_crops else known_crops[0]

    def _gemini_model_candidates(self, preferred_model: str | None) -> List[str]:
        raw_names = [preferred_model or os.getenv("GEMINI_MODEL_NAME", ""), *GEMINI_MODEL_CANDIDATES]
        names: List[str] = []
        for raw_name in raw_names:
            model_name = str(raw_name or "").strip()
            if not model_name:
                continue
            model_name = model_name.removeprefix("models/")
            if model_name not in names:
                names.append(model_name)
        return names

    def _build_gemini_models(self, model_names: Sequence[str]) -> List[tuple[str, Any]]:
        api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        if genai is None or not api_key:
            return []
        try:
            genai.configure(api_key=api_key)
        except Exception as exc:
            LOGGER.warning("Gemini model setup failed: %s", exc)
            return []

        models: List[tuple[str, Any]] = []
        for model_name in model_names:
            try:
                models.append((model_name, genai.GenerativeModel(model_name)))
            except Exception as exc:
                LOGGER.warning("Could not initialize Gemini model %s: %s", model_name, exc)
        return models

    def _load_pickle(self, path: Path) -> Any:
        try:
            with path.open("rb") as file:
                return pickle.load(file)
        except Exception as exc:
            LOGGER.warning("Could not load %s: %s", path.name, exc)
            return None

    def _load_json(self, path: Path) -> Dict[str, Any]:
        if not path.exists():
            raise FileNotFoundError(f"Required diagnosis asset not found: {path}")
        with path.open("r", encoding="utf-8") as file:
            return json.load(file)

    def _input_summary(self, features: Mapping[str, Any]) -> Dict[str, Any]:
        return {
            "crop": features["cropDisplay"],
            "state": features["stateDisplay"],
            "district": features["districtDisplay"],
            "sowingDate": features["sowingDate"],
            "season": features["season"],
            "normalizedSymptoms": features["symptoms"],
            "symptomScore": features["symptomScore"],
            "latitude": features["latitude"],
            "longitude": features["longitude"],
        }

    def _match_symptoms(self, symptoms: Sequence[str], triggers: Sequence[str]) -> List[str]:
        matches: List[str] = []
        for symptom in symptoms:
            for trigger in triggers:
                if symptom == trigger or symptom in trigger or trigger in symptom:
                    if symptom not in matches:
                        matches.append(symptom)
                    break
        return matches

    def _status_match_score(self, actual_status: str, ideal_status: str) -> float:
        distance = abs(STATUS_RANK[actual_status] - STATUS_RANK[ideal_status])
        if distance == 0:
            return 1.0
        if distance == 1:
            return 0.72
        if distance == 2:
            return 0.38
        return 0.12

    def _stable_shift(self, seed: str, phase: str, metric: str) -> int:
        digest = hashlib.sha256(f"{seed}:{phase}:{metric}".encode("utf-8")).hexdigest()
        bucket = int(digest[:2], 16) % 7
        return [-1, 0, 0, 0, 0, 1, 1][bucket]

    def _shift_status(self, status: str, shift: int) -> str:
        current_index = STATUS_RANK[status]
        shifted_index = min(max(current_index + shift, 0), len(STATUS_ORDER) - 1)
        return STATUS_ORDER[shifted_index]

    def _anomaly_status(self, strongest_deviation: float, isolation_score: float) -> str:
        if strongest_deviation >= 0.5 or isolation_score < -0.08:
            return "Severe Anomaly"
        if strongest_deviation >= 0.25 or isolation_score < 0.0:
            return "Moderate Anomaly"
        if strongest_deviation >= 0.1:
            return "Mild Anomaly"
        return "Normal"

    def _strongest_value(self, weather_phases: Sequence[Mapping[str, Any]], key: str) -> float:
        values = [float(phase.get(key, 0.0)) for phase in weather_phases if phase.get("dataDays", 0) > 0]
        if not values:
            return 0.0
        return round(max(values, key=lambda value: abs(value)), 4)

    def _strongest_phase_summary(self, weather_phases: Sequence[Mapping[str, Any]]) -> str:
        if not weather_phases:
            return "available symptoms rule-based pattern se match kar rahe hain"
        strongest = max(
            weather_phases,
            key=lambda phase: max(
                abs(float(phase.get("rainAnomaly", 0.0))),
                abs(float(phase.get("tempAnomaly", 0.0))),
                abs(float(phase.get("humidityAnomaly", 0.0))),
            ),
        )
        return (
            f"{strongest.get('phase')} phase me rainfall deviation "
            f"{strongest.get('rainfallDeviationPct', 0)}% aur temperature deviation "
            f"{strongest.get('temperatureDeviationPct', 0)}% tha"
        )

    def _deviation_ratio(self, actual: float, expected: float) -> float:
        if abs(expected) < 1e-6:
            return 0.0 if abs(actual) < 1e-6 else 1.0
        return (actual - expected) / abs(expected)

    def _mean(self, values: Iterable[float]) -> float:
        numbers = [float(value) for value in values]
        if not numbers:
            return 0.0
        return sum(numbers) / len(numbers)

    def _estimate_humidity_from_rain(self, precipitation_mm: Any) -> float:
        rain = finite_or_default(precipitation_mm)
        if rain >= 10:
            return 85.0
        if rain >= 2:
            return 72.0
        return 55.0

    def _two_sentence_text(self, text: str) -> str | None:
        cleaned = re.sub(r"\s+", " ", text).strip()
        if not cleaned:
            return None
        sentences = re.split(r"(?<=[.!?])\s+", cleaned)
        selected = " ".join(sentence for sentence in sentences[:2] if sentence)
        return selected or cleaned

    def _explanation_with_easy_step(self, text: str, easy_step: str | None) -> str:
        cleaned = self._two_sentence_text(text) or ""
        if not easy_step:
            return cleaned

        sentences = re.split(r"(?<=[.!?])\s+", cleaned)
        context = next((sentence.strip() for sentence in sentences if sentence.strip()), cleaned).strip()
        if context and context[-1] not in ".!?":
            context += "."

        step = easy_step.strip().rstrip(".!?")
        return f"{context} Aaj ka Easy step: {step}."


if __name__ == "__main__":
    engine = DiagnosisEngine()
    demo = engine.diagnose(
        crop="Cotton",
        state="Maharashtra",
        district="Pune",
        sowingDate="2025-07-01",
        symptoms=["Drought", "Wilting leaves", "Dry soil"],
        latitude=18.5204,
        longitude=73.8567,
    )
    print(json.dumps(demo, ensure_ascii=False, indent=2))
