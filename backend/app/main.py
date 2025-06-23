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
def predict_water(data: WaterData):
    try:
        input_dict = {
            "pH": float(data.pH),
            "TDS": float(data.TDS),
            "Turbidity": float(data.Turbidity),
            "Temperature": float(data.Temperature),
            "Dissolved Oxygen": float(data.Dissolved_Oxygen)
        }
    except:
        raise HTTPException(status_code=400, detail="Invalid input format. All values must be numeric or strings of numbers.")

    result = predict(input_dict)
    timestamp = datetime.utcnow().isoformat()
    
    log = {
        "timestamp": timestamp,
        "inputs": input_dict,
        "result": result
    }

    insert_log(log)
    return log

@app.get("/logs/download")
def download_logs():
    return get_all_logs()

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000)
