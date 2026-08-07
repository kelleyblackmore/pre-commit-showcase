import pytest

from tempconv import celsius_to_fahrenheit, fahrenheit_to_celsius
from tempconv.converter import BelowAbsoluteZeroError


@pytest.mark.parametrize(
    ("celsius", "fahrenheit"),
    [(0.0, 32.0), (100.0, 212.0), (-40.0, -40.0), (37.0, 98.6)],
)
def test_celsius_to_fahrenheit(celsius: float, fahrenheit: float) -> None:
    assert celsius_to_fahrenheit(celsius) == pytest.approx(fahrenheit)


@pytest.mark.parametrize(
    ("fahrenheit", "celsius"),
    [(32.0, 0.0), (212.0, 100.0), (-40.0, -40.0)],
)
def test_fahrenheit_to_celsius(fahrenheit: float, celsius: float) -> None:
    assert fahrenheit_to_celsius(fahrenheit) == pytest.approx(celsius)


def test_rejects_below_absolute_zero() -> None:
    with pytest.raises(BelowAbsoluteZeroError):
        celsius_to_fahrenheit(-300.0)
