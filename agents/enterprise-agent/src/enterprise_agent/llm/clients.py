"""LLM client boundaries and deterministic/testing implementations."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Mapping

from enterprise_agent.foundation import format_error_message

from .messages import LLMRequest, LLMResponse, Message


DEFAULT_MOCK_RESPONSE_TEXT = "This is a deterministic mock response."
DEFAULT_MOCK_INPUT_TOKENS = 10
DEFAULT_MOCK_OUTPUT_TOKENS = 5
DEFAULT_OPENAI_COMPATIBLE_ENDPOINT = "/chat/completions"
DEFAULT_CLIENT_TIMEOUT_SECONDS = 30.0
DEFAULT_CLIENT_MAX_RETRIES = 0


class BaseLLMClient(ABC):
    """Abstract boundary implemented by all LLM clients."""

    @abstractmethod
    async def complete(self, request: LLMRequest) -> LLMResponse:
        """Return a normalized response for one LLM request."""


class LLMClientError(RuntimeError):
    """Base error raised by LLM clients after provider details are normalized."""


class LLMTransportError(LLMClientError):
    """Raised when the transport cannot complete a provider request."""


class LLMProviderError(LLMClientError):
    """Raised when a provider response is invalid or reports a failure."""


class OpenAICompatibleTransport(ABC):
    """Transport boundary used by OpenAI-compatible clients."""

    @abstractmethod
    async def post_json(
        self,
        url: str,
        headers: Mapping[str, str],
        payload: Mapping[str, Any],
        timeout_seconds: float,
    ) -> Mapping[str, Any]:
        """POST a JSON request and return a decoded JSON response."""


@dataclass(frozen=True)
class OpenAICompatibleClientConfig:
    """Runtime settings for an OpenAI-compatible chat completions client."""

    base_url: str
    api_key: str
    endpoint: str = DEFAULT_OPENAI_COMPATIBLE_ENDPOINT
    timeout_seconds: float = DEFAULT_CLIENT_TIMEOUT_SECONDS
    max_retries: int = DEFAULT_CLIENT_MAX_RETRIES

    def __post_init__(self) -> None:
        base_url = self.base_url.strip().rstrip("/")
        api_key = self.api_key.strip()
        endpoint = self.endpoint.strip()

        if not base_url:
            raise ValueError(format_error_message("base_url", "must not be empty"))
        if not api_key:
            raise ValueError(format_error_message("api_key", "must not be empty"))
        if not endpoint:
            raise ValueError(format_error_message("endpoint", "must not be empty"))
        if not endpoint.startswith("/"):
            endpoint = f"/{endpoint}"
        if self.timeout_seconds <= 0:
            raise ValueError(format_error_message("timeout_seconds", "must be greater than 0"))
        if self.max_retries < 0:
            raise ValueError(format_error_message("max_retries", "must not be negative"))

        object.__setattr__(self, "base_url", base_url)
        object.__setattr__(self, "api_key", api_key)
        object.__setattr__(self, "endpoint", endpoint)

    @property
    def url(self) -> str:
        """Return the full chat completions endpoint URL."""

        return f"{self.base_url}{self.endpoint}"


@dataclass
class OpenAICompatibleLLMClient(BaseLLMClient):
    """OpenAI-compatible client boundary backed by an injectable transport."""

    config: OpenAICompatibleClientConfig
    transport: OpenAICompatibleTransport

    async def complete(self, request: LLMRequest) -> LLMResponse:
        """Send a request through the transport and normalize the response."""

        if not isinstance(request, LLMRequest):
            raise TypeError(format_error_message("request", "must be an LLMRequest"))

        payload = _build_openai_compatible_payload(request)
        headers = {
            "Authorization": f"Bearer {self.config.api_key}",
            "Content-Type": "application/json",
        }

        last_error: Exception | None = None
        for _ in range(self.config.max_retries + 1):
            try:
                raw_response = await self.transport.post_json(
                    url=self.config.url,
                    headers=headers,
                    payload=payload,
                    timeout_seconds=self.config.timeout_seconds,
                )
                return _parse_openai_compatible_response(raw_response, fallback_model=request.model)
            except LLMTransportError as error:
                last_error = error

        raise LLMTransportError(f"LLM transport failed after retries: {last_error}") from last_error


@dataclass
class MockLLMClient(BaseLLMClient):
    """A deterministic LLM client for tests and learning chapters."""

    response_text: str = DEFAULT_MOCK_RESPONSE_TEXT
    input_tokens: int = DEFAULT_MOCK_INPUT_TOKENS
    output_tokens: int = DEFAULT_MOCK_OUTPUT_TOKENS
    finish_reason: str = "stop"
    raw_id_prefix: str = "mock-response"
    _calls: list[LLMRequest] = field(default_factory=list, init=False, repr=False)

    def __post_init__(self) -> None:
        self.response_text = _read_required_text("response_text", self.response_text)
        self.finish_reason = _read_required_text("finish_reason", self.finish_reason)
        self.raw_id_prefix = _read_required_text("raw_id_prefix", self.raw_id_prefix)
        if self.input_tokens < 0:
            raise ValueError(format_error_message("input_tokens", "must not be negative"))
        if self.output_tokens < 0:
            raise ValueError(format_error_message("output_tokens", "must not be negative"))

    @property
    def calls(self) -> tuple[LLMRequest, ...]:
        """Return requests received by this mock client."""

        return tuple(self._calls)

    async def complete(self, request: LLMRequest) -> LLMResponse:
        """Return a deterministic assistant response and record the request."""

        if not isinstance(request, LLMRequest):
            raise TypeError(format_error_message("request", "must be an LLMRequest"))

        self._calls.append(request)
        call_number = len(self._calls)

        return LLMResponse(
            model=request.model,
            message=Message(role="assistant", content=self.response_text),
            input_tokens=self.input_tokens,
            output_tokens=self.output_tokens,
            finish_reason=self.finish_reason,
            raw_id=f"{self.raw_id_prefix}-{call_number:04d}",
        )


def _read_required_text(field: str, value: str) -> str:
    clean_value = value.strip()
    if not clean_value:
        raise ValueError(format_error_message(field, "must not be empty"))
    return clean_value


def _build_openai_compatible_payload(request: LLMRequest) -> dict[str, Any]:
    payload = {
        "model": request.model,
        "messages": [message.to_dict() for message in request.messages],
        "temperature": request.temperature,
    }
    if request.max_output_tokens is not None:
        payload["max_tokens"] = request.max_output_tokens
    if request.metadata:
        payload["metadata"] = dict(request.metadata)
    return payload


def _parse_openai_compatible_response(
    response: Mapping[str, Any],
    *,
    fallback_model: str,
) -> LLMResponse:
    try:
        choices = response["choices"]
        if not isinstance(choices, list) or not choices:
            raise KeyError("choices")
        first_choice = choices[0]
        message = first_choice["message"]
        role = message["role"]
        content = message["content"]
    except (KeyError, TypeError) as error:
        raise LLMProviderError("provider response missing choices[0].message") from error

    usage = response.get("usage", {})
    if usage is None:
        usage = {}
    if not isinstance(usage, Mapping):
        raise LLMProviderError("provider response usage must be an object")

    return LLMResponse(
        model=str(response.get("model") or fallback_model),
        message=Message(role=str(role), content=str(content)),
        input_tokens=_read_usage_int(usage, "prompt_tokens"),
        output_tokens=_read_usage_int(usage, "completion_tokens"),
        finish_reason=str(first_choice.get("finish_reason") or "stop"),
        raw_id=str(response["id"]) if response.get("id") is not None else None,
    )


def _read_usage_int(usage: Mapping[str, Any], key: str) -> int:
    value = usage.get(key, 0)
    if not isinstance(value, int):
        raise LLMProviderError(f"provider response usage.{key} must be an integer")
    if value < 0:
        raise LLMProviderError(f"provider response usage.{key} must not be negative")
    return value
