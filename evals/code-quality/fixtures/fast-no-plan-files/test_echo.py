import unittest

from echo import echo


class TestEcho(unittest.TestCase):
    def test_echo(self):
        self.assertEqual(echo("ping"), "ping")


if __name__ == "__main__":
    unittest.main()
