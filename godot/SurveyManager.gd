extends Node

signal player_loaded(player_id)
signal no_questions_available()
signal question_received(response_id, prompt, choices)
signal response_saved(response_id)

signal state_changed(state)

enum State {
    IDLE = 0,
    CREATE_PLAYER,
    GET_QUESTION,
    UPDATE_RESPONSE
}

const PLAYER_ID_PATH := "user://survey-player-id"
const GAME_ID := "<game id>"
const SURVEY_URL := "https://game.survey.hackberry.group"
"https://game.survey.hackberry.group/games/01G3YX6VG83EB42Z0QA7K9JG73/players"

var state: int = State.IDLE
var player_id: String


func _ready():
    var file := File.new()
    if not file.file_exists(PLAYER_ID_PATH):
        create_player()
    else:
        var err := file.open(PLAYER_ID_PATH, File.READ)
        if err != OK:
            prints("Failed to open", PLAYER_ID_PATH)

        player_id = file.get_line()
        emit_signal("player_loaded", player_id)


func create_player():
    while state != State.IDLE:
        yield(self, "state_changed")

    __set_state(State.CREATE_PLAYER)
    var request := HTTPRequest.new()
    add_child(request)
    var err := request.request(
        "%s/games/%s/players" % [SURVEY_URL, GAME_ID],
        ["Content-Length: 0"],
        true,
        HTTPClient.METHOD_POST
    )
    if err != OK:
        prints("Failed to create player - could not create request")
        return

    var response: Array = yield(request, "request_completed")
    remove_child(request)

    var result: int = response[0]
    var body: PoolByteArray = response[3]
    if result != OK:
        prints("Failed to create player - request failed")
        return

    var json := JSON.parse(body.get_string_from_utf8())
    if json.error:
        prints("Failed to create player - parsing response failed", json.error)
        prints(body.get_string_from_utf8())
        return

    if "error" in json.result:
        prints("Failed to create player - response indicates error", json.result.error)
        return

    player_id = json.result.playerId
    var file := File.new()
    err = file.open(PLAYER_ID_PATH, File.WRITE)
    if err != OK:
        prints("Failed to create player - could not save player id to file", PLAYER_ID_PATH)
        return

    file.store_line(player_id)
    file.close()
    emit_signal("player_loaded", player_id)
    __set_state(State.IDLE)


func get_new_question():
    while state != State.IDLE:
        yield(self, "state_changed")

    __set_state(State.GET_QUESTION)
    var request := HTTPRequest.new()
    add_child(request)
    var err := request.request(
        "%s/players/%s/responses" % [SURVEY_URL, player_id],
        ["Content-Length: 0"],
        true,
        HTTPClient.METHOD_POST
    )
    if err != OK:
        prints("Failed to get new question - could not create request")
        return

    var response: Array = yield(request, "request_completed")
    remove_child(request)

    var result: int = response[0]
    var body: PoolByteArray = response[3]
    if result != OK:
        prints("Failed to get new question - request failed")
        return

    var json := JSON.parse(body.get_string_from_utf8())
    if json.error:
        prints("Failed to get new question - parsing response failed", json.error)
        return

    if json.result == null:
        prints("No new questions available")
        emit_signal("no_questions_available")
        __set_state(State.IDLE)
        return

    if "error" in json.result:
        prints("Failed to get new question - response indicates error", json.result.error)
        return

    var response_id: String = json.result.responseId
    var prompt: String = json.result.prompt
    var choices: Array = json.result.choices
    emit_signal("question_received", response_id, prompt, choices)
    __set_state(State.IDLE)


func answer_survey_question(response_id: String, choice: int):
    while state != State.IDLE:
        yield(self, "state_changed")

    __set_state(State.UPDATE_RESPONSE)
    var request := HTTPRequest.new()
    add_child(request)
    var request_body = "choice=%d" % choice
    prints("request_body:", request_body)
    var err := request.request(
        "%s/responses/%s" % [SURVEY_URL, response_id],
        [
            "Content-Type: application/x-www-form-urlencoded",
            "Content-Length: %d" % len(request_body),
        ],
        true,
        HTTPClient.METHOD_POST,
        request_body
    )
    if err != OK:
        prints("Failed to update response - could not create request")
        return

    var response: Array = yield(request, "request_completed")
    remove_child(request)

    var result: int = response[0]
    var body: PoolByteArray = response[3]
    if result != OK:
        prints("Failed to update response - request failed")
        return

    var json := JSON.parse(body.get_string_from_utf8())
    if json.error:
        prints("Failed to update response - parsing response failed", json.error)
        return

    if "error" in json.result:
        prints("Failed to update response - response indicates error", json.result.error)
        return

    prints("Response updated:", json.result.success)
    emit_signal("response_saved", response_id)
    __set_state(State.IDLE)


func __set_state(v: int):
    state = v
    emit_signal("state_changed", state)
