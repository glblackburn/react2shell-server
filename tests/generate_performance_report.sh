#!/bin/bash
#
# Generate a comprehensive performance history report
#
# This script generates an HTML performance report with all metrics,
# trends, and limits based on collected performance history.
#
# Usage:
#   ./generate_performance_report.sh
#   or
#   make test-performance-report
#

set -euET -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_BIN="$PROJECT_ROOT/venv/bin"

cd "$SCRIPT_DIR"

# Check if venv exists
if [ ! -d "$PROJECT_ROOT/venv" ]; then
    echo "ERROR: Virtual environment not found. Run 'make test-setup' first." >&2
    exit 1
fi

echo "📊 Generating Performance History Report..."
echo ""

# Generate the report using Python
"$VENV_BIN/python3" << 'PYTHON_SCRIPT'
import sys
import os
import yaml
from pathlib import Path
from utils.performance_history import (
    load_history_files, generate_trend_report, compare_with_baseline,
    list_slowest_tests
)

# Load performance config
config_file = Path('performance_config.yaml')
config = {}
if config_file.exists():
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f) or {}

limits = config.get('limits', {})
suite_limits = limits.get('suites', {})
default_limit = limits.get('default', 30)
test_limits = limits.get('tests', {})  # Individual test limits

history = load_history_files(limit=50)

if history:
    # Generate comprehensive report with limits
    report_html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Performance History Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .section { background: white; padding: 25px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h2 { color: #667eea; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
        pre { background: #f8f9fa; border: 1px solid #e9ecef; border-radius: 5px; padding: 15px; overflow-x: auto; font-size: 0.9em; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #667eea; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .positive { color: #28a745; }
        .negative { color: #dc3545; }
        .warning { color: #ffc107; }
        .over-limit { background-color: #ffe6e6; }
        .individual-limit { font-weight: bold; color: #667eea; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Performance History Report</h1>
        <p>Generated: """ + str(history[0]['timestamp'] if history else 'N/A') + """</p>
        <p>Total Runs: """ + str(len(history)) + """ | Individual Test Limits: """ + str(len(test_limits)) + """</p>
    </div>
"""

    # Summary section
    if history:
        report_html += """
    <div class="section">
        <h2>📈 Recent Test Runs</h2>
        <table>
            <tr><th>Timestamp</th><th>Total Tests</th><th>Total Suites</th><th>Total Time</th></tr>
"""
        for run in history[:20]:
            total_time = sum(run.get('suites', {}).values())
            report_html += f"<tr><td>{run['timestamp'][:19]}</td><td>{run.get('total_tests', 0)}</td><td>{run.get('total_suites', 0)}</td><td>{total_time:.2f}s</td></tr>\n"
        report_html += "</table></div>\n"

    # Suite performance with limits
    if history:
        suite_times = {}
        for run in history:
            for suite, time in run.get('suites', {}).items():
                if suite not in suite_times:
                    suite_times[suite] = []
                suite_times[suite].append(time)
        
        if suite_times:
            report_html += """
    <div class="section">
        <h2>📊 Suite Performance Trends</h2>
        <table>
            <tr><th>Suite</th><th>Avg Time</th><th>Min</th><th>Max</th><th>Limit</th><th>Runs</th><th>Trend</th><th>Status</th></tr>
"""
            for suite, times in sorted(suite_times.items()):
                avg = sum(times) / len(times)
                first = times[-1] if len(times) > 0 else 0
                last = times[0] if len(times) > 0 else 0
                change_pct = ((last - first) / first * 100) if first > 0 else 0
                trend_class = "positive" if change_pct < 0 else "negative"
                trend_arrow = "↓" if change_pct < 0 else "↑"
                
                # Get limit for this suite
                suite_limit = suite_limits.get(suite, default_limit)
                status = ""
                row_class = ""
                if avg > suite_limit:
                    status = "❌ Over Limit"
                    row_class = "over-limit"
                elif avg > suite_limit * 0.8:
                    status = "⚠️ Near Limit"
                    row_class = "warning"
                else:
                    status = "✅ OK"
                
                report_html += f"<tr class=\"{row_class}\"><td>{suite}</td><td>{avg:.2f}s</td><td>{min(times):.2f}s</td><td>{max(times):.2f}s</td><td>{suite_limit}s</td><td>{len(times)}</td><td class=\"{trend_class}\">{trend_arrow} {abs(change_pct):.1f}%</td><td>{status}</td></tr>\n"
            report_html += "</table></div>\n"

    # Slowest tests with individual limits
    slowest = list_slowest_tests(limit=30)
    if slowest:
        report_html += """
    <div class="section">
        <h2>🐌 Slowest Tests (with Individual Limits)</h2>
        <table>
            <tr><th>Test</th><th>Avg (s)</th><th>Min (s)</th><th>Max (s)</th><th>Limit (s)</th><th>Runs</th><th>Status</th></tr>
"""
        for test in slowest:
            test_id = test['test_id']
            test_name = test_id.split('::')[-1] if '::' in test_id else test_id
            if len(test_name) > 60:
                test_name = test_name[:57] + "..."
            
            # Get individual test limit, or fall back to category-based limit
            test_limit = test_limits.get(test_id)  # Individual test limit
            limit_source = "individual"
            if not test_limit:
                # Fall back to category-based limits
                limit_source = "category"
                if 'smoke' in test_id.lower():
                    test_limit = limits.get('smoke', 10)
                elif 'slow' in test_id.lower():
                    test_limit = limits.get('slow', 60)
                elif 'version_switch' in test_id.lower() or 'security_status' in test_id.lower():
                    test_limit = limits.get('version_switch', 120)
                else:
                    test_limit = default_limit
            
            status = ""
            row_class = ""
            if test['avg'] > test_limit:
                status = "❌ Over Limit"
                row_class = "over-limit"
            elif test['avg'] > test_limit * 0.8:
                status = "⚠️ Near Limit"
                row_class = "warning"
            else:
                status = "✅ OK"
            
            limit_class = "individual-limit" if limit_source == "individual" else ""
            limit_display = f"<span class=\"{limit_class}\">{test_limit}</span>"
            
            report_html += f"<tr class=\"{row_class}\"><td>{test_name}</td><td>{test['avg']:.3f}</td><td>{test['min']:.3f}</td><td>{test['max']:.3f}</td><td>{limit_display}</td><td>{test['runs']}</td><td>{status}</td></tr>\n"
        report_html += "</table>"
        report_html += "<p><em>Note: Limits in <span class='individual-limit'>blue/bold</span> are individual test limits. Others use category-based limits.</em></p>"
        report_html += "</div>\n"

    # Trend report
    trend_text = generate_trend_report(limit=10)
    if trend_text and "No performance history" not in trend_text:
        trend_text_escaped = trend_text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        report_html += f"""
    <div class="section">
        <h2>📈 Performance Trends</h2>
        <pre>{trend_text_escaped}</pre>
    </div>
"""

    # Baseline comparison
    if history:
        latest = history[0]
        current_run = {}
        for test_id, test_data in latest.get('tests', {}).items():
            current_run[test_id] = [{'duration': test_data.get('avg', 0), 'status': test_data.get('status', 'passed')}]
        
        comparison = compare_with_baseline(current_run)
        if comparison.get('baseline_exists'):
            report_html += f"""
    <div class="section">
        <h2>⚖️ Baseline Comparison</h2>
        <p><strong>Total tests:</strong> {comparison.get('total_tests', 0)}</p>
        <p><strong>New tests:</strong> {comparison.get('new_tests', 0)}</p>
        <p><strong>Improved:</strong> {comparison.get('improved', 0)}</p>
        <p><strong>Regressed (>50% slower):</strong> {comparison.get('regressed', 0)}</p>
"""
            regressions = [
                (test_id, data) for test_id, data in comparison.get('comparisons', {}).items()
                if data.get('slower', False) and data.get('ratio', 1) > 1.5
            ]
            if regressions:
                report_html += """
        <h3>❌ Performance Regressions</h3>
        <table>
            <tr><th>Test</th><th>Current</th><th>Baseline</th><th>Slower By</th></tr>
"""
                for test_id, data in regressions[:10]:
                    test_name = test_id.split('::')[-1] if '::' in test_id else test_id
                    if len(test_name) > 50:
                        test_name = test_name[:47] + "..."
                    report_html += f"<tr><td>{test_name}</td><td>{data['current']:.3f}s</td><td>{data['baseline']:.3f}s</td><td class=\"negative\">{data['percent_change']:.1f}%</td></tr>\n"
                report_html += "</table>"
            report_html += "</div>\n"

    report_html += """
</body>
</html>
"""

    # Save report
    report_path = Path('reports/performance_history_report.html')
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, 'w') as f:
        f.write(report_html)
    
    abs_path = report_path.absolute()
    print(f"✅ Performance history report generated: {abs_path}")
    print(f"   Opening in browser...")
    
    import subprocess
    subprocess.run(['open', str(abs_path)])
else:
    print("❌ No performance history found.")
    print("   Run tests first to collect performance data:")
    print("   make test-smoke")
    print("   or")
    print("   make test-parallel")
PYTHON_SCRIPT
