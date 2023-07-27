
## How to run
To execute this program, first run in the export folder:
```bash
python -m http.server 
```
Then, open websocket server by running:
```bash
py .\server.py 
```
or, for Unix Systems:
```bash
python3 .\server.py 
```

This should run the websocket server (currently runs on localhost:5000, if you want this changed, you should also change it in Godot).

Go to http://localhost:8000/ (the default port of "python -m http.server") and try the simulator!

---
### Important Reminders While Developing:
* All obstacles (static bodies) that should be detected from ultrasonic sensor shall be renamed "obstacle".
* Final rotation position is rounded (currently) in godot if boolean linear_ground = true.
* Ground Sensor id are "hardcoded" in godot and set according to the yaml file of fossbot simulation in vrep.
* Camera sensors (ground + light) positions and rotations should be changed inside of godot (so they update with robot).
* Wait time (that you send in godot) should be in seconds.
* For the soundfx to work, user has to click on the simulator gui (if use has chosen to play a soundfx).
* Reset dir function stops the fossbot, and sets the direction to forward (currently).
* Boolean Horizontal Ground (used to directly rotate) = Set this to false if not horizontal ground in scene (you can also do it from editor).