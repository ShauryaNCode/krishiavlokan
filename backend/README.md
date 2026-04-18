<div align="center">

```
██╗  ██╗██████╗ ██╗███████╗██╗  ██╗██╗ █████╗ ██╗   ██╗██╗      ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗
██║ ██╔╝██╔══██╗██║██╔════╝██║  ██║██║██╔══██╗██║   ██║██║     ██╔═══██╗██║ ██╔╝██╔══██╗████╗  ██║
█████╔╝ ██████╔╝██║███████╗███████║██║███████║██║   ██║██║     ██║   ██║█████╔╝ ███████║██╔██╗ ██║
██╔═██╗ ██╔══██╗██║╚════██║██╔══██║██║██╔══██║╚██╗ ██╔╝██║     ██║   ██║██╔═██╗ ██╔══██║██║╚██╗██║
██║  ██╗██║  ██║██║███████║██║  ██║██║██║  ██║ ╚████╔╝ ███████╗╚██████╔╝██║  ██╗██║  ██║██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
```

**KrishiAvlokan Backend**

*FastAPI Service for Diagnosis and Voice APIs*

*Hackathon Build - April 2026*

---

</div>

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Backend Architecture](#2-backend-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Complete File Structure](#4-complete-file-structure)
5. [Quick Start](#5-quick-start)
6. [Environment Setup](#6-environment-setup)
7. [Core API Contract](#7-core-api-contract)
8. [Voice API Contract](#8-voice-api-contract)
9. [Diagnosis Route](#9-diagnosis-route)
10. [Voice Routes](#10-voice-routes)
11. [AI Pipeline Integration](#11-ai-pipeline-integration)
12. [Persistence and History](#12-persistence-and-history)
13. [Runtime Notes](#13-runtime-notes)
14. [Troubleshooting](#14-troubleshooting)
15. [Security and Secrets](#15-security-and-secrets)
16. [Team Ownership](#16-team-ownership)
17. [Demo Day Checklist](#17-demo-day-checklist)

---

## 1. Project Overview

This folder contains the FastAPI backend used by the Flutter client. It exposes diagnosis and voice-processing endpoints, validates incoming data, calls the AI pipeline, and persists diagnosis history locally.

### Backend goals

- Keep request and response contracts stable for the app
- Isolate route logic from AI pipeline logic
- Support both diagnosis and voice flows
- Persist diagnosis events for demo and debugging use

---

## 2. Backend Architecture

```text
Request
  ↓
FastAPI app
  ↓
Route module
  ↓
Schema validation
  ↓
AI service / AI pipeline call
  ↓
Structured JSON response
  ↓
Optional history persistence
```

### Main route groups

- `POST /diagnose`
- `POST /voice/transcribe`
- `POST /voice/extract`
- `GET /health`

---

## 3. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Web framework | FastAPI | API surface |
| Validation | Pydantic | Typed request and response models |
| Local persistence | JSON file storage | Diagnosis history |
| Voice uploads | python-multipart | Multipart form handling |
| AI integration | Internal Python imports | Diagnosis and voice extraction orchestration |
| Optional env loading | python-dotenv | Root `.env` support |

---

## 4. Complete File Structure

```text
backend/
│
├── README.md
├── main.py
├── schemas.py
├── storage.py
├── data/
│   └── history.json
├── routes/
│   ├── diagnosis.py
│   ├── voice.py
│   └── __init__.py
└── services/
    ├── voice_service.py
    └── __init__.py
```

---

## 5. Quick Start

### Install dependencies

```bash
cd backend
pip install fastapi uvicorn pydantic python-multipart requests pandas scikit-learn xgboost google-generativeai python-dotenv
```

### Run server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Verify

```bash
curl http://localhost:8000/health
```

Expected:

```json
{"status":"ok"}
```

---

## 6. Environment Setup

`main.py` loads a root-level `.env` file automatically when present.

### Recommended variables

```env
GEMINI_API_KEY=your_key_here
GEMINI_MODEL_NAME=gemini-2.5-flash
VOICE_TRANSCRIBE_MODEL=gemini-2.5-flash
VOICE_EXTRACT_MODEL=gemini-2.5-flash
```

### Why it matters

- Diagnosis explanations may use Gemini
- Voice transcription uses Gemini inline audio input
- Voice symptom extraction can use Gemini before falling back to rules

---

## 7. Core API Contract

### Endpoint

```text
POST /diagnose
Content-Type: application/json
```

### Request

```json
{
  "crop": "Wheat",
  "state": "Maharashtra",
  "district": "Pune",
  "sowingDate": "2025-07-01",
  "symptoms": ["drought", "heat"],
  "lat": 18.5204,
  "lon": 73.8567
}
```

### Response

```json
{
  "causeKey": "drought",
  "causeTitle": "Drought Stress",
  "confidenceScore": 0.87,
  "explanation": "Short Hinglish explanation",
  "weatherPhases": [],
  "recommendations": [],
  "inputSummary": {},
  "modelDetails": {}
}
```

---

## 8. Voice API Contract

### Transcribe endpoint

```text
POST /voice/transcribe
Content-Type: multipart/form-data
```

### Form fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `audio` | file | yes | Recorded chunk from Flutter |
| `languageCode` | string | no | Forwarded from app language |
| `sessionId` | string | no | Reserved for tracing |

### Transcribe response

```json
{
  "transcript": "patte peele ho rahe hain"
}
```

### Extract endpoint

```text
POST /voice/extract
Content-Type: application/json
```

### Extract request

```json
{
  "text": "patte peele ho rahe hain aur daag bhi hain",
  "sessionId": "171234567890"
}
```

### Extract response

```json
{
  "symptoms": ["nutrient", "fungal"]
}
```

---

## 9. Diagnosis Route

Implemented in:

```text
routes/diagnosis.py
```

### Responsibilities

- Parse `DiagnosisRequest`
- Lazy-load and cache the diagnosis engine
- Call `DiagnosisEngine.diagnose(...)`
- Save request and response payloads via `JSONStorage`
- Return a `DiagnosisResponse`

### Failure handling

- `422` for invalid user payloads
- `500` for unexpected engine failures

---

## 10. Voice Routes

Implemented in:

```text
routes/voice.py
services/voice_service.py
```

### `/voice/transcribe`

- Accepts uploaded audio chunk
- Resolves MIME type
- Calls `VoiceProcessingService.transcribe_audio(...)`
- Returns normalized transcript text

### `/voice/extract`

- Accepts raw transcript text
- Calls `VoiceProcessingService.extract_symptoms(...)`
- Returns symptom keys aligned with frontend/provider keys

### Supported symptom keys

```text
drought
waterlogging
nutrient
pest
fungal
heat
```

---

## 11. AI Pipeline Integration

Backend imports the AI layer directly from the repo root.

### Core integrations

- `ai_pipeline.diagnosis_engine.DiagnosisEngine`
- `ai_pipeline.voice_symptom_extractor.VoiceSymptomExtractor`

### Why this design

- Keeps the backend thin
- Keeps domain logic inside `ai_pipeline/`
- Avoids duplicating diagnosis or symptom extraction rules in route files

---

## 12. Persistence and History

History persistence is handled by:

```text
storage.py
data/history.json
```

### What is stored

- Sequential record ID
- UTC timestamp
- Raw request payload
- Raw response payload

This is intentionally simple and good for hackathon demo visibility.

---

## 13. Runtime Notes

### Important backend behavior

- `main.py` prepends the repo root to `sys.path`
- CORS is currently open to all origins for easier mobile integration
- Voice APIs depend on outbound access to Gemini if those features are enabled
- Diagnosis can fall back when live weather or model inference fails

### Current routes

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/diagnose` | Main diagnosis |
| `POST` | `/voice/transcribe` | Audio to transcript |
| `POST` | `/voice/extract` | Transcript to symptom keys |

---

## 14. Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError` | Missing packages | Install listed dependencies |
| `503` on `/voice/transcribe` | Gemini not configured | Add `GEMINI_API_KEY` to root `.env` |
| `422` on `/diagnose` | Payload invalid | Check date format and required fields |
| Empty transcript | Audio too short or upload issue | Verify app recording and request MIME |
| History not saved | File write or path issue | Confirm `backend/data/history.json` exists and is writable |

---

## 15. Security and Secrets

### Current stance

- This backend is optimized for hackathon integration speed
- Secrets should live in `.env` and never be committed
- Open CORS is acceptable for demo mode but not production

### Secrets to protect

- `GEMINI_API_KEY`
- Any future API tokens or production URLs

---

## 16. Team Ownership

| File / Area | Owner |
|---|---|
| `main.py` | Backend lead |
| `routes/diagnosis.py` | Backend + AI integration |
| `routes/voice.py` | Backend + voice integration |
| `services/voice_service.py` | Backend voice integration |
| `schemas.py` | Backend contract owner |
| `storage.py` | Backend persistence owner |

---

## 17. Demo Day Checklist

- [ ] `uvicorn main:app --reload` starts cleanly
- [ ] `/health` returns `ok`
- [ ] `/diagnose` returns valid JSON for a sample request
- [ ] `/voice/transcribe` works with a real audio chunk
- [ ] `/voice/extract` returns stable symptom keys
- [ ] `.env` is present with Gemini credentials if using voice
- [ ] `history.json` is writable and updating

---

<div align="center">

---

**KrishiAvlokan Backend** - Thin API layer over diagnosis and voice reasoning services.

*FastAPI · Pydantic · JSON Storage · AI Pipeline Integration · April 2026*

</div>
