extends PopupMenu

var config_:Config



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PreviewGame_toggled(button_pressed):
	if button_pressed:
		$"/root/MainStart".set("blocked", true)
		for child in $"/root/MainStart/HangmanRoot".get_children():
			child.visible = true
		if not config_.build_hangman:
			for child in $"/root/MainStart/GuessingRoot".get_children():
				child.get_child(0).text = "P"
				child.visible = true
			for child in $"/root/MainStart/WrongGuessesRoot".get_children():
				child.get_child(0).text = "P"
				child.visible = true
	else:
		$"/root/MainStart".reset_ui()
		if $VBoxContainer/PreviewFinish.pressed:
			return
		$"/root/MainStart".set("blocked", false)


func _on_ContextMenu_about_to_show():
	config_ = $"/root/MainStart".get("config_")


func _on_PreviewFinish_toggled(button_pressed):
	var box = $"/root/MainStart/FinishedBox"
	if button_pressed:
		$"/root/MainStart".set("blocked", true)
		box.get_child(0).text = "Hey, you won/lost the game!\n\n1. JustPoolitzer with 7 guesses\n2. Owo with 3 guesses\n3. fir_ with 1 guesses"
		box.modulate = Color(1, 1, 1, 1)
	else:
		box.modulate = Color(1, 1, 1, 0)
		if $VBoxContainer/PreviewGame.pressed:
			return
		$"/root/MainStart".reset_ui()
		$"/root/MainStart".set("blocked", false)

func _on_FolderButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _on_SettingsButton_pressed():
	$".".hide()
	$"/root/MainStart/Settings".visible = true

