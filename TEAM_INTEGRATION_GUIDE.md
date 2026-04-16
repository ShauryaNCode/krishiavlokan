# TEAM INTEGRATION GUIDE

KrishiAvalokan — Hackathon Build

---

## 1. Purpose

This document defines how the **Frontend, Backend, and AI Pipeline teams integrate and collaborate**.

The goal is to ensure:

* No breaking changes
* Consistent data flow
* Fast debugging
* Stable demo-ready system

---

## 2. Team Roles

| Role            | Responsibility                                         |
| --------------- | ------------------------------------------------------ |
| Frontend (Lead) | UI, navigation, API integration                        |
| Backend         | API endpoints, request validation, response formatting |
| AI Pipeline     | Diagnosis logic, inference, explanation generation     |

---

## 3. Repository Structure (STRICT)

```id="repo_structure"
krishiavalokan/
│
├── krishiavlokan_app/   ← Frontend ONLY
├── backend/             ← Backend ONLY
├── ai_pipeline/         ← AI ONLY
```

### Rules

* Do not modify another team's folder
* Do not move files across folders
* Shared contract must not be changed without agreement

---

## 4. API Contract (SOURCE OF TRUTH)

All teams must follow this exactly.

### Endpoint

```id="endpoint"
/diagnose
```

### Request

```json id="request"
{
  "crop": "Wheat",
  "state": "Maharashtra",
  "district": "Pune",
  "sowingDate": "2024-06-15",
  "symptoms": ["drought"],
  "isOffline": false
}
```

### Response

```json id="response"
{
  "crop": "Wheat",
  "state": "Maharashtra",
  "district": "Pune",
  "sowingDate": "2024-06-15",
  "symptoms": ["drought"],
  "causeKey": "drought",
  "causeTitle": "Drought Stress",
  "explanation": "Explanation text",
  "weatherPhases": [
    {"label": "Early", "status": "low"}
  ],
  "recommendations": [
    {"title": "Advice", "detail": "Details"}
  ],
  "isLimitedAnalysis": false
}
```

---

## 5. Integration Flow

```id="flow"
Frontend → Backend → AI Pipeline → Backend → Frontend
```

---

## 6. Frontend Integration Rules

### File to modify

```
lib/services/diagnosis_service.dart
```

### Steps

1. Replace mock logic with API call
2. Send request in exact format
3. Parse response into `AnalysisModel`

### Do NOT:

* Change field names
* Change response structure
* Add extra fields

---

## 7. Backend Integration Rules

### Responsibilities

* Accept request
* Validate input
* Call AI pipeline
* Return formatted response

### Required Files

```
backend/
  main.py
  routes/diagnosis.py
  schemas.py
```

### Flow

```id="backend_flow"
Receive Request
→ Validate (Pydantic)
→ Call AI pipeline
→ Format response
→ Return JSON
```

### Important

* Do not add or remove fields
* Do not rename keys
* Keep response identical to contract

---

## 8. AI Pipeline Integration Rules

### Responsibilities

* Implement diagnosis logic
* Generate cause
* Generate explanation
* Generate recommendations

### Entry Point

```
diagnosis_engine.py
```

### Function Signature

```python id="ai_func"
def analyze(data: dict) -> dict:
```

### Expected Output

Must return:

```python id="ai_output"
{
  "causeKey": "...",
  "causeTitle": "...",
  "explanation": "...",
  "weatherPhases": [...],
  "recommendations": [...],
  "isLimitedAnalysis": False
}
```

---

## 9. Data Standards (STRICT)

### Symptoms

```id="symptoms"
drought
waterlogging
pest
fungal
heat
nutrient
```

### Weather Status

```id="weather"
veryLow
low
normal
high
veryHigh
```

---

## 10. Development Workflow

### Branches

| Branch   | Owner    |
| -------- | -------- |
| frontend | Frontend |
| backend  | Backend  |
| ai       | AI       |

### Rules

* No direct push to main
* Use pull requests
* Test before merging

---

## 11. Integration Timeline

### Phase 1

* Frontend runs on mock
* Backend returns dummy response
* AI builds logic

### Phase 2

* Backend connects to AI
* Frontend connects to backend

### Phase 3

* Full system testing
* Bug fixing
* Demo preparation

---

## 12. Testing Checklist

### Must Work

* Full diagnosis flow
* Results always display
* No crashes
* History saves correctly
* Offline mode works

---

## 13. Debugging Strategy

### If issue occurs:

| Problem     | Check           |
| ----------- | --------------- |
| No response | Backend running |
| Wrong data  | API contract    |
| Crash       | Null values     |
| UI broken   | Model mismatch  |

---

## 14. Golden Rules

1. API contract is final
2. Do not rename fields
3. Keep responses consistent
4. Mock first, optimize later
5. Stability over complexity

---

## 15. Final Goal

A fully working system where:

```id="final_flow"
User Input → Diagnosis → Result → History
```

runs smoothly without errors.

---

KrishiAvalokan Integration Guide
Hackathon Build
