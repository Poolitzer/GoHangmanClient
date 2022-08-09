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
		# $TabContainer.set_current_tab(0)
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
		# reset the word if the amount of guesses changed
		if config_.amount_guess != int($TabContainer/Hangman/SpinBox.value):
			config_.amount_guess = int($TabContainer/Hangman/SpinBox.value)
			config_.wrong_guessed_chars = PoolStringArray([])
			config_.guessed_chars = PoolStringArray([])
			config_.current_guessers = {}
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
				config_.commands[text] = child.name.to_lower()
		# words
		var words = $"/root/MainStart".get("words")
		for child in $TabContainer/Words/ScrollContainer/VBoxContainer.get_children():
			if child.text:
				words[child.text] = 0
		for word in words_from_file:
			words[word] = words_from_file[word]
		$"/root/MainStart".set("words", words)
		if config_.current_word != $TabContainer/Words/CurrentWord.text:
			config_.current_word = $TabContainer/Words/CurrentWord.text
			config_.wrong_guessed_chars = PoolStringArray([])
			config_.guessed_chars = PoolStringArray([])
			config_.current_guessers = {}
		config_.random_words = $TabContainer/Words/AppendRandom.pressed
		# guess requirements
		if $"TabContainer/Guess Requirements/CheeringBits".pressed:
			config_.amount_bits = $"TabContainer/Guess Requirements/CheeringBits/AmountBits".value
		else:
			config_.amount_bits = 0
		if $"TabContainer/Guess Requirements/Subscribing".pressed:
			config_.amount_tier = $"TabContainer/Guess Requirements/Subscribing/TierRequired".value
			config_.amount_months = $"TabContainer/Guess Requirements/Subscribing/MonthsRequired".value
		else:
			config_.amount_tier = 0
			config_.amount_months = 0
		if $"TabContainer/Guess Requirements/ChatCommand".pressed:
			config_.amount_timeout = $"TabContainer/Guess Requirements/ChatCommand/Timeout".value
		else:
			config_.amount_timeout = 0
		config_.multitude = $"TabContainer/Guess Requirements/Multitude".pressed
		# cleanup/reset
		$"/root/MainStart".set_colours()
		$"/root/MainStart".reset_ui()
		$"/root/MainStart".save_()
		$".".visible = false
		$"/root/MainStart".set("blocked", false)
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
	# guess requirements tab
	$"TabContainer/Guess Requirements/CheeringBits".pressed = bool(config_.amount_bits)
	$"TabContainer/Guess Requirements/CheeringBits/AmountBits".value = config_.amount_bits
	$"TabContainer/Guess Requirements/Subscribing".pressed = bool(config_.amount_tier)
	$"TabContainer/Guess Requirements/Subscribing/TierRequired".value = config_.amount_tier
	$"TabContainer/Guess Requirements/Subscribing/MonthsRequired".value = config_.amount_months
	$"TabContainer/Guess Requirements/ChatCommand".pressed = bool(config_.amount_timeout)
	$"TabContainer/Guess Requirements/ChatCommand/Timeout".value = config_.amount_timeout
	$"TabContainer/Guess Requirements/Multitude".pressed = config_.multitude

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
		$TabContainer.set_tab_disabled(3, true)
	else:
		$TabContainer/Hangman/GuessHangman.set_pressed_no_signal(true)
		$TabContainer/Hangman/GuessedLetters.disabled = false
		$TabContainer/Hangman/WrongLetters.disabled = false
		$TabContainer/Hangman/CountAlreadyGuessed.disabled = false
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
