import json
import os
import pathlib

import firebase_admin
from firebase_admin import credentials, storage

from martial_arts_engine import extract_angle_sequence
from utils import read_expert_angles_file

os.makedirs("videos", exist_ok=True)
os.makedirs("angles", exist_ok=True)

try:
    # Initialize Firebase
    cred = credentials.Certificate("service_account.json")
    firebase_admin.initialize_app(cred, {
        # 'storageBucket': 'your-project-id.appspot.com'
        'storageBucket': 'codingminds-flutter-prototype.appspot.com'
    })
    bucket = storage.bucket()
except Exception as e:
    print(f"Firebase initialization error: {e}")
    exit(1)


def list_videos_in_folder(folder_name="martial_arts_sample_videos"):
    blobs = bucket.list_blobs(prefix=folder_name + "/")
    video_urls = []

    for blob in blobs:
        if blob.name.endswith(('.mp4', '.mov', '.avi')):  # or other video formats
            video_url = blob.generate_signed_url(version="v4", expiration=3600)

            # print(f"{blob.name}: {video_url}")
            video_urls.append((blob.name, video_url))

    return video_urls

    # check if the video exists in the local storage if not download it then process the video and save the angles


def download_and_process_videos():
    video_urls = list_videos_in_folder()
    existing_angles = read_expert_angles_file()

    for video_name, video_url in video_urls:
        # Check if the video already exists in the local storage

        if video_name.split("/")[-1] in existing_angles:
            print(f"{video_name} already processed.")
            continue
        local_video_path = f"videos/{video_name.split("/")[-1]}"
        if not os.path.exists(local_video_path):
            blob = bucket.blob(video_name)
            blob.download_to_filename(local_video_path)
            print(f"Downloaded {video_name} to {local_video_path}")

        video_name = pathlib.Path(video_name).name
        # Now you can process the video
        expert_angles, fps = extract_angle_sequence(local_video_path)
        # Save or process the angles in expert_angles.json file use the video name as the key
        # print(expert_angles)

        # Merge the new angles with the existing ones
        existing_angles[video_name] = {'angles':expert_angles.tolist(), 'fps': fps}

        # print(existing_angles)

        # Save the updated angles back to the file
        with open(f"angles/expert_angles.json", "w") as f:
            json.dump(existing_angles, f)

        # remove the downloaded video
        os.remove(local_video_path)


if __name__ == "__main__":
    video_urls = list_videos_in_folder()
    print(video_urls)
    # download_and_process_videos()
