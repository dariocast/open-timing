# OpenTiming ⏱️

**OpenTiming** è un'applicazione nativa per macOS ispirata a [Timing App](https://timingapp.com/), progettata per essere **100% offline-first**, rispettosa della privacy e a bassissimo consumo energetico.

Traccia automaticamente il tempo trascorso sulle diverse applicazioni, documenti e schede del browser, categorizzando le attività tramite regole intelligenti e visualizzando statistiche e timeline dettagliate.

---

## ✨ Funzionalità dell'MVP

- 🔒 **100% Offline & Privata**: Tutti i dati risiedono esclusivamente in un database SQLite locale (`~/Library/Application Support/OpenTiming/opetiming.sqlite`). Nessuna telemetria, nessun cloud, zero connessioni di rete.
- ⚡ **Background Tracking Intelligente**:
  - Rilevamento in tempo reale dell'app in primo piano (`NSWorkspace`).
  - Ispezione del titolo della finestra attiva e del documento tramite **macOS Accessibility API (`AXUIElement`)**.
  - Estrazione automatica dei domini/URL per i principali browser macOS (**Safari, Google Chrome, Arc, Brave, Microsoft Edge**).
  - Rilevamento automatico dell'inattività (**Idle Detection**) per escludere i momenti di pausa dal calcolo della produttività.
  - Aggregazione e coalescing delle sessioni continue per evitare il bloat del database.
- 📊 **Dashboard & Timeline Interattiva**:
  - **Overview**: Punteggio di produttività, ore totali, tempo produttivo/distraente/neutro, grafici a barre orari per l'intera giornata, top app e categorie.
  - **Timeline 24h**: Ribbon visivo continuo a blocchi colorati per visualizzare la cronologia della giornata con ricerca testuale istantanea e possibilità di riclassificare manualmente ogni evento.
  - **Progetti & Categorie**: Gestione personalizzata di categorie (colori, icone, punteggio produttività da -2 a +2) e progetti (tariffa oraria, categoria associata).
  - **Regole di Categorizzazione**: Motore di regole prioritarie (Regex, Contiene, Equals, Prefisso) su App, Bundle ID, Titolo Finestra o Dominio Web, con supporto per riapplicare le regole a tutto lo storico passato.
- 🗂️ **Export Dati**: Esportazione immediata dell'intero storico o di intervalli in formato **CSV** (per Excel / Numbers / Fogli Google) o **JSON**.
- 🖥️ **Menu Bar Extra**: Contatore live, app corrente in uso, stato tracciamento/pausa/idle e scorciatoia per aprire la Dashboard.

---

## 🏗️ Architettura del Progetto

```
open-timing/
├── Package.swift                     # Definizione SPM (Swift 5.9+, macOS 14.0+)
├── Info.plist                        # Metadati dell'app e descrizioni permessi Apple Events
├── scripts/
│   └── build_app.sh                  # Script per compilare e creare il bundle OpenTiming.app
├── Sources/OpenTiming/
│   ├── OpenTimingApp.swift           # Entry point SwiftUI + MenuBarExtra + WindowGroup
│   ├── Models/
│   │   ├── ActivityRecord.swift      # Modelli evento, statistiche e breakdown
│   │   ├── Category.swift            # Modelli Categorie e Progetti
│   │   └── Rule.swift                # Modello regole di categorizzazione
│   ├── Database/
│   │   └── DatabaseManager.swift     # Motore SQLite (WAL mode, indici, aggregazioni, export)
│   ├── Tracker/
│   │   ├── ActivityTracker.swift     # Engine di tracciamento e gestione sessioni
│   │   ├── WindowInspector.swift     # Accessibility API & estrazione URL/titoli finestra
│   │   └── IdleDetector.swift        # Rilevamento inattività con CGEventSource
│   ├── Rules/
│   │   └── RuleEngine.swift          # Valutazione regole di matching
│   └── Views/
│       ├── AppState.swift            # State management Observable per l'UI
│       ├── MainDashboardView.swift   # Sidebar navigation (Dashboard, Timeline, etc.)
│       ├── DashboardOverviewView.swift# Grafici Swift Charts e metriche
│       ├── TimelineView.swift        # Visual timeline ribbon e log eventi
│       ├── CategoriesProjectsView.swift # Gestione categorie e progetti
│       ├── RulesView.swift           # Gestione regole e riapplicazione storico
│       ├── SettingsView.swift        # Preferenze, idle timeout, permessi ed export
│       ├── MenuBarView.swift         # Popup compatto della Menu Bar
│       └── Helpers.swift             # Helper colori esadecimali, icone e formattazione
└── Tests/OpenTimingTests/
    └── OpenTimingTests.swift         # Test unitari per DB, regole, stats ed export
```

---

## 🚀 Come Eseguire e Compilare

### 1. Esecuzione Rapida da Terminale (Debug)
```bash
swift run OpenTiming
```

### 2. Creazione dell'App Bundle `.app` per macOS (Release)
```bash
./scripts/build_app.sh
open ./build/OpenTiming.app
```

### 3. Esecuzione dei Test Unitari
```bash
swift test
```

---

## 🔑 Permessi macOS Richiesti

Per leggere il titolo delle finestre delle altre applicazioni e gli URL del browser:
1. All'avvio, OpenTiming mostrerà un avviso se il permesso di **Accessibilità** non è ancora attivo.
2. Clicca su **"Grant Access"** o vai in **Impostazioni di Sistema > Privacy e Sicurezza > Accessibilità** e abilita **OpenTiming** (o il Terminale da cui lo stai eseguendo in debug).
