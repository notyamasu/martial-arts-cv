import os

from flask import Flask, request, abort, jsonify

from database import download_and_process_videos, list_videos_in_folder
from martial_arts_engine import run_aligned_analysis

app = Flask(__name__)
app.config['UPLOAD_EXTENSIONS'] = ['.mp4', '.mov']


@app.route('/')
def home():
    return 'Martial Arts API'


@app.route('/videos', methods=['GET'])
def get_videos():
    video_urls = list_videos_in_folder()
    # remove the folder name from the video name
    video_urls = {video_name.split('/')[-1]: video_url for video_name, video_url in video_urls}
    return jsonify(video_urls)


@app.route('/analyze', methods=['GET', 'POST'])  # route for uploading image
def analyze_videos():
    # get reference video filename
    expert_video_filename = request.form.get('ref_video_title')
    uploaded_user_video = request.files.getlist("user_video")[0]
    print(expert_video_filename)
    # print(uploaded_video.filename)
    # print(uploaded_user_video.filename)
    user_video_filename = uploaded_user_video.filename
    if user_video_filename != '':

        _, image_file_ext = os.path.splitext(user_video_filename)
        if image_file_ext not in app.config['UPLOAD_EXTENSIONS']:
            abort(400)

        uploaded_user_video.save(user_video_filename)
        # Update expert_angles.json with the new video
        download_and_process_videos()

        # call the martial arts engine to analyze the videos
        feedback, segments = run_aligned_analysis(expert_video_filename, user_video_filename)

        # remove the uploaded video
        if os.path.exists(expert_video_filename):
            os.remove(expert_video_filename)
        if os.path.exists(user_video_filename):
            os.remove(user_video_filename)

        return jsonify({"feedback": feedback, "segments": segments})
    else:
        return jsonify({"error": "No video uploaded"})


if __name__ == "__main__":
    app.run(host='0.0.0.0')
