# Smart Resume Analyzer

A cross-platform Flutter application that automatically analyzes and scores PDF resumes, providing tailored feedback and suggestions to help users improve their resumes.

---

## 🚀 Features

- **PDF Upload & Parsing**  
  - Select a PDF resume using a native file picker  
  - Robust text extraction via Syncfusion PDF  
  - Automatic detection and markup of section headers

- **Section Detection & Scoring**  
  - Splits parsed text into logical sections (Contact, Summary, Experience, etc.)  
  - Fuzzy header matching + content-based heuristics for missing sections  
  - Configurable scoring rules with major-specific skill sets  
  - Granular feedback and partial-credit scoring

- **Interactive UI**  
  - Stepper-driven upload/analyze flow  
  - Animated scanning effect during processing  
  - Attractive cards showing per-section scores, progress bars, and chips for matched skills  
  - Staggered reveal animations for results  

- **Extensible & Maintainable**  
  - Clean separation of models, services, utilities, providers, and widgets  
  - Centralized `ScoringRules` for easy tuning  
  - Automatic major detection from resume text  

---

## 📦 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (≥ 3.0)  
- Android Studio, Xcode, or VS Code with Flutter extensions  
- (Optional) A free Syncfusion Flutter PDF license

### Installation

1. **Clone the repository**  
   ```bash
   git clone https://github.com/your-org/smart-resume-analyzer.git
   cd smart-resume-analyzer
   flutter pub get
   flutter run


