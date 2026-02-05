# MagTapp

**MagTapp** – AI-Powered In-App Browser & Document Summarizer

MagTapp is a cross-platform Flutter app that combines a modern in-app browser with AI-powered summarization and translation features. Users can browse webpages, download and manage documents, summarize content, translate text, and access everything offline.

---

## Table of Contents

- [Key Features](#key-features)  
- [Architecture](#architecture)  
- [Setup & Installation](#setup--installation)  
- [Dependencies](#dependencies)  
- [Usage](#usage)  
- [Known Limitations](#known-limitations)  
- [Future Improvements](#future-improvements)  
- [Contributing](#contributing)  

---

## Key Features

### 1. In-App Browser
- Open and navigate any public URL  
- Multiple tabs (minimum 3)  
- Back, forward, refresh navigation  
- Page loading indicators & error handling  
- **Download Document** button for supported files (`.pdf`, `.docx`, `.pptx`, `.xlsx`)  

### 2. File Manager & Local Storage
- View and open downloaded files  
- Pick files from local storage  
- Metadata management (name, type, date, size)  
- Local history list of opened/summarized documents  
- Offline access via Hive/SQLite  

### 3. AI Summary & Translation
- Extract readable text from web pages and local documents  
- Generate AI summaries (mock/Open-source API)  
- Collapsible summary panel with:
  - Word count reduction
  - Copy, download, share options  
- AI translation support:
  - English → Hindi, Spanish, French
  - Toggleable view beside summary  

### 4. Tab & State Management
- Open, close, and switch tabs dynamically  
- Session preservation using local cache  
- Scalable state management via Riverpod  
- Caching of summaries to avoid repeated API calls  

### 5. Offline Mode
- Cached pages and summaries accessible offline  
- Previously saved summaries available without internet  

#### Optional Enhancements
- Text-to-Speech for summaries  
- Speech-to-Text URL input  
- Dark/Light mode toggle  
- Lottie animations for loading states  
- Installable PWA (Web version)  
- AI Quick Insight Panel (detects language/sentiment)  

---

## Architecture

**Clean Architecture Approach:**

lib/
├─ domain/ # Entities & business logic
├─ data/ # Repositories, API, storage
├─ presentation/ # UI: Widgets, Screens
└─ core/ # Utilities, constants, providers


**Key Technologies:**
- **State Management:** Riverpod – scalable, reactive, testable  
- **Local Storage:** Hive – offline caching, metadata, summaries  
- **Browser Integration:** flutter_inappwebview  
- **File Handling:** file_picker + path_provider  
- **AI Integration:** Mock/Open-source API for summarization & translation  

---

## Setup & Installation

### Prerequisites
- Flutter 3.x (Stable)  
- Dart 3.x  
- Android/iOS emulator or device  
- Web browser for PWA  

### Clone & Run
```bash
git clone https://github.com/<username>/magtapp.git
cd magtapp
flutter pub get
flutter run


Build for Web
flutter build web

Build for Android
flutter build apk --release
