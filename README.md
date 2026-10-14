# PhishWatch 🛡️
### Malay-Language Phishing Message Detection for Telegram

PhishWatch is an Android mobile application developed to identify potentially malicious phishing messages written in Malay within Telegram. It integrates machine learning-based text classification with mobile notification monitoring to help users recognize suspicious messages more efficiently.

The application uses **TF-IDF feature extraction and a Random Forest classifier** to analyze message text and estimate whether a message is phishing-related. A Flutter frontend communicates with a Flask API to obtain predictions, while Firebase Firestore is used to store detected-threat records.

![PhishWatch UI](<Project images/PhishWatch UI.png>)

## Features

- **Malay-Language Phishing Detection** — Classifies message text as phishing or legitimate using a trained machine learning model.
- **Telegram Notification Monitoring** — Uses Android's Notification Listener functionality to analyze supported incoming notifications.
- **Machine Learning Inference** — Integrates TF-IDF text features with a Random Forest classification model.
- **Confidence-Based Results** — Returns prediction results and class probability estimates to support the application's detection workflow.
- **Detection History** — Records detected-threat information, including message text, source, confidence and timestamp, in Firebase Firestore.
- **Mobile Interface** — Provides a Flutter-based interface for presenting detection results and threat information.

## System Architecture

PhishWatch consists of three main components:

1. **Flutter Mobile Application** — Handles the user interface, application state, notification monitoring and presentation of detection results.
2. **Flask REST API** — Receives message text, applies the required preprocessing and feature transformation, and runs model inference.
3. **Machine Learning Model** — Uses TF-IDF features and a trained Random Forest classifier to classify messages.

### Detection Workflow

1. The application receives message text through the supported input or notification-monitoring workflow.
2. The Flutter application sends the message to the Flask prediction API.
3. The backend preprocesses the message and transforms it into TF-IDF features using the fitted vectorizer.
4. The Random Forest model generates a classification and associated probability estimates.
5. The API returns the prediction to the mobile application.
6. The application presents the result and records detection information in Firestore where applicable.

## Technology Stack

| Component | Technologies |
|---|---|
| Mobile application | Flutter, Dart |
| Application architecture | MVVM |
| Machine learning | Python, scikit-learn, TF-IDF, Bigram, Trigram, Random Forest |
| Backend API | Flask, REST API |
| Database | Firebase Firestore |
| Mobile integration | Android Notification Listener |
| Development and testing | Git, Postman |

## Machine Learning Approach

PhishWatch uses machine learning to classify Malay-language messages as potentially phishing-related or legitimate. The classification pipeline uses text preprocessing, TF-IDF feature extraction and a Random Forest classifier.

### Model Experiments

Three model configurations were investigated to evaluate the effect of text feature representation on classification performance:

| Experiment | Description |
|---|---|
| TF-IDF + Random Forest | Uses TF-IDF representations of message text with a Random Forest classifier. |
| Bigram + Random Forest | Evaluates two-word sequences to capture contextual patterns in messages. |
| Trigram + Random Forest | Evaluates three-word sequences to capture longer textual patterns. |

### Model Comparison

The models were compared using classification evaluation metrics to assess their performance in detecting phishing messages.

![Model Evaluation](<Project images/Model Evaluation.png>)

The comparison chart presents the experimental results and supports the selection of the model configuration used in the PhishWatch application.

### Selected Model

The selected TF-IDF + Random Forest model is integrated into the Flask REST API. The API receives message text, applies the corresponding preprocessing and feature transformation, and returns a classification result with probability estimates to the Flutter application.

The trained model and its fitted preprocessing components must remain compatible with the inference pipeline.

### Evaluation Results

The project reported an accuracy of **97.1%** and a recall of **99.1%** for its reported model evaluation. These figures should be interpreted according to the evaluation setup and should not be assumed to apply to every model configuration or unseen real-world message.

## Repository Structure

The repository separates the mobile application, backend API and machine learning resources.

```text
phishwatch/
├── android/                  # Android platform integration
├── assets/                   # Application assets
├── lib/                      # Flutter application source code
├── backend/                  # Machine learning backend
│   ├── api.py                # Flask API and inference logic
│   ├── MalayPhishingModel.pkl # Trained Random Forest model
│   ├── MalayPhishingModel.py # Model training script
│   └── Model Comparison/     # Model comparison experiments
│       ├── compareModels.py  # Model comparison script
│       ├── MalayPhishingModel_Bigram.pkl # Trained Bigram + Random Forest model
│       └── MalayPhishingModel_Trigram.pkl  # Trained Trigram + Random Forest model
├── Project images/            # Application screenshots and charts
├── pubspec.yaml               # Flutter dependencies and configuration
├── README.md                  # Project documentation
```

## Limitations

- Detection performance depends on the training dataset and the characteristics of incoming messages.
- Messages containing unfamiliar slang, obfuscation or previously unseen phishing techniques may be misclassified.
- Notification monitoring depends on Android notification permissions and the information made available by the source application.
- API-based inference requires the backend to be running and reachable.
- The reported evaluation results do not establish a guarantee of real-world detection performance.

PhishWatch is intended as a supporting cybersecurity tool and should not be treated as a guarantee that every phishing message will be detected.

---

**Disclaimer:** PhishWatch is a student-developed research and software project. Detection results are probabilistic and may contain false positives or false negatives. Users should independently verify suspicious messages and links.
