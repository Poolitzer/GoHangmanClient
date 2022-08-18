extends Label

# Our WebSocketClient instance
var _client = WebSocketClient.new()
var config_:Config
var currentHangmanState = 0
var guessers = {}
var words = {}
var current_word_offset: int = 0
# this will be set to 1 once connected and then be used to multiply the wait time
var connected: int = 0
# these are exctracted from the set commands once at startup
var costs_command: String = ""
var guess_command: String = ""
var blocked: bool = false

func reset_ui():
	for i in range(12):
		$HangmanRoot.get_child(i).visible = true
	for i in range(11, 11-config_.amount_guess , -1):
		$HangmanRoot.get_child(i).visible = false
	currentHangmanState = 12 - config_.amount_guess
	for letter in config_.wrong_guessed_chars:
		$HangmanRoot.get_child(currentHangmanState).visible = true
		currentHangmanState += 1
	for child in $GuessingRoot.get_children():
		child.visible = false
		child.get_child(0).text = ""
	for child in $WrongGuessesRoot.get_children():
		child.visible = false
	if not config_.build_hangman:
		current_word_offset = int((12-config_.current_word.length())/2)
		if config_.show_guess:
			for i in range(current_word_offset, current_word_offset + config_.current_word.length()):
				$GuessingRoot.get_child(i).visible = true
		for letter in config_.guessed_chars:
			# otherwise it would run twice
			var index = -1
			for i in config_.current_word.countn(letter):
				index = config_.current_word.findn(letter, index+1)
				var child = $GuessingRoot.get_child(index + current_word_offset)
				child.get_child(0).text = letter.to_upper()
		if config_.show_wrong:
			var a = $WrongGuessesRoot.get_children()
			for letter in config_.wrong_guessed_chars:
				var child = false
				while !child:
					var b = a[randi() % a.size()]
					if !b.visible:
						child = b
				child.get_child(0).text = letter.to_upper()
				child.visible = true

func set_colours():
	# background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = config_.colour_background
	$BackgroundPanel.add_stylebox_override("panel", style_box)
	# hangman
	for child in $HangmanRoot.get_children():
		child.default_color = config_.colour_hangman
	# guessing
	for child in $GuessingRoot.get_children():
		child.default_color = config_.colour_guessing
		child.get_child(0).add_color_override("font_color", config_.colour_guessing_letter)
	# wrong guesses
	for child in $WrongGuessesRoot.get_children():
		child.default_color = config_.colour_wrong
		child.get_child(0).add_color_override("font_color", config_.colour_wrong_letter)
	# finished box
	var second_style_box = StyleBoxFlat.new()
	second_style_box.bg_color = config_.colour_finish_background
	second_style_box.border_color = config_.colour_finish_border
	second_style_box.border_width_bottom = 10
	second_style_box.border_width_left = 10
	second_style_box.border_width_right = 10
	second_style_box.border_width_top = 10
	second_style_box.border_blend = true
	$FinishedBox.add_stylebox_override("panel", second_style_box)
	$FinishedBox/Label.add_color_override("font_color", config_.colour_finish_text)
	

func _ready():
	load_()
	randomize()
	set_colours()
	reset_ui()
	for set_command in config_.commands:
		if config_.commands[set_command] == "guesscosts":
			costs_command = set_command
		elif config_.commands[set_command] == "guess":
			guess_command = set_command
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in afor i in config_.current_word.count(letter)-1:
	_client.connect("data_received", self, "_on_data")
	
	# Initiate connection to the given URL.
	var error = _client.connect_to_url("ws" + config_.url.trim_prefix("http") + "/websocket?client_key="+ config_.client_key)
	if error != OK:
		print("Unable to connect")
		set_process(false)
	

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	if not connected:
		$ErrorDialog.dialog_text = "Could not connect to the server. Once you are sure it is up, restart the game."
		$ErrorDialog.popup()
		set_process(false)
	else:
		yield(get_tree().create_timer(1.0*connected), "timeout")
		var error = _client.connect_to_url(config_.url + "/websocket?client_key="+ config_.client_key)
		if error != OK:
			print("Unable to connect")
			set_process(false)
		connected += 1
		if connected == 6:
			$ErrorDialog.dialog_text = "Tried reconnecting for 2 minutes, didn't work. Please close the game and restart once the server is up."
			$ErrorDialog.popup()
			set_process(false)
			

func _connected(proto = ""):
	connected = 1

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_()
		get_tree().quit()


func command_to_text(command: String) -> String:
	var string_to_return: String = ""
	if command == "explainbot":
		string_to_return = "With this bot, you can play the hangman game you see on screen. "
		if config_.amount_timeout:
			string_to_return += "You can use the " + guess_command + " command. "
			if config_.amount_bits and config_.amount_tier and config_.multitude:
				string_to_return += "Either cheer or subscribe to get instant guess(es). "
			elif config_.amount_bits and config_.amount_tier:
				string_to_return += "Either cheer or subscribe to get an instant guess. "
			elif config_.amount_bits and config_.multitude:
				string_to_return += "Cheer to get instant guess(es). "
			elif config_.amount_bits:
				string_to_return += "Cheer to get an instant guess. "
			elif config_.amount_tier and config_.multitude:
				string_to_return += "Susbcribe to get instant guess(es). "
			elif config_.amount_tier:
				string_to_return += "Subscribe to get an instant guess. "
		else:
			if config_.amount_bits and config_.amount_tier and config_.multitude:
				string_to_return += "You need to either cheer or subscribe to get guess(es). "
			elif config_.amount_bits and config_.amount_tier:
				string_to_return += "You need to either cheer or subscribe to get an guess. "
			elif config_.amount_bits and config_.multitude:
				string_to_return += "You need to cheer to get instant guess(es). "
			elif config_.amount_bits:
				string_to_return += "You need to cheer to get an instant guess. "
			elif config_.amount_tier and config_.multitude:
				string_to_return += "You need to susbcribe to get instant guess(es). "
			elif config_.amount_tier:
				string_to_return += "You need to susbcribe to get an instant guess. "
			string_to_return += "After you did that, use " + guess_command + " to guess. "
		string_to_return += " Check " + costs_command + " for the costs for one guess."
	elif command == "showcommands":
		string_to_return += "These are the commands you can use with this bot: "
		for set_commands in config_.commands:
			string_to_return += "* " + set_commands + " "
	elif command  == "guesscosts":
		string_to_return += "In order to get a guess, "
		if config_.amount_timeout:
			string_to_return += "you can use the " + guess_command + "command. But you need to wait for %s seconds until you can guess again. " % config_.amount_timeout
			if config_.amount_bits and config_.amount_tier and config_.multitude:
				string_to_return += "Either cheer %s Bits or subscribe at %s Tier for %s month(s) to get instant guess(es). " % [config_.amount_bits, config_.amount_tier, config_.amount_months]
			elif config_.amount_bits and config_.amount_tier:
				string_to_return += "Either cheer %s Bits or subscribe at %s Tier for %s month(s) to get an instant guess. " % [config_.amount_bits, config_.amount_tier, config_.amount_months]
			elif config_.amount_bits and config_.multitude:
				string_to_return += "Cheer %s Bits to get instant guess(es). " % config_.amount_bits
			elif config_.amount_bits:
				string_to_return += "Cheer %s Bits to get an instant guess. "% config_.amount_bits
			elif config_.amount_tier and config_.multitude:
				string_to_return += "Susbcribe at %s Tier for %s month(s) to get instant guess(es). " % [config_.amount_tier, config_.amount_months]
			elif config_.amount_tier:
				string_to_return += "Subscribe at %s Tier for %s month(s) to get an instant guess. " % [config_.amount_tier, config_.amount_months]
		else:
			if config_.amount_bits and config_.amount_tier and config_.multitude:
				string_to_return += "you need to either cheer %s Bits or subscribe at %s Tier for %s month(s) to get guess(es). " % [config_.amount_bits, config_.amount_tier, config_.amount_months]
			elif config_.amount_bits and config_.amount_tier:
				string_to_return += "you need to either cheer %s Bits or subscribe at %s Tier for %s month(s) to get an guess. "%  [config_.amount_bits, config_.amount_tier, config_.amount_months]
			elif config_.amount_bits and config_.multitude:
				string_to_return += "you need to cheer %s Bits to get instant guess(es). " % config_.amount_bits
			elif config_.amount_bits:
				string_to_return += "you need to cheer %s Bits  to get an instant guess. " % config_.amount_bits
			elif config_.amount_tier and config_.multitude:
				string_to_return += "you need to susbcribe at %s Tier for %s month(s) to get instant guess(es). " % [config_.amount_tier, config_.amount_months]
			elif config_.amount_tier:
				string_to_return += "you need to susbcribe at %s Tier for %s month(s) to get an instant guess. " % [config_.amount_tier, config_.amount_months]
		if config_.multitude:
			if config_.amount_bits and config_.amount_tier:
				string_to_return += "If you subscribe/cheer a multitude of the required amount, you get a multitude of guesses!"
			elif config_.amount_bits:	
				string_to_return += "If you cheer a multitude of the required amount, you get a multitude of guesses!"
			else:	
				string_to_return += "If you subscribe a multitude of the required amount, you get a multitude of guesses!"
	elif command == "guess":
		string_to_return += "You need to add the character you want to guess after the command with a blank space."
	return string_to_return

func draw_new_word(word: String):
	config_.current_word = word
	config_.wrong_guessed_chars = PoolStringArray([])
	config_.guessed_chars = PoolStringArray([])
	config_.current_guessers = {}
	reset_ui()
	$HangmanRoot.visible = true
	blocked = false
	

func new_word():
	# this can only happen when switching from intro screen:
	if config_.current_word:
		words[config_.current_word] = 1
	if not words.values().has(0):
		if not config_.random_words:
			$ErrorDialog.dialog_text = "No unguessed words left"
			$ErrorDialog.popup()
		else:
			var error = $HTTPRequest.request("https://random-word-api.herokuapp.com/word")
			if error != OK:
				$ErrorDialog.dialog_text = "An error occured while trying to get a random word."
				$ErrorDialog.popup()
			return
	var word = false
	var a = words.keys()
	while !word:
		var b = a[randi() % a.size()]
		if words[b] == 0:
			word = b
	draw_new_word(word.to_lower())

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code != 200:
			$ErrorDialog.dialog_text = "An error occured in the random word request."
			$ErrorDialog.popup()
			return
	var response = parse_json(body.get_string_from_utf8())
	# we can only be here if all words are guessed or none are wanted. in both
	# cases, if the word is in the known words dictionary, we don't want it,
	if response[0].length() > 11 or response[0] in words:
		var error = $HTTPRequest.request("https://random-word-api.herokuapp.com/word")
		if error != OK:
			$ErrorDialog.dialog_text = "An error occured while trying to get a random word."
			$ErrorDialog.popup()
		return
	draw_new_word(response[0].to_lower())

# this does the guess and returns a status int
# 0 if the guess was already known, 1 if it is a correct guess, 2 if not.
# 4 if it was a guess but we only build the hangman
func do_guess(guess: String, display_name: String) -> int:
	if config_.build_hangman:
		if display_name in config_.current_guessers:
			config_.current_guessers[display_name] += 1
		else:
			config_.current_guessers[display_name] = 1
		$HangmanRoot.get_child(currentHangmanState).visible = true
		currentHangmanState += 1
		var pool_array = config_.wrong_guessed_chars
		pool_array.push_back(guess)
		config_.wrong_guessed_chars = pool_array
		return 4
	if guess in config_.guessed_chars or guess in config_.wrong_guessed_chars:
		if config_.count_already:
			var pool_array = config_.wrong_guessed_chars
			pool_array.push_back(guess)
			config_.wrong_guessed_chars = pool_array
			$HangmanRoot.get_child(currentHangmanState).visible = true
			currentHangmanState += 1
			if config_.show_wrong:
				var a = $WrongGuessesRoot.get_children()
				var child = false
				while !child:
					var b = a[randi() % a.size()]
					if !b.visible:
						child = b
				child.get_child(0).text = guess.to_upper()
				child.visible = true
		return 0
	if guess in config_.current_word:
		var pool_array = config_.guessed_chars
		pool_array.push_back(guess)
		config_.guessed_chars = pool_array
		var index = -1
		for i in config_.current_word.countn(guess):
			index = config_.current_word.findn(guess, index+1)
			var child = $GuessingRoot.get_child(index + current_word_offset)
			child.get_child(0).text = guess.to_upper()
		if display_name in config_.current_guessers:
			config_.current_guessers[display_name] += config_.current_word.countn(guess)
		else:
			config_.current_guessers[display_name] = config_.current_word.countn(guess)
		return 1
	else:
		var pool_array = config_.wrong_guessed_chars
		pool_array.push_back(guess)
		config_.wrong_guessed_chars = pool_array
		$HangmanRoot.get_child(currentHangmanState).visible = true
		currentHangmanState += 1
		if config_.show_wrong:
			var a = $WrongGuessesRoot.get_children()
			var child = false
			while !child:
				var b = a[randi() % a.size()]
				if !b.visible:
					child = b
			child.get_child(0).text = guess.to_upper()
			child.visible = true
		return 2


const correct_guess = "This guess was correct \\o/."
const incorrect_guess = "This guess was incorrect :(."
const guess_exists = "This guess was already done."
const guess_exists_no_contigent = "This guess was already done. Do try again."
const guess_build_hangman = "You build another hangman part!"

func potential_guess(message: Dictionary) -> String:
	var guess = message["Message"].right(guess_command.length() + 1)
	if config_.build_hangman:
		guess = "e"
	if not guess:
		return "You need to add the character you want to guess after the command with a blank space."
	guess = guess.substr(0, 1).to_lower()
	var guesser = false
	if message["User"]["ID"] in guessers:
		guesser = guessers[message["User"]["ID"]]
	var guess_result: String = ""
	if config_.dont_limit:
		if message["Tags"]["badges"].get_slice("/", 0) in config_.dont_limit:
			var result = do_guess(guess, message["User"]["DisplayName"])
			if result == 0:
				guess_result = guess_exists
			elif result == 1:
				guess_result = correct_guess
			elif result == 2:
				guess_result = incorrect_guess
			else:
				guess_result = guess_build_hangman
	if not guess_result:
		if config_.amount_timeout:
			if not guesser:
				var result = do_guess(guess, message["User"]["DisplayName"])
				guessers[message["Tags"]["user-id"]] = {"last_guess": int(message["Tags"]["tmi-sent-ts"]),"guess_contigent": 0,
						"guesses": 0,"correct_guesses": 0}
				if result == 0:
					if not config_.count_already:
						guessers.erase(message["Tags"]["user-id"])
						guess_result = guess_exists_no_contigent
					guess_result = guess_exists
				elif result == 1:
					guess_result = correct_guess
				elif result == 2:
					guess_result = incorrect_guess
				else:
					guess_result = guess_build_hangman
			else:
				if (int(message["Tags"]["tmi-sent-ts"]) - guesser["last_guess"]) >= config_.amount_timeout*1000:
					var old_time = guesser["last_guess"]
					guesser["last_guess"] = int(message["Tags"]["tmi-sent-ts"])
					var result = do_guess(guess, message["User"]["DisplayName"])
					if result == 0:
						if not config_.count_already:
							guesser["last_guess"] = old_time
							guess_result = guess_exists_no_contigent
						guess_result = guess_exists
					elif result == 1:
						guess_result = correct_guess
					elif result == 2:
						guess_result = incorrect_guess
					else:
						guess_result = guess_build_hangman
				else:
					if guesser["guess_contigent"] == 0:
						var wait_time = int((config_.amount_timeout*1000 - (int(message["Tags"]["tmi-sent-ts"]) - guesser["last_guess"]))/1000)
						var message_to_send = "Sorry, you have to wait %s seconds more before you can ask again. " % wait_time
						if config_.amount_bits or config_.amount_tier:
							if config_.amount_bits and config_.amount_tier:
								message_to_send += "You can either subscribe or cheer to get another guess instantly. "
							elif config_.amount_bits:
								message_to_send += "You can cheer to get another guess instantly. "
							else:
								message_to_send += "You can subscribe to get another guess instantly. "
							return message_to_send + "Check " + costs_command + " to know the costs for one."
						else:
							return message_to_send
					else:
						guesser["guess_contigent"] -= 1
						var result = do_guess(guess, message["User"]["DisplayName"])
						if result == 0:
							if not config_.count_already:
								guesser["guess_contigent"] += 1
								guess_result = guess_exists_no_contigent
							guess_result = guess_exists
						elif result == 1:
							guess_result = correct_guess
						elif result == 2:
							guess_result = incorrect_guess
						else:
							guess_result = guess_build_hangman
		else:
			if guesser["guess_contigent"] == 0:
				var message_to_send = "Sorry, you need to "
				if config_.amount_bits and config_.amount_tier:
					message_to_send += "either subscribe or cheer to get another guess. "
				elif config_.amount_bits:
					message_to_send += "cheer to get another guess. "
				else:
					message_to_send += "subscribe to get another guess. "
				return message_to_send + "Check " + costs_command + " to know the costs for one."
			else:
				guesser["guess_contigent"] -= 1
				var result = do_guess(guess, message["User"]["DisplayName"])
				if result == 0:
					if not config_.count_already:
						guesser["guess_contigent"] += 1
						guess_result = guess_exists_no_contigent
					guess_result = guess_exists
				elif result == 1:
					guess_result = correct_guess
				elif result == 2:
					guess_result = incorrect_guess
				else:
					guess_result = guess_build_hangman
	var guessed_word = true
	for i in range(current_word_offset, current_word_offset + config_.current_word.length()):
		if not $GuessingRoot.get_child(i).get_child(0).text:
			guessed_word = false
	var failed_word = true
	for child in $HangmanRoot.get_children():
		if not child.visible:
			failed_word = false
	if not guessed_word and not failed_word:
		return guess_result
	else:
		blocked = true
		$FinishedBox/Label.text = "Guessing the hangman is over!"
		$Tween.interpolate_property($FinishedBox, "modulate",
		Color(1, 1, 1, 0), Color(1, 1, 1, 1), 5.0,
		Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		var timer = get_tree().create_timer(5)
		timer.connect("timeout", self, "animation_finished", [guessed_word])
		if config_.build_hangman:
			return "You finished the hangman! Congrats!"
		if guessed_word:
			return "Correct guess, and you finished the word! Congrats!"
		else:
			for index in config_.current_word.length():
				var child = $GuessingRoot.get_child(index + current_word_offset)
				child.get_child(0).text = config_.current_word.substr(index, 1).to_upper()
			return "Wrong guess, and you all failed the word! Congrats!"

class GuesserSorter:
	static func sort_descending(a, b):
		if a["guesses"] > b["guesses"]:
			return true
		return false


func animation_finished(won: bool):
	$HangmanRoot.visible = false
	var array_to_sort = []
	for key in config_.current_guessers:
		# TODO maybe use array.resize(n)?
		array_to_sort.append({"guesses": config_.current_guessers[key], "user_name": key})
	array_to_sort.sort_custom(GuesserSorter, "sort_descending")
	var text_to_insert = ""
	if config_.build_hangman:
		text_to_insert = "You build the hangman! Best guessers:\n\n"
	elif won:
		text_to_insert = "You guessed the word! Best guessers:\n\n"
	else:
		text_to_insert = "You failed to guess the word! Best guessers:\n\n"
	text_to_insert += "1. %s with %s guesses" % [
		array_to_sort[0]["user_name"],
		array_to_sort[0]["guesses"]]
	if len(array_to_sort) > 1:
		if len(array_to_sort) > 2:
			text_to_insert += "\n2. {username_1} with {guesses_1} guesses\n3. {username_2} with {guesses_2} guesses".format(
		{"username_1": array_to_sort[1]["user_name"], 
		"guesses_1": array_to_sort[1]["guesses"],
		"username_2": array_to_sort[2]["user_name"], 
		"guesses_2":  array_to_sort[2]["guesses"]})
		else:
			text_to_insert += "\n2. {username_1} with {guesses_1} guesses".format(
		{"username_1": array_to_sort[1]["user_name"], 
		"guesses_1": array_to_sort[1]["guesses"]})
	$FinishedBox/Label.text = text_to_insert
	yield(get_tree().create_timer(5.0), "timeout")
	$FinishedBox.modulate = Color(1, 1, 1, 0)
	if config_.build_hangman:
		config_.wrong_guessed_chars = PoolStringArray([])
		config_.current_guessers = {}
		reset_ui()
		$HangmanRoot.visible = true
		blocked = false
	else:
		new_word()

func add_guess_contingent(message: Dictionary) -> String:
	print("In add function")
	print(guessers)
	var amount_guesses: int = 0
	if config_.amount_bits:
		print(int(message["Tags"]["bits"]))
		if config_.multitude:
			amount_guesses = int(int(message["Tags"]["bits"]) / config_.amount_bits)
		else:
			if int(message["Tags"]["bits"]) >= config_.amount_bits:
				amount_guesses = 1
	else:
		var level:int
		var plan = message["Tags"]["msg-param-sub-plan"]
		print(plan)
		if plan == "Prime" || plan == "1000":
			level = 1
		elif plan == "2000":
			level = 2
		else:
			level = 3
		var months:int = 0
		if "msg-param-cumulative-months" in message["Tags"]:
			months = int(message["Tags"]["msg-param-cumulative-months"])
		else:
			months = int(message["Tags"]["msg-param-gift-months"])
		if config_.multitude:
			# this might be wrong math. I hate math.
			amount_guesses = int((months * level) / (config_.amount_months * config_.amount_tier))
		else:
			if level >= config_.amount_tier and months >= config_.amount_tier:
				amount_guesses = 1
	print(amount_guesses)
	if message["Tags"]["user-id"] in guessers:
		guessers[message["Tags"]["user-id"]]["amount_guesses"] += amount_guesses
	else:
		guessers[message["Tags"]["user-id"]] = {"last_guess": 0,"guess_contigent": amount_guesses,
							"guesses": 0,"correct_guesses": 0}
	print(guessers)
	print(guessers[message["Tags"]["user-id"]])
	return "You gained %s guesses with this @%s, use them wisely! Or not." % [amount_guesses, message["Tags"]["display-name"]]

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var message = _client.get_peer(1).get_packet().get_string_from_utf8()
	var json = JSON.parse(message).result
	if "pong" in json:
		return
	print(json)
	var message_to_send: String
	if config_.amount_bits:
		if "Tags" in json and "bits" in json["Tags"]:
			message_to_send = add_guess_contingent(json)
	if config_.amount_tier:
		if "Tags" in json:
			if "msg-param-cumulative-months" in json["Tags"] or "msg-param-gift-months" in json["Tags"] :
				message_to_send = add_guess_contingent(json)
	if "version" in json:
		if not json["version"].begins_with("0.0"):
			$ErrorDialog.dialog_text = "The server is on a higher version than this client. Please update this client."
			$ErrorDialog.popup()
			return
	if "Message" in json:
		# check if the whole message is in the commands.
		print(json["Message"].strip_edges() )
		if json["Message"].strip_edges() in config_.commands:
			var actual_command = config_.commands[json["Message"].strip_edges()]
			if config_.build_hangman:
				if actual_command == "guess":
					if blocked:
						message_to_send = "The game is ending/resetting, hang on."
					else:
						message_to_send = potential_guess(json)
				else:
					message_to_send = command_to_text(actual_command)
			else:
				message_to_send = command_to_text(actual_command)
		else:
			var command_split = json["Message"].split(" ")
			for i in range(command_split.size()-1, 0, -1):
				var potential_command = ""
				for n in range(i):
					potential_command += command_split[n] + " "
				potential_command = potential_command.strip_edges()
				if potential_command in config_.commands:
					var actual_command = config_.commands[potential_command]
					if actual_command == "guess":
						if blocked:
							message_to_send = "The game is ending/resetting, hang on."
						else:
							message_to_send = potential_guess(json)
					else:
						message_to_send = command_to_text(actual_command)
					break
	if message_to_send:
		message_to_send = json["ID"]  + " " + message_to_send
		_client.get_peer(1).put_packet(message_to_send.to_utf8())
	

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()


func save_():

	ResourceSaver.save("user://config.tres", config_)
	var file = File.new()
	file.open("user://guessers.csv", File.WRITE)
	for guesser in guessers:
		file.store_csv_line(PoolStringArray([guesser, guessers[guesser]["last_guess"], 
		guessers[guesser]["guess_contigent"], guessers[guesser]["guesses"], guessers[guesser]["correct_guesses"]]))
	file.close()
	
	file.open("user://words.csv", File.WRITE)
	for word in words:
		file.store_csv_line(PoolStringArray([word, words[word]]))
	file.close()

func load_():
	config_ = load("user://config.tres")
	if not config_:
		if SceneSwitcher.get_param("config"):
			config_ = SceneSwitcher.get_param("config")
			new_word()
			config_.guessed_chars = PoolStringArray([])
			config_.wrong_guessed_chars = PoolStringArray([])
			# need to set the colours here, otherwise they will default to black
			config_.colour_background = $BackgroundPanel.get_stylebox("panel").bg_color
			config_.colour_hangman = $HangmanRoot/Arc.default_color
			config_.colour_guessing = $GuessingRoot/Letter0.default_color
			config_.colour_guessing_letter = $GuessingRoot/Letter0/Label.get_color("font_color")
			config_.colour_wrong = $WrongGuessesRoot/Guess0.default_color
			config_.colour_wrong_letter = $WrongGuessesRoot/Guess0/Label.get_color("font_color")
			config_.colour_finish_background = $FinishedBox.get_stylebox("panel").bg_color
			config_.colour_finish_border = $FinishedBox.get_stylebox("panel").border_color
			config_.colour_finish_text = $FinishedBox/Label.get_color("font_color")
			save_()
	
	var file = File.new()
	file.open("user://guessers.csv", File.READ)
	var line: int = 0
	while true:
		line += 1
		var temp_guesser = file.get_csv_line()
		if not temp_guesser[0]:
			break
		if temp_guesser.size() < 5:
			$ErrorDialog.dialog_text = "The line " + String(line) + " of the guessers.csv is broken, it doesn't have enough elements in it."
			$ErrorDialog.popup()
			return
		guessers[temp_guesser[0]] = {"last_guess": int(temp_guesser[1]),"guess_contigent": int(temp_guesser[2]),
									"guesses": int(temp_guesser[3]),"correct_guesses": int(temp_guesser[4])}
	file.close()

	file.open("user://words.csv", File.READ)
	line = 0
	while true:
		line += 1
		var temp_word = file.get_csv_line()
		if not temp_word[0]:
			break
		if temp_word.size() < 2:
			$ErrorDialog.dialog_text = "The line " + String(line) + " of the words.csv is broken, it doesn't have enough elements in it."
			$ErrorDialog.popup()
			return
		words[temp_word[0]] = int(temp_word[1])
	file.close()


func _on_Control_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 2):
		$ContextMenu.set_position(event.position)
		$ContextMenu.popup()


func _on_Heartbeat_timeout():
	_client.get_peer(1).put_packet("ping".to_utf8())
