
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
* The velocities of the motors are not taken into consideration in rotation of x degrees (currently).
* Final rotation position is rounded (currently) in godot.
* Ground Sensor id are "hardcoded" in godot and set according to the yaml file of fossbot simulation in vrep.
* Camera sensors (ground + light) positions and rotations should be changed inside of godot (so they update with robot).