class Main {
    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.step = 10;
        this.Init();
    }

    Init() {
        this.canvas = document.getElementById('renderer');
        this.ctx = this.canvas.getContext('2d');
        let w = 500;
        let h = 500;

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
        let min = new Vec3(10,5,10);
        let max = new Vec3(20,10, 20);

        this.DrawRect(min.x, min.z);
        this.DrawRect(max.x, max.z);

        this.ctx.fillStyle = 'green';
        let orientation = this.GetOrientation(min,max);
        this.GetStartStop(5, min, max, orientation)
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
        //TODO: Z
    }
    hasDecimal(number) {
        return number % 1 != 0
    }
    GetStartStop(workerCount, min, max, orientation) {
        let distanceX = Math.abs(max.x - min.x) + 1;
        let distanceY = Math.abs(max.y - min.y) + 1;
        let distanceZ = Math.abs(max.z - min.z) + 1;

        let incrementX = Math.floor(distanceX / workerCount);
        let incrementY = Math.floor(distanceY / workerCount);
        let incrementZ = Math.floor(distanceZ / workerCount);

        let odd = false;
        if(this.hasDecimal(distanceX / workerCount) || this.hasDecimal(distanceZ / workerCount)) {
            odd = true;
        }

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

            this.DrawRect(worker_X_start, worker_Z_start);
            this.DrawRect(worker_X_end, worker_Z_end);
            workers[i] = {
                min: new Vec3(worker_X_start, min.z, worker_Z_start),
                max: new Vec3(worker_X_end, min.z, worker_Z_end),

            };
        }
        this.DrawWorkers(workers);
        this.DoWork(workers, orientation, odd)
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


    DoWork(workers, orientation, odd) {
        for (let i = 0; i < workers.length; i++) {
            let worker = workers[i];
            let distanceX = Math.abs(worker.max.x - worker.min.x);
            let distanceY = Math.abs(worker.max.y - worker.min.y);
            let distanceZ = Math.abs(worker.max.z - worker.min.z);

            if(i === workers.length - 1 && odd === true) { // If this is the last worker
                if(orientation === "x") {
                    distanceX++;
                    worker.max.x++;
                } else {
                    distanceZ++;
                    worker.max.z++;
                }
            }
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
                    this.UpDown(worker, startSpot, distanceX, distanceZ, orientation, safeZone);
                //}
                this.ZigZag(worker, startSpot, distanceX, distanceZ, orientation, safeZone);
            //}


            this.ctx.fillStyle = 'green';

        }
    }

    // What the fuck is this algo
    GetNextPos(min,max,x,z,startSpot, orientation, inverted) {
        if(orientation === "x") {
            if (inverted) {
                if (startSpot === StartSpots.TL) {
                    return {
                        x: max.x - x,
                        z: min.z + z
                    };
                }

                if (startSpot === StartSpots.TR) {
                    return {
                        x: min.x + x,
                        z: min.z + z

                    };
                }
                if (startSpot === StartSpots.BL) {
                    return {
                        x: max.x - x,
                        z: max.z - z

                    };
                }
                if (startSpot === StartSpots.BR) {
                    return {
                        x: min.x + x,
                        z: max.z - z

                    };
                }
            }
            //
            if (startSpot === StartSpots.TL) {
                return {
                    x: min.x + x,
                    z: min.z + z
                };
            }

            if (startSpot === StartSpots.TR) {
                return {
                    x: max.x - x,
                    z: min.z + z

                };
            }
            if (startSpot === StartSpots.BL) {
                return {
                    x: min.x + x,
                    z: max.z - z

                };
            }
            if (startSpot === StartSpots.BR) {
                return {
                    x: max.x - x,
                    z: max.z - z

                };
            }
        }
        if(orientation === "z") {

            if (inverted) {
                if (startSpot === StartSpots.TL) {
                    return {
                        x: min.x + x,
                        z: max.z - z
                    };
                }

                if (startSpot === StartSpots.TR) {
                    return {
                        x: max.x - x,
                        z: max.z - z

                    };
                }
                if (startSpot === StartSpots.BL) {
                    return {
                        x: min.x + x,
                        z: min.z + z

                    };
                }
                if (startSpot === StartSpots.BR) {
                    return {
                        x: max.x - x,
                        z: min.z + z

                    };
                }
            }
            //
            if (startSpot === StartSpots.TL) {
                return {
                    x: min.x + x,
                    z: min.z + z
                };
            }

            if (startSpot === StartSpots.TR) {
                return {
                    x: max.x - x,
                    z: min.z + z

                };
            }
            if (startSpot === StartSpots.BL) {
                return {
                    x: min.x + x,
                    z: max.z - z

                };
            }
            if (startSpot === StartSpots.BR) {
                return {
                    x: max.x - x,
                    z: max.z - z

                };
            }
        }
    }


    UpDown(worker, startSpot, distanceX, distanceZ, orientation, safeZone) {
        let step = 0;

        let aVal = safeZone;
        let bVal = distanceX;

        // Flip a,b/x,y depending on optimal rotation.

        if(orientation === "z") {
            aVal = safeZone;
            bVal = distanceZ;
        }
        let inverted = false;

        for (let a = 0; a < aVal; a++) {
            for (let b = 0; b <= bVal; b++) {
                this.ctx.fillStyle = '#FFFFFF' + step + '0';
                step++;
                let x = b;
                let z = a;
                if(orientation === "z") {
                    x = a;
                    z = b;
                }

                let nextPos = this.GetNextPos(worker.min,worker.max,x,z,startSpot, orientation, inverted);

/*
                x: min.min.x + x,
                z: min.min.z + z

                if(down) {
                    if(orientation === "z") {
                        nextPos = {
                            x: worker.min.x + x,
                            z: worker.max.z - z
                        };
                    }else if(orientation === "x") {
                        nextPos = {
                            x: worker.max.x - x,
                            z: worker.min.z + z
                        };
                    }
                }*/
                this.DrawRect(nextPos.x, nextPos.z);
            }
            if(inverted) {
                inverted = false
            } else {
                inverted = true
            }
        }
    }


    ZigZag(worker, startSpot, distanceX, distanceZ, orientation, safeZone) {
        let inverted = false;
        let aVal = distanceX ;
        let bVal = distanceZ;

        if(orientation === "z") {
            aVal = distanceZ;
            bVal = distanceX;
        }
        let step = 0;

        for (let a = 0; a <= aVal; a++) {
            for (let b = safeZone; b <= bVal; b++) {
                this.ctx.fillStyle = 'yellow';
                step++;

                let x = a;
                let z = b;
                if(orientation === "z") {
                    x = b;
                    z = a;
                }

                let nextPos = this.GetNextPos(worker.min,worker.max,x,z,startSpot, orientation, inverted);


                this.DrawRect(nextPos.x, nextPos.z);
            }
            if(inverted) {
                inverted = false
            } else {
                inverted = true
            }
        }
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
