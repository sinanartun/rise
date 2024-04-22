from flask import Flask, request, jsonify
from main import main
import logging

app = Flask(__name__)

@app.route('/healthcheck/', methods=['GET'])
def healthcheck():
    return jsonify({"status": "OK"}), 200

@app.route('/process_video/<video_id>', methods=['GET'])
def process_video(video_id):

    try:
        print(video_id)
        main(video_id)
        return jsonify({"status": "Processing started for video ID " + video_id}), 200
    except Exception as e:
        logging.error(f"Error processing video {video_id}: {str(e)}")
        return jsonify({"status": "Failed to start processing", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
