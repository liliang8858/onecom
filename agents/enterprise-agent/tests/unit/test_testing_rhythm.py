import pytest

from enterprise_agent.foundation import format_chapter_title


def test_format_chapter_title_pads_single_digit_number():
    assert format_chapter_title(3, "测试驱动的开发节奏") == "第 03 章：测试驱动的开发节奏"


def test_format_chapter_title_keeps_two_digit_number():
    assert format_chapter_title(12, "结构化输出与 JSON 校验") == "第 12 章：结构化输出与 JSON 校验"


def test_format_chapter_title_strips_extra_spaces():
    assert format_chapter_title(4, "  配置与环境变量基础  ") == "第 04 章：配置与环境变量基础"


def test_format_chapter_title_rejects_invalid_number():
    with pytest.raises(ValueError, match="greater than 0"):
        format_chapter_title(0, "无效章节")


def test_format_chapter_title_rejects_empty_title():
    with pytest.raises(ValueError, match="must not be empty"):
        format_chapter_title(5, "   ")

