import pytest

from enterprise_agent.llm import LLMRequest, LLMResponse, Message


def test_message_normalizes_role_content_and_name():
    message = Message(role=" User ", content="  Explain retries  ", name=" student ")

    assert message.role == "user"
    assert message.content == "Explain retries"
    assert message.name == "student"
    assert message.to_dict() == {
        "role": "user",
        "content": "Explain retries",
        "name": "student",
    }


def test_message_rejects_unknown_role_and_empty_content():
    with pytest.raises(ValueError, match="role must be one of"):
        Message(role="developer", content="hello")

    with pytest.raises(ValueError, match="content must not be empty"):
        Message(role="user", content="   ")


def test_llm_request_requires_model_and_messages():
    with pytest.raises(ValueError, match="model must not be empty"):
        LLMRequest(model=" ", messages=(Message(role="user", content="hello"),))

    with pytest.raises(ValueError, match="messages must contain at least one message"):
        LLMRequest(model="mock-chat", messages=())


def test_llm_request_normalizes_messages_metadata_and_prompt_text():
    request = LLMRequest(
        model=" mock-chat ",
        messages=[
            Message(role="system", content="You are concise."),
            Message(role="user", content="Summarize the incident."),
        ],
        metadata={" trace_id ": " req-001 "},
    )

    assert request.model == "mock-chat"
    assert request.messages == (
        Message(role="system", content="You are concise."),
        Message(role="user", content="Summarize the incident."),
    )
    assert request.metadata["trace_id"] == "req-001"
    assert request.prompt_text == "You are concise.\nSummarize the incident."
    assert request.to_payload() == {
        "model": "mock-chat",
        "messages": [
            {"role": "system", "content": "You are concise."},
            {"role": "user", "content": "Summarize the incident."},
        ],
        "temperature": 0.0,
        "metadata": {"trace_id": "req-001"},
    }


def test_llm_request_rejects_invalid_generation_settings():
    message = Message(role="user", content="hello")

    with pytest.raises(ValueError, match="temperature must be between 0 and 2"):
        LLMRequest(model="mock-chat", messages=(message,), temperature=2.1)

    with pytest.raises(ValueError, match="max_output_tokens must be greater than 0"):
        LLMRequest(model="mock-chat", messages=(message,), max_output_tokens=0)


def test_llm_response_requires_assistant_message_and_counts_tokens():
    response = LLMResponse(
        model=" mock-chat ",
        message=Message(role="assistant", content="Done."),
        input_tokens=10,
        output_tokens=4,
        finish_reason=" stop ",
        raw_id=" response-001 ",
    )

    assert response.model == "mock-chat"
    assert response.total_tokens == 14
    assert response.usage() == {
        "input_tokens": 10,
        "output_tokens": 4,
        "total_tokens": 14,
    }
    assert response.finish_reason == "stop"
    assert response.raw_id == "response-001"


def test_llm_response_rejects_user_message_and_negative_tokens():
    with pytest.raises(ValueError, match="message.role must be assistant"):
        LLMResponse(model="mock-chat", message=Message(role="user", content="hello"))

    with pytest.raises(ValueError, match="input_tokens must not be negative"):
        LLMResponse(
            model="mock-chat",
            message=Message(role="assistant", content="hello"),
            input_tokens=-1,
        )
