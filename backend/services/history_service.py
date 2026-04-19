from firebase_config import db
from datetime import datetime


def save_history(user_id, payload):
    payload["created_at"] = datetime.utcnow()

    db.collection("users") \
      .document(user_id) \
      .collection("history") \
      .add(payload)


def get_history(user_id):
    docs = db.collection("users") \
        .document(user_id) \
        .collection("history") \
        .stream()

    result = []

    for doc in docs:
        item = doc.to_dict()
        item["id"] = doc.id
        result.append(item)

    return result