"""Task-based LLM routing for choosing models and clients."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Mapping

from enterprise_agent.foundation import format_error_message

from .clients import BaseLLMClient
from .messages import LLMRequest, LLMResponse


DEFAULT_LLM_TASK_TYPE = "chat"


@dataclass(frozen=True)
class LLMRoute:
    """One routing target: a model name plus the client that can call it."""

    model: str
    client: BaseLLMClient

    def __post_init__(self) -> None:
        clean_model = self.model.strip()
        if not clean_model:
            raise ValueError(format_error_message("model", "must not be empty"))
        if not isinstance(self.client, BaseLLMClient):
            raise TypeError(format_error_message("client", "must be a BaseLLMClient"))

        object.__setattr__(self, "model", clean_model)


@dataclass
class LLMRouter(BaseLLMClient):
    """Route LLM requests by task type before calling a concrete client."""

    default_route: LLMRoute
    task_routes: Mapping[str, LLMRoute] = field(default_factory=dict)
    _routes: dict[str, LLMRoute] = field(default_factory=dict, init=False, repr=False)

    def __post_init__(self) -> None:
        if not isinstance(self.default_route, LLMRoute):
            raise TypeError(format_error_message("default_route", "must be an LLMRoute"))

        routes: dict[str, LLMRoute] = {}
        for task_type, route in self.task_routes.items():
            clean_task_type = _normalize_task_type(task_type)
            if not isinstance(route, LLMRoute):
                raise TypeError(format_error_message("task_routes", "must contain LLMRoute values"))
            routes[clean_task_type] = route

        self._routes = routes

    @property
    def routes(self) -> Mapping[str, LLMRoute]:
        """Return configured non-default task routes."""

        return dict(self._routes)

    def route_for(self, task_type: str) -> LLMRoute:
        """Return the configured route for a task type, or the default route."""

        clean_task_type = _normalize_task_type(task_type)
        return self._routes.get(clean_task_type, self.default_route)

    async def complete(self, request: LLMRequest) -> LLMResponse:
        """Choose a route from request metadata and return its normalized response."""

        if not isinstance(request, LLMRequest):
            raise TypeError(format_error_message("request", "must be an LLMRequest"))

        task_type = request.metadata.get("task_type", DEFAULT_LLM_TASK_TYPE)
        route = self.route_for(task_type)
        routed_request = LLMRequest(
            model=route.model,
            messages=request.messages,
            temperature=request.temperature,
            max_output_tokens=request.max_output_tokens,
            metadata=request.metadata,
        )
        return await route.client.complete(routed_request)


def _normalize_task_type(task_type: str) -> str:
    clean_task_type = str(task_type).strip().lower()
    if not clean_task_type:
        raise ValueError(format_error_message("task_type", "must not be empty"))
    return clean_task_type
