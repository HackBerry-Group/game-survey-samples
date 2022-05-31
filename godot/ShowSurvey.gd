extends Control


var current_response_id: String
var current_prompt: String
var current_choices: Array

onready var button: Button = $CenterContainer/VBoxContainer/Button
onready var prompt_label: Label = $CenterContainer/VBoxContainer/Prompt
onready var item_list: ItemList = $CenterContainer/VBoxContainer/ItemList


func _on_button_pressed():
    button.disabled = true
    prompt_label.text = "Loading..."
    item_list.clear()
    $SurveyManager.get_new_question()


func _on_item_selected(index: int):
    if not current_response_id or button.disabled:
        return

    prints("_on_item_selected", index)

    var response_id := current_response_id
    current_response_id = ""
    button.disabled = true
    prompt_label.text = "Saving..."
    $SurveyManager.answer_survey_question(response_id, index)


func _on_player_loaded(_player_id: String):
    $CenterContainer/VBoxContainer/Button.disabled = false
    $CenterContainer/VBoxContainer/Prompt.text = "Ready!"


func _on_no_questions_available():
    current_response_id = ""

    button.disabled = false
    prompt_label.text = "No questions available"


func _on_question_received(response_id: String, prompt: String, choices: Array):
    current_response_id = response_id
    current_prompt = prompt
    current_choices = choices

    button.disabled = false
    prompt_label.text = prompt
    for choice in choices:
        item_list.add_item(choice)


func _on_response_saved(_response_id: String):
    button.disabled = false
    prompt_label.text = "Saved!"
    item_list.clear()
