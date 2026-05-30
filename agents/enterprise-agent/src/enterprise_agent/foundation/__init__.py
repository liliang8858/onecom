"""Foundation helpers used to teach package structure."""

from .chapter_titles import format_chapter_title
from .config import AppConfig, load_app_config
from .logging import configure_logging, format_error_message
from .package_map import CORE_MODULES, ModuleInfo, find_module, get_module_names

__all__ = [
    "AppConfig",
    "CORE_MODULES",
    "configure_logging",
    "format_error_message",
    "ModuleInfo",
    "find_module",
    "format_chapter_title",
    "get_module_names",
    "load_app_config",
]
