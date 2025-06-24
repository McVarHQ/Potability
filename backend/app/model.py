import joblib
import os
import pandas as pd

MODEL_PATH = "model/xgb_baseline_model.pkl"
SCALER_PATH = "model/xgb_baseline_scaler.save"

def predict(input_dict):
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)


    REQUIRED_KEYS = ["ph", "totaldissolvedsolids", "turbidity", "temperature", "dissolvedoxygen"]

    # Normalize casing and get only required keys
    filtered = {}
    for key in REQUIRED_KEYS:
        val = input_dict.get(key)
        if val is None:
            raise ValueError(f"Missing required field: {key}")
        try:
            filtered[key] = float(val)
        except:
            raise ValueError(f"Invalid value for {key}: {val}")

    # Order matters: match model input order
    input_data = pd.DataFrame([[
        filtered["ph"],
        filtered["totaldissolvedsolids"],
        filtered["turbidity"],
        filtered["temperature"],
        filtered["dissolvedoxygen"]
    ]], columns=["pH", "TDS", "Turbidity", "Temperature", "Dissolved Oxygen"])

    df = pd.DataFrame(input_data)
    if scaler:
        df = scaler.transform(df)
    result = model.predict(df)[0]
    return "Potable" if result == 1 else "Not Potable"
