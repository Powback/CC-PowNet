let snake = [  {x: 10, y: 0},  {x: 10, y: 11},  {x: 10, y: 12},  {x: 10, y: 13},  {x: 11, y: 14},];
class Main {
    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.step = 10;
        this.head = {};
        this.snake = {};
        this.Init();
    }

    Init() {
        this.canvas = document.getElementById('renderer');
        this.ctx = this.canvas.getContext('2d');
        let w = 2000;
        let h = 2000;

        this.canvas.width  = w;
        this.canvas.height = h;
        this.snake = snake;
        this.Draw();
        this.DrawGrid(w,h,this.step);
        let scope = this;

        snake.forEach(scope.drawSnakePart.bind(this));

    }
    advanceSnake() {
        var dy = 1;
        var dx = 1;

        this.head = {x: snake[0].x + dx, y: snake[0].y + dy};
        snake.unshift(this.head);
        snake.pop();}

    Draw() {
        this.DrawRect(5,5);
        this.DrawRect(6,6);
        this.DrawRect(100,6);
        let scope = this;
    }
    drawSnakePart(snakePart) {
        this.DrawRect(snakePart.x, snakePart.y);
    }



    getScaled(x,y) {
        return new Vec2(x * this.step, y * this.step);
    }
    DrawRect(x,y) {
        let pos = this.getScaled(x,y);
        let scale = this.getScaled(1,1);
        return this.ctx.fillRect(pos.x, pos.y, scale.x, scale.y);
    }
    DrawGrid(w, h, step) {
        this.ctx.beginPath();
        for (var x=0;x<=w;x+=step) {
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, h);
        }
        // set the color of the line
        this.ctx.strokeStyle = 'rgb(20,0,0)';
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
