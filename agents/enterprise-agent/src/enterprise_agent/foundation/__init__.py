"""Foundation helpers used to teach package structure."""

from .chapter_titles import format_chapter_title
from .package_map import CORE_MODULES, ModuleInfo, find_module, get_module_names

__all__ = [
    "CORE_MODULES",
    "ModuleInfo",
    "find_module",
    "format_chapter_title",
    "get_module_names",
]

