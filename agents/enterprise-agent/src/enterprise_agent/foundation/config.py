import os
from dataclasses import dataclass
from typing import Mapping


DEFAULT_APP_NAME = "enterprise-agent"
DEFAULT_ENVIRONMENT = "development"
DEFAULT_LOG_LEVEL = "INFO"
DEFAULT_MODEL = "mock-chat"
DEFAULT_TOKEN_BUDGET = 100_000

ENV_VAR_APP_NAME = "ENTERPRISE_AGENT_APP_NAME"
ENV_VAR_ENVIRONMENT = "ENTERPRISE_AGENT_ENV"
ENV_VAR_LOG_LEVEL = "ENTERPRISE_AGENT_LOG_LEVEL"
ENV_VAR_DEFAULT_MODEL = "ENTERPRISE_AGENT_DEFAULT_MODEL"
ENV_VAR_TOKEN_BUDGET = "ENTERPRISE_AGENT_TOKEN_BUDGET"

ALLOWED_ENVIRONMENTS = ("development", "test", "production")
ALLOWED_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")


@dataclass(frozen=True)
class AppConfig:
    """Runtime settings for the learning project."""

    app_name: str = DEFAULT_APP_NAME
    environment: str = DEFAULT_ENVIRONMENT
    log_level: str = DEFAULT_LOG_LEVEL
    default_model: str = DEFAULT_MODEL
    token_budget: int = DEFAULT_TOKEN_BUDGET


def load_app_config(environ: Mapping[str, str] | None = None) -> AppConfig:
    """Build application config from environment variables and defaults."""

    source = os.environ if environ is None else environ

    app_name = _read_text(source, ENV_VAR_APP_NAME, DEFAULT_APP_NAME)
    environment = _read_text(source, ENV_VAR_ENVIRONMENT, DEFAULT_ENVIRONMENT).lower()
    log_level = _read_text(source, ENV_VAR_LOG_LEVEL, DEFAULT_LOG_LEVEL).upper()
    default_model = _read_text(source, ENV_VAR_DEFAULT_MODEL, DEFAULT_MODEL)
    token_budget = _read_positive_int(source, ENV_VAR_TOKEN_BUDGET, DEFAULT_TOKEN_BUDGET)

    if environment not in ALLOWED_ENVIRONMENTS:
        allowed = ", ".join(ALLOWED_ENVIRONMENTS)
        raise ValueError(f"{ENV_VAR_ENVIRONMENT} must be one of: {allowed}")

    if log_level not in ALLOWED_LOG_LEVELS:
        allowed = ", ".join(ALLOWED_LOG_LEVELS)
        raise ValueError(f"{ENV_VAR_LOG_LEVEL} must be one of: {allowed}")

    return AppConfig(
        app_name=app_name,
        environment=environment,
        log_level=log_level,
        default_model=default_model,
        token_budget=token_budget,
    )


def _read_text(source: Mapping[str, str], name: str, default: str) -> str:
    value = source.get(name, default).strip()
    if not value:
        raise ValueError(f"{name} must not be empty")
    return value


def _read_positive_int(source: Mapping[str, str], name: str, default: int) -> int:
    raw_value = source.get(name)
    if raw_value is None:
        return default

    if not raw_value.strip():
        raise ValueError(f"{name} must be an integer")

    try:
        value = int(raw_value.strip())
    except ValueError as error:
        raise ValueError(f"{name} must be an integer") from error

    if value < 1:
        raise ValueError(f"{name} must be greater than 0")

    return value
