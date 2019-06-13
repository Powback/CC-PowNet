class Main {
    //TODO: Calculate the optimal number of workers based on availability.

    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.step = 10;
        this.Init();
    }

    Init() {
        this.canvas = document.getElementById('renderer');
        this.ctx = this.canvas.getContext('2d');
        let w = 2048;
        let h = 2048;

        this.canvas.width  = w;
        this.canvas.height = h;
        this.Draw();
        this.DoLogic();
        this.DrawGrid(w,h,this.step);


    }
    Draw() {
        this.ctx.fillStyle = 'white';

    }

    DoLogic() {
        let min = new Vec3(50,0,23);
        let max = new Vec3(79,5, 80);

        this.DrawRect(min.x, min.z);
        this.DrawRect(max.x, max.z);

        this.ctx.fillStyle = 'green';
        this.GetStartStop(50, min, max)
    }

    GetOrientation(min,max) {
        let distanceX = Math.abs(max.x - min.z);
        let distanceY = Math.abs(max.y - min.y);
        let distanceZ = Math.abs(max.z - min.z);

        if(distanceX <= distanceZ) {
            return "x"
        } else {
            return "z"
        }
        //TODO: Z?
    }
    hasDecimal(number) {
        return number % 1 != 0
    }
    GetStartStop(workerCount, min, max) {

        let orientation = this.GetOrientation(min,max);

        let distanceX = Math.abs(max.x - min.x) + 1;
        let distanceY = Math.abs(max.y - min.y) + 1;
        let distanceZ = Math.abs(max.z - min.z) + 1;

        if(orientation === "x" && distanceX < workerCount) {
            workerCount = distanceX;
        }
        if(orientation === "y" && distanceY < workerCount) {
            workerCount = distanceY;
        }

        let incrementX = Math.round(distanceX / workerCount);
        let incrementY = Math.round(distanceY / workerCount);
        let incrementZ = Math.round(distanceZ / workerCount);
        let workers = [];
        for (let i = 0; i < workerCount; i++ ) {
            let worker_X_start;
            let worker_Z_start;
            let worker_X_end;
            let worker_Z_end;

            if(orientation == "x") {
                worker_X_start = min.x + (i * incrementX);
                worker_Z_start = min.z;

                worker_X_end = min.x + (i + 1) * incrementX - 1;
                worker_Z_end = max.z;
            } else {

                worker_X_start = min.x;
                worker_Z_start = min.z + (i * incrementZ);

                worker_X_end = max.x;
                worker_Z_end = min.z + (i + 1) * incrementZ - 1;
            }

            // Restrict to working area, cut off unmet
            if(worker_X_end > max.x) {
                worker_X_end = max.z;
            }
            if(worker_Z_end > max.z) {
                worker_Z_end = max.z;
            }
            //TODO: Some better way of dividing the tasks?
            //TODO: Invent a formula to figure out the optimal number of workers for this specific task.
            if(i + 1 === workerCount) { // Last worker, pad the last rows or columns
                if(worker_X_end < max.x) {
                    worker_X_end = max.x;
                }
                if(worker_Z_end < max.z) {
                    worker_Z_end = max.z;
                }
            }

            this.DrawRect(worker_X_start, worker_Z_start);
            this.DrawRect(worker_X_end, worker_Z_end);
            workers[i] = {
                min: new Vec3(worker_X_start, min.z, worker_Z_start),
                max: new Vec3(worker_X_end, min.z, worker_Z_end),

            };
        }
        this.DrawWorkers(workers);
        this.DoWork(workers, orientation)
    }

    DrawWorkers (workers) {
        for (let i = 0; i < workers.length; i++) {
            let worker = workers[i];
            this.DrawRect(worker.min.x, worker.min.z);
            this.ctx.fillStyle = 'red';

            this.DrawRect(worker.max.x, worker.max.z);
            this.ctx.fillStyle = 'green';
        }
    }


    DoWork(workers, orientation) {
        for (let i = 0; i < workers.length; i++) {
            let worker = workers[i];
            let distanceX = Math.abs(worker.max.x - worker.min.x);
            let distanceY = Math.abs(worker.max.y - worker.min.y);
            let distanceZ = Math.abs(worker.max.z - worker.min.z);

            let height = 6;
            let topBottom = false;
            let startSpot = StartSpots.BR;

            let rounds = height / 3;

            if(rounds < 1) {
                rounds = 1; // height is 1-3, we just need to go 1 round
            }
            if(this.hasDecimal(rounds)) {
                // We can't complete this run in one go
                rounds = Math.floor(rounds) + 1
            }
            //for (let round = 0; round < rounds; round++) {
                let safeZone = 0;

                //if(round === 0) {
                    safeZone = 2; // Make the drone dig out the 2 first rows first, so other drones can get to their spot.
              //  }



                //if(safeZone !== 0) {
            //this.UpDown(worker, startSpot, distanceX, distanceZ, orientation, safeZone);
            //this.UpDown(worker, startSpot, distanceX, distanceZ, "x", safeZone);
                //}
              //  this.ZigZag(worker, startSpot, distanceX, distanceZ, orientation, 10);
            //}

            //TODO: Y axis.
            //

            if(orientation == "x") {
                this.ZigZag2(worker, 1, distanceX, false);
                this.ZigZag2(worker, distanceX , distanceZ, true, 2);
            } else {
                this.ZigZag2(worker, 1, distanceZ, true, 0);
                this.ZigZag2(worker, distanceZ, distanceX, false, 2);
            }


            this.ctx.fillStyle = 'green';

        }
    }

    ZigZag2(worker, distanceX,distanceZ, flip, push = 0) {
        let x = 0;
        let z = 0;

            x = push;

        let xInvert = false;
        let lastTurn = 0;
        this.ctx.fillStyle = this.getRandomColor();

        let s_turn = [];

        let distanceA = distanceX;
        let distanceB = distanceZ;

        for (let i = 0; i <= distanceA; i++) {
            for (let i2 = push; i2 < distanceB; i2++) {
                if(x === distanceB) {
                    xInvert = true;
                }
                if(x === push) {
                    xInvert = false;
                }
                if(flip == false) {
                    this.DrawRect(worker.min.x + x, worker.min.z + z); // Draw current pos
                } else {
                    this.DrawRect(worker.min.x + z, worker.min.z + x); // Draw current pos
                }
                if(xInvert) {
                    x--;
                    s_turn.push("south")
                } else {
                    x++;
                    s_turn.push("north")
                }
                if(flip == false) {
                    this.DrawRect(worker.min.x + x, worker.min.z + z); // Draw current pos
                } else {
                    this.DrawRect(worker.min.x + z, worker.min.z + x); // Draw current pos
                }
            }
            if(z == distanceA) {
                return
            }

            s_turn.push("left");
            z++;
            if(flip == false) {
                this.DrawRect(worker.min.x + x, worker.min.z + z); // Draw current pos
            } else {
                this.DrawRect(worker.min.x + z, worker.min.z + x); // Draw current pos
            }
        }
    }

    AddToPath(x,y,flipped) {

    }

    getRandomColor() {
        var letters = '0123456789ABCDEF';
        var color = '#';
        for (var i = 0; i < 6; i++) {
            color += letters[Math.floor(Math.random() * 16)];
        }
        return color;
    }
    getScaled(x,y,z) {
        return new Vec3(x * this.step, y * this.step,y * this.step);
    }
    DrawRect(x,y,z) {
        let pos = this.getScaled(x,y,z);
        let scale = this.getScaled(1,1,1);
        this.ctx.fillRect(pos.x, pos.z, scale.x, scale.z);
        return;
    }
    DrawGrid(w, h, step) {
        this.ctx.beginPath();
        for (var x=0;x<=w;x+=step) {
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, h);
        }
        // set the color of the line
        this.ctx.strokeStyle = 'rgb(20,20,20)';
        this.ctx.lineWidth = 1;
        // the stroke will actually paint the current path
        this.ctx.stroke();
        // for the sake of the example 2nd path
        this.ctx.beginPath();
        for (var y=0;y<=h;y+=step) {
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(w, y);
        }
        // set the color of the line
        this.ctx.strokeStyle = 'rgb(20,20,20)';
        // just for fun
        this.ctx.lineWidth = 1;
        // for your original question - you need to stroke only once
        this.ctx.stroke();
    };
}
var StartSpots = {
    TL: 1,
    TR: 2,
    BL: 3,
    BR: 4
};
class Vec3 {
    constructor(x,y, z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}
