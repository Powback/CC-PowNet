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
        let min = new Vec2(20,20);
        let max = new Vec2(32,30);

        this.DrawRect(min.x, min.y);
        this.DrawRect(max.x, max.y);

        this.ctx.fillStyle = 'green';
        let orientation = this.GetOrientation(min,max);
        this.GetStartStop(2, min, max, orientation)
    }

    GetOrientation(min,max) {
        let distanceX = Math.abs(max.x - min.x);
        let distanceY = Math.abs(max.y - min.y);
        if(distanceX <= distanceY) {
            return "x"
        } else {
            return "y"
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
        if(this.hasDecimal(distanceX / workerCount) || this.hasDecimal(distanceY / workerCount)) {
            odd = true;
        }

        let workers = [];
        for (let i = 0; i < workerCount; i++ ) {
            let worker_X_start;
            let worker_Y_start;
            let worker_X_end;
            let worker_Y_end;
            if(orientation == "x") {
                worker_X_start = min.x + (i * incrementX);
                worker_Y_start = min.y;

                worker_X_end = min.x + (i + 1) * incrementX - 1;
                worker_Y_end = max.y;
            } else {
                worker_X_start = min.x;
                worker_Y_start = min.y + (i * incrementY);

                worker_X_end = max.x;
                worker_Y_end = min.y + (i + 1) * incrementY - 1;
            }

            this.DrawRect(worker_X_start, worker_Y_start);
            this.DrawRect(worker_X_end, worker_Y_end);
            workers[i] = {
                min: new Vec2(worker_X_start, worker_Y_start),
                max: new Vec2(worker_X_end, worker_Y_end),

            };
        }
        this.DrawWorkers(workers);
        this.DoWork(workers, orientation, odd)
    }

    DrawWorkers (workers) {
        for (let i = 0; i < workers.length; i++) {
            let worker = workers[i];
            this.DrawRect(worker.min.x, worker.min.y);
            this.ctx.fillStyle = 'red';

            this.DrawRect(worker.max.x, worker.max.y);
            this.ctx.fillStyle = 'green';
        }
    }


    DoWork(workers, orientation, odd) {

        for (let i = 0; i < workers.length; i++) {
            let worker = workers[i];
            let distanceX = Math.abs(worker.max.x - worker.min.x);
            let distanceY = Math.abs(worker.max.y - worker.min.y);
            if(i === workers.length - 1 && odd === true) { // If this is the last worker
                if(orientation == "x") {
                    distanceX++;
                    worker.max.x++;
                } else {
                    distanceY++;
                    worker.max.y++;
                }
            }
            let step = 0;

            let aVal = 2;
            let bVal = distanceX;


            if(orientation === "y") {
                aVal = 2;
                bVal = distanceY;
            }
            let down = false; // me_irl

            for (let a = 0; a < aVal; a++) {
                for (let b = 0; b <= bVal; b++) {
                    this.ctx.fillStyle = '#FFFFFF' + step + '0';
                    step++;
                    let x = b;
                    let y = a;
                    if(orientation === "y") {
                        x = a;
                        y = b;
                    }
                    let nextPos = {
                        x: worker.min.x + x,
                        y: worker.min.y + y
                    };
                    if(down) {
                        if(orientation === "y") {
                            nextPos = {
                                x: worker.min.x + x,
                                y: worker.max.y - y
                            };
                        }else if(orientation === "x") {
                            nextPos = {
                                x: worker.max.x - x,
                                y: worker.min.y + y
                            };
                        }
                    }
                    this.DrawRect(nextPos.x, nextPos.y);
                }
                if(down) {
                    down = false
                } else {
                    down = true
                }
            }
            aVal = distanceX;
            bVal = distanceY;

            if(orientation === "y") {
                aVal = distanceY;
                bVal = distanceX;
            }

            for (let a = 0; a <= aVal; a++) {
                for (let b = 2; b <= bVal; b++) {
                    this.ctx.fillStyle = '#FFFFFF' + step + '0';
                    step++;

                    let x = a;
                    let y = b;
                    if(orientation === "y") {
                        x = b;
                        y = a;
                    }
                    let nextPos = {
                        x: worker.min.x + x,
                        y: worker.min.y + y
                    };
                    if(down) {
                        if(orientation === "y") {
                            nextPos = {
                                x: worker.min.x + x,
                                y: worker.max.y - y
                            };
                        }else if(orientation === "x") {
                            nextPos = {
                                x: worker.min.x + x,
                                y: worker.max.y - (y - 2)
                            };
                        }
                    }


                    this.DrawRect(nextPos.x, nextPos.y);
                }
                if(down) {
                    down = false
                } else {
                    down = true
                }
            }


            this.DrawRect(worker.max.x, worker.max.y);
            this.ctx.fillStyle = 'green';
        }
    }

    getScaled(x,y) {
        return new Vec2(x * this.step, y * this.step);
    }
    DrawRect(x,y) {
        let pos = this.getScaled(x,y);
        let scale = this.getScaled(1,1);
        this.ctx.fillRect(pos.x, pos.y, scale.x, scale.y);
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

class Vec2 {
    constructor(x,y) {
        this.x = x;
        this.y = y;
    }
}
