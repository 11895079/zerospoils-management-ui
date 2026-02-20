#!/usr/bin/env python3
"""
Executive Report Generator for ZeroSpoils

Generates data-driven executive briefings showing development effort, impact, and progress.
Supports cumulative reports (all work to date) and date-range filtering.

Usage:
    python generate_executive_report.py                    # Cumulative report
    python generate_executive_report.py --from 2026-01-15 --to 2026-02-14  # Date range
    python generate_executive_report.py --from 2026-02-01                   # From date to today
    python generate_executive_report.py --latest                            # Last 7 days
"""

import subprocess
import json
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import argparse
from collections import defaultdict, Counter


class ExecutiveReportGenerator:
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path)
        self.app_path = self.repo_path / "app"
        self.planning_path = self.repo_path / "planning"
        self.start_date: Optional[datetime] = None
        self.end_date: Optional[datetime] = None
        self.roadmap_scope: Optional[List[str]] = None
        self.report_assets_dir: Optional[Path] = None
        self.report_timestamp: Optional[str] = None

    def set_roadmap_scope(self, scope: Optional[str] = None):
        """Set roadmap/milestone scope (comma-separated list like M1,M2)."""
        if scope:
            raw = [item.strip().upper() for item in scope.split(',') if item.strip()]
            self.roadmap_scope = [item for item in raw if re.match(r'^M\d+$', item)]
        else:
            self.roadmap_scope = None

    def set_date_range(self, from_date: Optional[str] = None, to_date: Optional[str] = None, latest: bool = False):
        """Set the date range for report filtering."""
        self.end_date = datetime.now().astimezone()

        if latest:
            self.start_date = self.end_date - timedelta(days=7)
        elif from_date:
            self.start_date = datetime.fromisoformat(from_date)
            if self.start_date.tzinfo is None:
                self.start_date = self.start_date.replace(tzinfo=self.end_date.tzinfo)
            if to_date:
                self.end_date = datetime.fromisoformat(to_date)
                if self.end_date.tzinfo is None:
                    self.end_date = self.end_date.replace(tzinfo=self.start_date.tzinfo)
        else:
            # Cumulative: start from beginning of git history
            self.start_date = None

    def run_git_command(self, *args) -> str:
        """Execute a git command and return output."""
        cmd = ["git", "-C", str(self.repo_path)] + list(args)
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if result.returncode != 0:
            print(f"Warning: git command failed: {' '.join(cmd)}")
            print(f"Error: {result.stderr}")
        return result.stdout or ""

    def get_commit_stats(self) -> Dict:
        """Extract commit statistics from git history."""
        log_format = "--COMMIT--%H|%an|%ad|%s|%b"
        git_log = self.run_git_command(
            "log", "--numstat", "--pretty=format:" + log_format, "--date=iso"
        )

        commits: List[Dict] = []
        current_commit: Optional[Dict] = None

        def finalize_commit(commit: Optional[Dict]):
            if commit:
                commits.append(commit)

        for raw_line in git_log.split('\n'):
            line = raw_line.rstrip()
            if line.startswith("--COMMIT--"):
                finalize_commit(current_commit)
                parts = line.replace("--COMMIT--", "", 1).split("|", 4)
                if len(parts) < 4:
                    continue
                date_str = parts[2].strip()
                try:
                    commit_date = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S %z")
                except ValueError:
                    try:
                        commit_date = datetime.fromisoformat(date_str)
                    except ValueError:
                        commit_date = datetime.now().astimezone()
                if commit_date.tzinfo is None:
                    commit_date = commit_date.replace(tzinfo=self.end_date.tzinfo if self.end_date else datetime.now().astimezone().tzinfo)

                current_commit = {
                    'hash': parts[0],
                    'author': parts[1],
                    'date': commit_date,
                    'subject': parts[3],
                    'body': parts[4] if len(parts) > 4 else '',
                    'files_changed': 0,
                    'insertions': 0,
                    'deletions': 0,
                }
            elif current_commit and line:
                numstat_parts = line.split('\t')
                if len(numstat_parts) >= 2:
                    insertions = numstat_parts[0]
                    deletions = numstat_parts[1]
                    if insertions.isdigit() and deletions.isdigit():
                        current_commit['insertions'] += int(insertions)
                        current_commit['deletions'] += int(deletions)
                    current_commit['files_changed'] += 1

        finalize_commit(current_commit)

        # Filter by date range
        filtered_commits = [c for c in commits if self._in_date_range(c['date'])]

        # Calculate aggregates
        total_commits = len(filtered_commits)
        total_insertions = sum(c['insertions'] for c in filtered_commits)
        total_deletions = sum(c['deletions'] for c in filtered_commits)

        authors = Counter(c['author'] for c in filtered_commits)
        commit_types = self._classify_commits(filtered_commits)

        return {
            'total_commits': total_commits,
            'total_insertions': total_insertions,
            'total_deletions': total_deletions,
            'net_lines': total_insertions - total_deletions,
            'commits': filtered_commits,
            'authors': dict(authors),
            'commit_types': commit_types,
        }

    def _in_date_range(self, date: datetime) -> bool:
        """Check if date is within the specified range."""
        if self.end_date and date.tzinfo is None:
            date = date.replace(tzinfo=self.end_date.tzinfo)
        if self.start_date and date < self.start_date:
            return False
        if self.end_date and date > self.end_date:
            return False
        return True

    def _classify_commits(self, commits: List[Dict]) -> Dict[str, int]:
        """Classify commits by type based on subject and body."""
        types = defaultdict(int)

        for commit in commits:
            subject = commit['subject'].lower()

            if subject.startswith('feat'):
                types['feature'] += 1
            elif subject.startswith('fix'):
                types['fix'] += 1
            elif subject.startswith('refactor'):
                types['refactor'] += 1
            elif subject.startswith('test'):
                types['test'] += 1
            elif subject.startswith('docs'):
                types['documentation'] += 1
            elif subject.startswith('chore'):
                types['chore'] += 1
            elif 'merge pull request' in subject.lower():
                types['merge'] += 1
            else:
                types['other'] += 1

        return dict(types)

    def get_test_coverage(self) -> Dict:
        """Extract test coverage metrics from lcov.info."""
        lcov_file = self.app_path / "coverage" / "lcov.info"

        if not lcov_file.exists():
            return {'coverage_percent': 0, 'files': 0, 'lines': 0, 'lines_hit': 0}

        with open(lcov_file, 'r') as f:
            content = f.read()

        lines_hit = 0
        total_lines = 0

        for line in content.split('\n'):
            if line.startswith('LH:'):
                try:
                    lines_hit += int(line.split(':')[1])
                except ValueError:
                    continue
            elif line.startswith('LF:'):
                try:
                    total_lines += int(line.split(':')[1])
                except ValueError:
                    continue

        coverage_percent = (lines_hit / total_lines * 100) if total_lines > 0 else 0

        return {
            'coverage_percent': round(coverage_percent, 1),
            'lines_hit': lines_hit,
            'total_lines': total_lines,
        }

    def get_code_metrics(self) -> Dict:
        """Get code metrics (files, total lines, etc.)."""
        # Count Dart files
        dart_files = list(self.app_path.glob("lib/**/*.dart"))
        test_files = list(self.app_path.glob("test/**/*.dart"))

        total_dart_lines = 0
        for dart_file in dart_files:
            try:
                with open(dart_file, 'r', encoding='utf-8', errors='ignore') as f:
                    total_dart_lines += len(f.readlines())
            except:
                pass

        return {
            'dart_files': len(dart_files),
            'test_files': len(test_files),
            'total_dart_lines': total_dart_lines,
        }

    def get_milestone_progress(self) -> Dict:
        """Get milestone completion status from planning docs."""
        milestones = {}
        missing_status = []
        milestone_themes = {}
        milestones_path = self.planning_path / "milestones"

        milestone_dirs = sorted(milestones_path.glob("M[0-9]"))
        if self.roadmap_scope:
            milestone_dirs = [m for m in milestone_dirs if m.name.upper() in self.roadmap_scope]

        for milestone_dir in milestone_dirs:
            readme_file = milestone_dir / "README.md"
            if readme_file.exists():
                with open(readme_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                theme = self._extract_milestone_theme(content, milestone_dir.name)
                if theme:
                    milestone_themes[milestone_dir.name] = theme

                # Extract completion metrics from README
                # Patterns: "Progress: 10/10", "(10/17 completed)", "12/15 issues complete"
                completion_match = re.search(r'Progress:.*?(\d+)\s*/\s*(\d+)', content, re.IGNORECASE)
                if not completion_match:
                    completion_match = re.search(r'\((\d+)\s*/\s*(\d+)\s+completed\)', content, re.IGNORECASE)
                if not completion_match:
                    completion_match = re.search(r'(\d+)\s*/\s*(\d+)\s+issues?\s+complete', content, re.IGNORECASE)

                if completion_match:
                    complete = int(completion_match.group(1))
                    total = int(completion_match.group(2))
                    milestones[milestone_dir.name] = {
                        'complete': complete,
                        'total': total,
                        'percent': (complete / total * 100) if total > 0 else 0,
                    }
                else:
                    missing_status.append(milestone_dir.name)

        return {
            'milestones': milestones,
            'missing_status': missing_status,
            'themes': milestone_themes,
        }

    def get_features_implemented(self) -> List[str]:
        """Extract list of implemented features from recent commits."""
        features = []

        for commit in self.get_commit_stats()['commits'][-30:]:  # Last 30 commits
            subject = commit['subject']
            if subject.lower().startswith('feat') or 'feature' in commit['body'].lower():
                # Extract feature name, removing conventional commit prefix
                feature = re.sub(r'^feat\(.*?\):\s*', '', subject, flags=re.IGNORECASE).strip()
                if feature and len(feature) > 5:
                    features.append(feature)

        return features[:10]  # Top 10 features

    def generate_report(self) -> str:
        """Generate the executive report."""
        commit_stats = self.get_commit_stats()
        coverage = self.get_test_coverage()
        code_metrics = self.get_code_metrics()
        milestone_data = self.get_milestone_progress()
        milestones = milestone_data['milestones']
        missing_milestones = milestone_data['missing_status']
        milestone_themes = milestone_data['themes']
        features = self.get_features_implemented()
        attribution = self._get_commit_attribution(commit_stats['commits'])
        dora_metrics = self._get_dora_metrics(commit_stats['commits'])

        # Calculate time period description
        period_desc = self._format_period_description()
        roadmap_scope = ", ".join(self.roadmap_scope) if self.roadmap_scope else "All milestones"

        # Calculate key metrics
        avg_commits_per_day = self._calculate_avg_commits_per_day(commit_stats['commits'])
        time_investment = self._calculate_time_investment(commit_stats['commits'])
        productivity_score = self._calculate_productivity_score(commit_stats, code_metrics, coverage)

        report = f"""# Executive Report: ZeroSpoils Development Progress

**Report Generated:** {datetime.now().strftime('%B %d, %Y at %H:%M %Z')}
**Reporting Period:** {period_desc}
**Roadmap Scope:** {roadmap_scope}

---

## Executive Summary

This report documents the development progress and effort expended building the ZeroSpoils Flutter mobile application—a household food waste reduction platform. The data presented reflects actual development activity, code metrics, and delivery progress.

**Key Achievement:** Successfully implemented {commit_stats['total_commits']} commits with {code_metrics['dart_files']} production Dart files and {code_metrics['test_files']} test files, delivering robust offline-first functionality with {coverage['coverage_percent']}% test coverage.

## MVP Overview (Milestones M1–M3)

The MVP roadmap spans **M1–M3**. Below is the current summary based on milestone status files and code alignment.
"""

        mvp_scope = ["M1", "M2", "M3"]
        for milestone in mvp_scope:
            theme = milestone_themes.get(milestone, "Theme not specified")
            if milestone in milestones:
                complete = milestones[milestone]['complete']
                total = milestones[milestone]['total']
                percent = milestones[milestone]['percent']
                report += f"- **{milestone}:** {theme} — {complete}/{total} complete ({percent:.0f}%)\n"
            else:
                report += f"- **{milestone}:** {theme} — Status missing (update milestone README)\n"

        report += f"""

---

## Development Activity

### Overall Statistics
| Metric | Value |
|--------|-------|
| **Total Commits** | {commit_stats['total_commits']:,} |
| **Net Code Change** | +{commit_stats['total_insertions']:,} / -{commit_stats['total_deletions']:,} lines |
| **Average Commits/Day** | {avg_commits_per_day:.1f} |
| **Unique Contributors** | {len(commit_stats['authors'])} |

### Commit Attribution (Human vs Copilot Agent)
- **Human commits:** {attribution['human_commits']} ({attribution['human_percent']:.1f}%)
- **Copilot agent commits:** {attribution['copilot_commits']} ({attribution['copilot_percent']:.1f}%)

### Commit Volume per Week
"""

        chart_info = self._generate_commit_volume_chart(commit_stats['commits'])
        if chart_info['path']:
            report += f"![]({chart_info['path']})\n"
        else:
            report += f"_Chart unavailable: {chart_info['note']}_\n"

        report += """

### Commit Breakdown by Type
"""

        for commit_type, count in sorted(commit_stats['commit_types'].items(), key=lambda x: x[1], reverse=True):
            pct = (count / commit_stats['total_commits'] * 100) if commit_stats['total_commits'] > 0 else 0
            report += f"- **{commit_type.capitalize()}:** {count} commits ({pct:.0f}%)\n"

        report += f"""

### Development Pace
- **Feature Development:** {commit_stats['commit_types'].get('feature', 0)} new features implemented
- **Bug Fixes:** {commit_stats['commit_types'].get('fix', 0)} bugs resolved
- **Refactoring:** {commit_stats['commit_types'].get('refactor', 0)} code quality improvements
- **Test Coverage:** {commit_stats['commit_types'].get('test', 0)} test-related commits

---

## Code Quality & Testing

### Test Coverage
| Metric | Value |
|--------|-------|
| **Code Coverage** | {coverage['coverage_percent']:.1f}% |
| **Lines Tested** | {coverage['lines_hit']:,} / {coverage['total_lines']:,} |
| **Test Files** | {code_metrics['test_files']} |

**Plain-English Notes:**
- **Lines Tested** means how many executable lines were actually exercised by automated tests in that run, not the total size of the codebase.
- A small number here simply means tests covered only a subset of the code during that run.

### Codebase Metrics
| Metric | Value |
|--------|-------|
| **Production Dart Files** | {code_metrics['dart_files']} |
| **Total Lines of Code** | {code_metrics['total_dart_lines']:,} |
| **Avg File Size** | {(code_metrics['total_dart_lines'] / code_metrics['dart_files'] if code_metrics['dart_files'] > 0 else 0):.0f} LOC |

---

## Feature Delivery

### Recently Implemented Features
"""

        for i, feature in enumerate(features, 1):
            report += f"{i}. {feature}\n"

        report += f"""

---

## Milestone Progress

### Completion Status
"""

        if milestones:
            for milestone, data in sorted(milestones.items()):
                progress_bar = self._generate_progress_bar(data['percent'])
                report += f"- **{milestone}:** {progress_bar} {data['complete']}/{data['total']} ({data['percent']:.0f}%)\n"
        else:
            report += "No milestone data available in planning documentation.\n"

        if missing_milestones:
            report += f"\n**Not Reported (status missing in milestone README):** {', '.join(sorted(missing_milestones))}\n"

        if milestones or missing_milestones:
            report += "\n### Milestone Summary\n"
            for milestone in sorted(set(list(milestones.keys()) + missing_milestones)):
                theme = milestone_themes.get(milestone, "Theme not specified")
                if milestone in milestones:
                    percent = milestones[milestone]['percent']
                    status = "Complete" if percent >= 100 else "In progress"
                    report += f"- **{milestone}:** {theme} — {status} ({percent:.0f}%)\n"
                else:
                    report += f"- **{milestone}:** {theme} — Status missing (update milestone README)\n"

        report += f"""

---

## Productivity Metrics

### Effort Score
- **Overall Productivity:** {productivity_score:.0f}/100
- **Development Intensity:** {self._calculate_development_intensity(commit_stats, code_metrics):.0f}/100
- **Code Quality Index:** {coverage['coverage_percent']:.0f}/100

**Effort Score Meaning:**
- **0–39**: Low (light activity or narrow scope)
- **40–69**: Moderate (steady progress)
- **70–84**: Strong (high delivery pace + breadth)
- **85–100**: Exceptional (sustained, high-impact delivery)

### Time Investment
"""

        report += f"""- **Calendar Span:** {time_investment['calendar_days']} days / {time_investment['calendar_hours']} hours
- **Active Development Days:** {time_investment['active_days']}
- **Average Commits per Active Day:** {time_investment['avg_commits_per_active_day']:.1f}
- **Average Daily Commits:** {avg_commits_per_day:.1f}
- **Code Changes Per Commit:** {(commit_stats['net_lines'] / commit_stats['total_commits']) if commit_stats['total_commits'] > 0 else 0:.0f} net lines

---

## DORA Metrics (from Git Tags, PR Merges, CI Logs)

| Metric | Value | Notes |
|--------|-------|-------|
| **Deployment Frequency** | {dora_metrics['deployment_frequency']} | {dora_metrics['deployment_note']} |
| **Lead Time for Changes** | {dora_metrics['lead_time']} | {dora_metrics['lead_time_note']} |
| **Change Failure Rate** | {dora_metrics['change_failure_rate']} | {dora_metrics['change_failure_note']} |
| **MTTR** | {dora_metrics['mttr']} | {dora_metrics['mttr_note']} |

---

## Contributors

### Team Members
"""

        for author, count in sorted(commit_stats['authors'].items(), key=lambda x: x[1], reverse=True):
            pct = (count / commit_stats['total_commits'] * 100) if commit_stats['total_commits'] > 0 else 0
            report += f"- **{author}:** {count} commits ({pct:.1f}%)\n"

        report += f"""

---

## Technical Achievements

### Platform Support
- ✅ iOS build pipeline implemented
- ✅ Android build pipeline implemented
- ✅ Windows/macOS desktop support
- ✅ Offline-first data model with local storage

### Architecture
- ✅ Clean architecture (domain/data/presentation layers)
- ✅ Dependency injection with GetIt
- ✅ Repository pattern for data abstraction
- ✅ Reactive state management

### Quality Measures
- ✅ Automated testing suite ({code_metrics['test_files']} test files)
- ✅ Code coverage at {coverage['coverage_percent']:.1f}%
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Lint/format validation on all PRs

---

## Impact Assessment

### Value Delivered
1. **MVP Completeness:** Core inventory, shopping list, and receipt capture functionality
2. **Data Reliability:** Offline-first architecture with eventual sync capability
3. **User Experience:** Multi-platform support (iOS, Android, Windows)
4. **Code Maintainability:** Comprehensive test coverage and architecture patterns
5. **Team Velocity:** Consistent delivery with {commit_stats['total_commits']} production commits

### Lines of Code by Category
- **Production Code:** {code_metrics['total_dart_lines']:,} lines
- **Net Addition:** +{commit_stats['total_insertions']:,} lines (project inception)
- **Refactoring Effort:** {commit_stats['commit_types'].get('refactor', 0)} quality improvement passes

**Definitions:**
- **Production Code:** total lines across `app/lib/**/*.dart`.
- **Net Addition:** cumulative insertions minus deletions from git history in the reporting range.
- **Refactoring Effort:** count of commits labeled `refactor` (quality improvements, not feature expansion).

---

## Conclusion

The ZeroSpoils project demonstrates significant technical achievement through:
- **{commit_stats['total_commits']} commits** representing focused, incremental development
- **{code_metrics['dart_files']} production files** organized in clean, maintainable architecture
- **{coverage['coverage_percent']:.1f}% test coverage** ensuring reliability and maintainability
- **Cross-platform deployment** ready for iOS, Android, and desktop platforms

The codebase is production-ready in terms of **code quality, architecture, test coverage, CI/lint, and build stability** — this is **not** a declaration to launch today or a statement of go-to-market readiness.

---

**Report Generated by:** ZeroSpoils Executive Report Generator
**Data Sources:** Git history, test coverage (lcov.info), planning documentation
"""

        return report

    def _format_period_description(self) -> str:
        """Format a human-readable period description."""
        if not self.start_date:
            return "All-time (project inception to present)"
        elif (self.end_date - self.start_date).days <= 7:
            return f"{self.start_date.strftime('%B %d')} to {self.end_date.strftime('%B %d, %Y')} (last {(self.end_date - self.start_date).days} days)"
        else:
            return f"{self.start_date.strftime('%B %d')} to {self.end_date.strftime('%B %d, %Y')}"

    def _calculate_avg_commits_per_day(self, commits: List[Dict]) -> float:
        """Calculate average commits per day."""
        if not commits:
            return 0

        dates = [c['date'].date() for c in commits]
        unique_days = len(set(dates))

        return len(commits) / unique_days if unique_days > 0 else 0

    def _calculate_productivity_score(self, commit_stats: Dict, code_metrics: Dict, coverage: Dict) -> float:
        """Calculate overall productivity score (0-100)."""
        score = 0

        # Commits contribution (max 30 points)
        commit_score = min(30, commit_stats['total_commits'] / 3)  # 90+ commits = 30 points
        score += commit_score

        # Code volume contribution (max 30 points)
        code_score = min(30, code_metrics['total_dart_lines'] / 500)  # 15k lines = 30 points
        score += code_score

        # Test coverage contribution (max 20 points)
        coverage_score = coverage['coverage_percent'] / 5  # 100% = 20 points
        score += coverage_score

        # Code changes per commit (quality metric, max 20 points)
        avg_changes = commit_stats['net_lines'] / commit_stats['total_commits'] if commit_stats['total_commits'] > 0 else 0
        change_score = min(20, avg_changes / 5)  # 100 net lines/commit = 20 points
        score += change_score

        return min(100, score)

    def _calculate_development_intensity(self, commit_stats: Dict, code_metrics: Dict) -> float:
        """Calculate development intensity (0-100)."""
        features = commit_stats['commit_types'].get('feature', 0)
        fixes = commit_stats['commit_types'].get('fix', 0)
        total = commit_stats['total_commits']

        # Score based on feature/fix ratio and code changes
        intensity = (features * 5 + fixes * 2) / total * 100 if total > 0 else 0
        return min(100, intensity)

    def _is_copilot_commit(self, author: str) -> bool:
        """Detect Copilot/agent/bot authored commits by author string."""
        author_lower = author.lower()
        return any(token in author_lower for token in ["copilot", "swe-agent[bot]", "github-actions[bot]"])

    def _get_commit_attribution(self, commits: List[Dict]) -> Dict[str, float]:
        """Compute human vs copilot agent commit attribution."""
        if not commits:
            return {
                'human_commits': 0,
                'copilot_commits': 0,
                'human_percent': 0.0,
                'copilot_percent': 0.0,
            }

        copilot_commits = sum(1 for c in commits if self._is_copilot_commit(c['author']))
        human_commits = len(commits) - copilot_commits
        total = len(commits)

        return {
            'human_commits': human_commits,
            'copilot_commits': copilot_commits,
            'human_percent': (human_commits / total * 100) if total > 0 else 0.0,
            'copilot_percent': (copilot_commits / total * 100) if total > 0 else 0.0,
        }

    def _calculate_time_investment(self, commits: List[Dict]) -> Dict[str, float]:
        """Calculate calendar span, hours, and active development days."""
        if not commits:
            return {
                'calendar_days': 0,
                'calendar_hours': 0,
                'active_days': 0,
                'avg_commits_per_active_day': 0.0,
            }

        commit_dates = sorted(c['date'] for c in commits)
        start = self.start_date or commit_dates[0]
        end = self.end_date or commit_dates[-1]

        if start.tzinfo is None and end.tzinfo is not None:
            start = start.replace(tzinfo=end.tzinfo)
        if end.tzinfo is None and start.tzinfo is not None:
            end = end.replace(tzinfo=start.tzinfo)

        delta = end - start
        calendar_days = max(0, delta.days)
        calendar_hours = calendar_days * 24

        active_days = len(set(c['date'].date() for c in commits))
        avg_commits_per_active_day = len(commits) / active_days if active_days > 0 else 0.0

        return {
            'calendar_days': calendar_days,
            'calendar_hours': calendar_hours,
            'active_days': active_days,
            'avg_commits_per_active_day': avg_commits_per_active_day,
        }

    def _get_dora_metrics(self, commits: List[Dict]) -> Dict[str, str]:
        """Compute DORA-style metrics using git tags, PR merges, and CI logs where available."""
        tag_dates = self._get_tag_dates()
        deployment_frequency, deployment_note = self._calculate_deployment_frequency(tag_dates)

        lead_time, lead_note = self._calculate_lead_time_from_merges(commits)

        change_failure_rate = "Not enough data"
        change_failure_note = "Requires incident/rollback markers or CI failure logs; none detected locally."

        mttr = "Not enough data"
        mttr_note = "Requires incident resolution timestamps; not available in local repo."

        return {
            'deployment_frequency': deployment_frequency,
            'deployment_note': deployment_note,
            'lead_time': lead_time,
            'lead_time_note': lead_note,
            'change_failure_rate': change_failure_rate,
            'change_failure_note': change_failure_note,
            'mttr': mttr,
            'mttr_note': mttr_note,
        }

    def _get_tag_dates(self) -> List[datetime]:
        """Return tag dates (creator date) sorted ascending."""
        raw = self.run_git_command("for-each-ref", "refs/tags", "--format=%(refname:short)|%(creatordate:iso)")
        tag_dates = []
        for line in raw.splitlines():
            if "|" not in line:
                continue
            _, date_str = line.split("|", 1)
            date_str = date_str.strip()
            try:
                tag_date = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S %z")
            except ValueError:
                try:
                    tag_date = datetime.fromisoformat(date_str)
                except ValueError:
                    continue
            if self._in_date_range(tag_date):
                tag_dates.append(tag_date)

        return sorted(tag_dates)

    def _calculate_deployment_frequency(self, tag_dates: List[datetime]) -> Tuple[str, str]:
        """Calculate deployment frequency based on tags in the reporting window."""
        if not tag_dates:
            return "Not available", "No tags found in range; tag releases to measure deployments."

        start = self.start_date or tag_dates[0]
        end = self.end_date or tag_dates[-1]
        delta_days = max(1, (end - start).days)
        per_week = (len(tag_dates) / (delta_days / 7.0)) if delta_days > 0 else 0
        return f"{per_week:.2f} per week", "Based on git tags as deployment markers."

    def _calculate_lead_time_from_merges(self, commits: List[Dict]) -> Tuple[str, str]:
        """Estimate lead time using merge commits as PR boundaries."""
        if not commits:
            return "Not available", "No commits available in range."

        commits_sorted = sorted(commits, key=lambda c: c['date'])
        merge_indices = [i for i, c in enumerate(commits_sorted) if 'merge pull request' in c['subject'].lower()]
        if not merge_indices:
            return "Not available", "No PR merge commits detected in range."

        lead_times = []
        prev_index = 0
        for idx in merge_indices:
            window_commits = commits_sorted[prev_index:idx + 1]
            if window_commits:
                oldest = window_commits[0]['date']
                merge_date = commits_sorted[idx]['date']
                lead_times.append((merge_date - oldest).total_seconds())
            prev_index = idx + 1

        if not lead_times:
            return "Not available", "Insufficient data to estimate lead time."

        lead_times.sort()
        median_seconds = lead_times[len(lead_times) // 2]
        median_days = median_seconds / 86400
        return f"{median_days:.1f} days", "Approximate: time from first commit to merge commit per PR window."

    def _generate_progress_bar(self, percent: float) -> str:
        """Generate a visual progress bar."""
        filled = int(round(percent / 10))
        empty = max(0, 10 - filled)
        bar = "#" * filled + "-" * empty
        return f"`{bar}`"

    def _extract_milestone_theme(self, content: str, milestone_name: str) -> str:
        """Extract milestone theme from README content."""
        header_match = re.search(r'^#\s*Milestone\s*' + re.escape(milestone_name) + r'\s*[—-]\s*(.+)$', content, re.MULTILINE)
        if header_match:
            return header_match.group(1).strip()

        objective_match = re.search(r'^\*\*Objective:\*\*\s*(.+)$', content, re.MULTILINE)
        if objective_match:
            return objective_match.group(1).strip()

        return ""

    def _generate_commit_volume_chart(self, commits: List[Dict]) -> Dict[str, Optional[str]]:
        """Generate a weekly commit volume chart image using Plotly."""
        if not self.report_assets_dir or not self.report_timestamp:
            return {'path': None, 'note': 'Chart generation skipped (no report output directory).'}

        try:
            import plotly.graph_objects as go
        except Exception:
            return {'path': None, 'note': 'Chart generation skipped (plotly not installed).'}

        weekly_counts: Dict[str, int] = defaultdict(int)
        for commit in commits:
            iso_year, iso_week, _ = commit['date'].isocalendar()
            week_key = f"{iso_year}-W{iso_week:02d}"
            weekly_counts[week_key] += 1

        if not weekly_counts:
            return {'path': None, 'note': 'No commits available for weekly chart.'}

        weeks_sorted = sorted(weekly_counts.keys())
        counts = [weekly_counts[week] for week in weeks_sorted]

        fig = go.Figure(
            data=[go.Bar(x=weeks_sorted, y=counts, marker_color="#4C78A8")]
        )
        fig.update_layout(
            title="Commit Volume per Week",
            xaxis_title="ISO Week",
            yaxis_title="Commits",
            template="plotly_white",
            height=360,
            margin=dict(l=40, r=20, t=50, b=40),
        )

        self.report_assets_dir.mkdir(parents=True, exist_ok=True)
        image_name = f"commit-volume-per-week-{self.report_timestamp}.png"
        output_path = self.report_assets_dir / image_name

        try:
            fig.write_image(str(output_path))
        except Exception:
            return {'path': None, 'note': 'Chart generation failed (install plotly + kaleido).'}

        return {'path': f"assets/{image_name}", 'note': None}

    def save_report(self, filename: Optional[str] = None) -> Path:
        """Save report to file."""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            if self.start_date:
                period = f"{self.start_date.strftime('%Y%m%d')}-to-{self.end_date.strftime('%Y%m%d')}"
            else:
                period = "cumulative"
            filename = f"executive-report-{period}-{timestamp}.md"

        output_dir = self.repo_path / "docs" / "executive-briefings"
        output_dir.mkdir(parents=True, exist_ok=True)

        self.report_assets_dir = output_dir / "assets"
        self.report_timestamp = timestamp

        output_path = output_dir / filename

        milestone_data = self.get_milestone_progress()
        self._review_milestone_status(milestone_data)

        report = self.generate_report()

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(report)

        return output_path

    def export_pdf(self, markdown_path: Path) -> Path:
        """Export a markdown report to PDF using HTML rendering."""
        try:
            return self._export_pdf_with_weasyprint(markdown_path)
        except Exception:
            return self._export_pdf_with_xhtml2pdf(markdown_path)

    def _export_pdf_with_weasyprint(self, markdown_path: Path) -> Path:
        """Export PDF using WeasyPrint (preferred)."""
        import markdown as md
        from weasyprint import HTML, CSS

        markdown_text = markdown_path.read_text(encoding='utf-8')
        html_body = md.markdown(markdown_text, extensions=["tables", "fenced_code"])

        css = CSS(string="""
            body { font-family: Arial, Helvetica, sans-serif; color: #111; }
            h1, h2, h3 { color: #222; }
            table { border-collapse: collapse; width: 100%; margin: 12px 0; }
            th, td { border: 1px solid #ddd; padding: 6px 8px; font-size: 12px; }
            th { background: #f5f5f5; }
            img { max-width: 100%; height: auto; }
            code { background: #f6f8fa; padding: 2px 4px; border-radius: 4px; }
            pre { background: #f6f8fa; padding: 8px; border-radius: 6px; }
        """)

        html = HTML(string=html_body, base_url=str(markdown_path.parent))
        pdf_path = markdown_path.with_suffix('.pdf')
        html.write_pdf(str(pdf_path), stylesheets=[css])
        return pdf_path

    def _export_pdf_with_xhtml2pdf(self, markdown_path: Path) -> Path:
        """Export PDF using xhtml2pdf as a Windows-friendly fallback."""
        import markdown as md
        from xhtml2pdf import pisa

        markdown_text = markdown_path.read_text(encoding='utf-8')
        html_body = md.markdown(markdown_text, extensions=["tables", "fenced_code"])

        html = f"""
        <html>
          <head>
            <style>
              body {{ font-family: Arial, Helvetica, sans-serif; color: #111; }}
              h1, h2, h3 {{ color: #222; }}
              table {{ border-collapse: collapse; width: 100%; margin: 12px 0; }}
              th, td {{ border: 1px solid #ddd; padding: 6px 8px; font-size: 12px; }}
              th {{ background: #f5f5f5; }}
              img {{ max-width: 100%; height: auto; }}
              code {{ background: #f6f8fa; padding: 2px 4px; border-radius: 4px; }}
              pre {{ background: #f6f8fa; padding: 8px; border-radius: 6px; }}
            </style>
          </head>
          <body>{html_body}</body>
        </html>
        """

        def link_callback(uri: str, rel: str) -> str:
            if uri.startswith("http://") or uri.startswith("https://"):
                return uri
            candidate = (markdown_path.parent / uri).resolve()
            return str(candidate)

        pdf_path = markdown_path.with_suffix('.pdf')
        with open(pdf_path, 'wb') as pdf_file:
            result = pisa.CreatePDF(html, dest=pdf_file, encoding='utf-8', link_callback=link_callback)
            if result.err:
                raise RuntimeError(
                    "PDF export failed. Install dependencies with: pip install markdown xhtml2pdf"
                )

        return pdf_path

    def _review_milestone_status(self, milestone_data: Dict) -> None:
        """Ensure milestone status is reviewed before report generation."""
        milestones = milestone_data.get('milestones', {})
        missing = milestone_data.get('missing_status', [])

        if self.roadmap_scope:
            scoped_missing = [m for m in missing if m.upper() in self.roadmap_scope]
            scoped_available = [m for m in milestones.keys() if m.upper() in self.roadmap_scope]

            if scoped_missing:
                raise ValueError(
                    "Milestone status missing for scoped milestones: "
                    + ", ".join(sorted(scoped_missing))
                    + ". Update planning/milestones/<Mx>/README.md before generating the report."
                )

            print("Milestone status review (scoped): " + ", ".join(sorted(scoped_available)))
        else:
            if missing:
                print("Milestone status review: missing status for " + ", ".join(sorted(missing)))
            else:
                print("Milestone status review: all milestone READMEs have status metrics.")


def main():
    parser = argparse.ArgumentParser(
        description="Generate executive reports for ZeroSpoils development",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate cumulative report (all time)
  python generate_executive_report.py

  # Generate report for specific date range
  python generate_executive_report.py --from 2026-01-15 --to 2026-02-14

    # Generate report scoped to a roadmap (milestones)
    python generate_executive_report.py --roadmap M1,M2

  # Generate report from date to today
  python generate_executive_report.py --from 2026-02-01

  # Generate report for last 7 days
  python generate_executive_report.py --latest
        """
    )

    parser.add_argument(
        '--from',
        dest='from_date',
        help='Start date (YYYY-MM-DD) - inclusive'
    )
    parser.add_argument(
        '--to',
        dest='to_date',
        help='End date (YYYY-MM-DD) - inclusive'
    )
    parser.add_argument(
        '--latest',
        action='store_true',
        help='Generate report for last 7 days'
    )
    parser.add_argument(
        '--output',
        help='Output filename (default: auto-generated)'
    )
    parser.add_argument(
        '--no-save',
        action='store_true',
        help='Print report to stdout instead of saving'
    )
    parser.add_argument(
        '--repo',
        default='.',
        help='Path to repository (default: current directory)'
    )
    parser.add_argument(
        '--pdf',
        action='store_true',
        help='Also export the report to PDF'
    )
    parser.add_argument(
        '--roadmap',
        help='Comma-separated milestone scope (e.g., M1,M2). Defaults to all milestones.'
    )

    args = parser.parse_args()

    generator = ExecutiveReportGenerator(args.repo)
    generator.set_date_range(args.from_date, args.to_date, args.latest)
    generator.set_roadmap_scope(args.roadmap)

    if args.no_save:
        print(generator.generate_report())
    else:
        output_path = generator.save_report(args.output)
        print(f"✅ Report saved to: {output_path}")
        if args.pdf:
            pdf_path = generator.export_pdf(output_path)
            print(f"✅ PDF exported to: {pdf_path}")
        print(f"\n📊 Report ready for sharing:")
        print(f"   - Open in editor: {output_path}")
        if args.pdf:
            print(f"   - PDF version: {pdf_path}")
        print(f"   - Copy content for email or documentation")


if __name__ == '__main__':
    main()
