from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from app.model import predict
from app.db import insert_log, get_all_logs
import uvicorn

app = FastAPI()

class WaterData(BaseModel):
    pH: float | str
    TDS: float | str
    Turbidity: float | str
    Temperature: float | str
    Dissolved_Oxygen: float | str

@app.post("/predict")
def predict_water(req: Request):
    try:
        input_dict = await req.json()
        result = predict(input_dict)
        return {
            "timestamp": datetime.now().isoformat(),
            "inputs": input_dict,
            "result": result
        }
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})

@app.get("/logs/download")
def download_logs():
    return get_all_logs()

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000)
