from fastapi import APIRouter
from services.history_service import save_history, get_history

router = APIRouter(prefix="/history", tags=["History"])


@router.post("/{user_id}")
def add_history(user_id: str, payload: dict):
    save_history(user_id, payload)
    return {"message": "Saved successfully"}


@router.get("/{user_id}")
def fetch_history(user_id: str):
    return get_history(user_id)