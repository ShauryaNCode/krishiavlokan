# KrishiAvalokan: Full-Fledged AI Backend Documentation

## 1. Project Overview

KrishiAvalokan is an AI-driven agritech solution designed to diagnose
crop failures by analyzing the intersection of Farmer Symptoms,
Historical Weather Anomalies, and Crop Science.

The system uses a hybrid approach: - XGBoost Classifier (Primary) -
Rule-Based Engine (Fallback)

------------------------------------------------------------------------

## 2. Completed Architecture

### ai_pipeline/ (Brain)

-   diagnosis_engine.py → Core orchestration
-   models/ → Trained models (XGBoost, encoders)
-   rules/ → Rule-based logic
-   templates/ → Hinglish explanation templates

### backend/ (Body)

-   main.py → FastAPI entry point
-   routes/ → API endpoints (/diagnose, /health, /history)
-   schemas.py → Request/Response validation
-   storage.py → Local JSON history storage

------------------------------------------------------------------------

## 3. Full-Fledged AI Logic

### Step 1: Weather Retrieval

-   Fetch 120 days of historical weather
-   Source: Open-Meteo API

### Step 2: Anomaly Detection

-   Model: Isolation Forest
-   Stages:
    -   Early
    -   Mid
    -   Late

### Step 3: ML Classification

-   Model: XGBoost
-   Outputs:
    -   drought
    -   waterlogging
    -   pest_disease
    -   heat_stress
    -   normal

### Step 4: AI Explanation

-   Model: Gemini 1.5 Flash
-   Output: 2-line Hinglish explanation

------------------------------------------------------------------------

## 4. API Documentation

### POST /diagnose

#### Request Body:

{ "crop": "Cotton", "state": "Maharashtra", "district": "Pune",
"sowingDate": "2025-07-15", "symptoms": \["wilting", "drysoil",
"leafcurling"\], "lat": 18.5204, "lon": 73.8567, "isOffline": false }

#### Response Fields:

-   causeKey
-   explanation
-   weatherPhases
-   modelDetails

------------------------------------------------------------------------

### GET /history

-   Returns past diagnoses

------------------------------------------------------------------------

## 5. Frontend Integration Guide

### Run Backend

python -m uvicorn backend.main:app --host 0.0.0.0 --port 8001

### Base URL (Flutter)

http://192.168.X.X:8001

### Note:

-   GPS required
-   If no coordinates → fallback mode

------------------------------------------------------------------------

## 6. Current Status

  Component        Status       Technology
  ---------------- ------------ ------------------
  Data Science     Completed    XGBoost
  Weather Engine   Completed    Open-Meteo
  Logic Scorer     Completed    Isolation Forest
  Backend API      Completed    FastAPI
  LLM Layer        Integrated   Gemini 1.5 Flash
