#!/usr/bin/env python3
"""
Performance history tracking and analysis utilities.

This module provides tools to:
- Store timestamped performance data from test runs
- Compare current runs against historical data
- Generate trend reports
- Analyze performance over time
"""
import json
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from collections import defaultdict


PERFORMANCE_HISTORY_DIR = Path("tests/.performance_history")
PERFORMANCE_BASELINE_FILE = Path("tests/.performance_baseline.json")


def ensure_history_dir():
    """Ensure the performance history directory exists."""
    PERFORMANCE_HISTORY_DIR.mkdir(parents=True, exist_ok=True)


def save_run_history(current_run: Dict, suite_times: Dict, timestamp: Optional[str] = None):
    """Save performance data from a test run to history.
    
    Args:
        current_run: Dictionary of test_id -> list of run data
        suite_times: Dictionary of suite_name -> total_time
        timestamp: Optional timestamp string (ISO format). If None, uses current time.
    """
    ensure_history_dir()
    
    if timestamp is None:
        timestamp = datetime.now().isoformat()
    
    history_file = PERFORMANCE_HISTORY_DIR / f"run_{timestamp.replace(':', '-').replace('.', '-')}.json"
    
    # Calculate averages for each test
    test_data = {}
    for test_id, runs in current_run.items():
        if isinstance(runs, list) and runs:
            durations = [r.get('duration', 0) for r in runs if isinstance(r, dict)]
            if durations:
                test_data[test_id] = {
                    'avg': sum(durations) / len(durations),
                    'min': min(durations),
                    'max': max(durations),
                    'runs': len(durations),
                    'status': runs[0].get('status', 'unknown')
                }
        elif isinstance(runs, dict) and 'duration' in runs:
            test_data[test_id] = {
                'avg': runs['duration'],
                'min': runs['duration'],
                'max': runs['duration'],
                'runs': 1,
                'status': runs.get('status', 'unknown')
            }
    
    history_data = {
        'timestamp': timestamp,
        'tests': test_data,
        'suites': dict(suite_times),
        'total_tests': len(test_data),
        'total_suites': len(suite_times)
    }
    
    with open(history_file, 'w') as f:
        json.dump(history_data, f, indent=2)
    
    return history_file


def load_history_files(limit: Optional[int] = None) -> List[Dict]:
    """Load historical performance data files.
    
    Args:
        limit: Maximum number of history files to load (most recent first)
    
    Returns:
        List of history data dictionaries, sorted by timestamp (newest first)
    """
    ensure_history_dir()
    
    if not PERFORMANCE_HISTORY_DIR.exists():
        return []
    
    history_files = sorted(
        PERFORMANCE_HISTORY_DIR.glob("run_*.json"),
        key=lambda p: p.stat().st_mtime,
        reverse=True
    )
    
    if limit:
        history_files = history_files[:limit]
    
    history_data = []
    for history_file in history_files:
        try:
            with open(history_file, 'r') as f:
                data = json.load(f)
                data['_file'] = str(history_file)
                history_data.append(data)
        except Exception:
            continue
    
    return history_data


def get_test_trends(test_id: str, limit: int = 10) -> List[Dict]:
    """Get historical trend data for a specific test.
    
    Args:
        test_id: Test identifier (e.g., "test_suites/test_hello_world.py::TestHelloWorldButton::test_button_is_visible")
        limit: Maximum number of historical runs to analyze
    
    Returns:
        List of dictionaries with timestamp and performance data for the test
    """
    history = load_history_files(limit=limit * 2)  # Load more to account for missing tests
    
    trends = []
    for run in history:
        if test_id in run.get('tests', {}):
            test_data = run['tests'][test_id]
            trends.append({
                'timestamp': run['timestamp'],
                'avg': test_data.get('avg', 0),
                'min': test_data.get('min', 0),
                'max': test_data.get('max', 0),
                'runs': test_data.get('runs', 1)
            })
    
    return trends[:limit]


def compare_with_baseline(current_run: Dict) -> Dict:
    """Compare current run data against baseline.
    
    Args:
        current_run: Dictionary of test_id -> list of run data
    
    Returns:
        Dictionary with comparison results
    """
    if not PERFORMANCE_BASELINE_FILE.exists():
        return {'baseline_exists': False}
    
    try:
        with open(PERFORMANCE_BASELINE_FILE, 'r') as f:
            baseline = json.load(f)
    except Exception:
        return {'baseline_exists': False, 'error': 'Failed to load baseline'}
    
    comparisons = {}
    for test_id, runs in current_run.items():
        if test_id not in baseline:
            comparisons[test_id] = {'status': 'new_test', 'baseline': None}
            continue
        
        # Calculate current average
        if isinstance(runs, list) and runs:
            durations = [r.get('duration', 0) for r in runs if isinstance(r, dict)]
            if durations:
                current_avg = sum(durations) / len(durations)
            else:
                continue
        elif isinstance(runs, dict) and 'duration' in runs:
            current_avg = runs['duration']
        else:
            continue
        
        baseline_avg = baseline[test_id].get('avg', baseline[test_id].get('max', 0))
        
        if baseline_avg == 0:
            comparisons[test_id] = {'status': 'no_baseline', 'baseline': 0}
            continue
        
        ratio = current_avg / baseline_avg
        percent_change = (ratio - 1) * 100
        
        comparisons[test_id] = {
            'status': 'compared',
            'current': current_avg,
            'baseline': baseline_avg,
            'ratio': ratio,
            'percent_change': percent_change,
            'faster': ratio < 1.0,
            'slower': ratio > 1.0
        }
    
    return {
        'baseline_exists': True,
        'comparisons': comparisons,
        'total_tests': len(comparisons),
        'new_tests': sum(1 for c in comparisons.values() if c.get('status') == 'new_test'),
        'improved': sum(1 for c in comparisons.values() if c.get('faster', False)),
        'regressed': sum(1 for c in comparisons.values() if c.get('slower', False) and c.get('ratio', 1) > 1.5)
    }


def generate_trend_report(test_id: Optional[str] = None, limit: int = 10) -> str:
    """Generate a text report of performance trends.
    
    Args:
        test_id: Optional specific test to analyze. If None, analyzes all tests.
        limit: Number of historical runs to include
    
    Returns:
        Formatted text report
    """
    history = load_history_files(limit=limit)
    
    if not history:
        return "No performance history found. Run tests with performance tracking enabled."
    
    lines = []
    lines.append("=" * 80)
    lines.append("PERFORMANCE TREND REPORT")
    lines.append("=" * 80)
    lines.append(f"Analyzing {len(history)} historical runs")
    lines.append(f"Most recent run: {history[0]['timestamp']}")
    lines.append(f"Oldest run: {history[-1]['timestamp']}")
    lines.append("")
    
    if test_id:
        # Single test analysis
        trends = get_test_trends(test_id, limit=limit)
        if not trends:
            return f"No historical data found for test: {test_id}"
        
        lines.append(f"Test: {test_id}")
        lines.append("-" * 80)
        lines.append(f"{'Run':<20} {'Avg (s)':<12} {'Min (s)':<12} {'Max (s)':<12} {'Change':<12}")
        lines.append("-" * 80)
        
        prev_avg = None
        for trend in trends:
            change = ""
            if prev_avg is not None:
                change_pct = ((trend['avg'] - prev_avg) / prev_avg) * 100
                change = f"{change_pct:+.1f}%"
            
            lines.append(
                f"{trend['timestamp'][:19]:<20} "
                f"{trend['avg']:<12.3f} "
                f"{trend['min']:<12.3f} "
                f"{trend['max']:<12.3f} "
                f"{change:<12}"
            )
            prev_avg = trend['avg']
        
        # Calculate overall trend
        if len(trends) >= 2:
            first_avg = trends[-1]['avg']
            last_avg = trends[0]['avg']
            overall_change = ((last_avg - first_avg) / first_avg) * 100
            lines.append("")
            lines.append(f"Overall trend: {overall_change:+.1f}% ({'faster' if overall_change < 0 else 'slower'})")
    
    else:
        # Suite-level analysis
        suite_times_by_run = defaultdict(list)
        for run in history:
            for suite, time in run.get('suites', {}).items():
                suite_times_by_run[suite].append({
                    'timestamp': run['timestamp'],
                    'time': time
                })
        
        lines.append("Suite Performance Trends:")
        lines.append("-" * 80)
        
        for suite, times in sorted(suite_times_by_run.items()):
            if len(times) < 2:
                continue
            
            times.sort(key=lambda x: x['timestamp'])
            first_time = times[0]['time']
            last_time = times[-1]['time']
            change_pct = ((last_time - first_time) / first_time) * 100
            
            lines.append(f"{suite}:")
            lines.append(f"  First run: {first_time:.2f}s ({times[0]['timestamp'][:19]})")
            lines.append(f"  Last run:  {last_time:.2f}s ({times[-1]['timestamp'][:19]})")
            lines.append(f"  Change:    {change_pct:+.1f}% ({'faster' if change_pct < 0 else 'slower'})")
            lines.append("")
    
    return "\n".join(lines)


def list_slowest_tests(limit: int = 10, history_limit: int = 5) -> List[Dict]:
    """List the slowest tests based on recent history.
    
    Args:
        limit: Number of slowest tests to return
        history_limit: Number of recent runs to analyze
    
    Returns:
        List of test information dictionaries, sorted by average time (slowest first)
    """
    history = load_history_files(limit=history_limit)
    
    test_times = defaultdict(list)
    for run in history:
        for test_id, test_data in run.get('tests', {}).items():
            test_times[test_id].append(test_data.get('avg', 0))
    
    # Calculate average for each test
    test_averages = []
    for test_id, times in test_times.items():
        if times:
            test_averages.append({
                'test_id': test_id,
                'avg': sum(times) / len(times),
                'min': min(times),
                'max': max(times),
                'runs': len(times)
            })
    
    test_averages.sort(key=lambda x: x['avg'], reverse=True)
    return test_averages[:limit]
