class Main {
    //TODO: Calculate the optimal number of workers based on availability.

    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.step = 5;
        this.Init();
    }

    Init() {
        this.canvas = document.getElementById('renderer');
        this.ctx = this.canvas.getContext('2d');
        let w = 1000;
        let h = 1000;

        this.canvas.width = w;
        this.canvas.height = h;
        this.Draw();
        this.DoLogic();
        this.DrawGrid(w,h,this.step);


    }
    Draw() {
        this.ctx.fillStyle = 'white';

    }

    DoLogic() {
        let min = new Vec3(7,0,23);
        let max = new Vec3(2,5, 80);

        this.DrawRect(min.x, min.z);
        this.DrawRect(max.x, max.z);

        this.ctx.fillStyle = 'green';
        this.GetStartStop(2, min, max)
    }

    GetOrientation(min,max) {
        let distanceX = Math.abs(max.x - min.x);
        let distanceY = Math.abs(max.y - min.y);
        let distanceZ = Math.abs(max.z - min.z);

        if(distanceX <= distanceZ) {
            return "z"
        } else {
            return "x"
        }
        //TODO: Z?
    }
    hasDecimal(number) {
        return number % 1 != 0
    }
    GetStartStop(workerCount, p_Min, p_Max) {
        let min = p_Min.Clone();
        let max = p_Max.Clone();
        if(p_Min.x > p_Max.x) {
            min.x = p_Max.x;
            max.x = p_Min.x;
        }
        if(p_Min.y > p_Max.y) {
            min.y = p_Max.y;
            max.y = p_Min.y;
        }
        if(p_Min.z > p_Max.z) {
            min.z = p_Max.z;
            max.z = p_Min.z;
        }

        let orientation = this.GetOrientation(min,max);

        let distanceX = Math.abs(max.x - min.x);
        let distanceY = Math.abs(max.y - min.y);
        let distanceZ = Math.abs(max.z - min.z);

        if(orientation === "z" && distanceX < workerCount) {
            workerCount = distanceX;
        }
        if(orientation === "x" && distanceY < workerCount) {
            workerCount = distanceY;
        }
        console.log(workerCount)

        let incrementX = Math.round(distanceX / workerCount);
        let incrementY = Math.round(distanceY / workerCount);
        let incrementZ = Math.round(distanceZ / workerCount);
        console.log(incrementX)
        let workers = [];
        for (let i = 0; i < workerCount; i++ ) {
            let worker_X_start;
            let worker_Z_start;
            let worker_X_end;
            let worker_Z_end;

            if(orientation == "z") {
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
                pos: new Vec3(worker_X_start, min.z, worker_Z_start),
                direction: "west"
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
            let grid = this.GenerateGrid(worker.min, worker.max);
            grid[worker.pos.x][worker.pos.y][worker.pos.z] = 0;
            let workRemaining = this.GetWorkAmount(worker.min, worker.max);

            let sideStep = false;

            while(workRemaining > 0) {

                this.ctx.fillStyle = this.getRandomColor();
                let distances = this.GetDistances(worker.pos, grid);

                // Direct neighbor
                if (distances[1] !== undefined) {
                    let target = distances[1][0];
                    if(distances[1][1] !== undefined && sideStep) {
                        target = distances[1][1];
                    }
                    let limit;
                    if(sideStep) {
                        limit = 1;
                    }
                    worker.direction = this.GetDirection(worker.pos, target);
                    let move = this.MoveUntilStop(worker, grid, limit);
                    workRemaining = workRemaining - move.count
                }
                if(sideStep) {
                    sideStep = false;
                } else {
                    sideStep = true;
                }
            }
        }
    }

    MoveUntilStop(worker, grid, limit = 100000000) {
        let s_Pos = worker.pos;
        let moveCount = 0;
        let s_Index = 0;
        while (this.Forward(worker, grid) !== false && s_Index < limit) {
            s_Index++;
            grid[worker.pos.x][worker.pos.y][worker.pos.z] = 0;
            this.DrawRect(worker.pos.x, worker.pos.z); // Draw current pos
            moveCount++;
        }
        return {count: moveCount, pos: s_Pos}

    }

    Forward(worker, grid) {
        let s_ExpectedPos = this.Move( {x: worker.pos.x, y: worker.pos.y, z: worker.pos.z}, worker.direction);
        if(s_ExpectedPos.x > worker.max.x || s_ExpectedPos.y > worker.max.y || s_ExpectedPos.z > worker.max.z) {
            return false
        } else if(s_ExpectedPos.x < worker.min.x || s_ExpectedPos.y < worker.min.y || s_ExpectedPos.z < worker.min.z) {
            return false
        } else if(grid[s_ExpectedPos.x][s_ExpectedPos.y][s_ExpectedPos.z] === 0) {
            return false
        } else {
            worker.pos = s_ExpectedPos
        }
    }

    Move(pos, direction) {
        if(direction === "north") {
            pos.z--
        }
        if(direction === "south") {
            pos.z++
        }
        if(direction === "east") {
            pos.x++
        }
        if(direction === "west") {
            pos.x--
        }
        return pos
    }
    OppositeDir(dir) {
        if(dir === "south") {
            return "north"
        }
        if(dir === "north") {
            return "south"
        }
        if(dir === "west") {
            return "east"
        }
        if(dir === "east") {
            return "west"
        }
    }
    GetDirection(currentPos, pos) {
        if(pos.z < currentPos.z) {
            return "north"
        }
        if(pos.z > currentPos.z) {
            return "south"
        }
        if(pos.x > currentPos.x) {
            return "east"
        }
        if(pos.x < currentPos.x) {
            return "west"
        }


    }

    GenerateGrid(min, max) {
        let grid = [];

        for(let x = min.x; x <= max.x; x++) {
            if(grid[x] == undefined) {
                grid[x] = [];
            }
            for (let y = min.y; y <= max.y; y++) {
                if(grid[x][y] == undefined) {
                    grid[x][y] = [];
                }
                for (let z = min.z; z <= max.z; z++) {
                    grid[x][y][z] = 1
                }
            }
        }
        return grid;
    }

    GetWorkAmount(p_Min, p_Max) {
        let distance = Math.abs(p_Max.x - p_Min.x) + 1
        distance = distance * Math.abs(p_Max.z - p_Min.z);
        return distance
    }
    GetDistance(a,b) {
        return Math.abs(a - b);
    }
    GetDistances(pos, grid) {
        let distances = [];
        Object.keys(grid).forEach(function(x) {
            Object.keys(grid[x]).forEach(function(y) {
                Object.keys(grid[x][y]).forEach(function(z) {
                    if (x == pos.x && y == pos.y && z == pos.z) {
                    } else {
                        if(grid[x][y][z] == 1) {
                            let distance = 0;
                            distance += Math.abs(pos.x - x);
                            //distance += Math.abs(pos.y - y);
                            distance += Math.abs(pos.z - z);
                            if(distances[distance] === undefined) {
                                distances[distance] = []
                            }
                            distances[distance].push({x: x, y:y, z:z})
                        }

                    }
                });
            });
        });
        return distances
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
        console.log("a:" + distanceA);
        console.log("b:" + distanceB);

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
                console.log(s_turn)

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

    Clone() {
        return new Vec3(this.x, this.y, this.z)
    }

}
