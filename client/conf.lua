local love = require("love");

function love.conf(t)
    t.console = true;
    t.window.resizable = true;
    t.window.width = 600;
    t.window.height = 500;
end