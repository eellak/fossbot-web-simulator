## How to run
To run the server and connect to the simulator, run from exports directory:
```bash
python3 server.py
```

This should run a socketio-flask server. Go to http://localhost:8000/godot and try the simulator!

All the files necessary for deployment are in the exports folder (just download it, run the server as shown above, and then you can test the simulator).

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
* To handle camera within screen: press right click and drag or movement keys (w, a, s, d or arrows).
* Camera Gimball has a camera_target in each fossbot (dont change the name of that!)
* For the Flask Server, make sure to have defined the url_for in template html (and also that all index.html is saved in templates and all the other required files for the sim in static).
* If you implement any GET methods in godot, it is recommended to add them to the list PARALLEL_METHODS (in godot).