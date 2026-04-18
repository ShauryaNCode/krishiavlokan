<div align="center">

```
██╗  ██╗██████╗ ██╗███████╗██╗  ██╗██╗ █████╗ ██╗   ██╗██╗      ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗
██║ ██╔╝██╔══██╗██║██╔════╝██║  ██║██║██╔══██╗██║   ██║██║     ██╔═══██╗██║ ██╔╝██╔══██╗████╗  ██║
█████╔╝ ██████╔╝██║███████╗███████║██║███████║██║   ██║██║     ██║   ██║█████╔╝ ███████║██╔██╗ ██║
██╔═██╗ ██╔══██╗██║╚════██║██╔══██║██║██╔══██║╚██╗ ██╔╝██║     ██║   ██║██╔═██╗ ██╔══██║██║╚██╗██║
██║  ██╗██║  ██║██║███████║██║  ██║██║██║  ██║ ╚████╔╝ ███████╗╚██████╔╝██║  ██╗██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

**KrishiAvlokan AI Pipeline**

*Diagnosis Engine and Voice Symptom Reasoning Layer*

*Hackathon Build - April 2026*

---

</div>

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Pipeline Architecture](#2-pipeline-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Complete File Structure](#4-complete-file-structure)
5. [Quick Start](#5-quick-start)
6. [Diagnosis Engine](#6-diagnosis-engine)
7. [Feature Building](#7-feature-building)
8. [Rules and Templates](#8-rules-and-templates)
9. [Model Assets](#9-model-assets)
10. [Voice Symptom Extraction](#10-voice-symptom-extraction)
11. [Backend Integration](#11-backend-integration)
12. [Sample Data and Testing](#12-sample-data-and-testing)
13. [Fallback Logic](#13-fallback-logic)
14. [Troubleshooting](#14-troubleshooting)
15. [Data and Secrets](#15-data-and-secrets)
16. [Team Ownership](#16-team-ownership)
17. [Demo Day Checklist](#17-demo-day-checklist)

---

## 1. Project Overview

This folder contains the diagnosis intelligence used by the backend. It is responsible for converting structured crop inputs and voice-derived transcript text into stable diagnosis outputs and symptom keys.

### AI pipeline goals

- Normalize and validate diagnosis inputs
- Use weather-aware model inference when available
- Fall back gracefully to rule-based scoring
- Convert messy voice text into known symptom keys
- Return backend-safe, UI-friendly outputs

---

## 2. Pipeline Architecture

```text
Structured request
  ↓
feature_builder.py
  ↓
DiagnosisEngine
  ├─ fetch weather
  ├─ build anomaly features
  ├─ run XGBoost path
  ├─ map label to cause
  └─ generate explanation
  ↓
Fallback rules if needed
  ↓
Diagnosis response

Transcript text
  ↓
voice_symptom_extractor.py
  ├─ normalize
  ├─ Hinglish expansion
  ├─ Gemini extraction attempt
  └─ rules fallback
  ↓
symptom keys
```

---

## 3. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Core runtime | Python | Diagnosis orchestration |
| Data shaping | pandas | Model input framing when available |
| Weather fetch | requests | Open-Meteo API access |
| Models | XGBoost pickles, scikit-learn | Prediction and anomaly handling |
| LLM | Gemini API | Explanation and voice extraction/transcription support |
| Rule assets | JSON | Cause rules and text templates |

---

## 4. Complete File Structure

```text
ai_pipeline/
│
├── README.md
├── AI_NOTES.md
├── KrishiAvalokan_Backend_Documentation.md
├── diagnosis_engine.py
├── voice_symptom_extractor.py
├── data/
│   ├── sample_inputs.json
│   ├── sample_requests.json
│   └── sample_responses.json
├── models/
│   ├── crop_encoder.pkl
│   ├── failure_encoder.pkl
│   └── xgb_crop_model.pkl
├── rules/
│   └── diagnosis_rules.json
├── templates/
│   └── explanation_templates.json
└── utils/
    └── feature_builder.py
```

---

## 5. Quick Start

### Run the diagnosis engine demo

```bash
cd ai_pipeline
python diagnosis_engine.py
```

### Direct module usage

```python
from ai_pipeline.diagnosis_engine import DiagnosisEngine

engine = DiagnosisEngine()
result = engine.diagnose(
    crop="Cotton",
    state="Maharashtra",
    district="Pune",
    sowingDate="2025-07-01",
    symptoms=["drought", "heat"],
    lat=18.5204,
    lon=73.8567,
)
```

---

## 6. Diagnosis Engine

Main file:

```text
diagnosis_engine.py
```

### Main responsibilities

- Build normalized feature payloads
- Fetch and process historical weather
- Build anomaly features
- Run the loaded XGBoost model when possible
- Map model output to frontend/backend cause keys
- Generate explanation text
- Return consistent fallback responses when the live path fails

### Main entry points

- `DiagnosisEngine.diagnose(...)`
- `DiagnosisEngine.diagnose_from_payload(...)`

---

## 7. Feature Building

Feature normalization lives in:

```text
utils/feature_builder.py
```

### Responsibilities

- Validate `sowingDate`
- Normalize crop and symptom keys
- Validate coordinates
- Infer season
- Calculate compact symptom score
- Build exact model feature vectors

### Important normalized concepts

- `season`
- `symptomScore`
- `hasCoordinates`
- normalized symptom lists for diagnosis scoring

---

## 8. Rules and Templates

### Files

```text
rules/diagnosis_rules.json
templates/explanation_templates.json
```

### Rules file contains

- Cause metadata
- Trigger symptoms
- Weather ideals by phase
- Season hints
- Recommendations

### Templates file contains

- Fallback explanation patterns used when Gemini explanation generation is unavailable

---

## 9. Model Assets

Stored in:

```text
models/
```

### Current assets

- `xgb_crop_model.pkl`
- `crop_encoder.pkl`
- `failure_encoder.pkl`

### Notes

- The engine can still return a diagnosis when model loading fails
- Missing model assets push execution toward rule fallback instead of crashing

---

## 10. Voice Symptom Extraction

Voice extraction lives in:

```text
voice_symptom_extractor.py
```

### Responsibilities

- Normalize messy transcript text
- Expand Hindi and Hinglish phrases into symptom cues
- Attempt Gemini-based structured extraction
- Fall back to deterministic symptom rules

### Supported output keys

```text
drought
waterlogging
nutrient
pest
fungal
heat
```

### Example

```python
from ai_pipeline.voice_symptom_extractor import VoiceSymptomExtractor

extractor = VoiceSymptomExtractor()
extractor.extract("patte peele hain aur kale daag bhi hain")
# ["nutrient", "fungal"]
```

---

## 11. Backend Integration

The backend imports this folder directly.

### Main usage points

- `backend/routes/diagnosis.py` uses `DiagnosisEngine`
- `backend/services/voice_service.py` uses `VoiceSymptomExtractor`

### Integration principle

- Business intelligence stays here
- Routes remain thin and transport-focused
- Frontend symptom keys must stay aligned with outputs from this folder

---

## 12. Sample Data and Testing

Sample files:

```text
data/sample_inputs.json
data/sample_requests.json
data/sample_responses.json
```

These are useful for:

- sanity checking payload shapes
- validating frontend-backend-AI contracts
- demo rehearsal

---

## 13. Fallback Logic

The diagnosis engine is intentionally resilient.

### Fallback triggers

- Weather fetch failure
- Model load failure
- Model inference failure
- Gemini explanation failure

### Fallback behavior

- Diagnosis still returns a valid `causeKey`
- Explanation is generated from templates or rule summaries
- Backend contract remains stable

This is important for hackathon demos where network conditions may be unstable.

---

## 14. Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Weather fetch fails | No internet or API issue | Engine should fall back, inspect logs |
| Pickle load warning | Missing model files or incompatible environment | Confirm files in `models/` and installed libs |
| Gemini explanation missing | No API key or model error | Add `GEMINI_API_KEY` or rely on templates |
| Voice extraction too weak | Transcript ambiguous | Expand rules or improve transcript quality |
| Import path issues | Running from wrong directory | Run from repo root or ensure root on `sys.path` |

---

## 15. Data and Secrets

### Sensitive inputs

- `GEMINI_API_KEY`
- Any model-selection environment variables

### Project guidance

- Keep secrets in root `.env`
- Do not commit credentials
- Keep sample data synthetic and demo-safe

---

## 16. Team Ownership

| File / Area | Owner |
|---|---|
| `diagnosis_engine.py` | AI lead |
| `utils/feature_builder.py` | AI + backend contract owner |
| `rules/diagnosis_rules.json` | Domain logic owner |
| `templates/explanation_templates.json` | Explanation owner |
| `voice_symptom_extractor.py` | Voice intelligence owner |
| `models/*.pkl` | Model asset owner |

---

## 17. Demo Day Checklist

- [ ] `DiagnosisEngine` runs from a local script
- [ ] Model files exist and load
- [ ] At least one fallback response has been tested
- [ ] Voice extractor returns valid symptom keys for Hinglish samples
- [ ] Gemini-backed paths are tested if `.env` is available
- [ ] Sample data matches current backend contract

---

<div align="center">

---

**KrishiAvlokan AI Pipeline** - The diagnosis brain and voice symptom reasoning layer behind the app.

*Python · Weather Reasoning · XGBoost Assets · Voice Extraction · April 2026*

</div>
