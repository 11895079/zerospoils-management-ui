# ZeroSpoils Monorepo

Flutter mobile app for household food waste reduction.

## License & Intellectual Property

This repository is the proprietary intellectual property of 11895079 Canada Inc.
No permission is granted to use, copy, modify, publish, distribute, sublicense,
or create derivative works from any part of this repository. 
See [LICENSE](LICENSE) for full terms.

## Folder Structure

```
.
├── planning/          # Backlog, milestones, documentation
│   ├── issues/        # Issue markdown files (numbered 000-590)
│   ├── milestones/    # Issues grouped by M1-M7 delivery phases
│   ├── docs/          # Architecture, design, data model, telemetry
│   ├── scripts/       # Automation: label/milestone creation
│   ├── AGENTS.md      # AI coding agent workflow guide
│   └── requirements.txt
│
├── app/               # Flutter application (main branch + feature branches)
│   ├── lib/           # Dart source code
│   ├── test/          # Unit & widget tests
│   ├── pubspec.yaml   # Flutter dependencies
│   └── ...
│
├── docs/              # Developer guides & walkthroughs
│   ├── flutter-basics.md       # Dart/Flutter fundamentals for beginners
│   ├── code-patterns.md        # Practical patterns & code examples
│   └── gradle-guide.md         # Android build system guide
│
├── ARCHITECTURE.md    # System architecture & design overview
├── PRE-COMMIT.md      # Git hooks & pre-commit checks
└── README.md          # This file
```

## Quick Start

### 1. Clone & Setup
```bash
git clone https://github.com/bakintunde/zerospoils.git
cd zerospoils

# Install Git hooks (format & lint checks)
bash scripts/setup-hooks.sh      # Linux/macOS
# OR
scripts\setup-hooks.bat           # Windows
```

### 2. Understanding the Codebase (New Developers)

**Start here if you're new to Flutter or this codebase:**

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** (12 min read)
   - Overview of clean architecture
   - Key technologies (GoRouter, Riverpod, Hive)
   - How data flows through the app
   - Common patterns explained

2. **[docs/flutter-basics.md](docs/flutter-basics.md)** (8 min read)
   - Dart syntax fundamentals
   - Flutter widget concepts
   - State management basics
   - Hot reload & development tips

3. **[docs/code-patterns.md](docs/code-patterns.md)** (10 min read)
   - Practical patterns with code examples
   - Navigation, state management, UI components
   - Testing patterns
   - Error handling

4. **[docs/gradle-guide.md](docs/gradle-guide.md)** (5 min read)
   - Android build system explanation
   - Common build errors and fixes
   - When you encounter Gradle issues

**Total time: ~35 minutes to fully understand the codebase**

### 3. Planning & Backlog
All backlog grooming, issue definitions, and documentation live in `planning/`. See [planning/README.md](planning/README.md) for:
- Bulk issue creation workflow
- Milestone structure (M1-M7)
- Label/milestone setup scripts

### 4. App Implementation
Implementation happens in `app/` folder. Create feature branches off `main`:
```bash
git checkout -b feature/item-inventory
# ... implement using planning/issues/* as your spec
# ... commit with small, focused PRs
```

**Pre-commit checks:** Format and analyzer checks run automatically before each commit. See [PRE-COMMIT.md](PRE-COMMIT.md) for details.

## Workflow for Implementation

1. **Select Issue** from `planning/milestones/M1/` (or relevant milestone)
2. **Read Issue** – acceptance criteria + test plan are your spec
3. **Create Feature Branch**: `git checkout -b feature/xxx`
4. **Implement in `app/`** – code + tests + telemetry per DoD
5. **Submit PR** linking back to planning issue
6. **Update Issue** status in planning/ when merged

## Project Status & Hours Tracking

**Last Updated:** April 22, 2026

### Cumulative Human Hours Invested
| Phase | Hours | Status | Notes |
|-------|-------|--------|-------|
| Planning & Documentation | ~40h | ✅ Complete | Repo setup, design tokens, data model, telemetry schemas, UX docs |
| M1 Flutter Skeleton | ~20h | ✅ Complete | App compiles, routing, DI, telemetry, CI; all M1 issues closed |
| M2 Core Features | ~50h | ✅ Complete | Hive storage, add item, inventory list, item detail, shopping list, notifications, settings, dark mode, Android signing, backup/restore, export/delete |
| M3 MVP Quality (in progress) | ~68h | 🔄 68% (15/22) | Shopping batch receipt capture and batch-linking flows merged (PR #105 + #106); telemetry, feature flags, reminder prefs, notification scheduling, OCR, packaged-item fast-add, Firebase (Crashlytics+Remote Config+FCM), offline suite, badges foundation |
| **Total** | **~178h** | **M3 in progress** | Full MVP feature set taking shape; beta distribution in progress |

**Next Milestones:** M3/201 (Receipt AR overlay), M3/202 (Fresh produce recognition), M3/350 (Zesto Phase 1), M3/361 (Firebase App Distribution)

## CI/CD Strategy

- **Planning changes**: Lint markdown, validate issue structure
- **App changes**: Run tests on `app/` path only (don't re-test planning docs)
- **Feature branches**: Small PRs implementing one issue at a time
- **Releases**: Tag-triggered builds for Android (APK/AAB) and iOS (IPA) – see [docs/release.md](docs/release.md)

## Creating a Release

**Quick version:**
1. Update version in `app/pubspec.yaml` (e.g., `0.1.0-beta.1+1`)
2. Commit: `git commit -m "chore: Bump version to 0.1.0-beta.1"`
3. Tag: `git tag v0.1.0-beta.1`
4. Push: `git push origin v0.1.0-beta.1`
5. GitHub Actions builds APK, AAB, IPA → uploads artifacts + creates draft release

**Full guide:** See [docs/release.md](docs/release.md) for versioning strategy, code signing setup, and troubleshooting.
## Android Release Signing & Data Backup

### Release Signing Configuration

To build release APKs that can update without requiring uninstall (preserving user data):

1. **Generate keystore** (one-time setup):
   ```bash
   keytool -genkey -v -keystore ~/zerospoils-release-key.jks \
     -alias zerospoils -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Configure signing**:
   ```bash
   cd app/android
   cp key.properties.template key.properties
   # Edit key.properties with your keystore credentials
   ```

3. **Build release APK**:
   ```bash
   cd app
   flutter build apk --release
   ```

**See:** [docs/ANDROID_SIGNING_GUIDE.md](docs/ANDROID_SIGNING_GUIDE.md) for complete setup guide

### Data Backup (For Testing)

If you need to preserve data when updating between differently-signed builds:

- **Quick reference**: [docs/APK_UPDATE_FIX.md](docs/APK_UPDATE_FIX.md)
- **Manual ADB backup**: [docs/MANUAL_DATA_BACKUP.md](docs/MANUAL_DATA_BACKUP.md)
- **Complete walkthrough**: [docs/README_DATA_RESCUE.md](docs/README_DATA_RESCUE.md)

Once on a properly signed build, future updates work smoothly without data loss.


## References
- [planning/AGENTS.md](planning/AGENTS.md) – AI coding agent instructions
- [planning/README.md](planning/README.md) – Backlog details
- [planning/milestones/M1/README.md](planning/milestones/M1/README.md) – First milestone guide
- [CONTRIBUTING.md](CONTRIBUTING.md) – Contribution workflow & PR checklist
- [docs/release.md](docs/release.md) – Release workflow & versioning guide
