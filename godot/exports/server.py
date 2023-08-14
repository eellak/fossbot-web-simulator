import os
import uuid
from flask import Flask, render_template, session
from flask_socketio import join_room, leave_room, SocketIO, emit

server_port = int(os.getenv("SERVER_PORT", "8000"))

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "this_is_a_secret")
socketio = SocketIO(app)

def generate_session_id():
    return str(uuid.uuid4())

@app.route('/')
def index():
    session.clear()
    # generates session id for each tab:
    session_id = generate_session_id()
    session["session_id"] = session_id
    return render_template('index.html', session_id=session_id)

@app.route('/<path:path>')
def serve_static(path):
    return app.send_static_file(path)

@socketio.on("connect")
def connect(auth):
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
        print(f"Room {session_id} removed.")

if __name__ == '__main__':
    print(f"Server started on port {server_port}.")
    socketio.run(app=app, port=server_port)
    # socketio.run(app=app, port=server_port, debug=True)
