
from flask import Flask, render_template, request, jsonify
import os
from hdfs import InsecureClient
from flask_socketio import SocketIO
# Import additional libraries
from flask_socketio import emit
import time  # Import the time module

app = Flask(__name__)
socketio = SocketIO(app)

# HDFS base URL
hdfs_base_url = "http://master:9870"
hdfs_user = "hdfs"
hdfs_group = "test"

# Function that upload files to HDFS
def upload_to_hdfs(client, file, path, local_file_path):
    chunk_size = 4096  # Adjust the chunk size as needed
    total_size = os.path.getsize(local_file_path)
    uploaded_size = 0

    start_time = time.time()  # Record the start time
    with client.write(path, overwrite=True) as writer:
        while True:
            chunk = file.read(chunk_size)
            if not chunk:
                break  # Break if no more data to read

            writer.write(chunk)
            uploaded_size += len(chunk)
            socketio.emit('update_progress', {'percentage': (uploaded_size / total_size) * 100})

    end_time = time.time()  # Record the end time
    hdfs_time = end_time - start_time

    return hdfs_time

# Function to interact with HDFS using the hdfs library
def hdfs_interaction(action, path, local_file_path=None):
    client = InsecureClient(hdfs_base_url, user=hdfs_user)

    if action == "upload":
        with open(local_file_path, "rb") as file:
            hdfs_time = upload_to_hdfs(client, file, path, local_file_path)

            return hdfs_time


    elif action == "delete_file":
        client.delete(path)
    elif action == "create_directory":
        client.makedirs(path)
    elif action == "delete_directory":
        client.delete(path, recursive=True)

# Route for the file upload page
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/info')
def info_routes():
    return render_template('info.html')

# Route to handle file uploads
@app.route('/upload_file', methods=['POST'])
def upload_file():
    file = request.files['file']

    if file.filename == '':
        return jsonify({"success": False, "error": "No file selected for upload."})

    local_file_path = os.path.join("./temp", file.filename)
    file.save(local_file_path)

    file_path = request.form.get('file_path')

    try:
        start_time = time.time()  # Record the start time

        hdfs_time = hdfs_interaction("upload", file_path, local_file_path)
        os.remove(local_file_path)  # Remove the local file after successful upload

        end_time = time.time()  # Record the end time

        total_time = end_time - start_time

        return jsonify({"success": True, "total operation time": total_time, "hdfs write time": hdfs_time})
    except Exception as e:
        app.logger.error(f"Error uploading file '{local_file_path}' to '{file_path}': {e}")
        return jsonify({"success": False, "error": f"Error uploading file '{local_file_path}' to '{file_path}': {e}"})

# Route to handle file deletion
@app.route('/delete_file', methods=['POST'])
def delete_file():
    file_path = request.form.get('file_path')

    try:
        hdfs_interaction("delete_file", file_path)
        return jsonify({"success": True})
    except Exception as e:
        app.logger.error(f"Error deleting file '{file_path}': {e}")
        return jsonify({"success": False, "error": f"Error deleting file '{file_path}': {e}"})

# Route to handle directory creation
@app.route('/create_directory', methods=['POST'])
def create_directory():
    directory_path = request.form.get('directory_path')

    try:
        hdfs_interaction("create_directory", directory_path)
        return jsonify({"success": True})
    except Exception as e:
        app.logger.error(f"Error creating directory '{directory_path}': {e}")
        return jsonify({"success": False, "error": f"Error creating directory '{directory_path}': {e}"})

# Route to handle directory deletion
@app.route('/delete_directory', methods=['POST'])
def delete_directory():
    directory_path = request.form.get('directory_path')

    try:
        hdfs_interaction("delete_directory", directory_path)
        return jsonify({"success": True})
    except Exception as e:
        app.logger.error(f"Error deleting directory '{directory_path}': {e}")
        return jsonify({"success": False, "error": f"Error deleting directory '{directory_path}': {e}"})

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=80, debug=True, allow_unsafe_werkzeug=True)
