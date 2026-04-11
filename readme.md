# 🎮 Quiz Quest: Game Client (Godot)

This is the student-facing game component of the **Quiz Quest Architecture Pro** system. Built with Godot, it transforms traditional assessments into an RPG-style experience where quiz performance directly affects "Boss Battles."

## 🔌 Connection Settings

The game communicates with the **Admin Dashboard** via a REST API. To connect, you must point the client to the Admin PC's IP address.

* **Default Port:** `7777`
* **Protocol:** `HTTP`
* **Target:** `http://<ADMIN_IP>:7777/api/`

---

## 🛠️ Key Implementation Modules

### 1. Authentication (`/api/login`)
Students log in using the credentials created in the Admin Dashboard.
* **Requires:** `username`, `password`
* **Returns:** `student_id`, `name`, `section`

### 2. Quiz Fetching (`/api/get_schedules`)
The client fetches quizzes that are currently active based on the server's system time.
* **Filtering:** Only shows quizzes where `CurrentTime` is between `start_time` and `end_time`.

### 3. Submission (`/api/submit_results`)
Upon completing a boss battle, the game sends a detailed report back to the Admin.

**Required JSON Structure:**
```json
{
    "student_id": 12,
    "quiz_title": "Science Unit 1",
    "score": 8,
    "total": 10,
    "defeated_boss": "Magma Golem",
    "quiz_details": [
        {
            "question": "What is H2O?",
            "student_answer": "Water",
            "correct_answer": "Water",
            "status": "Correct"
        }
    ]
}
```

---

## 🏗️ Recommended GDScript Structure

### The Result Builder
To ensure the Admin App can show the "Scrollable Breakdown," construct your `quiz_details` array during the game:

```gdscript
var quiz_history = []

func _on_answer_submitted(question, answer, correct_answer):
    var entry = {
        "question": question,
        "student_answer": answer,
        "correct_answer": correct_answer,
        "status": "Correct" if answer == correct_answer else "Incorrect"
    }
    quiz_history.append(entry)
```

### The Boss Logic
When the boss's HP reaches 0, trigger the submission:

```gdscript
func _on_boss_defeated(boss_name):
    var final_score = calculate_score()
    var total_q = quiz_history.size()
    
    # Call your HTTPRequest node here
    ServerNode.send_results(student_id, current_quiz_title, final_score, total_q, boss_name, quiz_history)
```

---

## ⚠️ Setup & Troubleshooting

1.  **Network Permission:** Ensure "Internet" permissions are enabled in your Godot Export templates (especially for Android/Web exports).
2.  **CORS/Firewall:** If the game fails to connect, ensure the Admin PC's firewall allows inbound traffic on Port `7777`.
3.  **Localhost Warning:** Do not use `127.0.0.1` unless testing on the same machine as the Admin App. Use the local network IP (e.g., `192.168.x.x`).

## 📁 JSON Quiz Format
The game expects quiz data to follow this structure:
```json
[
  {
    "question": "Which planet is the Red Planet?",
    "options": ["Earth", "Mars", "Venus", "Jupiter"],
    "answer": "Mars"
  }
]
```

---
*Quiz Quest Architecture Pro - Elevating Education through Play.*