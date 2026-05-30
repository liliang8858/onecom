import io
import logging

import pytest

from enterprise_agent.foundation import AppConfig, configure_logging, format_error_message


def test_configure_logging_applies_config_log_level():
    stream = io.StringIO()
    logger = configure_logging(
        AppConfig(log_level="WARNING"),
        logger_name="enterprise_agent.tests.warning",
        stream=stream,
    )

    logger.info("hidden")
    logger.warning("visible")

    output = stream.getvalue()
    assert "hidden" not in output
    assert "WARNING:enterprise_agent.tests.warning:visible" in output


def test_configure_logging_replaces_existing_handler():
    stream = io.StringIO()
    logger = configure_logging(
        AppConfig(log_level="INFO"),
        logger_name="enterprise_agent.tests.repeat",
        stream=stream,
    )

    configure_logging(
        AppConfig(log_level="INFO"),
        logger_name="enterprise_agent.tests.repeat",
        stream=stream,
    )

    logger.info("once")

    assert stream.getvalue().count("once") == 1


def test_configure_logging_rejects_unknown_level_on_manual_config():
    with pytest.raises(ValueError, match="log_level must be one of"):
        configure_logging(AppConfig(log_level="VERBOSE"), logger_name="enterprise_agent.tests.bad")


def test_configure_logging_disables_propagation_to_root_logger():
    logger = configure_logging(
        AppConfig(log_level="INFO"),
        logger_name="enterprise_agent.tests.propagation",
        stream=io.StringIO(),
    )

    assert logger.propagate is False
    assert logger.level == logging.INFO


def test_format_error_message_is_short_and_consistent():
    assert format_error_message("token_budget", "must be greater than 0") == "token_budget must be greater than 0"


def test_format_error_message_rejects_empty_parts():
    with pytest.raises(ValueError, match="field must not be empty"):
        format_error_message(" ", "must be set")

    with pytest.raises(ValueError, match="problem must not be empty"):
        format_error_message("log_level", " ")
