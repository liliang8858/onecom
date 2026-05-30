import pytest

from enterprise_agent.foundation import AppConfig, load_app_config


def test_load_app_config_uses_safe_defaults():
    config = load_app_config({})

    assert config == AppConfig(
        app_name="enterprise-agent",
        environment="development",
        log_level="INFO",
        default_model="mock-chat",
        token_budget=100_000,
    )


def test_load_app_config_reads_environment_overrides():
    config = load_app_config(
        {
            "ENTERPRISE_AGENT_APP_NAME": "training-agent",
            "ENTERPRISE_AGENT_ENV": "test",
            "ENTERPRISE_AGENT_LOG_LEVEL": "debug",
            "ENTERPRISE_AGENT_DEFAULT_MODEL": "mock-fast",
            "ENTERPRISE_AGENT_TOKEN_BUDGET": "2500",
        }
    )

    assert config.app_name == "training-agent"
    assert config.environment == "test"
    assert config.log_level == "DEBUG"
    assert config.default_model == "mock-fast"
    assert config.token_budget == 2500


def test_load_app_config_rejects_empty_text_value():
    with pytest.raises(ValueError, match="ENTERPRISE_AGENT_DEFAULT_MODEL must not be empty"):
        load_app_config({"ENTERPRISE_AGENT_DEFAULT_MODEL": "   "})


def test_load_app_config_rejects_unknown_environment():
    with pytest.raises(ValueError, match="ENTERPRISE_AGENT_ENV must be one of"):
        load_app_config({"ENTERPRISE_AGENT_ENV": "staging"})


def test_load_app_config_rejects_unknown_log_level():
    with pytest.raises(ValueError, match="ENTERPRISE_AGENT_LOG_LEVEL must be one of"):
        load_app_config({"ENTERPRISE_AGENT_LOG_LEVEL": "verbose"})


def test_load_app_config_rejects_non_integer_token_budget():
    with pytest.raises(ValueError, match="ENTERPRISE_AGENT_TOKEN_BUDGET must be an integer"):
        load_app_config({"ENTERPRISE_AGENT_TOKEN_BUDGET": "many"})


def test_load_app_config_rejects_empty_token_budget():
    with pytest.raises(ValueError, match="ENTERPRISE_AGENT_TOKEN_BUDGET must be an integer"):
        load_app_config({"ENTERPRISE_AGENT_TOKEN_BUDGET": "   "})


def test_load_app_config_rejects_non_positive_token_budget():
    with pytest.raises(ValueError, match="ENTERPRISE_AGENT_TOKEN_BUDGET must be greater than 0"):
        load_app_config({"ENTERPRISE_AGENT_TOKEN_BUDGET": "0"})
