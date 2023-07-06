import websockets
import asyncio
import json

conn_clients = []

async def server(ws, path):
    conn_clients.append(ws)
    print('Client Connected.')
    async for msg in ws:
        # print(path)
        if not isinstance(msg, str):    # godot sends a text here
            msg = msg.decode("utf-8")
            data = {"func": "", "return":msg}
        else:   # browser sends this:
            print(f"Msg from client: {msg}")

            msg_dict = json.loads(msg)  # Parse JSON string into Python dictionary

            data = {
                "func": msg_dict["func"], "vel_right": float(msg_dict["vel_right"]), 
                "vel_left": float(msg_dict["vel_left"]), "degree": float(msg_dict["degree"]), 
                "color": msg_dict["color"], "axis":msg_dict["axis"], "tar_dist":float(msg_dict["tar_dist"]),
                "sensor_id": int(msg_dict["sensorId"]), "dark_value":float(msg_dict["darkValue"])
            }
            if data["vel_right"] > 100:
                data["vel_right"] = 100
            if data["vel_left"] > 100:
                data["vel_left"] = 100
        # if msg_dict["func"] == 'move_forward':
        #     data = {"msg":"","x": 0, "z": 0, "p":1}
        # elif msg_dict["func"] == 'move_backward':
        #     data["x"] = 1
        # elif msg_dict["func"] == 'rotate_clockwise':
        #     data["x"] = 0
        # elif msg_dict["func"] == 'rotate_counterclockwise':
        #     data["x"] = 0

        for w in conn_clients:
            try:
                await w.send(json.dumps(data))
            except websockets.ConnectionClosed:
                conn_clients.remove(w)


async def main():
    async with websockets.serve(server, "localhost", 5000):
        print('Server started.')
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
