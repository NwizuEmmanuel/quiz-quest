extends HTTPRequest

# Signal Declarations
signal login_completed(success, data)
signal schedules_received(data)
signal quiz_downloaded(data)
signal result_submitted(success)
signal request_finished(data)
signal error_occurred(message)

const BASE_URL = "http://127.0.0.1:7777/api"

func _ready():
	self.request_completed.connect(_on_request_completed)

# --- API FUNCTIONS ---

func login_student(u: String, p: String):
	var body = JSON.stringify({"username": u, "password": p})
	request(BASE_URL + "/login", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

# --- API: DOWNLOAD FULL QUIZ DATA (Simplified) ---
func get_active_schedules():
	var url = BASE_URL + "/get_schedules"
	request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	
func download_quiz(schedule_id: int):
	var url = BASE_URL + "/get_full_quiz"
	# No passcode needed in the body anymore
	var body = JSON.stringify({
		"schedule_id": schedule_id
	})
	
	var headers = ["Content-Type: application/json"]
	request(url, headers, HTTPClient.METHOD_POST, body)

func submit_result(s_id: int, title: String, score: int, total: int):
	var body = JSON.stringify({"student_id": s_id, "quiz_title": title, "score": score, "total": total})
	request(BASE_URL + "/submit_results", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

# --- CALLBACK HANDLER ---
func _on_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		error_occurred.emit("Network connection failed.")
		return

	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)

	request_finished.emit(json)

	match response_code:
		200:
			if json is Dictionary:
				if json.has("questions"):
					quiz_downloaded.emit(json)
				elif json.has("student_id"):
					login_completed.emit(true, json)
			elif json is Array: # <--- ADD THIS LOGIC
				schedules_received.emit(json)
		201:
			result_submitted.emit(true)
		401:
			login_completed.emit(false, {"message": "Invalid Login"})
			error_occurred.emit("Unauthorized: Invalid credentials.")
		403:
			error_occurred.emit("Access Denied: Wrong Passcode.")
		404:
			error_occurred.emit("Resource not found.")
		_:
			error_occurred.emit("Server error occurred.")
