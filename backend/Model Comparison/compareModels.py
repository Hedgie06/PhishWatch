import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.pipeline import Pipeline

# --- 1. SETUP & DATA LOADING ---
filename = 'Malay_phishing_dataset_cleaned.csv'
try:
    df = pd.read_csv(filename)
    print(f"Loaded dataset '{filename}' successfully.")
except FileNotFoundError:
    print(f"Error: File '{filename}' not found. Please check the path.")
    exit()

# Drop missing and map labels
df = df.dropna(subset=['message', 'label'])
label_mapping = {'phishing': 'phishing', 'safe': 'safe'}
df['label'] = df['label'].map(label_mapping)

# --- 2. PREPROCESSING ---
slang_dict = {
    r"\bx\b": "tak", r"\bnk\b": "nak", r"\byg\b": "yang", r"\butk\b": "untuk",
    r"\bdgn\b": "dengan", r"\borg\b": "orang", r"\bsy\b": "saya", r"\btlg\b": "tolong",
    r"\bkat\b": "dekat", r"\bni\b": "ini", r"\btu\b": "itu", r"\bbleh\b": "boleh",
    r"\bdlm\b": "dalam", r"\bkpd\b": "kepada", r"\bdh\b": "dah", r"\bje\b": "sahaja",
    r"\bjg\b": "juga", r"\bbr\b": "baru", r"\btau\b": "tahu", r"\bskrg\b": "sekarang",
    r"\bwslm\b": "waalaikumussalam", r"\basap\b": "segera"
}

def clean_and_normalize(text):
    text = str(text).replace('url_token', '')
    text = re.sub(r'http\S+|www\.\S+', ' ', text)
    text = text.lower().replace('\n', ' ')
    for slang, formal in slang_dict.items():
        text = re.sub(slang, formal, text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

print("Applying Preprocessing...")
df['message'] = df['message'].apply(clean_and_normalize)

# Split Data
X_train, X_test, y_train, y_test = train_test_split(
    df['message'], df['label'], test_size=0.2, random_state=42
)

# --- 3. DEFINE THE 3 FINAL MODELS ---
models = {
    # MODEL 1: The Winner (Keywords)
    "1. TF-IDF + RF": Pipeline([
        ('tfidf', TfidfVectorizer(max_features=5000)),
        ('clf', RandomForestClassifier(n_estimators=100, random_state=42))
    ]),
    
    # MODEL 2: Short Phrases (Frequency)
    "2. N-gram (1,2) + RF": Pipeline([
        ('vec', CountVectorizer(max_features=5000, ngram_range=(1, 2))),
        ('clf', RandomForestClassifier(n_estimators=100, random_state=42))
    ]),

    # MODEL 3: Long Phrases (Frequency)
    "3. N-gram (1,3) + RF": Pipeline([
        ('vec', CountVectorizer(max_features=5000, ngram_range=(1, 3))),
        ('clf', RandomForestClassifier(n_estimators=100, random_state=42))
    ])
}

# --- 4. TRAINING LOOP ---
results = []
print("\n--- STARTING FINAL COMPARISON ---")

for name, pipeline in models.items():
    print(f"Training {name}...")
    pipeline.fit(X_train, y_train)
    y_pred = pipeline.predict(X_test)
    
    acc = accuracy_score(y_test, y_pred)
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_test, y_pred, average='binary', pos_label='phishing'
    )
    
    results.append({
        "Model": name,
        "Accuracy": acc,
        "Precision": precision,
        "Recall": recall,
        "F1-Score": f1
    })

# --- 5. OUTPUT ---
results_df = pd.DataFrame(results)
print("\n--- FINAL RESULTS TABLE ---")
print(results_df.round(4))

# Plotting
results_melted = results_df.melt(id_vars="Model", var_name="Metric", value_name="Score")
plt.figure(figsize=(10, 6))
sns.set_style("whitegrid")
chart = sns.barplot(data=results_melted, x="Metric", y="Score", hue="Model", palette="viridis")
plt.title("Model Evaluation: (TF-IDF vs Bigram vs Trigram)", fontsize=14, fontweight='bold')
plt.ylim(0.9, 1.0)
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
plt.ylabel("Score (0.0 - 1.0)")
plt.tight_layout()

# Add labels
for container in chart.containers:
    chart.bar_label(container, fmt='%.3f', padding=3, fontsize=9)

plt.show()