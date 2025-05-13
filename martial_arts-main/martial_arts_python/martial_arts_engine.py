import math

import cv2
import mediapipe as mp
import numpy as np
from fastdtw import fastdtw
from scipy.spatial.distance import euclidean

from feedback import get_martial_arts_feedback
from utils import read_expert_angles_file

# ========== Setup ==========
mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils
pose_landmarks = mp_pose.PoseLandmark

# Joints for angle measurement
ANGLE_JOINTS = {
    "Right Elbow": (pose_landmarks.RIGHT_SHOULDER, pose_landmarks.RIGHT_ELBOW, pose_landmarks.RIGHT_WRIST),
    "Left Elbow": (pose_landmarks.LEFT_SHOULDER, pose_landmarks.LEFT_ELBOW, pose_landmarks.LEFT_WRIST),
    "Right Shoulder": (pose_landmarks.RIGHT_ELBOW, pose_landmarks.RIGHT_SHOULDER, pose_landmarks.RIGHT_HIP),
    "Left Shoulder": (pose_landmarks.LEFT_ELBOW, pose_landmarks.LEFT_SHOULDER, pose_landmarks.LEFT_HIP),
    "Right Knee": (pose_landmarks.RIGHT_HIP, pose_landmarks.RIGHT_KNEE, pose_landmarks.RIGHT_ANKLE),
    "Left Knee": (pose_landmarks.LEFT_HIP, pose_landmarks.LEFT_KNEE, pose_landmarks.LEFT_ANKLE),
    "Right Hip": (pose_landmarks.RIGHT_SHOULDER, pose_landmarks.RIGHT_HIP, pose_landmarks.RIGHT_KNEE),
    "Left Hip": (pose_landmarks.LEFT_SHOULDER, pose_landmarks.LEFT_HIP, pose_landmarks.LEFT_KNEE),
    "Torso Left": (pose_landmarks.LEFT_SHOULDER, pose_landmarks.LEFT_HIP, pose_landmarks.LEFT_KNEE),
    "Torso Right": (pose_landmarks.RIGHT_SHOULDER, pose_landmarks.RIGHT_HIP, pose_landmarks.RIGHT_KNEE),
    "Neck Bend": (pose_landmarks.NOSE, pose_landmarks.LEFT_SHOULDER, pose_landmarks.LEFT_HIP),
}


# ========== Utility Functions ==========
def calculate_angle(a, b, c):
    a, b, c = np.array(a), np.array(b), np.array(c)
    ba = a - b
    bc = c - b
    cosine = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    angle = np.arccos(np.clip(cosine, -1.0, 1.0))
    return np.degrees(angle)


def get_coords(landmarks, name, w, h):
    lm = landmarks[name.value]
    return [lm.x * w, lm.y * h]


def extract_angle_sequence(video_path):
    cap = cv2.VideoCapture(video_path)
    angles = []
    fps = cap.get(cv2.CAP_PROP_FPS)

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            h, w = frame.shape[:2]
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb)

            if results.pose_landmarks:
                lm = results.pose_landmarks.landmark
                frame_angles = []
                for a, b, c in ANGLE_JOINTS.values():
                    frame_angles.append(calculate_angle(
                        get_coords(lm, a, w, h),
                        get_coords(lm, b, w, h),
                        get_coords(lm, c, w, h)
                    ))
                angles.append(frame_angles)

    cap.release()
    return np.array(angles), fps


def save_video_segment(video_path, frame_indices, output_path, fps=30):
    cap = cv2.VideoCapture(video_path)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    out = cv2.VideoWriter(output_path,
                          cv2.VideoWriter_fourcc(*'mp4v'),
                          fps,
                          (width, height))

    frame_set = set(frame_indices)
    # print(frame_set)
    index = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if index in frame_set:
            out.write(frame)
        index += 1
        if index > max(frame_indices):
            break

    cap.release()
    out.release()


# ========== DTW + Segment-Based Comparison ==========
def align_and_get_path(expert_angles, user_angles):
    distance, path = fastdtw(expert_angles, user_angles, dist=euclidean)
    return path, distance


def get_aligned_segments(path, window_size=30):
    segments = []
    for i in range(0, len(path) - window_size, window_size):
        window = path[i:i + window_size]
        expert_idx = [e for e, _ in window]
        user_idx = [u for _, u in window]
        segments.append((expert_idx, user_idx))
    return segments


def compare_aligned_segments(expert_angles, user_angles, segments, user_video, expert_fps, print_results=False,
                             expert_video=None):
    joint_names = list(ANGLE_JOINTS.keys())
    # expert_video_basename = pathlib.Path(expert_video).stem
    # user_video_basename = pathlib.Path(user_video).stem
    # print(f"Saving video segments to {expert_video_basename} and {user_video_basename} folders...")
    # os.makedirs(expert_video_basename, exist_ok=True)
    # os.makedirs(user_video_basename, exist_ok=True)

    full_summary = []
    segment_list = []
    user_fps = 1

    for i, (exp_idxs, usr_idxs) in enumerate(segments):
        exp_window = np.array([expert_angles[i] for i in exp_idxs])
        usr_window = np.array([user_angles[j] for j in usr_idxs])

        min_len = min(len(exp_window), len(usr_window))
        exp_window = exp_window[:min_len]
        usr_window = usr_window[:min_len]

        joint_diffs = np.mean(np.abs(exp_window - usr_window), axis=0)
        avg_diff = np.mean(joint_diffs)

        if i == 0:
            user_fps = get_fps(user_video)

        usr_end_time, usr_start_time = get_start_end_time(user_fps, usr_idxs)
        expert_end_time, expert_start_time = get_start_end_time(expert_fps, exp_idxs)
        print(f"Segment {i + 1}: {usr_start_time:.2f}s - {usr_end_time:.2f}s  (User) | "
              f"{expert_start_time:.2f}s - {expert_end_time:.2f}s  (Expert)")

        segment_key = f"Segment {i + 1}\n"
        segment_text = f"Average angle difference: {avg_diff:.2f} degrees\n"

        for name, diff in zip(joint_names, joint_diffs):
            if diff < 10:
                status = "Good match"
            elif diff < 25:
                status = "Needs improvement"
            else:
                status = "Poor match"
            segment_text += f"- {name}: {diff:.2f} degrees ({status})\n"

        segment_list.append({
            "segment_text": segment_text,
            "usr_start_time": usr_start_time,
            "usr_end_time": usr_end_time,
            "expert_start_time": expert_start_time,
            "expert_end_time": expert_end_time,
        })
        if print_results:
            print(segment_key)
            print(segment_text)
        full_summary.append(segment_key + segment_text)
        # we can use the saved videos to show the user the segments where they need to improve
        # and the expert's video

        # user_output_path = f"{user_video_basename}/user_segment_{i + 1}.mp4"
        # save_video_segment(user_video, usr_idxs, user_output_path)
        #
        # expert_output_path = f"{expert_video_basename}/expert_segment_{i + 1}.mp4"
        # save_video_segment(expert_video, exp_idxs, expert_output_path)

    return "\n".join(full_summary), segment_list


def get_start_end_time(fps, frame_idxs):
    start_frame = min(frame_idxs)
    end_frame = max(frame_idxs)
    start_time = math.floor(start_frame / fps)
    end_time = math.ceil(end_frame / fps)
    return end_time, start_time


def get_fps(video):
    cap = cv2.VideoCapture(video)
    fps = cap.get(cv2.CAP_PROP_FPS)
    cap.release()
    return fps


# ========== Main Function ==========
def run_aligned_analysis(expert_video, user_video, window_size=60, print_result=False):  # window_size= 60 is ~2 seconds
    print("Retrieving expert angles from database...")
    print(f"Expert video: {expert_video}")
    expert_data = read_expert_angles_file()[expert_video]
    expert_angles = np.array(expert_data['angles'])
    expert_fps = expert_data['fps']

    print("Extracting joint angles from user...")
    user_angles, _ = extract_angle_sequence(user_video)

    print("Aligning sequences with DTW...")
    path, distance = align_and_get_path(expert_angles, user_angles)
    print(f"DTW distance: {distance:.2f}")

    print("Splitting DTW path into aligned segments...")
    segments = get_aligned_segments(path, window_size)

    print("Comparing each aligned segment...")
    summary_text, segments = compare_aligned_segments(expert_angles, user_angles, segments, user_video, expert_fps,
                                                      print_results=print_result)
    print("\nGenerating overall feedback using OpenAI...")

    feedback = get_martial_arts_feedback(summary_text)
    if print_result:
        print("\n===== Overall Feedback =====")
        print(feedback)
    return feedback, segments


if __name__ == "__main__":
    run_aligned_analysis("martial_arts.mp4", "sample_videos/pose1.mp4", window_size=60,
                         print_result=True)
