"""
WebDriver driver caching and management utility.

This module provides functions to pre-install and cache browser drivers
to avoid network downloads during test execution.
"""
import os
import sys
import logging
from pathlib import Path

logger = logging.getLogger(__name__)


def get_driver_cache_dir():
    """Get the webdriver-manager cache directory."""
    return Path.home() / ".wdm"


def check_chrome_driver_cached():
    """Check if Chrome driver is already cached."""
    cache_dir = get_driver_cache_dir()
    if not cache_dir.exists():
        return False
    
    # Check for chromedriver in cache
    # webdriver-manager stores drivers in cache_dir/drivers/chromedriver/
    chromedriver_dir = cache_dir / "drivers" / "chromedriver"
    if chromedriver_dir.exists():
        # Check if any version is cached
        for item in chromedriver_dir.iterdir():
            if item.is_dir():
                # Check if driver executable exists
                driver_exe = item / "chromedriver"
                if driver_exe.exists() and driver_exe.is_file():
                    return True
                # Windows executable
                driver_exe = item / "chromedriver.exe"
                if driver_exe.exists() and driver_exe.is_file():
                    return True
    
    return False


def check_firefox_driver_cached():
    """Check if Firefox driver (geckodriver) is already cached."""
    cache_dir = get_driver_cache_dir()
    if not cache_dir.exists():
        return False
    
    # Check for geckodriver in cache
    geckodriver_dir = cache_dir / "drivers" / "geckodriver"
    if geckodriver_dir.exists():
        # Check if any version is cached
        for item in geckodriver_dir.iterdir():
            if item.is_dir():
                # Check if driver executable exists
                driver_exe = item / "geckodriver"
                if driver_exe.exists() and driver_exe.is_file():
                    return True
                # Windows executable
                driver_exe = item / "geckodriver.exe"
                if driver_exe.exists() and driver_exe.is_file():
                    return True
    
    return False


def install_chrome_driver(force=False):
    """Install and cache Chrome driver."""
    try:
        from webdriver_manager.chrome import ChromeDriverManager
        
        if not force and check_chrome_driver_cached():
            logger.info("Chrome driver already cached, skipping download")
            # Still call install() to get the path, but it will use cache
            driver_path = ChromeDriverManager().install()
            logger.info(f"Using cached Chrome driver: {driver_path}")
            return True
        
        logger.info("Installing Chrome driver (this may take a moment)...")
        driver_path = ChromeDriverManager().install()
        logger.info(f"Chrome driver installed: {driver_path}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to install Chrome driver: {e}")
        return False


def install_firefox_driver(force=False):
    """Install and cache Firefox driver (geckodriver)."""
    try:
        from webdriver_manager.firefox import GeckoDriverManager
        
        if not force and check_firefox_driver_cached():
            logger.info("Firefox driver already cached, skipping download")
            # Still call install() to get the path, but it will use cache
            driver_path = GeckoDriverManager().install()
            logger.info(f"Using cached Firefox driver: {driver_path}")
            return True
        
        logger.info("Installing Firefox driver (this may take a moment)...")
        driver_path = GeckoDriverManager().install()
        logger.info(f"Firefox driver installed: {driver_path}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to install Firefox driver: {e}")
        return False


def install_all_drivers(force=False):
    """Install all browser drivers."""
    results = {}
    results['chrome'] = install_chrome_driver(force=force)
    results['firefox'] = install_firefox_driver(force=force)
    return results


def clean_driver_cache():
    """Remove all cached drivers."""
    cache_dir = get_driver_cache_dir()
    if cache_dir.exists():
        import shutil
        try:
            shutil.rmtree(cache_dir)
            logger.info(f"Cleaned driver cache: {cache_dir}")
            return True
        except Exception as e:
            logger.error(f"Failed to clean driver cache: {e}")
            return False
    else:
        logger.info("No driver cache found to clean")
        return True


def upgrade_drivers():
    """Upgrade drivers by cleaning cache and reinstalling."""
    logger.info("Upgrading drivers (cleaning cache and reinstalling)...")
    if clean_driver_cache():
        return install_all_drivers(force=True)
    return {'chrome': False, 'firefox': False}


def get_driver_status():
    """Get status of cached drivers."""
    status = {
        'chrome_cached': check_chrome_driver_cached(),
        'firefox_cached': check_firefox_driver_cached(),
        'cache_dir': str(get_driver_cache_dir()),
        'cache_exists': get_driver_cache_dir().exists()
    }
    return status


def main():
    """CLI entry point for driver management."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Manage WebDriver driver cache')
    parser.add_argument('action', choices=['install', 'clean', 'upgrade', 'status'],
                       help='Action to perform')
    parser.add_argument('--browser', choices=['chrome', 'firefox', 'all'],
                       default='all', help='Browser driver to manage')
    parser.add_argument('--force', action='store_true',
                       help='Force reinstall even if cached')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')
    
    args = parser.parse_args()
    
    # Configure logging
    level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(levelname)s: %(message)s'
    )
    
    if args.action == 'status':
        status = get_driver_status()
        print("Driver Cache Status:")
        print(f"  Cache directory: {status['cache_dir']}")
        print(f"  Cache exists: {status['cache_exists']}")
        print(f"  Chrome driver cached: {status['chrome_cached']}")
        print(f"  Firefox driver cached: {status['firefox_cached']}")
        sys.exit(0)
    
    elif args.action == 'install':
        if args.browser == 'chrome':
            success = install_chrome_driver(force=args.force)
        elif args.browser == 'firefox':
            success = install_firefox_driver(force=args.force)
        else:
            results = install_all_drivers(force=args.force)
            success = all(results.values())
        
        sys.exit(0 if success else 1)
    
    elif args.action == 'clean':
        success = clean_driver_cache()
        sys.exit(0 if success else 1)
    
    elif args.action == 'upgrade':
        results = upgrade_drivers()
        success = all(results.values())
        sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
