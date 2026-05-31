import asyncio
from dataclasses import dataclass, field
from typing import Any, Mapping

import pytest

from enterprise_agent.llm import (
    LLMProviderError,
    LLMRequest,
    LLMTransportError,
    Message,
    OpenAICompatibleClientConfig,
    OpenAICompatibleLLMClient,
    OpenAICompatibleTransport,
)


def make_request() -> LLMRequest:
    return LLMRequest(
        model="gpt-compatible",
        messages=(
            Message(role="system", content="Return a concise answer."),
            Message(role="user", content="Explain provider normalization."),
        ),
        temperature=0.2,
        max_output_tokens=64,
        metadata={"trace_id": "req-008"},
    )


@dataclass
class FakeTransport(OpenAICompatibleTransport):
    responses: list[Mapping[str, Any]] = field(default_factory=list)
    errors: list[Exception] = field(default_factory=list)
    calls: list[dict[str, Any]] = field(default_factory=list)

    async def post_json(
        self,
        url: str,
        headers: Mapping[str, str],
        payload: Mapping[str, Any],
        timeout_seconds: float,
    ) -> Mapping[str, Any]:
        self.calls.append(
            {
                "url": url,
                "headers": dict(headers),
                "payload": dict(payload),
                "timeout_seconds": timeout_seconds,
            }
        )
        if self.errors:
            raise self.errors.pop(0)
        return self.responses.pop(0)


def provider_response() -> Mapping[str, Any]:
    return {
        "id": "chatcmpl-008",
        "model": "gpt-compatible",
        "choices": [
            {
                "message": {"role": "assistant", "content": "Normalized answer."},
                "finish_reason": "stop",
            }
        ],
        "usage": {"prompt_tokens": 11, "completion_tokens": 7},
    }


def test_config_normalizes_url_endpoint_and_rejects_invalid_values():
    config = OpenAICompatibleClientConfig(
        base_url=" https://api.example.test/v1/ ",
        api_key=" secret-key ",
        endpoint="chat/completions",
        timeout_seconds=5,
        max_retries=2,
    )

    assert config.base_url == "https://api.example.test/v1"
    assert config.api_key == "secret-key"
    assert config.endpoint == "/chat/completions"
    assert config.url == "https://api.example.test/v1/chat/completions"

    with pytest.raises(ValueError, match="base_url must not be empty"):
        OpenAICompatibleClientConfig(base_url=" ", api_key="key")

    with pytest.raises(ValueError, match="timeout_seconds must be greater than 0"):
        OpenAICompatibleClientConfig(base_url="https://api.example.test", api_key="key", timeout_seconds=0)

    with pytest.raises(ValueError, match="max_retries must not be negative"):
        OpenAICompatibleClientConfig(base_url="https://api.example.test", api_key="key", max_retries=-1)


def test_client_sends_openai_compatible_payload_and_normalizes_response():
    transport = FakeTransport(responses=[provider_response()])
    config = OpenAICompatibleClientConfig(
        base_url="https://api.example.test/v1",
        api_key="test-key",
        timeout_seconds=9,
    )
    client = OpenAICompatibleLLMClient(config=config, transport=transport)

    response = asyncio.run(client.complete(make_request()))

    assert transport.calls == [
        {
            "url": "https://api.example.test/v1/chat/completions",
            "headers": {
                "Authorization": "Bearer test-key",
                "Content-Type": "application/json",
            },
            "payload": {
                "model": "gpt-compatible",
                "messages": [
                    {"role": "system", "content": "Return a concise answer."},
                    {"role": "user", "content": "Explain provider normalization."},
                ],
                "temperature": 0.2,
                "max_tokens": 64,
                "metadata": {"trace_id": "req-008"},
            },
            "timeout_seconds": 9,
        }
    ]
    assert response.model == "gpt-compatible"
    assert response.message.content == "Normalized answer."
    assert response.usage() == {
        "input_tokens": 11,
        "output_tokens": 7,
        "total_tokens": 18,
    }
    assert response.raw_id == "chatcmpl-008"


def test_client_retries_transport_errors_then_succeeds():
    transport = FakeTransport(
        responses=[provider_response()],
        errors=[TimeoutError("request timed out"), LLMTransportError("connection reset")],
    )
    config = OpenAICompatibleClientConfig(
        base_url="https://api.example.test/v1",
        api_key="test-key",
        max_retries=2,
    )
    client = OpenAICompatibleLLMClient(config=config, transport=transport)

    response = asyncio.run(client.complete(make_request()))

    assert response.message.content == "Normalized answer."
    assert len(transport.calls) == 3


def test_client_raises_transport_error_after_retry_budget_is_exhausted():
    transport = FakeTransport(errors=[ConnectionError("offline"), TimeoutError("still offline")])
    config = OpenAICompatibleClientConfig(
        base_url="https://api.example.test/v1",
        api_key="test-key",
        max_retries=1,
    )
    client = OpenAICompatibleLLMClient(config=config, transport=transport)

    with pytest.raises(LLMTransportError, match=r"failed after 2 attempt\(s\): still offline"):
        asyncio.run(client.complete(make_request()))


def test_client_rejects_invalid_provider_response_without_retrying():
    transport = FakeTransport(responses=[{"choices": []}])
    config = OpenAICompatibleClientConfig(base_url="https://api.example.test/v1", api_key="test-key")
    client = OpenAICompatibleLLMClient(config=config, transport=transport)

    with pytest.raises(LLMProviderError, match=r"missing choices\[0\].message"):
        asyncio.run(client.complete(make_request()))

    assert len(transport.calls) == 1


def test_client_rejects_invalid_request_type():
    transport = FakeTransport(responses=[provider_response()])
    config = OpenAICompatibleClientConfig(base_url="https://api.example.test/v1", api_key="test-key")
    client = OpenAICompatibleLLMClient(config=config, transport=transport)

    with pytest.raises(TypeError, match="request must be an LLMRequest"):
        asyncio.run(client.complete("not a request"))  # type: ignore[arg-type]
