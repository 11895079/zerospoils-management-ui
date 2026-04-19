# Executive Briefings

Periodic data-driven executive reports documenting development effort, impact, and progress on ZeroSpoils.

## Quick Start

### Generate Reports

**Cumulative Report (All Work to Date)**
```powershell
python scripts/generate_executive_report.py --pdf
```

**Date-Range Report**
```powershell
python scripts/generate_executive_report.py --from 2026-01-15 --to 2026-02-14 --pdf
```

**From Date to Today**
```powershell
python scripts/generate_executive_report.py --from 2026-02-01 --pdf
```

**Last 7 Days**
```powershell
python scripts/generate_executive_report.py --latest --pdf
```

**Scoped to a Roadmap (Milestones)**
```powershell
python scripts/generate_executive_report.py --roadmap M1,M2 --pdf
```

**Print to Console (No File)**
```powershell
python scripts/generate_executive_report.py --no-save
```

All executive briefings should be generated with `--pdf` so the Markdown and PDF artifacts stay paired.

### Windows Users

Use the batch script wrapper:
```batch
scripts\generate_executive_report.bat
scripts\generate_executive_report.bat --from 2026-02-01 --to 2026-02-14 --pdf
scripts\generate_executive_report.bat --latest --pdf
```

## Report Contents

Each executive report includes:

- **Executive Summary** — High-level achievement overview
- **Development Activity** — Commits, code changes, contributor breakdown
- **Code Quality & Testing** — Test coverage, codebase metrics
- **Feature Delivery** — Recently implemented features
- **Milestone Progress** — Completion status by milestone
- **Milestone Summary** — Milestone themes and completion percent
- **Productivity Metrics** — Effort scores, development intensity
- **DORA Metrics** — Deployment frequency, lead time, change failure rate, MTTR (when data exists)
- **Technical Achievements** — Platform support, architecture, quality measures
- **Impact Assessment** — Value delivered and project status
- **Charts** — Weekly commit volume chart (Plotly image)

## Data Sources

Reports are generated from authoritative project data:

1. **Git History** — Commits, authors, code changes, dates
2. **Test Coverage** — `app/coverage/lcov.info` (LCOV format)
3. **Code Metrics** — Dart file count, lines of code
4. **Planning Documentation** — Milestone README progress tables
5. **Git Tags + PR Merges** — DORA deployment and lead time estimates
6. **CI/CD Logs** — Change failure rate and MTTR when logs are available

All metrics are **calculated in real-time** from source data—no manual updates required.

## Report Metadata

Each report includes:

- **Generated timestamp** — When the report was created
- **Reporting period** — Date range covered
- **Data sources** — Which files provided the metrics
- **Unique identifier** — Filename with timestamp for archival

### Filename Convention

Auto-generated filenames follow this pattern:
```
executive-report-<period>-YYYYMMDD-HHMMSS.{md|pdf}
```

Examples:
- `executive-report-cumulative-20260215-163557.md` — All-time report
- `executive-report-20260201-to-20260215-20260215-163557.md` — Date-range report

## Using Reports

### Email Sharing
1. Generate report: `python scripts/generate_executive_report.py --pdf`
2. Open report in editor: `docs/executive-briefings/Executive_Report_*.md`
3. Copy content into email or Markdown viewer
4. Share with stakeholders

### Documentation Integration
- Save reports to this folder for archival
- Link from project roadmaps or status pages
- Reference specific metrics in project updates
- Track velocity trends across multiple reports

### Periodic Reporting

**Weekly (Every Friday)**
```powershell
# Generate last 7 days
python scripts/generate_executive_report.py --latest --pdf
```

**Monthly (First of Month)**
```powershell
# Generate for previous month (example for February)
python scripts/generate_executive_report.py --from 2026-02-01 --to 2026-02-28 --pdf
```

**Milestone Checkpoints**
```powershell
# After completing a milestone (example: M1 completed on Jan 31)
python scripts/generate_executive_report.py --from 2026-01-15 --to 2026-01-31 --pdf
```

**Retrospective Reports**
```powershell
# Quarter report (Q1 2026)
python scripts/generate_executive_report.py --from 2026-01-01 --to 2026-03-31 --pdf
```

## Automation

Add to CI/CD pipeline (GitHub Actions) to generate reports automatically:

```yaml
name: Generate Executive Report
on:
  schedule:
    - cron: '0 18 * * 5'  # Every Friday at 6 PM

jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - run: python scripts/generate_executive_report.py --pdf
      - uses: actions/upload-artifact@v3
        with:
          name: executive-reports
          path: docs/executive-briefings/
```

## Technical Details

### Script Architecture

The `generate_executive_report.py` script uses:

- **Git command-line interface** — Extract commit history, authors, changes
- **LCOV parsing** — Read test coverage data
- **File system scanning** — Count production/test files, measure LOC
- **Planning document parsing** — Extract milestone completion percentages
- **Statistical analysis** — Calculate averages, productivity scores
- **DORA approximations** — Tags for deployments, PR merges for lead time
- **Markdown generation** — Format professional email-ready reports

### Supported Platforms

- ✅ Windows (PowerShell, Command Prompt)
- ✅ macOS (bash, zsh)
- ✅ Linux (bash, etc.)

**Requirements:**
- Python 3.7+
- Git CLI
- Markdown viewer (VS Code, browser, etc.)
- Plotly + Kaleido (for charts): `pip install plotly kaleido`
- Markdown + WeasyPrint (for PDF, preferred): `pip install markdown weasyprint`
- Markdown + xhtml2pdf (PDF fallback on Windows): `pip install markdown xhtml2pdf`

### Performance

- Typical report generation: **< 5 seconds**
- No external API calls or network dependencies
- Full git history processing: **< 30 seconds** for large repos

## Troubleshooting

### "Python is not recognized"
Ensure Python 3 is installed and added to PATH:
```powershell
python --version
```

### "git is not recognized"
Ensure Git CLI is installed:
```powershell
git --version
```

### No test coverage data
Run tests with coverage before generating report:
```powershell
cd app
flutter test --coverage
```

### Git history not showing
Ensure you're in the correct repository directory:
```powershell
cd c:\Projects\zerospoils\etc\zerospoils_github_issues_pack
python scripts/generate_executive_report.py --pdf
```

## Examples

### Example Report: Cumulative Project Status

Generate with:
```powershell
python scripts/generate_executive_report.py --pdf --output "Cumulative_Project_Report.md"
```

### Example Report: Weekly Update

Generate with:
```powershell
python scripts/generate_executive_report.py --latest --pdf --output "Weekly_Report_Feb14.md"
```

### Example Report: Sprint Retrospective

Generate with:
```powershell
python scripts/generate_executive_report.py \
  --from 2026-02-07 \
  --to 2026-02-14 \
  --pdf \
  --output "Sprint_Retrospective_Feb7-14.md"
```

## Tips & Best Practices

1. **Schedule Regular Reports**
   - Weekly: Use `--latest` for trend tracking
   - Monthly: Use `--from` for beginning of month
   - Quarterly: Use both `--from` and `--to`

2. **Version Control Reports**
   - Commit generated reports to git
   - Track metrics over time
   - Enable historical analysis

3. **Customize Distribution**
   - Generate and email reports automatically
   - Include in sprint planning documents
   - Reference in stakeholder updates

4. **Data Quality**
   - Ensure test suite runs regularly (`flutter test --coverage`)
   - Use conventional commits (feat:, fix:, etc.) for classification
   - Keep milestone READMEs updated in planning folder

## See Also

- [Project README](../README.md)
- [Planning Documentation](../planning/README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Architecture Documentation](../ARCHITECTURE.md)

---

**Last Updated:** February 14, 2026  
**Script Version:** 1.0  
**Data Driven:** ✅ All metrics extracted from source data in real-time
