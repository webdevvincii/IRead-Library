# guessing_game.py

import random

def generate_number(rng=random.randint):
    return rng(1, 10)

def check_guess(secret, guess):
    if guess < secret:
        return "Too low!"
    elif guess > secret:
        return "Too high!"
    else:
        return "Correct!"

def play_game(input_func=input, print_func=print, rng=random.randint):
    secret = generate_number(rng)
    print_func("Guess a number between 1 and 10:")
    while True:
        guess = int(input_func())
        result = check_guess(secret, guess)
        print_func(result)
        if result == "Correct!":
            break
