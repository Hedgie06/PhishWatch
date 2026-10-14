import pandas as pd
import joblib
import re
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.pipeline import Pipeline

# 1. Load Data
filename = 'Malay_phishing_dataset_cleaned.csv'
try:
    df = pd.read_csv(filename)
    print(f"✅ Loaded dataset '{filename}' successfully.")
except FileNotFoundError:
    print(f"❌ Error: File '{filename}' not found.")
    exit()

df = df.dropna(subset=['message', 'label'])
label_mapping = {'phishing': 'spam', 'safe': 'ham'}
df['label'] = df['label'].map(label_mapping)

# --- NEW: SLANG NORMALIZATION DICTIONARY ---
# This converts common text-speak into formal Malay
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
    r"\basap\b": "segera" # urgent words often used in scams
}

def clean_and_normalize(text):
    # 1. Remove URLs (Context-Only Strategy)
    text = re.sub(r'http\S+|www\.\S+', ' ', text)
    
    # 2. Lowercase & Basic cleaning
    text = text.lower().replace('\n', ' ')
    
    # 3. Apply Slang Normalization
    for slang, formal in slang_dict.items():
        text = re.sub(slang, formal, text)
        
    # 4. Remove extra spaces
    text = re.sub(r'\s+', ' ', text).strip()
    return text

print("🧹 Applying Slang Normalization & Removing URLs...")
df['message'] = df['message'].apply(clean_and_normalize)

# 2. Create Pipeline
print("\n🔄 Initializing Pipeline...")
pipeline = Pipeline([
    ('tfidf', TfidfVectorizer(max_features=5000)),
    ('clf', RandomForestClassifier(n_estimators=100, random_state=42))
])

# 3. Split & Train
X_train, X_test, y_train, y_test = train_test_split(df['message'], df['label'], test_size=0.2, random_state=42)

print("\n🤖 Training Final Model...")
pipeline.fit(X_train, y_train)

# 4. Evaluate
y_pred = pipeline.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print(f"Accuracy: {accuracy * 100:.2f}%")
print(classification_report(y_test, y_pred))

# 5. Save
output_file = 'MalayPhishingModel.pkl'
joblib.dump(pipeline, output_file)
print(f"✅ Saved final model to '{output_file}'")