# Martial Arts AI Trainer

An AI-powered martial arts training and feedback system that compares a user’s recorded performance with expert
demonstration videos. The system uses **pose estimation**, **joint angle analysis**, **Dynamic Time Warping (DTW)**, and
**OpenAI GPT** to provide **insightful coaching feedback**.

---

##  Project Overview

This application is designed to:

- Analyze body pose and joint angles from user videos using MediaPipe.
- Compare user movements to expert videos using DTW.
- Provide per-segment and overall performance feedback using OpenAI GPT.
- Serve video data and analysis results via a Flask API.
- Store expert videos in Firebase Storage.

---

##  File Structure and Description

### `server.py`

**🔹 Main Flask application** – Acts as the API layer for the system.

- `GET /videos`: Returns a dictionary of available expert video filenames and signed download URLs from Firebase.
- `POST /analyze`: Accepts a user video and expert video filename. It:
    - Saves and analyzes the video.
    - Extracts pose angles.
    - Performs DTW-based comparison.
    - Returns detailed per-segment results and GPT-based textual feedback.
- Manages safe uploading, cleanup of temporary files, and returns structured JSON responses.

---

### `database.py`

**🔹 Firebase integration & expert video management**

- Initializes Firebase using a `service_account.json` file.
- `list_videos_in_folder()`: Retrieves video file names and signed URLs from the Firebase bucket.
- `download_and_process_videos()`:
    - Downloads expert videos from Firebase if they haven't been processed yet.
    - Extracts joint angle data using MediaPipe.
    - Saves the processed angle sequences to `angles/expert_angles.json`.

This ensures that expert data is cached and reused efficiently.

---

### `martial_arts_engine.py`

**🔹 Core analysis engine** — the “brain” of the comparison system.

Handles:

- **Pose angle extraction**: Uses MediaPipe to identify and compute joint angles for every video frame.
- **Angle measurement**: Measures 11 key joint angles including elbows, shoulders, hips, knees, and torso.
- **Sequence alignment**: Uses **FastDTW** (Dynamic Time Warping) to align expert and user angle sequences.
- **Segment comparison**:
    - Splits aligned sequences into time-based segments.
    - Calculates joint-wise differences.
    - Assesses performance per joint in each segment.
    - Returns numerical and qualitative feedback per segment.

Also calls the GPT engine to generate user-friendly, overall feedback.

---

### `feedback.py`

**🔹 OpenAI GPT feedback generation**

- Reads OpenAI API key from `openai_key.json`.
- Uses the `get_martial_arts_feedback()` function to:
    - Send a system+user prompt to the GPT model.
    - Convert raw segment comparison into a coach-style response.
    - Emphasizes praise, critique, and actionable improvement tips.

The result is motivational and instructional feedback tailored to the user.

---

### `utils.py`

**🔹 Utility functions**

- `read_expert_angles_file()`: Reads `expert_angles.json` file and loads the precomputed joint angles of expert videos.
- Helps in avoiding redundant processing and speeds up API calls.

---

### `angles/expert_angles.json`

**Stores precomputed joint angle data** for all expert videos.

- JSON structure where each video name maps to:
    - `"angles"`: A list of joint angle vectors per frame.
    - `"fps"`: The frames per second of the video (needed for segment timing).

Example:

```json
{
  "kick1.mp4": {
    "angles": [[45.0, 60.1, ...], ...],
    "fps": 30
  }
}
