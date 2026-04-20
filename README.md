# KrishiAvlokan
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![XGBoost](https://img.shields.io/badge/ML-XGBoost-orange?style=for-the-badge)
![MeteoAPI](https://img.shields.io/badge/Weather-Open--Meteo-005BBB?style=for-the-badge&logo=icloud&logoColor=white)
![Geocoding](https://img.shields.io/badge/Geocoding-Nominatim-4A4A4A?style=for-the-badge&logo=openstreetmap&logoColor=white)
![Gemini](https://img.shields.io/badge/LLM-Gemini_API-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Provider](https://img.shields.io/badge/State-Provider-purple?style=for-the-badge)
![go_router](https://img.shields.io/badge/Routing-go__router-blue?style=for-the-badge)

> AI-powered crop diagnosis for field-level farmers — real-time, voice-first, weather-aware

<img width="1200" height="700" alt="KrishsiAvlokanMain" src="https://github.com/user-attachments/assets/c19a3bf6-60e5-4de8-8fa5-cc9e88aaeae1" />


## Why This Matters

India has over **140 million farming households**. When a crop starts failing, the average farmer has no fast, reliable way to diagnose the cause in the field. Agronomists are scarce, internet searches are generic, and most AI tools require fluent English and a stable connection.

KrishiAvlokan changes that. A farmer picks a crop, drops a pin, sets a sowing date, and describes symptoms in **Hindi, Hinglish, or English — by voice**. In seconds, the system returns a diagnosis, a plain-language explanation, and actionable recommendations — all informed by live weather data.

---

<img width="1200" height="542" alt="KrishiAvlokanStep" src="https://github.com/user-attachments/assets/22a2c4fc-16b0-4172-a1ef-7de82870a841" />

*Guided 4-step diagnosis flow with voice symptom capture and live-weather-aware AI reasoning*

## What It Does

A farmer opens the app and walks through a guided 4-step flow. Before a diagnosis is returned, KrishiAvlokan:

1. Collects **crop, location, sowing date, and symptoms** through a simple guided UI
2. Optionally captures **voice symptoms** in Hindi/Hinglish via a chunked audio pipeline
3. Sends the structured request to a **FastAPI backend** for validation and routing
4. Runs the case through a **weather-aware AI diagnosis engine** combining live weather, ML models, and rule-based reasoning
5. Returns a **cause, confidence score, plain-language explanation, and recommendations**

The result is displayed immediately — with a diagnosis summary, weather context, and a history entry saved for later.

---

## Key Engineering Highlights

### Hybrid Diagnosis Engine
- **Weather-aware path** — fetches live weather anomalies for the farmer's coordinates; drought, heat, and waterlogging signals feed directly into the model
- **XGBoost + rule-based ensemble** — supervised ML for known symptom patterns, diagnosis rules for edge cases and sparse symptom sets
- **Explanation templates** — structured, localized output from `explanation_templates.json` so responses stay readable at low literacy levels

### Voice Symptom Pipeline
- **Chunked audio recording** via `record` package — audio sent to backend in short segments so no long upload stalls the UX
- **Gemini-backed transcription** (`/voice/transcribe`) handles mixed-language speech, noise, and incomplete sentences
- **Structured extraction** (`/voice/extract`) maps free-form transcripts to canonical symptom keys like `nutrient`, `fungal`, `pest`
- **Incremental symptom injection** — voice-detected symptoms merge into the existing Step 4 selection without overwriting manual choices

### Guided UX for Non-Technical Users
- 4-step flow with large tap targets, designed for one-handed field use
- Voice state surfaced via status bars and badges — no extra navigation required
- Offline-friendly patterns: settings and history persisted locally
- Hinglish diagnosis explanations as the default output format

---

## Example: What Happens on a Drought Symptom Report

> Farmer selects Wheat in Pune, sowing date 1 July, and says "patte peele hain, sukh rahe hain"

- Voice pipeline transcribes and extracts: `drought`, `heat`
- Live weather confirms below-average rainfall anomaly for Pune coordinates
- `amount_log` feature + `is_heat_stress` flag + weather signal compound
- **Diagnosis output: Drought Stress — confidence 0.87**
- Explanation generated in Hinglish with water management recommendations

---

## Architecture

```
Flutter App
    │
    ├── Guided 4-step symptom collection
    ├── Optional voice capture (chunked audio)
    ├── Voice API calls → /voice/transcribe → /voice/extract
    ├── Symptom keys merged into DiagnosisProvider
    │
    └──▶  POST /diagnose
                │
                ├── Pydantic schema validation
                ├── Feature builder (location + sowing + symptoms + weather)
                ├── XGBoost inference + rule overlay
                ├── Explanation template rendering
                └── Diagnosis stored in history.json
                │
                └──▶  { causeKey, causeTitle, confidenceScore, explanation, recommendations }
                            │
                            └── Flutter displays results screen
                                History entry saved
                                Next diagnosis ready
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter 3.x + Provider |
| Routing | go_router |
| Voice UX | speech_to_text, flutter_tts, record |
| HTTP | http |
| Backend API | FastAPI + Uvicorn |
| Validation | Pydantic |
| AI Engine | Python (custom diagnosis engine) |
| Weather + ML | requests, pandas, scikit-learn, XGBoost |
| LLM Integration | Gemini API (voice transcription + extraction) |

---

## Screens

| Screen | Purpose |
|---|---|
| Splash | App bootstrap and first-run transition |
| Language | Regional language selection |
| Home | Entry point into diagnosis flow |
| Step 1 — Crop | Crop selection |
| Step 2 — Location | State, district, GPS coordinates |
| Step 3 — Sowing Date | Date input |
| Step 4 — Symptoms | Manual selection + voice input |
| Loading | Wait state during diagnosis |
| Results | Diagnosis explanation and recommendations |
| History | Past diagnosis records |
| Settings | Language, voice, and app preferences |

---

## Quick Start

### Frontend (Flutter)

```bash
cd krishiavlokan_app
flutter pub get
flutter run
```

Update the backend URL in `lib/core/constants/app_constants.dart` to point to your machine.

### Backend (FastAPI)

```bash
cd backend
pip install fastapi uvicorn pydantic python-multipart requests pandas scikit-learn xgboost google-generativeai python-dotenv
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Health check:
```bash
curl http://localhost:8000/health
```

> Full setup details, API contract, voice pipeline docs, and demo scenarios are in [`DEVELOPER_GUIDE.md`](./DEVELOPER_GUIDE.md)

---

## What We Would Build Next

- **Offline diagnosis fallback** — on-device rule engine for no-connectivity field conditions
- **Regional language expansion** — Tamil, Telugu, and Marathi voice and output support
- **Image-based diagnosis** — photo of affected crop as an additional symptom input
- **Push alerts** — proactive weather-risk warnings before symptoms appear
- **Crowdsourced symptom database** — anonymized farmer reports to improve diagnosis accuracy over time
- **SMS fallback** — for feature phones with no data connection

---

## 👥 Team

Built during Build With AI Hackathon — April 2026
(Google Developers Group (GDG) Goa x PCCE)

| Contributor | Role | Responsibilities |
|-------------|------|-----------------|
| **[Shaurya Naik](https://github.com/ShauryaNCode)** | Flutter + UX + Voice Service | Mobile app, guided flow, voice UX, Provider state, voice service, history and settings |
| **[Siddhant Kerkar](https://github.com/Siddhantdev404)** | Diagnosis + Backend | Diagnosis engine, feature builder, rule engine, backend FastAPI, Gemini integration |
| **[Priyam Redkar](https://github.com/priyamredker)** | API + FirebaseDB | Diagnosis Rules, Firebase Data Base, backend orchestration |

---

*KrishiAvlokan is a hackathon prototype built for rapid demonstration and modular iteration.*
