"""Simple JSON-backed diagnosis history storage."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from typing import Any, Dict, List, Mapping


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_HISTORY_PATH = PROJECT_ROOT / "backend" / "data" / "history.json"


class JSONStorage:
    """Persist diagnosis history to a local JSON file."""

    def __init__(self, path: str | Path = DEFAULT_HISTORY_PATH) -> None:
        self.path = Path(path)
        self._lock = Lock()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.path.write_text("[]\n", encoding="utf-8")

    def save_diagnosis(
        self,
        request_payload: Mapping[str, Any],
        response_payload: Mapping[str, Any],
    ) -> Dict[str, Any]:
        """Append a diagnosis event and return the stored record."""

        with self._lock:
            history = self.get_history()
            record = {
                "id": len(history) + 1,
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "request": dict(request_payload),
                "response": dict(response_payload),
            }
            history.append(record)
            self.path.write_text(
                json.dumps(history, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            return record

    def get_history(self) -> List[Dict[str, Any]]:
        """Return all saved diagnosis records."""

        if not self.path.exists():
            return []
        try:
            data = json.loads(self.path.read_text(encoding="utf-8") or "[]")
        except json.JSONDecodeError:
            return []
        return data if isinstance(data, list) else []
