"""Logging helpers for the foundation learning chapters."""

from __future__ import annotations

import logging
from typing import TextIO

from .config import ALLOWED_LOG_LEVELS, AppConfig


DEFAULT_LOGGER_NAME = "enterprise_agent"
LOG_FORMAT = "%(levelname)s:%(name)s:%(message)s"


def configure_logging(
    config: AppConfig,
    logger_name: str = DEFAULT_LOGGER_NAME,
    stream: TextIO | None = None,
) -> logging.Logger:
    """Configure and return the project logger."""

    level_name = config.log_level.strip().upper()
    if level_name not in ALLOWED_LOG_LEVELS:
        allowed = ", ".join(ALLOWED_LOG_LEVELS)
        raise ValueError(format_error_message("log_level", f"must be one of: {allowed}"))

    logger = logging.getLogger(logger_name)
    logger.setLevel(getattr(logging, level_name))
    logger.handlers.clear()

    handler = logging.StreamHandler(stream)
    handler.setLevel(logger.level)
    handler.setFormatter(logging.Formatter(LOG_FORMAT))
    logger.addHandler(handler)
    logger.propagate = False

    return logger


def format_error_message(field: str, problem: str) -> str:
    """Return a short, consistent error message."""

    clean_field = field.strip()
    clean_problem = problem.strip()

    if not clean_field:
        raise ValueError("field must not be empty")
    if not clean_problem:
        raise ValueError("problem must not be empty")

    return f"{clean_field} {clean_problem}"
