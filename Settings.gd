extends Panel

var config_:Config
var node_triggered_new_line: Dictionary = {}
var words_from_file: Dictionary = {}
var reset_confirmation = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_TabContainer_tab_selected(tab):
	# we set Exit to be the last tab selected, and then set in there all the config
	if tab == $TabContainer.get_child_count()-1:
		# we need to sleep for the spinboxes to save their current value
		# to the value property
		yield(get_tree().create_timer(0.01), "timeout")
		# color
		config_.colour_background = $TabContainer/Colours/Background.color
		config_.colour_hangman =  $TabContainer/Colours/Hangman.color
		config_.colour_guessing = $TabContainer/Colours/Guessing.color
		config_.colour_guessing_letter = $TabContainer/Colours/GuessingLetters.color
		config_.colour_wrong = $TabContainer/Colours/Wrong.color
		config_.colour_wrong_letter = $TabContainer/Colours/WrongLetters.color
		config_.colour_finish_background = $TabContainer/Colours/FinishBackground.color
		config_.colour_finish_border = $TabContainer/Colours/FinishBorder.color
		config_.colour_finish_text = $TabContainer/Colours/FinishText.color
		# skipping server tab, that one has its own request logic
		# hangman tab:
		config_.build_hangman = $TabContainer/Hangman/BuildHangman.pressed
		config_.show_guess = $TabContainer/Hangman/GuessedLetters.pressed
		config_.show_wrong = $TabContainer/Hangman/WrongLetters.pressed
		config_.count_already = $TabContainer/Hangman/CountAlreadyGuessed.pressed
		# chat commands
		config_.commands = {}
		for child in $"TabContainer/Chat Commands".get_children():
			if child.pressed:
				var text = child.get_child(0).text
				if not text:
					$TabContainer.set_current_tab(4)
					$"/root/MainStart/ErrorDialog".dialog_text = "The command at " + child.text + " is empty, which can not work..."
					$"/root/MainStart/ErrorDialog".popup()
					return
				if text in config_.commands:
					$"/root/MainStart/ErrorDialog".dialog_text = "The command at " + child.text + " was already used, which can not work..."
					$"/root/MainStart/ErrorDialog".popup()
					return
				if child.name.to_lower() == "guesscosts":
					$"/root/MainStart".set("costs_command", text)
				elif child.name.to_lower() == "guess":
					$"/root/MainStart".set("guess_command", text)
				config_.commands[text] = child.name.to_lower()
		# words
		var words = $"/root/MainStart".get("words")
		for child in $TabContainer/Words/ScrollContainer/VBoxContainer.get_children():
			if child.text:
				words[child.text.to_lower()] = 0
		for word in words_from_file:
			words[word.to_lower()] = int(words_from_file[word])
		if config_.current_word != $TabContainer/Words/CurrentWord.text:
			config_.current_word = $TabContainer/Words/CurrentWord.text.to_lower()
			config_.wrong_guessed_chars = PoolStringArray([])
			config_.guessed_chars = PoolStringArray([])
			config_.current_guessers = {}
			words[$TabContainer/Words/CurrentWord.text.to_lower()] = 0
		$"/root/MainStart".set("words", words)
		config_.random_words = $TabContainer/Words/AppendRandom.pressed
		# guess costs, everything else is handled by signals because race conditions
		config_.multitude = $"TabContainer/Guess Costs/Multitude".pressed
		var temp_limits = []
		if $"TabContainer/Guess Costs/Streamer".pressed:
			temp_limits.append("broadcaster")
		if $"TabContainer/Guess Costs/Moderators".pressed:
			temp_limits.append("moderator")
		if $"TabContainer/Guess Costs/VIPs".pressed:
			temp_limits.append("vip")
		config_.dont_limit = PoolStringArray(temp_limits)
		# cleanup/reset
		$"/root/MainStart".set_colours()
		$"/root/MainStart".reset_ui()
		$"/root/MainStart".save_()
		$"/root/MainStart".set("blocked", false)
		if $"/root/MainStart/ContextMenu/VBoxContainer/PreviewGame".pressed:
			$"/root/MainStart/ContextMenu"._on_PreviewGame_toggled(true)
		if $"/root/MainStart/ContextMenu/VBoxContainer/PreviewFinish".pressed:
			$"/root/MainStart/ContextMenu"._on_PreviewFinish_toggled(true)
		$".".visible = false
	else:
		# hide this again if it was set to true at one point
		$TabContainer/Server/Label.visible = false
		$TabContainer/Words/OpenCsvFile/Label.visible = false
		config_.current_tab = tab


func _on_Settings_draw():
	$"/root/MainStart".set("blocked", true)
	config_ = $"/root/MainStart".get("config_")
	# only enable words tab if needed
	if config_.build_hangman:
		$TabContainer.set_tab_disabled(3, true)
	$TabContainer.current_tab = config_.current_tab
	# colours tab
	$TabContainer/Colours/Background.color = config_.colour_background
	$TabContainer/Colours/Hangman.color = config_.colour_hangman
	$TabContainer/Colours/Guessing.color = config_.colour_guessing
	$TabContainer/Colours/GuessingLetters.color = config_.colour_guessing_letter
	$TabContainer/Colours/Wrong.color = config_.colour_wrong
	$TabContainer/Colours/WrongLetters.color = config_.colour_wrong_letter
	$TabContainer/Colours/FinishBackground.color = config_.colour_finish_background
	$TabContainer/Colours/FinishBorder.color = config_.colour_finish_border
	$TabContainer/Colours/FinishText.color = config_.colour_finish_text
	# server tab
	$TabContainer/Server/Server_URL.text = config_.url
	$TabContainer/Server/Key.text = config_.client_key
	# Hangman tab
	$TabContainer/Hangman/BuildHangman.pressed = config_.build_hangman
	$TabContainer/Hangman/GuessedLetters.pressed = config_.show_guess
	$TabContainer/Hangman/WrongLetters.pressed = config_.show_wrong
	$TabContainer/Hangman/CountAlreadyGuessed.pressed = config_.count_already
	$TabContainer/Hangman/SpinBox.value = config_.amount_guess
	# words
	$TabContainer/Words/CurrentWord.text = config_.current_word
	$TabContainer/Words/AppendRandom.pressed = config_.random_words
	# Chat commands tab
	for command_button in $"TabContainer/Chat Commands".get_children():
		for command_text in config_.commands:
			if config_.commands[command_text] == command_button.name.to_lower():
				command_button.pressed = true
				command_button.get_child(0).text = command_text
				break
	if config_.build_hangman:
		$"TabContainer/Chat Commands/GuessedLettersRight/ShowingRightLetters".visible = false
		$"TabContainer/Chat Commands/GuessedLettersWrong/ShowingWrongLetters".visible = false
	# guess Costs tab
	$"TabContainer/Guess Costs/CheeringBits".pressed = bool(config_.amount_bits)
	$"TabContainer/Guess Costs/CheeringBits/AmountBits".value = config_.amount_bits
	$"TabContainer/Guess Costs/Subscribing".pressed = bool(config_.amount_tier)
	$"TabContainer/Guess Costs/Subscribing/TierRequired".value = config_.amount_tier
	$"TabContainer/Guess Costs/Subscribing/MonthsRequired".value = config_.amount_months
	$"TabContainer/Guess Costs/ChatCommand".pressed = bool(config_.amount_timeout)
	$"TabContainer/Guess Costs/ChatCommand/Timeout".value = config_.amount_timeout
	$"TabContainer/Guess Costs/Multitude".pressed = config_.multitude
	if config_.dont_limit:
		for type in config_.dont_limit:
			if type == "broadcaster":
				$"TabContainer/Guess Costs/Streamer".pressed = true
			elif type == "moderator":
				$"TabContainer/Guess Costs/Moderators".pressed = true
			else:
				$"TabContainer/Guess Costs/VIPs".pressed = true

# server tab
func _on_Submit_pressed():
	config_.url = $TabContainer/Server/Server_URL.text
	if not ("http://" in config_.url or "https://" in config_.url):
		config_.url = "http://" + config_.url
	var local_url = config_.url
	if not "/setup" in $TabContainer/Server/Server_URL.text:
		local_url = local_url + "/setup"
	else:
		config_.url = config_.url.trim_suffix("/setup")
	$HTTPRequest.request(local_url + "?client_key=" + $TabContainer/Server/Key.text)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if json.error:
		$"/root/MainStart/ErrorDialog".dialog_text = "The server did not return a json response. Are you sure you entered the correct URL?"
		$"/root/MainStart/ErrorDialog".popup()
		return
	if response_code != 200:
		$"/root/MainStart/ErrorDialog".dialog_text = $"/root/MainStart/ErrorDialog".dialog_text + json.result["description"]
		$"/root/MainStart/ErrorDialog".popup()
		return	
	if not json.result["version"].begins_with("0.0"):
		$"/root/MainStart/ErrorDialog".dialog_text = "The server is on a higher version than this client. Please update this client."
		$"/root/MainStart/ErrorDialog".popup()
		return
	config_.client_key = $TabContainer/Server/Key.text
	$TabContainer/Server/Label.visible = true


# hangman tab - visual stuff
func _on_BuildHangman_toggled(button_pressed):
	if button_pressed:
		$TabContainer/Hangman/GuessHangman.set_pressed_no_signal(false)
		$TabContainer/Hangman/GuessedLetters.disabled = true
		$TabContainer/Hangman/WrongLetters.disabled = true
		$TabContainer/Hangman/CountAlreadyGuessed.disabled = true
		$"TabContainer/Chat Commands/GuessedLettersRight/ShowingRightLetters".visible = false
		$"TabContainer/Chat Commands/GuessedLettersWrong/ShowingWrongLetters".visible = false
		$TabContainer.set_tab_disabled(3, true)
	else:
		$TabContainer/Hangman/GuessHangman.set_pressed_no_signal(true)
		$TabContainer/Hangman/GuessedLetters.disabled = false
		$TabContainer/Hangman/WrongLetters.disabled = false
		$TabContainer/Hangman/CountAlreadyGuessed.disabled = false
		if not $TabContainer/Hangman/GuessedLetters.pressed:
			$"TabContainer/Chat Commands/GuessedLettersRight/ShowingRightLetters".visible = true
		if not $TabContainer/Hangman/WrongLetters.pressed:
			$"TabContainer/Chat Commands/GuessedLettersWrong/ShowingWrongLetters".visible = true
		$TabContainer.set_tab_disabled(3, false)


func _on_GuessHangman_toggled(button_pressed):
	# setting press here sends a signal, so the function above is triggered
	if button_pressed:
		$TabContainer/Hangman/BuildHangman.pressed = false
	else:
		$TabContainer/Hangman/BuildHangman.pressed = true


func _on_GuessedLetters_toggled(button_pressed):
	# show the hint only if that is set
	$"TabContainer/Chat Commands"/GuessedLettersRight/ShowingRightLetters.visible = !button_pressed


func _on_WrongLetters_toggled(button_pressed):
	# show the hint only if that is set
	$"TabContainer/Chat Commands"/GuessedLettersWrong/ShowingWrongLetters.visible = !button_pressed


func _on_SpinBox_value_changed(value):
	# reset the word if the amount of guesses changed
	# also this needs to be on signal change to avoid race conditions
	if config_.amount_guess != int(value):
		config_.amount_guess = int(value)
		config_.wrong_guessed_chars = PoolStringArray([])
		config_.guessed_chars = PoolStringArray([])
		config_.current_guessers = {}


# words logic
func _on_VBoxContainer_ready():
	for child in $TabContainer/Words/ScrollContainer/VBoxContainer.get_children():
		child.connect("text_changed", self, "_on_LineEdit_text_changed", [child])
		node_triggered_new_line[child.name] = false

func _on_LineEdit_text_changed(new_text, child):
	if node_triggered_new_line[child.name]:
		return
	# if not lines_generated
	var new_line = LineEdit.new()
	new_line.name = "LineEdit" + String($TabContainer/Words/ScrollContainer/VBoxContainer.get_child_count())
	new_line.max_length = 11
	new_line.placeholder_text = "More-Words"
	var dynamic_font = load("res://Fonts/30Font.tres")
	new_line.add_font_override("font", dynamic_font)
	new_line.connect("text_changed", self, "_on_LineEdit_text_changed", [new_line])
	$TabContainer/Words/ScrollContainer/VBoxContainer.add_child(new_line)
	node_triggered_new_line[new_line.name] = false
	node_triggered_new_line[child.name] = true


func _on_OpenCsvFile_pressed():
	$TabContainer/Words/OpenCsvFile/FileDialog.popup()


func _on_FileDialog_file_selected(path):
	var file = File.new()
	var err = file.open(path, 1)
	if err:
		$"/root/MainStart/ErrorDialog".dialog_text = "I encountered an error while opening the file, error number " + err
		$"/root/MainStart/ErrorDialog".popup()
	else:
		var line: int = 0
		while true:
			line += 1
			var temp_word = file.get_csv_line()
			if not temp_word[0]:
				break
			if temp_word.size() < 2:
				$"/root/MainStart/ErrorDialog".dialog_text = "The line " + String(line) + " is broken, it doesn't have enough elements in it."
				$"/root/MainStart/ErrorDialog".popup()
				return
			if temp_word[0].length() > 11:
				$"/root/MainStart/ErrorDialog".dialog_text = "The word " + temp_word[0] + " at line " + String(line) + " is " + String(temp_word[0].length() - 11) +  " characters too long."
				$"/root/MainStart/ErrorDialog".popup()
				return
			words_from_file[temp_word[0]] = int(temp_word[1])
		$TabContainer/Words/OpenCsvFile/Label.visible = true
	file.close()


func _on_TextureRect_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		$TabContainer/Words/HintDialog.popup()

func _on_TextureRect2_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		$TabContainer/Words/CurrentWord.secret = false
	if (event is InputEventMouseButton && not event.pressed && event.button_index == 1):
		$TabContainer/Words/CurrentWord.secret = true

func _on_ResetUsed_pressed():
	var words = $"/root/MainStart".get("words")
	for word in words:
		words[word] = 0
	for word in words_from_file:
		words_from_file[word] = 0
	$"/root/MainStart".set("words", words)


func _on_ResetWords_pressed():
	$TabContainer/Words/ResetDialog.popup()


func _on_ResetDialog_confirmed():
	$"/root/MainStart".set("words", {})

# guess cost slide - all of these need to be on signal to avoid race conditions
# since they are there, just pressing the checkbox wont save the value, so we also signal handle them
 

func _on_CheeringBits_pressed():
	if not $"TabContainer/Guess Costs/CheeringBits".pressed:
		config_.amount_bits = 0
	else:
		config_.amount_bits = $"TabContainer/Guess Costs/CheeringBits/AmountBits".value

func _on_AmountBits_value_changed(value):
	if $"TabContainer/Guess Costs/CheeringBits".pressed:
		config_.amount_bits = int(value)

func _on_Subscribing_pressed():
	if not $"TabContainer/Guess Costs/Subscribing".pressed:
			config_.amount_tier = 0
			config_.amount_months = 0
	else:
		config_.amount_tier = $"TabContainer/Guess Costs/Subscribing/TierRequired".value
		config_.amount_months = $"TabContainer/Guess Costs/Subscribing/MonthsRequired".value

func _on_TierRequired_value_changed(value):
	if $"TabContainer/Guess Costs/Subscribing".pressed:
		config_.amount_tier = int(value)


func _on_MonthsRequired_value_changed(value):
	if $"TabContainer/Guess Costs/Subscribing".pressed:
		config_.amount_months = int(value)


func _on_ChatCommand_pressed():
	if not $"TabContainer/Guess Costs/ChatCommand".pressed:
		config_.amount_timeout = 0
	else:
		 config_.amount_timeout = $"TabContainer/Guess Costs/ChatCommand/Timeout".value

func _on_Timeout_value_changed(value):
	if $"TabContainer/Guess Costs/ChatCommand".pressed:
		config_.amount_timeout = int(value)

