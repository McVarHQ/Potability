from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.db import get_db_pool
import json

router = APIRouter()

@router.get("/logs")
async def get_logs():
    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            rows = await conn.fetch("SELECT * FROM logs ORDER BY timestamp DESC LIMIT 50")

        logs = []
        for row in rows:
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
