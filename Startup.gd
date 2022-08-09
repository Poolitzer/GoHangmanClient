extends CanvasLayer


# Declare member variables
var twitch_url: String
var config_ = Config.new()
var node_triggered_new_line = {}
var file_path: String


# Called when the node enters the scene tree for the first time.
func _ready():
	if File.new().file_exists("user://config.tres"):
		get_tree().change_scene("res://Main.tscn")
		return
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")


# just so pressing an inline url works
func _on_RichTextLabel_meta_clicked(meta):
	# `meta` is not guaranteed to be a String, so convert it to a String
	# to avoid script errors at run-time.
	OS.shell_open(str(meta))


# continue button for the first three slides
func _on_Continue_pressed():
	var children = $Panel.get_children()
	for child_index in children.size():
		if children[child_index].visible:
			children[child_index].visible = false
			children[child_index + 1].visible = true
			return

# second slide
func _on_Submit_pressed():
	config_.url = $Panel/Server_URL.text
	if not ("http://" in $Panel/Server_URL.text or "https://" in $Panel/Server_URL.text):
		config_.url = "http://" + config_.url
	var local_url = config_.url
	if not "/setup" in $Panel/Server_URL.text:
		local_url = local_url + "/setup"
	else:
		config_.url = config_.url.trim_suffix("/setup")
	$HTTPRequest.request(local_url + "?client_key=" + $Panel/Server_URL/Key.text)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if json.error:
		$ErrorDialog.dialog_text = "The server did not return a json response. Are you sure you entered the correct URL?"
		$ErrorDialog.popup()
		return
	if response_code != 200:
		$ErrorDialog.dialog_text = $ErrorDialog.dialog_text + json.result["description"]
		$ErrorDialog.popup()
		return	
	if not json.result["version"].begins_with("0.0"):
		$ErrorDialog.dialog_text = "The server is on a higher version than this client. Please update this client."
		$ErrorDialog.popup()
		return
	config_.client_key = $Panel/Server_URL/Key.text
	$Panel/Server_URL/Label.visible = true
	$Panel/Server_URL/Button.disabled = false


func _on_text_entered(_new_text):
	_on_Submit_pressed()


func _on_ErrorDialog_popup_hide():
	$ErrorDialog.dialog_text = "The server returned the following error:\n\n"

# fourth slide
func _on_BuildHangman_toggled(button_pressed):
	if button_pressed:
		$Panel/TypeHangman/GuessHangman.pressed = false


func _on_GuessHangman_toggled(button_pressed):
	if button_pressed:
		$Panel/TypeHangman/BuildHangman.pressed = false


func _on_ContinueType_pressed():
	$Panel/TypeHangman.visible = false
	if $Panel/TypeHangman/BuildHangman.pressed:
		$Panel/AmountGuesses.visible = true
		config_.build_hangman = true
	else:
		$Panel/WordSource.visible = true
		config_.build_hangman = false

# fifth slide
func _on_RandomWords_toggled(button_pressed):
	if button_pressed:
		$Panel/WordSource/OwnWords.pressed = false


func _on_OwnWords_toggled(button_pressed):
	if button_pressed:
		$Panel/WordSource/RandomWords.pressed = false


func _on_ContinueWordSource_pressed():
	$Panel/WordSource.visible = false
	if $Panel/WordSource/RandomWords.pressed:
		config_.random_words = true
		$Panel/ShowGuesses.visible = true
	else:
		config_.random_words = false
		$Panel/InputWord.visible = true


func _on_BackWordSource_pressed():
	$Panel/WordSource.visible = false
	$Panel/TypeHangman.visible = true

# sixth slide
func _on_VBoxContainer_ready():
	for child in $Panel/InputWord/ScrollContainer/VBoxContainer.get_children():
		child.connect("text_changed", self, "_on_LineEdit_text_changed", [child])
		node_triggered_new_line[child.name] = false


func _on_LineEdit_text_changed(new_text, child):
	if node_triggered_new_line[child.name]:
		return
	# if not lines_generated
	var new_line = LineEdit.new()
	new_line.name = "LineEdit" + String($Panel/InputWord/ScrollContainer/VBoxContainer.get_child_count())
	new_line.max_length = 11
	new_line.placeholder_text = "More-Words"
	var dynamic_font = load("res://Fonts/30Font.tres")
	new_line.add_font_override("font", dynamic_font)
	new_line.connect("text_changed", self, "_on_LineEdit_text_changed", [new_line])
	$Panel/InputWord/ScrollContainer/VBoxContainer.add_child(new_line)
	node_triggered_new_line[new_line.name] = false
	node_triggered_new_line[child.name] = true


func _on_TextureRect_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		$Panel/InputWord/HintDialog.popup()


func _on_OpenCsvFile_pressed():
	$Panel/InputWord/OpenCsvFile/FileDialog.popup()


func _on_FileDialog_file_selected(path):
	var file = File.new()
	var err = file.open(path, 1)
	if err:
		$ErrorDialog.dialog_text = "I encountered an error while opening the file, error number " + err
		$ErrorDialog.popup()
	else:
		file_path = path
		$Panel/InputWord/OpenCsvFile.text = "File succesfully set"
	file.close()


func _on_BackInputWord_pressed():
	$Panel/InputWord.visible = false
	$Panel/WordSource.visible = true


func _on_ContinueInputWord_pressed():
	config_.random_words = $Panel/InputWord/AppendRandom.pressed
	var temp_words: = []
	for child in $Panel/InputWord/ScrollContainer/VBoxContainer.get_children():
		if child.text:
			temp_words.append(PoolStringArray([child.text, "0"]))
	if file_path:
		var file = File.new()
		var err = file.open(file_path, 1)
		var line: int = 0
		while true:
			line += 1
			var temp_word = file.get_csv_line()
			if not temp_word[0]:
				break
			if temp_word.size() < 2:
				$ErrorDialog.dialog_text = "The line " + String(line) + " is broken, it doesn't have enough elements in it."
				$ErrorDialog.popup()
				return
			if temp_word[0].length() > 11:
				$ErrorDialog.dialog_text = "The word " + temp_word[0] + " at line " + String(line) + " is " + String(temp_word[0].length() - 11) +  " characters too long."
				$ErrorDialog.popup()
				return
			temp_words.append(PoolStringArray([temp_word[0], int(temp_word[1])]))
		file.close()
	if not (config_.random_words || temp_words.size() != 0):
		$ErrorDialog.dialog_text = "You did not supply any words and did not activate adding random ones, so there is no way to guess..."
		$ErrorDialog.popup()
		return
	config_.word_file = false
	if temp_words.size() != 0:
		var file = File.new()
		file.open("user://words.csv", File.WRITE)
		for word in temp_words:
			file.store_csv_line(word)
		file.close()
		config_.word_file = true
	$Panel/InputWord.visible = false
	$Panel/ShowGuesses.visible = true

# seventh slide
func _on_ContinueShowGuesses_pressed():
	config_.show_guess = $Panel/ShowGuesses/GuessedLetters.pressed
	config_.show_wrong = $Panel/ShowGuesses/WrongLetters.pressed
	config_.count_already = $Panel/ShowGuesses/CountAlreadyGuessed.pressed
	$Panel/ShowGuesses.visible = false
	$Panel/AmountGuesses.visible = true


func _on_BackShowGuesses_pressed():
	$Panel/ShowGuesses.visible = false
	if config_.word_file:
		$Panel/InputWord.visible = true
	else:
		$Panel/WordSource.visible = true

# eigth slide
func _on_BackAmountGuesses_pressed():
	$Panel/AmountGuesses.visible = false
	if config_.build_hangman:
		$Panel/TypeHangman.visible = true
	else:
		$Panel/ShowGuesses.visible = true
	

func _on_ContinueAmountGuesses_pressed():
	config_.amount_guess = int($Panel/AmountGuesses/SpinBox.value)
	$Panel/AmountGuesses.visible = false
	$Panel/TypeGuesses.visible = true


# ninth slide
func _on_BackTypeGuesses_pressed():
	$Panel/TypeGuesses.visible = false
	$Panel/AmountGuesses.visible = true


func _on_TypeCheckbox_pressed():
	if ($Panel/TypeGuesses/CheeringBits.pressed || $Panel/TypeGuesses/Subscribing.pressed || $Panel/TypeGuesses/ChatCommand.pressed):
		$Panel/TypeGuesses/ContinueTypeGuesses.disabled = false
	else:
		$Panel/TypeGuesses/ContinueTypeGuesses.disabled = true


func _on_ContinueTypeGuesses_pressed():
	if $Panel/TypeGuesses/CheeringBits.pressed:
		config_.amount_bits = $Panel/TypeGuesses/CheeringBits/AmountBits.value
	else:
		config_.amount_bits = 0
	if $Panel/TypeGuesses/Subscribing.pressed:
		config_.amount_tier = $Panel/TypeGuesses/Subscribing/TierRequired.value
		config_.amount_months = $Panel/TypeGuesses/Subscribing/MonthsRequired.value
	else:
		config_.amount_tier = 0
		config_.amount_months = 0
	if $Panel/TypeGuesses/ChatCommand.pressed:
		config_.amount_timeout = $Panel/TypeGuesses/ChatCommand/Timeout.value
	else:
		config_.amount_timeout = 0
	$Panel/TypeGuesses.visible = false
	if (config_.amount_bits || config_.amount_tier):
		$Panel/Multitude.visible = true
	else:
		$Panel/Chat.visible = true

# tenth slide
func _on_BackMultitude_pressed():
	$Panel/Multitude.visible = false
	$Panel/TypeGuesses.visible = true

func _on_ContinueMultitude_pressed():
	config_.multitude = $Panel/Multitude/MultitudeBox.pressed
	$Panel/Multitude.visible = false
	$Panel/Chat.visible = true


# eleventh slide
func _on_Chat_draw():
	if config_.build_hangman:
		$Panel/Chat/Commands/GuessedLettersRight.disabled = true
		$Panel/Chat/Commands/GuessedLettersRight/LettersRightCommand.editable = false
		$Panel/Chat/Commands/GuessedLettersWrong.disabled = true
		$Panel/Chat/Commands/GuessedLettersWrong/LettersWrongCommand.editable = false
	else:
		if not config_.show_guess:
			$Panel/Chat/Commands/GuessedLettersRight/ShowingRightLetters.visible = true
		if not config_.show_wrong:
			$Panel/Chat/Commands/GuessedLettersWrong/ShowingWrongLetters.visible = true


func _on_BackChat_pressed():
	$Panel/Chat.visible = false
	if (config_.amount_bits || config_.amount_tier):
		$Panel/Multitude.visible = true
	else:
		$Panel/TypeGuesses.visible = true


func _on_ContinueChat_pressed():
	for child in $Panel/Chat/Commands.get_children():
		if child.pressed:
			var text = child.get_child(0).text
			if not text:
				$ErrorDialog.dialog_text = "The command at " + child.text + " is empty, which can not work..."
				$ErrorDialog.popup()
				return
			config_.commands[text] = child.name.to_lower()
	$Panel/Chat.visible = false
	$Panel/Finish.visible = true

# twelfth slide
func _on_BackFinish_pressed():
	$Panel/Finish.visible = false
	$Panel/Chat.visible = true


func _on_ContinueFinish_pressed():
	SceneSwitcher.change_scene("res://Main.tscn", {"config": config_})
