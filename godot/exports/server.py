import os
import uuid
from flask import Flask, render_template, session
from flask_socketio import join_room, leave_room, SocketIO, emit

server_ip = os.getenv("SOCKETIO_IP", "localhost")
server_port = int(os.getenv("SOCKETIO_PORT", "8000"))

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "this_is_a_secret")
socketio = SocketIO(app)

def generate_session_id():
    return str(uuid.uuid4())

@app.route('/godot')
def index():
    session.clear()
    # generates session id for each tab:
    session_id = generate_session_id()
    session["session_id"] = session_id
    return render_template('index.html', session_id=session_id, ws_ip=server_ip, ws_port=server_port)

@app.route('/<path:path>')
def serve_static(path):
    return app.send_static_file(path)


@socketio.on("pythonConnect")
def pythonConnect(session_id):
    session["session_id"] = session_id
    join_room(session_id)
    print(f"Client joined room {session_id}")

@socketio.on('browserConnect')
def browserConnect():
    session_id = session.get("session_id")
    join_room(session_id)
    print(f"Client joined room {session_id}")


@socketio.on("clientMessage")
def message(data):
    room = session.get("session_id")
    print(f"Room: {room} & Message sent From Client: {data}")
    content = {
        "message": data
    }
    emit("clientMessage", content, to=room)


@socketio.on("godotMessage")
def message(data):
    room = session.get("session_id")
    print(f"Room: {room} & Message sent From Godot: {data}")
    content = {
        "message": data
    }
    emit("godotMessage", content, to=room)


@socketio.on("disconnect")
def disconnect():
    session_id = session.get("session_id")
    clients = socketio.server.manager.rooms.get(session_id)
    if not clients or len(clients) == 0:
        leave_room(session_id)
        print(f"Client from room {session_id} was removed.")

if __name__ == '__main__':
    print(f"Godot server running on http://{server_ip}:{server_port}/godot.")
    socketio.run(app=app, port=server_port)
    # socketio.run(app=app, port=server_port, debug=True)
