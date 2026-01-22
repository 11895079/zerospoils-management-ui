# Pre-commit Hooks

This repository uses Git pre-commit hooks to ensure code quality before committing changes.

## What Gets Checked

The pre-commit hook automatically runs:

1. **Format Check**: `dart format --set-exit-if-changed .`
   - Ensures all Dart code follows consistent formatting rules
   - Fails if any files need formatting

2. **Analyzer**: `flutter analyze --no-pub`
   - Checks for lint errors, warnings, and code issues
   - Fails if any analyzer issues are found

3. **Tests**: `flutter test`
   - Runs all unit, widget, and integration tests
   - Fails if any tests fail
   - Catches regressions locally before pushing to CI

## How It Works

When you run `git commit`, the hook automatically:
1. ✅ Checks formatting of all Dart files
2. ✅ Runs the Flutter analyzer
3. ✅ Runs all tests
4. ✅ Only allows the commit if all checks pass
5. ❌ Blocks the commit and shows errors if checks fail

## Example Output

**Successful commit:**
```bash
$ git commit -m "feat: add new feature"
🔍 Running pre-commit checks...
📝 Checking Dart formatting...
✅ Formatting check passed
🔎 Running Flutter analyzer...
✅ Analyzer passed
🧪 Running tests...
✅ Tests passed
✨ All pre-commit checks passed!
[feature-branch abc123] feat: add new feature
```

**Failed commit (test failure):**
```bash
$ git commit -m "fix: update logic"
🔍 Running pre-commit checks...
📝 Checking Dart formatting...
✅ Formatting check passed
🔎 Running Flutter analyzer...
✅ Analyzer passed
🧪 Running tests...
❌ Tests failed. Fix them before committing.
```

## Fixing Issues

### Format Issues
If the format check fails:
```bash
cd app
dart format .
git add .
git commit -m "your message"
```

### Analyzer Issues
If the analyzer fails:
1. Review the error messages
2. Fix the reported issues in your code
3. Try committing again

## Bypassing the Hook (Not Recommended)

In rare cases where you need to bypass the hook:
```bash
git commit --no-verify -m "your message"
```

⚠️ **Warning**: Bypassing the hook may cause CI failures on GitHub.

## Setup for New Team Members

After cloning the repository, run the setup script to install the hooks:

**Linux/macOS:**
```bash
bash scripts/setup-hooks.sh
```

**Windows:**
```cmd
scripts\setup-hooks.bat
```

Or manually:
```bash
cp scripts/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit  # Linux/macOS only
```

## Modifying Hook Behavior

The hook source is tracked at `scripts/hooks/pre-commit`. To modify:

1. Edit `scripts/hooks/pre-commit`
2. Reinstall by running the setup script again
3. Commit your changes so other team members get the update
