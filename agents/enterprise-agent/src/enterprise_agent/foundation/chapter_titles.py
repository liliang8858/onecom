"""Chapter-title helpers used to teach test-driven development."""


def format_chapter_title(number: int, title: str) -> str:
    """Format a course chapter title in the standard lesson style."""

    if number < 1:
        raise ValueError("chapter number must be greater than 0")

    clean_title = title.strip()
    if not clean_title:
        raise ValueError("chapter title must not be empty")

    return f"第 {number:02d} 章：{clean_title}"

