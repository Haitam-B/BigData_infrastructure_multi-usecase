from flask import Flask, send_file, jsonify
import os

app = Flask(__name__)

# Configuration
ARCHIVE_NAME = 'bigdata.zip'  # Name of the existing archive file

@app.route('/download-archive', methods=['GET'])
def download_archive():
    if os.path.exists(ARCHIVE_NAME):
        return send_file(
            ARCHIVE_NAME,
            as_attachment=True,
            download_name=ARCHIVE_NAME,
            mimetype='application/zip'
        )
    else:
        return jsonify({"error": "File not found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True)
