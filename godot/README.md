
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
* All obstacles that should be detected from ultrasonic sensor shall be also in collision mask 8.
* Final rotation position is rounded (currently) in godot.
* Ground Sensor id are "hardcoded" in godot and set according to the yaml file of fossbot simulation in vrep.
* Camera sensors (ground + light) positions offsets and rotations should be changed inside of godot (so they update with robot).
* Wait time (that you send in godot) should be in seconds.
* For the soundfx to work, user has to click on the simulator gui (if user has chosen to play a soundfx).
* Reset dir function stops the fossbot, and sets the direction to forward (currently).
* Boolean Horizontal Ground = Set this to true if horizontal ground in scene for more accurate rotation and movement (you can also do it from editor). Restart scene to apply different value for boolean horizontal ground.
* To change camera: press 1 for player camera, 2 for orthogonal player camera, 3 for stage camera.
* To handle camera within screen: press right click and drag.