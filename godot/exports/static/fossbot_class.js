// Implementation for godot robot.

class FossBot {
    /** Godot robot */

    constructor(session_id, kwargs) {
        /**
         * @param {String} session_id: the session id.
         * @param kwargs (optional):
         * - fossbot_name (str): The name of the fossbot you want to control in the scene
                (to change this name, you should also change the name of the fossbot in the scene).
            - server_address (str): The address of the server. Defaults to 'http://localhost:8000'.
            - namespace (str): The namespace of the socketio for fossbot sim (default is "/godot").
            - motor_left_speed (float): The velocity of the left motor. Defaults to 100.
            - motor_right_speed (float): The velocity of the right motor. Defaults to 100.
            - default_step (float): The default step distance. Defaults to 15.
            - rotate_90 (float): The degree value. Defaults to 90.
            - light_sensor (float): The light value. Defaults to 700.
            - line_sensor_center (float): The value of the center sensor for black line detection. Defaults to 50.
            - line_sensor_right (float): The value of the right sensor for black line detection. Defaults to 50.
            - line_sensor_left (float): The value of the left sensor for black line detection. Defaults to 50.
            - sensor_distance (float): The max distance for detecting objects. Defaults to 15.
            - left_motor_name (str): The name of the left motor in the scene.
                Defaults to "left_motor" (to change it, you should also change it in the scene).
            - right_motor_name (str): The name of the right motor in the scene.
                Defaults to "right_motor" (to change it, you should also change it in the scene).
        */
        this.session_id = session_id;
        this.fossbot_name = kwargs.fossbot_name || "fossbot";
        const namespace = kwargs.namespace || "/godot";
        const server_address = kwargs.server_address || 'http://localhost:8000';
        const conn_url = server_address + namespace
        this.sio = io.connect(conn_url);

        this.sio.on("connect", () => {
            this.sio.emit("pythonConnect", {"session_id": this.session_id, "user_id": this.sio.id});
            console.log("Connected to socketio server on " + conn_url);
        });

        this.sio.on("godotError", result => {
            if (this.sio.connected) {
                this.sio.disconnect();
            }
            throw new Error(result["data"]);
        });

        this.vel_left = kwargs.motor_left_speed || 100;
        this.vel_right = kwargs.motor_right_speed || 100;
        this.default_dist = kwargs.default_step || 15;
        this.degree = kwargs.rotate_90 || 90;
        this.light_value = kwargs.light_sensor || 700;
        this.middle_sensor_val = kwargs.line_sensor_center || 50;
        this.right_sensor_val = kwargs.line_sensor_right || 50;
        this.left_sensor_val = kwargs.line_sensor_left || 50;
        this.sensor_distance = kwargs.sensor_distance || 15;
        this.motor_left_name = kwargs.left_motor_name || "left_motor";
        this.motor_right_name = kwargs.right_motor_name || "right_motor";
    }

    just_move(direction = "forward") {
        /**
         * Move forward/backwards.
         * @param: direction: the direction to be headed to.
         */
        if (!["forward", "reverse"].includes(direction)) {
            throw new Error('Uknown Direction!');
        }
        const param = {
            func: "just_move",
            vel_left: this.vel_left,
            vel_right: this.vel_right,
            direction: direction
        };
        this.__post_godot(param);
    }

    async move_distance(dist, direction = "forward") {
        if (dist < 0) {
            throw new Error("Negative Distance not allowed.");
        }
        if (!["forward", "reverse"].includes(direction)) {
            console.log('Uknown Direction!');
            throw new Error();
        }
        if (dist == 0) {
            return;
        }
        let param = {
            "func": "move_distance",
            "vel_left": this.vel_left,
            "vel_right": this.vel_right,
            "tar_dist": dist,
            "direction": direction
        };
        await this.__post_godot(param);
        let result = await this.__get_godot({ func: "dist_travelled", motor_name: this.motor_right_name});
        while (result < dist) {
            result = await this.__get_godot({ func: "dist_travelled", motor_name: this.motor_right_name});
        }
        // console.log("TRAVELLED DISTANCE!");
        this.stop();
    }

    reset_dir() {
        // Resets all motors direction to default (forward).
        const param = {
          func: "reset_dir"
        };
        this.__post_godot(param);
    }

    stop() {
        // Stop moving.
        const param = {
            func: "stop"
        };
        this.__post_godot(param);
    }

    async wait(time_s) {
        // Waits (sleeps) for an amount of time.
        await new Promise((resolve) => {
            setTimeout(() => {
                resolve();
            }, time_s * 1000);
        });
    }


    async move_forward_distance(dist) {
        // Moves robot forward input distance.
        await this.move_distance(dist);
    }

    async move_forward_default() {
        // Moves robot forward default distance.
        await this.move_distance(this.default_dist);
    }

    move_forward() {
        // Moves robot forwards.
        this.just_move();
    }

    async move_reverse_distance(dist) {
        // Moves robot input distance in reverse.
        await this.move_distance(dist, "reverse");
    }
    
    async move_reverse_default() {
        // Moves robot default distance in reverse.
        await this.move_distance(this.default_dist, "reverse");
    }

    move_reverse() {
        // Moves robot in reverse.
        this.just_move("reverse");
    }

    just_rotate(dir_id) {
        /*
         * Rotates fossbot towards the specified dirId.
         * Params:
         *   - dir_id: the direction id to rotate to:
         *            - counterclockwise: dirId == 0
         *            - clockwise: dirId == 1
         */
        if (![0, 1].includes(dir_id)) {
          throw new Error("Unknown Direction!");
        }
        const param = {
          func: "just_rotate",
          dir_id: dir_id,
          vel_right: this.vel_right,
          vel_left: this.vel_left,
        };
        this.__post_godot(param);
    }

    async rotate_90(dir_id) {
        /*
        * Rotates fossbot 90 degrees towards the specified dirId.
        * Params:
        *   - dir_id: the direction id to rotate 90 degrees:
        *            - counterclockwise: dirId == 0
        *            - clockwise: dirId == 1
        */
        if (![0, 1].includes(dir_id)) {
            throw new Error("Unknown Direction!");
        }
        const param = {
            func: "rotate_90",
            degree: this.degree,
            dir_id: dir_id,
            vel_right: this.vel_right,
            vel_left: this.vel_left,
        };
        await this.__post_godot(param);
        let result = await this.__get_godot({ func: "deg_rotated" });
        while (result < this.degree) {
            result = await this.__get_godot({ func: "deg_rotated" });
        }
        //console.log("ROTATED DEGREES!");
        this.stop();
    }

    rotate_clockwise() {
        /*
         * Rotates robot clockwise.
         */
        this.just_rotate(1);
    }
    
    rotate_counterclockwise() {
        /*
         * Rotates robot counterclockwise.
         */
        this.just_rotate(0);
    }

    async rotate_clockwise_90() {
        /*
         * Rotates robot 90 degrees clockwise.
         */
        await this.rotate_90(1);
    }

    async rotate_counterclockwise_90() {
        /*
         * Rotates robot 90 degrees counterclockwise.
         */
        await this.rotate_90(0);
    }


    async get_distance() {
        // Returns the distance from the closest obstacle.
        return await this.__get_godot({ func: "get_distance" });
    }

    async check_for_obstacle() {
        // Checks if there is an obstacle nearby.
        const i = await this.__get_godot({ func: "get_distance" });
        return i <= this.sensor_distance;
    }

    play_sound(audio_path) {
        // plays a sound (stored in simulator).
        const param = {
            func: "play_sound",
            sound_path: audio_path,
        };
        this.__post_godot(param);
    }

    async get_floor_sensor(sensor_id) {
        // Returns the reading value of a floor sensor.
        if (![1, 2, 3].includes(sensor_id)) {
            console.log(`Sensor id ${sensor_id} is out of bounds.`);
            return 0.0;
        }
        return await this.__get_godot({func: "get_floor_sensor", sensor_id: sensor_id});
    }

    async check_on_line(sensor_id) {
        // Checks if the requested sensor is on line.
        if (![1, 2, 3].includes(sensor_id)) {
          console.log(`Sensor id ${sensor_id} is out of bounds.`);
          return false;
        }

        const read = await this.__get_godot({func: "get_floor_sensor", sensor_id: sensor_id});
        //console.log(read);
        if (sensor_id === 1) {
            if (read <= this.middle_sensor_val / 100) {
                return true;
            }
        } else if (sensor_id === 2) {
            if (read <= this.right_sensor_val / 100) {
                return true;
            }
        } else if (sensor_id === 3) {
            if (read <= this.left_sensor_val / 100) {
                return true;
            }
        }
        return false;
    }


    // accelerometer
    async get_acceleration(axis) {
        /**
         * Gets acceleration of specified axis.
         * @param {string} axis - The axis to get the acceleration from.
         * @returns {number} - The acceleration of specified axis.
         */

        if (!['x', 'y', 'z'].includes(axis)) {
            console.log("Dimension not recognized!!");
            return 0.0;
        }

        const param = {
            func: "get_acceleration",
            axis: axis
        };

        const value = await this.__get_godot(param);
        console.log(value);
        return value;
    }

    async get_gyroscope(axis) {
        /**
         * Gets gyroscope of specified axis.
         * @param {string} axis - The axis to get the gyroscope from.
         * @returns {number} - The gyroscope of specified axis.
         */

        if (!['x', 'y', 'z'].includes(axis)) {
            console.log("Dimension not recognized!!");
            return 0.0;
        }
    
        const param = {
            func: "get_gyroscope",
            axis: axis
        };
    
        const value = await this.__get_godot(param);
        console.log(value);
        return value;
    }

    // rgb
    rgb_set_color(color) {
        /**
         * Sets a led to input color.
         * @param {string} color - The wanted color.
         */
        if (!['red', 'green', 'blue', 'white', 'violet', 'cyan', 'yellow', 'closed'].includes(color)) {
            console.log('Unknown color!');
            throw new Error('Unknown color!');
        }
        const param = {
            func: 'rgb_set_color',
            color: color,
        };
        this.__post_godot(param);
    }

    // light sensor
    async get_light_sensor() {
        /**
         * Returns the reading of the light sensor.
         * @returns {number} - The reading of the light sensor.
         */
        return await this.__get_godot({func: "get_light_sensor"});
    }

    async check_for_dark() {
        /**
         * Returns true only if light sensor detects dark.
         * @returns {boolean} - True if light sensor detects dark, else false.
         */
        const value = await this.__get_godot({func: "get_light_sensor"});
        console.log(value);
        return value < this.lightValue;
    }

    // noise detection
    async get_noise_detection() {
        /**
         * Returns true only if noise is detected.
         * @returns {boolean} - True if noise is detected, else false.
         */
        const state = await this.__get_godot({func: "get_noise_detection"});
        console.log(state);
        return state;
    }

    // exit
    exit() {
        /**
         * Exits.
         */
        if (this.sio.connected) {
            this.__post_godot({"func": "exit"});
            this.sio.disconnect();
        }
    }

    // timer
    stop_timer() {
        /**
         * Stops the timer.
         */
        const param = {
            func: 'stop_timer',
        };
        this.__post_godot(param);
    }

    start_timer() {
        /**
         * Starts the timer.
         */
        const param = {
            func: 'start_timer',
        };
        this.__post_godot(param);
    }

    async get_elapsed() {
        /**
         * Returns the time from start in seconds.
         * @returns {number} - The elapsed time in seconds.
         */
        const value = await this.__get_godot({func: "get_elapsed"});
        console.log('elapsed time in sec:', value);
        return value;
    }

    __post_godot(param) {
        /**
         * Used to post a response from Godot (POST).
         * @param {Object} param - The dictionary to be sent to Godot.
         */
        param.fossbot_name = this.fossbot_name;
        this.sio.emit("clientMessage", param);
    }

    async __get_godot(data) {
        // const result = await this.__asyncEmit(data);
        // return result;
        try {
            const result = await this.__asyncEmit(data);
            // console.log("RESULT FROM SOCKETIO: ", result); // Handle the result returned by the socket event
            return result; // Return the result to the caller
        } catch (error) {
            console.error("Error while getting data from godot: ", error);
        }
    }


    async __asyncEmit(data) {
        return new Promise((resolve, reject) => {
            data.fossbot_name = this.fossbot_name
            this.sio.emit("clientMessage", data);
            this.sio.on("godotMessage", result => {
                this.sio.off("godotMessage");
                resolve(result["data"]);
            });
            setTimeout(() => reject(new Error("Timeout")), 5000);
        });
    }

}
