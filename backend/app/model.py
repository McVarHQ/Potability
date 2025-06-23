import joblib
import os
import pandas as pd

MODEL_PATH = "model/xgb_baseline_model.pkl"
SCALER_PATH = "model/xgb_baseline_scaler.save"

def predict(input_dict):
    model = joblib.load(MODEL_PATH)
    try:
        scaler = joblib.load(SCALER_PATH)
    except:
        scaler = None

    df = pd.DataFrame([input_dict])
    if scaler:
        df = scaler.transform(df)
    result = model.predict(df)[0]
    return "Potable" if result == 1 else "Not Potable"
