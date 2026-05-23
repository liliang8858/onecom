"""Project metadata used by the first learning chapter."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ProjectInfo:
    """Basic metadata for smoke tests and early examples."""

    name: str
    version: str
    stage: str


def get_project_info() -> ProjectInfo:
    """Return stable project metadata for setup verification."""

    return ProjectInfo(
        name="enterprise-agent",
        version="0.1.0",
        stage="chapter-01-project-setup",
    )

