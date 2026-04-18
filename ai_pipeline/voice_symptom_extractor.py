"""Voice symptom extraction for messy farmer speech."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Mapping, Sequence

try:
    import requests
except Exception:  # pragma: no cover - optional runtime dependency
    requests = None

try:
    from ai_pipeline.utils.feature_builder import normalize_key
except ImportError:  # pragma: no cover - direct script fallback
    from utils.feature_builder import normalize_key


BASE_DIR = Path(__file__).resolve().parent
RULES_PATH = BASE_DIR / "rules" / "diagnosis_rules.json"
GEMINI_TEXT_MODEL = os.getenv("VOICE_EXTRACT_MODEL", "gemini-2.5-flash")
GEMINI_GENERATE_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent?key={api_key}"
)

HINGLISH_REPLACEMENTS: Mapping[str, str] = {
    "paani jama": "waterlogging flooded standing water",
    "pani jama": "waterlogging flooded standing water",
    "jad gal": "root rot",
    "jad sadh": "root rot",
    "sukha": "dry drought",
    "sukh raha": "dry wilting",
    "murjha": "wilting",
    "murjhaya": "wilting",
    "peela": "yellow yellowing",
    "pila": "yellow yellowing",
    "peele patte": "yellow leaves",
    "pile patte": "yellow leaves",
    "daag": "spots",
    "dhabbe": "spots blotches",
    "kaale daag": "black spots",
    "kale daag": "black spots",
    "bhoore daag": "brown spots",
    "safed powder": "white powder mildew",
    "safed parat": "white powder layer",
    "keede": "pests insects",
    "keeda": "pest insect",
    "kide": "pests insects",
    "patte kha rahe": "leaves eaten",
    "garmi": "heat hot",
    "jal gaya": "burnt heat",
    "jhulsa": "scorched heat",
    "khad nahi": "fertilizer deficiency",
    "poshan ki kami": "nutrient deficiency",
}

VOICE_RULES: Mapping[str, Mapping[str, Sequence[str]]] = {
    "drought": {
        "strong": ("drought", "wilting", "dry soil", "leaf curling", "dry"),
        "weak": ("drooping", "thirsty", "shriveled", "water deficit", "curling"),
    },
    "waterlogging": {
        "strong": ("waterlogging", "standing water", "root rot", "flooded"),
        "weak": ("wet soil", "soggy", "bad smell", "soft stem", "overwatered"),
    },
    "nutrient": {
        "strong": (
            "nutrient deficiency",
            "yellow leaves",
            "yellowing",
            "pale leaves",
        ),
        "weak": ("yellow", "pale", "slow growth", "poor flowering", "purpling"),
    },
    "pest": {
        "strong": ("pests", "insects", "holes in leaves", "chewed leaves"),
        "weak": ("holes", "sticky residue", "eggs", "eaten leaves", "worms"),
    },
    "fungal": {
        "strong": ("leaf spots", "black spots", "white powder", "mold growth"),
        "weak": ("spots", "blotches", "fungal", "mildew", "disease"),
    },
    "heat": {
        "strong": ("heat stress", "scorched leaves", "sunburn", "tip burn"),
        "weak": ("heat", "hot", "burnt", "flower drop", "dry panicle"),
    },
}


class VoiceSymptomExtractor:
    """Returns app symptom keys from messy text transcripts."""

    def __init__(
        self,
        rules_path: str | Path = RULES_PATH,
        model_name: str = GEMINI_TEXT_MODEL,
    ) -> None:
        self.rules_path = Path(rules_path)
        self.model_name = model_name
        self._rules = self._load_rules()

    def extract(self, text: str) -> List[str]:
        cleaned = self._normalize_text(text)
        if not cleaned:
            return []

        llm_result = self._extract_with_gemini(cleaned)
        if llm_result:
            return llm_result

        return self._extract_with_rules(cleaned)

    def _extract_with_gemini(self, cleaned: str) -> List[str]:
        api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        if requests is None or not api_key:
            return []

        prompt = (
            "You classify farmer speech into crop symptom keys. "
            "Return JSON only with this schema: "
            '{"symptoms":["drought","waterlogging","nutrient","pest","fungal","heat"]}. '
            "Use only keys that are directly supported by the text. "
            "Farmer speech may be Hindi, Hinglish, broken English, or fragments. "
            "Multiple symptoms are allowed. "
            f'Text: "{cleaned}"'
        )

        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "text": prompt,
                        }
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 120,
            },
        }

        try:
            response = requests.post(
                GEMINI_GENERATE_URL.format(model=self.model_name, api_key=api_key),
                json=payload,
                timeout=15,
            )
            response.raise_for_status()
            payload = response.json()
        except Exception:
            return []

        response_text = self._response_text(payload)
        if not response_text:
            return []

        return self._parse_symptom_json(response_text)

    def _extract_with_rules(self, cleaned: str) -> List[str]:
        expanded = self._expand_hinglish(cleaned)
        compact = normalize_key(expanded)
        matches: List[str] = []

        for symptom_key, config in self._rules.items():
            strong_hits = sum(
                1 for term in config.get("strong", ()) if self._contains_term(expanded, compact, term)
            )
            weak_hits = sum(
                1 for term in config.get("weak", ()) if self._contains_term(expanded, compact, term)
            )
            if strong_hits >= 1 or weak_hits >= 2:
                matches.append(symptom_key)

        return matches

    def _load_rules(self) -> Dict[str, Dict[str, List[str]]]:
        with self.rules_path.open("r", encoding="utf-8") as file:
            raw_rules = json.load(file)

        merged_rules: Dict[str, Dict[str, List[str]]] = {}
        for symptom_key, base_config in VOICE_RULES.items():
            trigger_symptoms = raw_rules.get("causes", {}).get(symptom_key, {}).get("trigger_symptoms", [])
            merged_rules[symptom_key] = {
                "strong": list(dict.fromkeys([*base_config["strong"], *trigger_symptoms])),
                "weak": list(dict.fromkeys(base_config["weak"])),
            }
        return merged_rules

    def _normalize_text(self, value: str) -> str:
        return re.sub(r"\s+", " ", re.sub(r"[^\w\s]", " ", value.casefold())).strip()

    def _expand_hinglish(self, text: str) -> str:
        expanded = f" {text} "
        replacements = sorted(
            HINGLISH_REPLACEMENTS.items(),
            key=lambda item: len(item[0]),
            reverse=True,
        )
        for source, target in replacements:
            expanded = expanded.replace(f" {source} ", f" {target} ")
        return re.sub(r"\s+", " ", expanded).strip()

    def _contains_term(self, expanded: str, compact: str, term: str) -> bool:
        normalized_term = self._normalize_text(term)
        if not normalized_term:
            return False

        if " " in normalized_term:
            return normalized_term in expanded

        compact_term = normalize_key(normalized_term)
        if compact_term and compact_term in compact:
            return True

        pattern = re.compile(rf"\b{re.escape(normalized_term)}\b")
        return bool(pattern.search(expanded))

    def _response_text(self, payload: Mapping[str, Any]) -> str:
        texts: List[str] = []
        for candidate in payload.get("candidates", []) or []:
            content = candidate.get("content", {}) or {}
            for part in content.get("parts", []) or []:
                text = str(part.get("text", "")).strip()
                if text:
                    texts.append(text)
        return "\n".join(texts).strip()

    def _parse_symptom_json(self, raw_text: str) -> List[str]:
        match = re.search(r"\{.*\}", raw_text, flags=re.DOTALL)
        candidate = match.group(0) if match else raw_text.strip()
        try:
            payload = json.loads(candidate)
        except json.JSONDecodeError:
            return []

        symptoms = payload.get("symptoms", [])
        if not isinstance(symptoms, list):
            return []

        valid = []
        seen = set()
        for symptom in symptoms:
            key = str(symptom).strip()
            if key in self._rules and key not in seen:
                valid.append(key)
                seen.add(key)
        return valid
