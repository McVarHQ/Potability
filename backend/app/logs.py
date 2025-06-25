from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.db import get_all_logs
import json

router = APIRouter()

@router.get("/logs")
async def get_logs():
    try:
        raw_logs = await get_all_logs()

        logs = []
        for row in raw_logs:
            try:
                inputs = json.loads(row["inputs"]) if isinstance(row["inputs"], str) else row["inputs"]
            except json.JSONDecodeError:
                inputs = {"error": "Invalid input format"}

            logs.append({
                "timestamp": row["timestamp"].isoformat() if row["timestamp"] else None,
                "inputs": inputs,
                "result": row["result"]
            })

        return JSONResponse(content=logs)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
