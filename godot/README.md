
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

### Important Reminder While Developing:
All obstacles (static bodies) that should be detected from ultrasonic sensor shall be renamed "obstacle".