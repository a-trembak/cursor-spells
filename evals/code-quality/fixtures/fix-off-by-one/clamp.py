"""Clamp n into [low, high] inclusive."""


def clamp(n: int, low: int, high: int) -> int:
    if n < low:
        return low
    if n > high:
        return high
    return n
