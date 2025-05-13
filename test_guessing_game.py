# test_guessing_game.py

import unittest
from guessing_game import check_guess, generate_number, play_game

class TestGuessingGame(unittest.TestCase):
    def test_check_guess_correct(self):
        self.assertEqual(check_guess(5, 5), "Correct!")

    def test_check_guess_low(self):
        self.assertEqual(check_guess(5, 3), "Too low!")

    def test_check_guess_high(self):
        self.assertEqual(check_guess(5, 7), "Too high!")

    def test_generate_number(self):
        mock_rng = lambda a, b: 7
        self.assertEqual(generate_number(mock_rng), 7)

    def test_play_game_correct_first_try(self):
        inputs = iter(['7'])
        outputs = []

        def mock_input():
            return next(inputs)

        def mock_print(msg):
            outputs.append(msg)

        play_game(input_func=mock_input, print_func=mock_print, rng=lambda a, b: 7)
        self.assertIn("Correct!", outputs)

if __name__ == '__main__':
    unittest.main()
