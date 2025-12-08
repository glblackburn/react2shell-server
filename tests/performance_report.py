#!/usr/bin/env python3
"""
Performance report generator and trend analyzer.

Usage:
    python3 performance_report.py [command] [options]

Commands:
    trends [test_id]     - Show performance trends (optionally for specific test)
    compare              - Compare latest run against baseline
    slowest [limit]      - List slowest tests
    history [limit]      - List recent performance history
    summary              - Show summary of recent runs
"""
import sys
import argparse
from pathlib import Path

# Add tests directory to path
sys.path.insert(0, str(Path(__file__).parent))

from utils.performance_history import (
    load_history_files,
    get_test_trends,
    compare_with_baseline,
    generate_trend_report,
    list_slowest_tests
)


def cmd_trends(test_id=None, limit=10):
    """Show performance trends."""
    report = generate_trend_report(test_id=test_id, limit=limit)
    print(report)


def cmd_compare():
    """Compare latest run against baseline."""
    history = load_history_files(limit=1)
    if not history:
        print("No performance history found.")
        return
    
    latest = history[0]
    current_run = {}
    for test_id, test_data in latest.get('tests', {}).items():
        # Convert back to format expected by compare_with_baseline
        current_run[test_id] = [{'duration': test_data.get('avg', 0), 'status': test_data.get('status', 'passed')}]
    
    comparison = compare_with_baseline(current_run)
    
    if not comparison.get('baseline_exists'):
        print("No baseline found. Run 'make test-update-baseline' to create one.")
        return
    
    print("=" * 80)
    print("PERFORMANCE COMPARISON: Latest Run vs Baseline")
    print("=" * 80)
    print(f"Total tests: {comparison.get('total_tests', 0)}")
    print(f"New tests: {comparison.get('new_tests', 0)}")
    print(f"Improved: {comparison.get('improved', 0)}")
    print(f"Regressed (>50% slower): {comparison.get('regressed', 0)}")
    print()
    
    # Show regressions
    regressions = [
        (test_id, data) for test_id, data in comparison.get('comparisons', {}).items()
        if data.get('slower', False) and data.get('ratio', 1) > 1.5
    ]
    if regressions:
        print("❌ Performance Regressions (>50% slower):")
        for test_id, data in regressions:
            print(f"  {test_id}")
            print(f"    Current: {data['current']:.3f}s")
            print(f"    Baseline: {data['baseline']:.3f}s")
            print(f"    Slower by: {data['percent_change']:.1f}%")
        print()
    
    # Show improvements
    improvements = [
        (test_id, data) for test_id, data in comparison.get('comparisons', {}).items()
        if data.get('faster', False)
    ]
    if improvements:
        print("✓ Performance Improvements:")
        for test_id, data in improvements[:5]:  # Show top 5
            print(f"  {test_id}: {abs(data['percent_change']):.1f}% faster")
        if len(improvements) > 5:
            print(f"  ... and {len(improvements) - 5} more")
        print()


def cmd_slowest(limit=10):
    """List slowest tests."""
    slowest = list_slowest_tests(limit=limit)
    
    print("=" * 80)
    print(f"SLOWEST {limit} TESTS (based on recent history)")
    print("=" * 80)
    print(f"{'Test':<60} {'Avg (s)':<12} {'Min (s)':<10} {'Max (s)':<10}")
    print("-" * 80)
    
    for test in slowest:
        test_name = test['test_id'].split('::')[-1] if '::' in test['test_id'] else test['test_id']
        if len(test_name) > 58:
            test_name = test_name[:55] + "..."
        print(f"{test_name:<60} {test['avg']:<12.3f} {test['min']:<10.3f} {test['max']:<10.3f}")


def cmd_history(limit=10):
    """List recent performance history."""
    history = load_history_files(limit=limit)
    
    if not history:
        print("No performance history found.")
        return
    
    print("=" * 80)
    print(f"RECENT PERFORMANCE HISTORY ({len(history)} runs)")
    print("=" * 80)
    print(f"{'Timestamp':<25} {'Tests':<8} {'Suites':<8} {'Total Time':<12}")
    print("-" * 80)
    
    for run in history:
        total_time = sum(run.get('suites', {}).values())
        print(
            f"{run['timestamp'][:19]:<25} "
            f"{run.get('total_tests', 0):<8} "
            f"{run.get('total_suites', 0):<8} "
            f"{total_time:<12.2f}s"
        )


def cmd_summary(limit=5):
    """Show summary of recent runs."""
    history = load_history_files(limit=limit)
    
    if not history:
        print("No performance history found.")
        return
    
    print("=" * 80)
    print("PERFORMANCE SUMMARY")
    print("=" * 80)
    print(f"Analyzing {len(history)} recent runs")
    print()
    
    # Suite summary
    suite_times_by_run = {}
    for run in history:
        for suite, time in run.get('suites', {}).items():
            if suite not in suite_times_by_run:
                suite_times_by_run[suite] = []
            suite_times_by_run[suite].append(time)
    
    if suite_times_by_run:
        print("Suite Performance (average over recent runs):")
        print("-" * 80)
        for suite, times in sorted(suite_times_by_run.items()):
            avg_time = sum(times) / len(times)
            min_time = min(times)
            max_time = max(times)
            print(f"  {suite}:")
            print(f"    Avg: {avg_time:.2f}s  Min: {min_time:.2f}s  Max: {max_time:.2f}s")
        print()
    
    # Test count summary
    total_tests = sum(run.get('total_tests', 0) for run in history)
    avg_tests = total_tests / len(history) if history else 0
    print(f"Average tests per run: {avg_tests:.1f}")
    print(f"Total test executions: {total_tests}")


def main():
    parser = argparse.ArgumentParser(description='Performance report generator')
    subparsers = parser.add_subparsers(dest='command', help='Command to run')
    
    # Trends command
    trends_parser = subparsers.add_parser('trends', help='Show performance trends')
    trends_parser.add_argument('test_id', nargs='?', help='Optional test ID to analyze')
    trends_parser.add_argument('--limit', type=int, default=10, help='Number of runs to analyze')
    
    # Compare command
    subparsers.add_parser('compare', help='Compare latest run against baseline')
    
    # Slowest command
    slowest_parser = subparsers.add_parser('slowest', help='List slowest tests')
    slowest_parser.add_argument('--limit', type=int, default=10, help='Number of tests to show')
    
    # History command
    history_parser = subparsers.add_parser('history', help='List recent performance history')
    history_parser.add_argument('--limit', type=int, default=10, help='Number of runs to show')
    
    # Summary command
    summary_parser = subparsers.add_parser('summary', help='Show summary of recent runs')
    summary_parser.add_argument('--limit', type=int, default=5, help='Number of runs to analyze')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    try:
        if args.command == 'trends':
            cmd_trends(test_id=args.test_id, limit=args.limit)
        elif args.command == 'compare':
            cmd_compare()
        elif args.command == 'slowest':
            cmd_slowest(limit=args.limit)
        elif args.command == 'history':
            cmd_history(limit=args.limit)
        elif args.command == 'summary':
            cmd_summary(limit=args.limit)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
