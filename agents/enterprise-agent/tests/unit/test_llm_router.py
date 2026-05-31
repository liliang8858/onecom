import asyncio

import pytest

from enterprise_agent.llm import (
    BaseLLMClient,
    LLMRequest,
    LLMRoute,
    LLMRouter,
    Message,
    MockLLMClient,
)


def make_request(*, task_type: str | None = None) -> LLMRequest:
    metadata = {"trace_id": "req-009"}
    if task_type is not None:
        metadata["task_type"] = task_type

    return LLMRequest(
        model="caller-placeholder",
        messages=(Message(role="user", content="Route this request."),),
        temperature=0.1,
        max_output_tokens=32,
        metadata=metadata,
    )


def test_route_requires_model_and_base_client():
    assert isinstance(LLMRoute(model="mock-chat", client=MockLLMClient()), LLMRoute)

    with pytest.raises(ValueError, match="model must not be empty"):
        LLMRoute(model=" ", client=MockLLMClient())

    with pytest.raises(TypeError, match="client must be a BaseLLMClient"):
        LLMRoute(model="mock-chat", client=object())  # type: ignore[arg-type]


def test_router_uses_default_route_when_task_type_is_missing():
    default_client = MockLLMClient(response_text="default answer")
    router = LLMRouter(default_route=LLMRoute(model="general-chat", client=default_client))

    response = asyncio.run(router.complete(make_request()))

    assert isinstance(router, BaseLLMClient)
    assert response.model == "general-chat"
    assert response.message.content == "default answer"
    assert default_client.calls[0].model == "general-chat"
    assert default_client.calls[0].metadata["trace_id"] == "req-009"


def test_router_selects_task_route_and_preserves_request_settings():
    default_client = MockLLMClient(response_text="default answer")
    reasoning_client = MockLLMClient(response_text="reasoning answer")
    router = LLMRouter(
        default_route=LLMRoute(model="general-chat", client=default_client),
        task_routes={
            "reasoning": LLMRoute(model="reasoning-model", client=reasoning_client),
        },
    )

    response = asyncio.run(router.complete(make_request(task_type=" reasoning ")))

    assert response.model == "reasoning-model"
    assert response.message.content == "reasoning answer"
    assert default_client.calls == ()
    assert len(reasoning_client.calls) == 1
    routed_request = reasoning_client.calls[0]
    assert routed_request.model == "reasoning-model"
    assert routed_request.temperature == 0.1
    assert routed_request.max_output_tokens == 32
    assert routed_request.metadata["task_type"] == "reasoning"


def test_router_falls_back_to_default_route_for_unknown_task_type():
    default_client = MockLLMClient(response_text="default answer")
    coding_client = MockLLMClient(response_text="coding answer")
    router = LLMRouter(
        default_route=LLMRoute(model="general-chat", client=default_client),
        task_routes={"coding": LLMRoute(model="coding-model", client=coding_client)},
    )

    response = asyncio.run(router.complete(make_request(task_type="summarization")))

    assert response.model == "general-chat"
    assert response.message.content == "default answer"
    assert len(default_client.calls) == 1
    assert coding_client.calls == ()


def test_route_for_normalizes_task_type_and_routes_are_copied():
    coding_route = LLMRoute(model="coding-model", client=MockLLMClient())
    router = LLMRouter(
        default_route=LLMRoute(model="general-chat", client=MockLLMClient()),
        task_routes={" Coding ": coding_route},
    )

    assert router.route_for("coding") is coding_route
    assert router.route_for("CODING") is coding_route

    routes = router.routes
    assert routes == {"coding": coding_route}
    routes["other"] = coding_route
    assert "other" not in router.routes


def test_router_rejects_invalid_configuration_and_request_type():
    with pytest.raises(TypeError, match="default_route must be an LLMRoute"):
        LLMRouter(default_route=MockLLMClient())  # type: ignore[arg-type]

    with pytest.raises(ValueError, match="task_type must not be empty"):
        LLMRouter(
            default_route=LLMRoute(model="general-chat", client=MockLLMClient()),
            task_routes={" ": LLMRoute(model="coding-model", client=MockLLMClient())},
        )

    router = LLMRouter(default_route=LLMRoute(model="general-chat", client=MockLLMClient()))
    with pytest.raises(TypeError, match="request must be an LLMRequest"):
        asyncio.run(router.complete("not a request"))  # type: ignore[arg-type]
