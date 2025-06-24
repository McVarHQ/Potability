from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from datetime import datetime
from app.model import predict
from app.db import insert_log, get_all_logs, init_db
from pydantic import BaseModel
import asyncio

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    await init_db()

class WaterData(BaseModel):
    pH: float | str
    TDS: float | str
    Turbidity: float | str
    Temperature: float | str
    Dissolved_Oxygen: float | str

@app.post("/predict")
async def predict_water(request: Request):
    try:
        input_dict = await request.json()
        result = predict(input_dict)
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "inputs": input_dict,
            "result": result
        }
        await insert_log(log_entry)
        return log_entry
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})

@app.get("/logs/download")
async def download_logs():
    logs = await get_all_logs()
    return logs
