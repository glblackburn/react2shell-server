# Design: Single Run for Performance Tests (Eliminate Duplicate Run and Extra History File)

## Problem

`make test-performance` currently runs pytest **twice** when updating the baseline:

1. **Step 1:** `PYTEST_SAVE_HISTORY=true pytest ...` — run tests, save history, check regressions.
2. **Step 2:** If `UPDATE_BASELINE=true` or baseline missing: `PYTEST_UPDATE_BASELINE=true PYTEST_SAVE_HISTORY=true pytest ...` — run tests again, save baseline and history.

That causes:

- Duplicate test execution (double time when baseline is updated).
- Two history files per `make test-performance` (one per run).
- Redundant work: the same run could both record history and update the baseline.

## Goal

- One pytest run per `make test-performance`.
- One history file per run when baseline is updated.
- Baseline still updated when `UPDATE_BASELINE=true` or when `tests/.performance_baseline.json` is missing.

## Design: Single Run with Conditional Baseline Update

### Idea

The baseline is updated in **pytest_sessionfinish** when `PYTEST_UPDATE_BASELINE=true`. There is no need for a separate run; we only need to set that env var in the **same** run when we want to update the baseline.

So:

- **One run:** Run pytest once per `make test-performance`.
- **Env for that run:** Set `PYTEST_SAVE_HISTORY=true` always; set `PYTEST_UPDATE_BASELINE=true` only when we want to update the baseline (user requested or baseline missing).
- **Result:** One history file; baseline is updated at session end when requested.

### Makefile Changes

**Current (two runs when updating baseline):**

```make
echo "Step 1: Running performance tests..."; \
PYTEST_SAVE_HISTORY=true $(PYTEST) $(TEST_DIR)/ -v || true; \
echo ""; \
if [ "$$UPDATE_BASELINE" = "true" ] || [ ! -f tests/.performance_baseline.json ]; then \
	echo "Step 2: Updating performance baseline..."; \
	PYTEST_UPDATE_BASELINE=true PYTEST_SAVE_HISTORY=true $(PYTEST) $(TEST_DIR)/ -v || true; \
	echo "✓ Performance baseline updated!"; \
else \
	echo "Step 2: Baseline exists, skipping update (set UPDATE_BASELINE=true to force update)"; \
fi; \
echo ""; \
echo "Step 3: Generating comprehensive performance report..."; \
...
echo "Step 4: Performance Summary:"; \
```

**New (single run; baseline update in same run):**

```make
echo "Step 1: Running performance tests..."; \
if [ "$$UPDATE_BASELINE" = "true" ] || [ ! -f tests/.performance_baseline.json ]; then \
	echo "  (Baseline will be updated at end of run)"; \
	PYTEST_SAVE_HISTORY=true PYTEST_UPDATE_BASELINE=true $(PYTEST) $(TEST_DIR)/ -v || true; \
	[ -f tests/.performance_baseline.json ] && echo "✓ Performance baseline updated!"; \
else \
	PYTEST_SAVE_HISTORY=true $(PYTEST) $(TEST_DIR)/ -v || true; \
fi; \
echo ""; \
echo "Step 2: Generating comprehensive performance report..."; \
...
echo "Step 3: Performance Summary:"; \
```

- **Step 1:** Single pytest invocation. If we need to update the baseline, set `PYTEST_UPDATE_BASELINE=true` for that run; plugin writes baseline in `pytest_sessionfinish`. Otherwise run with `PYTEST_SAVE_HISTORY=true` only.
- **Step 2:** Generate report (current Step 3).
- **Step 3:** Summary (current Step 4).

No second pytest run; step numbers after Step 1 shift down by one.

### Plugin Behavior (Unchanged)

- `pytest_sessionfinish`: if `PYTEST_UPDATE_BASELINE=true` and tracker has data, call `tracker.save_baseline()` and write `tests/.performance_baseline.json`.
- No plugin code change required; only Makefile logic.

### Outcomes

| Aspect              | Before (when updating baseline) | After                    |
|---------------------|----------------------------------|--------------------------|
| Pytest runs         | 2                                | 1                        |
| History files       | 2                                | 1                        |
| Baseline update     | Second run                       | Same run (sessionfinish) |
| Total test time     | ~2×                              | ~1×                      |

### Edge Cases

1. **Step 1 killed (e.g. SIGKILL):** History may be partial (timestamped file); baseline is not updated (sessionfinish never ran). Same as today for the first run.
2. **UPDATE_BASELINE=true:** One run with both env vars; baseline updated at end. Single history file.
3. **Baseline missing:** Treated like UPDATE_BASELINE=true; one run updates baseline and writes one history file.
4. **Baseline exists, UPDATE_BASELINE unset:** One run, history only; no baseline write.

### Docs / Help Text

- Update `make test-performance` help and any docs that say "Step 2: Updating performance baseline" (separate run) to describe a single run with optional baseline update.
- PERFORMANCE_TRACKING.md: mention that baseline is updated in the same run when requested, so there is only one run and one history file per `make test-performance`.

### Implementation Checklist

- [x] Makefile: single pytest invocation in Step 1; set `PYTEST_UPDATE_BASELINE=true` when `UPDATE_BASELINE=true` or baseline file missing; print "Baseline will be updated at end of run" when so; after run, print "✓ Performance baseline updated!" if baseline file exists.
- [x] Makefile: rename "Step 3" → "Step 2", "Step 4" → "Step 3".
- [x] README / PERFORMANCE_TRACKING.md: describe single-run flow and that baseline is updated at end of run when requested.
- [x] No plugin changes (optional: add a one-line comment in sessionfinish that baseline update makes a second run unnecessary).
