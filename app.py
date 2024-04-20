from flask import Flask, request, jsonify
from main import main

app = Flask(__name__)

@app.route('/healthcheck/', methods=['GET'])
def healthcheck():
    return jsonify({"status": "OK"}), 200


@app.route('/process_video/<video_id>', methods=['POST'])
def process_video(video_id):
    event = {'video_id': video_id}
    context = {}  # You can define context if needed or pass an empty dictionary
    main(event, context)
    return jsonify({"status": "Processing started for video ID " + video_id}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
