# Contributing to ZeroSpoils

Thank you for your interest in contributing to ZeroSpoils! This guide outlines our development workflow and expectations.

## Development Workflow

### 1. Pick an Issue
- Choose an issue from `planning/milestones/` (start with M1)
- Read the **Goal**, **Acceptance Criteria**, and **Test Plan**
- These form your implementation spec

### 2. Create a Feature Branch
```bash
git checkout -b feature/descriptive-name
```

Use this naming convention:
- `feature/item-inventory` – Adding new feature
- `fix/crash-on-delete` – Bug fix
- `docs/update-architecture` – Documentation

### 3. Implement Your Changes

**Code:**
- Place implementation in `app/lib/`
- Follow Dart/Flutter conventions
- Keep changes focused (one issue = one PR)

**Tests:**
- Add unit tests in `app/test/`
- Widget tests for UI components
- Integration tests for critical flows
- Aim for >80% coverage on modified code

**Telemetry:**
- Instrument key user events (see `planning/docs/telemetry.md`)
- Include event name and key properties
- Ensure no PII in event data

**Docs:**
- Update `planning/docs/` if behavior changes
- Document API changes in code comments
- Add test plan verification steps

### 4. Commit with Clarity
```bash
git commit -m "feat: add item detail screen

- Implement tap to view full item details
- Add edit/delete/mark-used actions
- Add unit tests for actions
- Add telemetry for user interactions

Closes #123"
```

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` – New feature
- `fix:` – Bug fix
- `docs:` – Documentation
- `test:` – Test additions
- `refactor:` – Code restructuring
- `perf:` – Performance improvement

### 5. Submit a Pull Request

Create PR with:
- **Title:** Short description (what & why)
- **Description:** Reference the planning issue number
- **Linked Issues:** Link to `planning/milestones/` issue
- **Checklist:** Complete the PR template below

### 6. Code Review
- Address reviewer feedback promptly
- Re-request review after changes
- At least one approval required before merge

### 7. Merge to Main
- Squash merge (single clean commit)
- Delete feature branch after merge
- Update issue status in planning/

## Pre-Commit Hooks
Install once after cloning to catch issues early:
- Linux/macOS: `bash scripts/setup-hooks.sh`
- Windows: `scripts\setup-hooks.bat`

Hooks run automatically on `git commit`:
- Format: `dart format --set-exit-if-changed .`
- Analyze: `flutter analyze --no-pub`

## PR Template Checklist

When creating a PR, ensure:
- [ ] References planning issue (link to file path)
- [ ] Tests added/updated for new code
- [ ] Test coverage ≥80% for modified files
- [ ] `flutter analyze` passes locally
- [ ] `dart format .` applied
- [ ] Telemetry instrumented (event names + properties)
- [ ] Offline-first behavior verified
- [ ] Accessibility basics checked (labels, contrast, tap targets ≥44pt)
- [ ] Documentation updated (planning/docs/ if behavior changed)
- [ ] No secrets, API keys, or PII committed

## Code Style

### Dart/Flutter
- Use `dart format` (built-in formatter)
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Prefer `const` constructors
- Use meaningful variable names
- Comment complex logic

### Git Commits
- One logical change per commit
- Write clear commit messages
- Reference issues: "Closes #123"

## Testing

### Unit Tests
```dart
test('should calculate expiry correctly', () {
  final item = Item(name: 'Milk', expiryDate: DateTime(2025, 1, 20));
  expect(item.daysUntilExpiry, 5);
});
```

### Widget Tests
```dart
testWidgets('should display item name', (WidgetTester tester) async {
  await tester.pumpWidget(ItemDetailScreen(item: testItem));
  expect(find.text('Milk'), findsOneWidget);
});
```

### Running Tests
```bash
cd app
flutter test                    # All tests
flutter test test/unit/        # Unit tests only
flutter test --coverage        # With coverage report
```

## Telemetry Events

All major user actions should log events. See `planning/docs/telemetry.md` for:
- Event naming convention
- Standard properties (platform, app_version, timestamp)
- Privacy guardrails

Example:
```dart
analytics.logEvent(
  name: 'item_marked_used',
  parameters: {
    'category': item.category,
    'days_until_expiry': item.daysUntilExpiry,
  },
);
```

## Accessibility

Every screen must meet:
- ✓ Labels on all interactive elements
- ✓ Contrast ratio ≥4.5:1 for text
- ✓ Touch targets ≥44x44 dp
- ✓ Support for text scaling (up to 2x)
- ✓ Semantic labels for images

## Questions?

- Check `planning/docs/` for architecture and design decisions
- Review recent PRs for patterns and examples
- Open a discussion issue for questions

Thank you for contributing to ZeroSpoils! 🎉
