import asyncio

import pytest

from enterprise_agent.llm import BaseLLMClient, LLMRequest, Message, MockLLMClient


def make_request() -> LLMRequest:
    return LLMRequest(
        model="mock-chat",
        messages=(
            Message(role="system", content="Answer as a test double."),
            Message(role="user", content="What is a mock client?"),
        ),
        metadata={"trace_id": "req-007"},
    )


def test_mock_client_implements_base_client_boundary():
    client = MockLLMClient()

    assert isinstance(client, BaseLLMClient)


def test_mock_client_returns_deterministic_response():
    client = MockLLMClient(response_text="Mocked answer.", input_tokens=12, output_tokens=3)
    request = make_request()

    response = asyncio.run(client.complete(request))

    assert response.model == "mock-chat"
    assert response.message.role == "assistant"
    assert response.message.content == "Mocked answer."
    assert response.usage() == {
        "input_tokens": 12,
        "output_tokens": 3,
        "total_tokens": 15,
    }
    assert response.finish_reason == "stop"
    assert response.raw_id == "mock-response-0001"


def test_mock_client_records_calls_without_exposing_mutable_history():
    client = MockLLMClient()
    request = make_request()

    asyncio.run(client.complete(request))

    assert client.calls == (request,)
    assert isinstance(client.calls, tuple)


def test_mock_client_increments_raw_id_for_each_call():
    client = MockLLMClient(raw_id_prefix="chapter-07")

    first = asyncio.run(client.complete(make_request()))
    second = asyncio.run(client.complete(make_request()))

    assert first.raw_id == "chapter-07-0001"
    assert second.raw_id == "chapter-07-0002"
    assert len(client.calls) == 2


def test_mock_client_rejects_invalid_request_type():
    client = MockLLMClient()

    with pytest.raises(TypeError, match="request must be an LLMRequest"):
        asyncio.run(client.complete("not a request"))  # type: ignore[arg-type]


def test_mock_client_rejects_empty_or_negative_configuration():
    with pytest.raises(ValueError, match="response_text must not be empty"):
        MockLLMClient(response_text=" ")

    with pytest.raises(ValueError, match="finish_reason must not be empty"):
        MockLLMClient(finish_reason=" ")

    with pytest.raises(ValueError, match="input_tokens must not be negative"):
        MockLLMClient(input_tokens=-1)

    with pytest.raises(ValueError, match="output_tokens must not be negative"):
        MockLLMClient(output_tokens=-1)
