from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import joblib

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change this to specific domains in production (e.g., ["http://localhost:3000"])
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)
from pydantic import BaseModel
import joblib
import pandas as pd

# Load the scaler and the model separately
model = joblib.load("extubation_failure_classifier.joblib")
scaler = joblib.load("extubation_failure_scaler.joblib")

class PredictionInput(BaseModel):
    demo_age: float
    demo_icu_los_min: float
    score_rass: float
    vital_heart_rate: float
    vital_bp_mean: float
    vent_total_duration: float
    vent_resp_rate_spont: float
    vent_minute_volume: float
    vent_p_mean: float
    vent_spont_duration: float
    vent_mandatory_duration: float
    labs_plt: float
    labs_glucose: float
    labs_ptt: float
    labs_bun: float
    med_norepinephrine_dose: float
    clin_flbalance: float
    demo_bmi: float
    clin_fl_input_per_d: float
    clin_fl_output_per_d: float
    vital_pulse_press: float

@app.post("/predict")
async def predict(input_data: PredictionInput):
    # Convert input data to a DataFrame with feature names
    features = pd.DataFrame([[ 
        input_data.demo_age,
        input_data.demo_icu_los_min,
        input_data.score_rass,
        input_data.vital_heart_rate,
        input_data.vital_bp_mean,
        input_data.vent_total_duration,
        input_data.vent_resp_rate_spont,
        input_data.vent_minute_volume,
        input_data.vent_p_mean,
        input_data.vent_spont_duration,
        input_data.vent_mandatory_duration,
        input_data.labs_plt,
        input_data.labs_glucose,
        input_data.labs_ptt,
        input_data.labs_bun,
        input_data.med_norepinephrine_dose,
        input_data.clin_flbalance,
        input_data.demo_bmi,
        input_data.clin_fl_input_per_d,
        input_data.clin_fl_output_per_d,
        input_data.vital_pulse_press
    ]], columns=[
        'demo_age', 'demo_icu_los_min', 'score_rass', 'vital_heart_rate', 'vital_bp_mean', 
        'vent_total_duration', 'vent_resp_rate_spont', 'vent_minute_volume', 'vent_p_mean', 
        'vent_spont_duration', 'vent_mandatory_duration', 'labs_plt', 'labs_glucose', 'labs_ptt', 
        'labs_bun', 'med_norepinephrine_dose', 'clin_flbalance', 'demo_bmi', 
        'clin_fl_input_per_d', 'clin_fl_output_per_d', 'vital_pulse_press'
    ])

    # Scale the input features
    scaled_features = scaler.transform(features)

    # Iterate over features and print feature name and its scaled value
    feature_names = features.columns
    scaled_feature_values = scaled_features[0]  # Since it's a single sample

    feature_value_pairs = {feature_names[i]: scaled_feature_values[i] for i in range(len(feature_names))}
    print("Scaled features with names:")
    for name, value in feature_value_pairs.items():
        print(f"{name}: {value}")

    # Predict class and probabilities
    prediction = model.predict(scaled_features)
    prediction_proba = model.predict_proba(scaled_features)

    # Return the predicted class and probabilities
    return {
        "predicted_class": int(prediction[0]),  # binary classification
        "probabilities": prediction_proba[0].tolist(),  # Convert numpy array to list
        "scaled_features": feature_value_pairs  # Added for debug info in the response
    }
