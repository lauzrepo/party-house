# GitHub Repository Setup Guide

This guide will help you set up the payment portal repository with best practices for version control, collaboration, and CI/CD.

## Table of Contents

- [Initial Repository Setup](#initial-repository-setup)
- [Branch Strategy](#branch-strategy)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Environment Variables](#environment-variables)
- [GitHub Secrets](#github-secrets)
- [Pull Request Template](#pull-request-template)
- [Issue Templates](#issue-templates)
- [Branch Protection Rules](#branch-protection-rules)

---

## Initial Repository Setup

### 1. Create Repository

```bash
# Create new repository on GitHub
# Then clone it locally
git clone https://github.com/your-org/payment-portal.git
cd payment-portal
```

### 2. Initialize Git Configuration

```bash
# Set up Git config
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Create initial commit
git add .
git commit -m "feat: initial project setup"
git push origin main
```

### 3. Create .gitignore

The repository should have the following `.gitignore`:

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
*.lcov
.nyc_output

# Production builds
build/
dist/
.next/
out/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Prisma
prisma/dev.db
prisma/dev.db-journal

# AWS
.aws-sam/

# Misc
.cache/
temp/
tmp/
```

---

## Branch Strategy

We use **Git Flow** with the following branches:

### Main Branches

- **`main`** - Production-ready code
- **`develop`** - Integration branch for features

### Supporting Branches

- **`feature/*`** - New features (e.g., `feature/subscription-management`)
- **`bugfix/*`** - Bug fixes (e.g., `bugfix/payment-validation`)
- **`hotfix/*`** - Critical production fixes (e.g., `hotfix/security-patch`)
- **`release/*`** - Release preparation (e.g., `release/v1.0.0`)

### Workflow

```bash
# Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/subscription-management

# Work on feature
git add .
git commit -m "feat: add subscription management"
git push origin feature/subscription-management

# Create PR to develop
# After review and approval, merge to develop

# Create release branch from develop
git checkout develop
git checkout -b release/v1.0.0

# Merge to main and tag
git checkout main
git merge release/v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge release/v1.0.0
git push origin develop
```

---

## GitHub Actions CI/CD

Create `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  backend-test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install backend dependencies
        working-directory: ./backend
        run: npm ci

      - name: Run Prisma migrations
        working-directory: ./backend
        run: npx prisma migrate dev
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db

      - name: Run backend tests
        working-directory: ./backend
        run: npm test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          JWT_SECRET: test-secret

      - name: Check test coverage
        working-directory: ./backend
        run: npm run test:coverage

  frontend-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install frontend dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Run frontend tests
        working-directory: ./frontend
        run: npm test

      - name: Check test coverage
        working-directory: ./frontend
        run: npm run test:coverage

      - name: Build frontend
        working-directory: ./frontend
        run: npm run build

  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install backend dependencies
        working-directory: ./backend
        run: npm ci

      - name: Lint backend
        working-directory: ./backend
        run: npm run lint

      - name: Install frontend dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Lint frontend
        working-directory: ./frontend
        run: npm run lint

  deploy-staging:
    needs: [backend-test, frontend-test, lint]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to staging
        run: echo "Deploy to staging environment"
        # Add your deployment commands here

  deploy-production:
    needs: [backend-test, frontend-test, lint]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to production
        run: echo "Deploy to production environment"
        # Add your deployment commands here
```

---

## Environment Variables

### Development Environment

Create `.env.example` files in both frontend and backend:

**Backend `.env.example`:**

```env
NODE_ENV=development
PORT=5000
DATABASE_URL=postgresql://user:password@localhost:5432/payment_portal
JWT_SECRET=your-jwt-secret-here
JWT_REFRESH_SECRET=your-jwt-refresh-secret-here
HELCIM_API_TOKEN=your-helcim-api-token
HELCIM_WEBHOOK_SECRET=your-webhook-secret
FRONTEND_URL=http://localhost:3000
EMAIL_SERVICE_API_KEY=your-email-api-key
AWS_S3_BUCKET=your-s3-bucket
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
```

**Frontend `.env.example`:**

```env
VITE_API_URL=http://localhost:5000/api
VITE_HELCIM_TOKEN=your-helcim-public-token
```

---

## GitHub Secrets

Configure the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

### Production Secrets

```
DATABASE_URL
JWT_SECRET
JWT_REFRESH_SECRET
HELCIM_API_TOKEN
HELCIM_WEBHOOK_SECRET
EMAIL_SERVICE_API_KEY
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_S3_BUCKET
```

### Staging Secrets

```
STAGING_DATABASE_URL
STAGING_HELCIM_API_TOKEN
STAGING_FRONTEND_URL
```

### Deployment Secrets

```
VERCEL_TOKEN           # For frontend deployment
RAILWAY_TOKEN          # For backend deployment
RENDER_API_KEY         # Alternative backend hosting
```

---

## Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## Description

<!-- Describe your changes in detail -->

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issue

<!-- Link to the issue: Fixes #123 -->

## How Has This Been Tested?

- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist

- [ ] My code follows the code style of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Screenshots (if applicable)

<!-- Add screenshots here -->

## Additional Notes

<!-- Any additional information -->
```

---

## Issue Templates

### Bug Report Template

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Steps to Reproduce

1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Screenshots

If applicable, add screenshots to help explain your problem.

## Environment

- OS: [e.g., macOS, Windows, Linux]
- Browser: [e.g., Chrome, Firefox, Safari]
- Version: [e.g., 1.0.0]

## Additional Context

Add any other context about the problem here.
```

### Feature Request Template

Create `.github/ISSUE_TEMPLATE/feature_request.md`:

```markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description

A clear and concise description of what you want to happen.

## Problem Statement

What problem does this feature solve?

## Proposed Solution

Describe the solution you'd like.

## Alternatives Considered

Describe any alternative solutions or features you've considered.

## Additional Context

Add any other context or screenshots about the feature request here.
```

---

## Branch Protection Rules

Configure these settings in GitHub (Settings → Branches → Branch protection rules):

### For `main` branch:

- ✅ Require pull request reviews before merging
  - Required approvals: 2
- ✅ Require status checks to pass before merging
  - Required checks: `backend-test`, `frontend-test`, `lint`
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Do not allow bypassing the above settings
- ✅ Restrict who can push to matching branches
- ✅ Require linear history

### For `develop` branch:

- ✅ Require pull request reviews before merging
  - Required approvals: 1
- ✅ Require status checks to pass before merging
  - Required checks: `backend-test`, `frontend-test`, `lint`
- ✅ Require branches to be up to date before merging
- ✅ Allow force pushes (for rebasing)

---

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

### Examples:

```
feat(payments): add subscription cancellation
fix(auth): resolve JWT token expiration issue
docs(readme): update installation instructions
refactor(api): simplify payment controller logic
test(payments): add unit tests for refund flow
```

---

## Code Review Guidelines

### For Reviewers:

1. Check code quality and adherence to standards
2. Verify tests are included and passing
3. Ensure documentation is updated
4. Look for security vulnerabilities
5. Verify no sensitive data is committed
6. Check for proper error handling
7. Ensure no breaking changes without proper communication

### For Contributors:

1. Keep PRs small and focused
2. Write descriptive commit messages
3. Include tests for new features
4. Update documentation
5. Request review from appropriate team members
6. Address review comments promptly
7. Rebase on latest develop before merging

---

## Release Process

1. **Create release branch from develop**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/v1.0.0
   ```

2. **Update version numbers**
   - Update `package.json` in frontend and backend
   - Update CHANGELOG.md

3. **Final testing**
   - Run all tests
   - Perform manual QA
   - Fix any bugs found

4. **Merge to main**
   ```bash
   git checkout main
   git merge release/v1.0.0
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin main --tags
   ```

5. **Merge back to develop**
   ```bash
   git checkout develop
   git merge release/v1.0.0
   git push origin develop
   ```

6. **Deploy to production**
   - Trigger production deployment
   - Monitor for issues

7. **Create GitHub Release**
   - Go to Releases → Draft a new release
   - Select the tag
   - Add release notes from CHANGELOG
   - Publish release

---

## Helpful Commands

```bash
# View commit history
git log --oneline --graph --all

# Check branch status
git status

# See differences
git diff

# Stash changes
git stash
git stash pop

# Rebase on develop
git checkout feature/my-feature
git rebase develop

# Squash commits
git rebase -i HEAD~3

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

---

## Troubleshooting

### Merge Conflicts

```bash
# Update your branch with latest develop
git checkout develop
git pull origin develop
git checkout feature/my-feature
git rebase develop

# Resolve conflicts in your editor
# Then continue rebase
git add .
git rebase --continue
```

### Failed CI Checks

1. Pull latest changes
2. Run tests locally
3. Fix failing tests
4. Push changes
5. Wait for CI to pass

### Accidentally Committed Secrets

```bash
# Remove file from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/file" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (coordinate with team!)
git push origin --force --all
```

**Important:** Immediately rotate any exposed secrets!

---

## Additional Resources

- [Git Flow Cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
