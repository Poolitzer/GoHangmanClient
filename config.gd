extends Resource
class_name Config

export(String) var url
export(String) var client_key
export(int) var amount_guess
# this one is true if only hangman is build, not guessed!
export(bool) var build_hangman
export(bool) var random_words
export(bool) var show_guess
export(bool) var show_wrong
export(bool) var count_already
export(bool) var word_file
export(int) var amount_bits
export(int) var amount_tier
export(int) var amount_months
export(int) var amount_timeout
export(bool) var multitude
export(Dictionary) var commands = {}
export(String) var current_word
export(PoolStringArray) var guessed_chars
export(PoolStringArray) var wrong_guessed_chars
export(Dictionary) var current_guessers
export(int) var current_tab
# these ones are only changeable in the context settings menu
export(Color) var colour_background
export(Color) var colour_hangman
export(Color) var colour_guessing
export(Color) var colour_guessing_letter
export(Color) var colour_wrong
export(Color) var colour_wrong_letter
export(Color) var colour_finish_background
export(Color) var colour_finish_border
export(Color) var colour_finish_text
