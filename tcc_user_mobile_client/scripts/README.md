# TCC Compliance Task Scripts

Scripts to automate App Store compliance tasks using Claude Code.

## Prerequisites

- Claude Code CLI installed (`claude` command available)
- Firebase CLI installed (for deployment)
- Logged into Firebase (`firebase login`)

## Scripts

### 1. `run_compliance_parallel.sh` (Recommended)

Full-featured parallel executor with auto-continue support.

```bash
# Run all automated tasks
./run_compliance_parallel.sh

# Reset state (start fresh)
./run_compliance_parallel.sh --reset

# Check completion status
./run_compliance_parallel.sh --status
```

**Features:**
- Runs 4 tasks in parallel (Wave 1)
- Auto-continues from last checkpoint if interrupted
- Color-coded output with progress tracking
- Detailed logs in `logs/` directory

### 2. `quick_run.sh`

Simple task runner for individual or all tasks.

```bash
# Run specific task
./quick_run.sh api      # Add delete account API
./quick_run.sh ui       # Add deletion UI
./quick_run.sh privacy  # Create privacy policy
./quick_run.sh terms    # Create terms of service
./quick_run.sh support  # Create support page
./quick_run.sh deploy   # Deploy to Firebase

# Run all tasks
./quick_run.sh all
```

### 3. `run_compliance_tasks.sh`

Original detailed executor with comprehensive prompts.

```bash
./run_compliance_tasks.sh
```

## Task Execution Order

```
WAVE 1 (Parallel):
├── T5: Delete Account API
├── T9: Privacy Policy
├── T10: Terms of Service
└── T11: Support Page

WAVE 2 (Sequential):
└── T6-8: Deletion UI

WAVE 3 (Sequential):
└── T12: Firebase Deploy
```

## Auto-Continue

If interrupted (Ctrl+C), the script saves state. Simply re-run to continue:

```bash
# First run (interrupted)
./run_compliance_parallel.sh
^C  # Interrupted

# Continue from where it stopped
./run_compliance_parallel.sh
```

## Manual Tasks

These tasks cannot be automated and require human action:

| Task | Description |
|------|-------------|
| #13 | Verify Apple Developer account is Organization type |
| #14 | Gather financial regulatory licenses |
| #15 | Create demo account (appreview@tcc.com) |
| #16 | Complete KYC verification for demo account |
| #17 | Add wallet balance to demo account |
| #18 | Document credentials in App Store Connect |

## Logs

All task logs are saved to `scripts/logs/`:

```
logs/
├── T5_143022.log      # Delete API task
├── T9_143022.log      # Privacy policy task
├── T10_143023.log     # Terms task
├── T11_143023.log     # Support task
├── T6-8_143145.log    # UI task
└── T12_143302.log     # Deploy task
```

## Troubleshooting

**Task fails:**
```bash
# Check the log file
cat scripts/logs/T5_*.log

# Re-run just that task
./quick_run.sh api
```

**Permission denied:**
```bash
chmod +x scripts/*.sh
```

**Claude not found:**
```bash
# Ensure Claude Code is installed
which claude
```

**Firebase deploy fails:**
```bash
# Login to Firebase
firebase login

# Check project
firebase projects:list
```
