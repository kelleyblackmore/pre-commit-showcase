"""Temperature conversion helpers.

Deliberately small. The point of this module is not the arithmetic - it is that
every hook in ``.pre-commit-config.yaml`` has something real to inspect:
``ruff`` checks the style and the docstrings, ``ruff-format`` the layout,
``mypy --strict`` the annotations, and ``bandit`` the (absence of) unsafe calls.
"""

from __future__ import annotations

ABSOLUTE_ZERO_C = -273.15


class BelowAbsoluteZeroError(ValueError):
    """Raised when a temperature falls below absolute zero."""


def celsius_to_fahrenheit(celsius: float) -> float:
    """Convert a Celsius temperature to Fahrenheit.

    Args:
        celsius: Temperature in degrees Celsius.

    Returns:
        The equivalent temperature in degrees Fahrenheit.

    Raises:
        BelowAbsoluteZeroError: If ``celsius`` is below absolute zero.
    """
    if celsius < ABSOLUTE_ZERO_C:
        msg = f"{celsius} degC is below absolute zero ({ABSOLUTE_ZERO_C} degC)"
        raise BelowAbsoluteZeroError(msg)
    return celsius * 9.0 / 5.0 + 32.0


def fahrenheit_to_celsius(fahrenheit: float) -> float:
    """Convert a Fahrenheit temperature to Celsius.

    Args:
        fahrenheit: Temperature in degrees Fahrenheit.

    Returns:
        The equivalent temperature in degrees Celsius.

    Raises:
        BelowAbsoluteZeroError: If ``fahrenheit`` is below absolute zero.
    """
    celsius = (fahrenheit - 32.0) * 5.0 / 9.0
    if celsius < ABSOLUTE_ZERO_C:
        msg = f"{fahrenheit} degF is below absolute zero"
        raise BelowAbsoluteZeroError(msg)
    return celsius
