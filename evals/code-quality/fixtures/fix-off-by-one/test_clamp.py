import unittest

from clamp import clamp


class TestClamp(unittest.TestCase):
    def test_inside(self):
        self.assertEqual(clamp(5, 0, 10), 5)

    def test_low(self):
        self.assertEqual(clamp(-1, 0, 10), 0)

    def test_high_inclusive(self):
        self.assertEqual(clamp(10, 0, 10), 10)


if __name__ == "__main__":
    unittest.main()
