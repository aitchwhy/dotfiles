"""
Logging configuration for health analysis pipeline.

Provides structured logging with file and console outputs.
"""

import logging
import sys
from datetime import datetime
from pathlib import Path


def setup_logging(
    log_dir: Path | None = None,
    level: int = logging.INFO,
    console: bool = True,
) -> logging.Logger:
    """
    Set up logging for the pipeline.

    Args:
        log_dir: Directory for log files. If None, only console logging.
        level: Logging level (default: INFO)
        console: Whether to log to console (default: True)

    Returns:
        Configured logger
    """
    logger = logging.getLogger("health_analysis")
    logger.setLevel(level)

    # Clear existing handlers
    logger.handlers = []

    # Formatter
    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Console handler
    if console:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(level)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

    # File handler
    if log_dir:
        log_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = log_dir / f"pipeline_{timestamp}.log"

        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.DEBUG)  # Always capture debug to file
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        logger.info(f"Logging to: {log_file}")

    return logger


def get_logger(name: str = "health_analysis") -> logging.Logger:
    """Get a logger instance."""
    return logging.getLogger(name)


class PipelineLogger:
    """Context manager for pipeline stage logging."""

    def __init__(self, stage_name: str, logger: logging.Logger | None = None):
        self.stage_name = stage_name
        self.logger = logger or get_logger()
        self.start_time: datetime | None = None

    def __enter__(self) -> PipelineLogger:
        self.start_time = datetime.now()
        self.logger.info(f"=== STAGE: {self.stage_name} ===")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        if self.start_time:
            duration = (datetime.now() - self.start_time).total_seconds()
            if exc_type:
                self.logger.error(
                    f"Stage {self.stage_name} failed after {duration:.2f}s: {exc_val}"
                )
            else:
                self.logger.info(f"Stage {self.stage_name} completed in {duration:.2f}s")
        return False  # Don't suppress exceptions

    def log(self, message: str, level: int = logging.INFO) -> None:
        """Log a message within the stage."""
        self.logger.log(level, f"[{self.stage_name}] {message}")

    def debug(self, message: str) -> None:
        """Log debug message."""
        self.log(message, logging.DEBUG)

    def info(self, message: str) -> None:
        """Log info message."""
        self.log(message, logging.INFO)

    def warning(self, message: str) -> None:
        """Log warning message."""
        self.log(message, logging.WARNING)

    def error(self, message: str) -> None:
        """Log error message."""
        self.log(message, logging.ERROR)
