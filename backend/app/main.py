from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from datetime import datetime
from app.model import predict
from app.db import insert_log, init_db
from pydantic import BaseModel
from app.logs import router as logs_router  # ✅ Import router from logs.py

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

# ✅ Include new /logs route (modular)
app.include_router(logs_router)
