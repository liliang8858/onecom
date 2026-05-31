"""Data objects that describe an LLM call without calling a real model."""

from __future__ import annotations

from dataclasses import dataclass, field
from types import MappingProxyType
from typing import Mapping

from enterprise_agent.foundation import format_error_message


ALLOWED_MESSAGE_ROLES = ("system", "user", "assistant", "tool")
DEFAULT_TEMPERATURE = 0.0


@dataclass(frozen=True)
class Message:
    """A single chat message sent to or returned by an LLM."""

    role: str
    content: str
    name: str | None = None

    def __post_init__(self) -> None:
        clean_role = self.role.strip().lower()
        clean_content = self.content.strip()
        clean_name = self.name.strip() if self.name is not None else None

        if clean_role not in ALLOWED_MESSAGE_ROLES:
            allowed = ", ".join(ALLOWED_MESSAGE_ROLES)
            raise ValueError(format_error_message("role", f"must be one of: {allowed}"))
        if not clean_content:
            raise ValueError(format_error_message("content", "must not be empty"))
        if clean_name == "":
            raise ValueError(format_error_message("name", "must not be empty"))

        object.__setattr__(self, "role", clean_role)
        object.__setattr__(self, "content", clean_content)
        object.__setattr__(self, "name", clean_name)

    def to_dict(self) -> dict[str, str]:
        """Return an API-friendly chat message payload."""

        payload = {
            "role": self.role,
            "content": self.content,
        }
        if self.name is not None:
            payload["name"] = self.name
        return payload


@dataclass(frozen=True)
class LLMRequest:
    """A complete request boundary for a single LLM call."""

    model: str
    messages: tuple[Message, ...]
    temperature: float = DEFAULT_TEMPERATURE
    max_output_tokens: int | None = None
    metadata: Mapping[str, str] = field(default_factory=dict)

    def __post_init__(self) -> None:
        clean_model = self.model.strip()
        if not clean_model:
            raise ValueError(format_error_message("model", "must not be empty"))

        messages = tuple(self.messages)
        if not messages:
            raise ValueError(format_error_message("messages", "must contain at least one message"))
        if not all(isinstance(message, Message) for message in messages):
            raise TypeError(format_error_message("messages", "must contain Message objects"))

        if not 0 <= self.temperature <= 2:
            raise ValueError(format_error_message("temperature", "must be between 0 and 2"))

        if self.max_output_tokens is not None and self.max_output_tokens < 1:
            raise ValueError(format_error_message("max_output_tokens", "must be greater than 0"))

        metadata = {
            str(key).strip(): str(value).strip()
            for key, value in self.metadata.items()
        }
        if any(not key for key in metadata):
            raise ValueError(format_error_message("metadata keys", "must not be empty"))
        if any(not value for value in metadata.values()):
            raise ValueError(format_error_message("metadata values", "must not be empty"))

        object.__setattr__(self, "model", clean_model)
        object.__setattr__(self, "messages", messages)
        object.__setattr__(self, "metadata", MappingProxyType(metadata))

    @property
    def prompt_text(self) -> str:
        """Return all message content joined for simple logging or tests."""

        return "\n".join(message.content for message in self.messages)

    def to_payload(self) -> dict[str, object]:
        """Return a provider-neutral request payload for later clients."""

        payload: dict[str, object] = {
            "model": self.model,
            "messages": [message.to_dict() for message in self.messages],
            "temperature": self.temperature,
        }
        if self.max_output_tokens is not None:
            payload["max_output_tokens"] = self.max_output_tokens
        if self.metadata:
            payload["metadata"] = dict(self.metadata)
        return payload


@dataclass(frozen=True)
class LLMResponse:
    """A normalized response boundary returned by an LLM client."""

    model: str
    message: Message
    input_tokens: int = 0
    output_tokens: int = 0
    finish_reason: str = "stop"
    raw_id: str | None = None

    def __post_init__(self) -> None:
        clean_model = self.model.strip()
        clean_finish_reason = self.finish_reason.strip()
        clean_raw_id = self.raw_id.strip() if self.raw_id is not None else None

        if not clean_model:
            raise ValueError(format_error_message("model", "must not be empty"))
        if self.message.role != "assistant":
            raise ValueError(format_error_message("message.role", "must be assistant"))
        if self.input_tokens < 0:
            raise ValueError(format_error_message("input_tokens", "must not be negative"))
        if self.output_tokens < 0:
            raise ValueError(format_error_message("output_tokens", "must not be negative"))
        if not clean_finish_reason:
            raise ValueError(format_error_message("finish_reason", "must not be empty"))
        if clean_raw_id == "":
            raise ValueError(format_error_message("raw_id", "must not be empty"))

        object.__setattr__(self, "model", clean_model)
        object.__setattr__(self, "finish_reason", clean_finish_reason)
        object.__setattr__(self, "raw_id", clean_raw_id)

    @property
    def total_tokens(self) -> int:
        """Return total tokens reported for this call."""

        return self.input_tokens + self.output_tokens

    def usage(self) -> dict[str, int]:
        """Return token usage in a shape that later metrics code can reuse."""

        return {
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "total_tokens": self.total_tokens,
        }
