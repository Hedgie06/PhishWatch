from flask import Flask, request, jsonify
import joblib
import re

app = Flask(__name__)

# Load the trained model
model = joblib.load("MalayPhishingModel.pkl")

# SLANG DICTIONARY 
slang_dict = {
    r"\bx\b": "tak",
    r"\bnk\b": "nak",
    r"\byg\b": "yang",
    r"\butk\b": "untuk",
    r"\bdgn\b": "dengan",
    r"\borg\b": "orang",
    r"\bsy\b": "saya",
    r"\btlg\b": "tolong",
    r"\bkat\b": "dekat",
    r"\bni\b": "ini",
    r"\btu\b": "itu",
    r"\bbleh\b": "boleh",
    r"\bdlm\b": "dalam",
    r"\bkpd\b": "kepada",
    r"\bdh\b": "dah",
    r"\bje\b": "sahaja",
    r"\bjg\b": "juga",
    r"\bbr\b": "baru",
    r"\btau\b": "tahu",
    r"\bskrg\b": "sekarang",
    r"\bwslm\b": "waalaikumussalam",
    r"\basap\b": "segera"
}

def clean_text(text):
    # 1. REMOVE URLs completely (Context-Only Strategy)
    text = re.sub(r'http\S+|www\.\S+', ' ', text)
    
    # 2. Lowercase & Basic cleaning
    text = text.lower()
    text = text.replace('\n', ' ')
    
    # 3. Apply Slang Normalization 
    # iterate through the dictionary and fix the words
    for slang, formal in slang_dict.items():
        text = re.sub(slang, formal, text)
        
    # 4. Remove extra spaces
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text

@app.route("/")
def home():
    return "✅ Flask phishing detection API is running!"

@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json(force=True)
        raw_message = data.get("message")

        if not raw_message:
            return jsonify({"error": "No message provided"}), 400

        # CLEAN THE MESSAGE BEFORE PREDICTING
        cleaned_message = clean_text(raw_message)
        
        # Now pass the cleaned message to the model
        probs = model.predict_proba([cleaned_message])[0]
        
        spam_prob = probs[1]
        ham_prob = probs[0]

        prediction = "spam" if spam_prob > 0.6 else "ham"

        return jsonify({
            "prediction": prediction,
            "spam_probability": float(spam_prob),
            "ham_probability": float(ham_prob)
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)