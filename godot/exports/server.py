import os
import uuid
from flask import Flask, render_template, session
from flask_socketio import join_room, leave_room, SocketIO, emit

server_ip = os.getenv("SOCKETIO_IP", "localhost")
server_port = int(os.getenv("SOCKETIO_PORT", "8000"))
socketio_namespace = os.getenv("SOCKETIO_NAMESPACE", "/godot")
fossbot_simapp_route = os.getenv("FOSSBOT_APP_ROUTE", "/godot")

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "this_is_a_secret")
socketio = SocketIO(app)

def generate_session_id():
    return str(uuid.uuid4())

@app.route(fossbot_simapp_route)
def index():
    session.clear()
    # generates session id for each tab:
    session_id = generate_session_id()
    session["session_id"] = session_id
    return render_template('index.html', session_id=session_id, ws_ip=server_ip, ws_port=server_port, sio_namespace=socketio_namespace)

@app.route('/<path:path>')
def serve_static(path):
    return app.send_static_file(path)


@socketio.on("pythonConnect", namespace=socketio_namespace)
def pythonConnect(data):
    session_id = data["session_id"]
    session["session_id"] = session_id
    session["user_id"] = data["user_id"]
    session["env_user"] = bool(data.get("env_user", False))
    join_room(session_id)
    print(f"Client joined room {session_id}")

@socketio.on('browserConnect', namespace=socketio_namespace)
def browserConnect():
    session_id = session.get("session_id")
    session["env_user"] = False
    join_room(session_id)
    print(f"Client joined room {session_id}")


@socketio.on("clientMessage", namespace=socketio_namespace)
def clientMessage(data):
    room = session.get("session_id")
    data["user_id"] = session.get("user_id")
    print(f"Room: {room} & Message sent From Client: {data}")
    emit("clientMessage", data, to=room)


@socketio.on("godotMessage", namespace=socketio_namespace)
def godotMessage(data):
    user_id = data["user_id"]
    print(f"Message sent From Godot (to user {user_id}): {data}")
    emit("godotMessage", data, to=user_id)


@socketio.on("godotError", namespace=socketio_namespace)
def godotError(data):
    user_id = data["user_id"]
    print(f"Error sent From Godot (to user {user_id}): {data}")
    emit("godotError", data, to=user_id)


@socketio.on("disconnect", namespace=socketio_namespace)
def disconnect():
    session_id = session.get("session_id")
    exit_func = "exit"
    if session["env_user"]:
        exit_func = "exit_env"
    if "user_id" in session:
        emit("clientMessage", {"func":exit_func, "user_id":session["user_id"]}, to=session_id)
    leave_room(session_id)
    print(f"Client from room {session_id} was removed.")

if __name__ == '__main__':
    print(f"Godot server running on http://{server_ip}:{server_port}{fossbot_simapp_route}.")
    socketio.run(app=app, host=server_ip, port=server_port)
    # socketio.run(app=app, host=server_ip, port=server_port, debug=True)
