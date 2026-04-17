local love = require("love");
local enet = require("enet");

local textbutton = require("textbutton");
local inputbox = require("inputbox");
local scrolling_window = require("scrolling_window");
local serialization = require("shared.serialization");

local IP_ADDRESS = "192.168.0.102"; -- Add your IP address, for instance 192.168.0.2 (you can check it by using ipconfig for Windows or ifconfig for Mac/Linux)
local PORT = "5000";

local host = enet.host_create();
local server = host:connect(IP_ADDRESS .. ":" .. PORT);

local main_canvas = love.graphics.newCanvas(1920, 1080);
local chat_canvas = love.graphics.newCanvas(1920, 1080);

local player_username = "";
local chat_message = "";

local is_connected = false;

local USERNAME_INPUT_WINDOW_SIZE = {250 / love.graphics.getWidth(), 40 / love.graphics.getHeight()};
local ENTER_CHAT_BUTTON_SIZE = {150 / love.graphics.getWidth(), 40 / love.graphics.getHeight()};
local CHAT_INPUT_WINDOW_SIZE = {love.graphics.getWidth(), 0};
local CHAT_WINDOW_SIZE = {love.graphics.getWidth(), love.graphics.getHeight() * .75};

local methods = {
    ["backspace"] = function(t)
        return string.sub(t, 1, #t - 1);
    end,

    ["return"] = function(t)
        if #t == 0 then return; end

        local data = serialization.encode({"Receive", t});
        server:send(data);

        return "";
    end,
}

function love.quit()
    local data = serialization.encode({"Disconnect", player_username});
    server:send(data);

    host:flush();
end

function love.keypressed(key) -- Special detection for backspace key
    love.keyboard.setKeyRepeat(true);

    if not methods[key] then return; end

    if not is_connected then
        local res = methods[key](player_username);
        player_username = res or "";
    else
        local res = methods[key](chat_message);
        chat_message = res or "";
    end
end

function love.textinput(key)
    if not is_connected then
        if string.len(player_username) >= 30 then
            player_username = player_username;
        else
            player_username = player_username .. key;
        end
    else
        chat_message = chat_message .. key;
    end
end

function love.wheelmoved(x, y)
    CHAT_WINDOW:scroll(x * -1, y * -1);
end

local function calculate_ui_size(x, y)
    return {love.graphics.getWidth() * x, love.graphics.getHeight() * y};
end

function love.load()
    USERNAME_INPUTBOX = inputbox.new("UsernameInputbox", {}, {.5, 0}, {{love.graphics.getWidth() * .5, love.graphics.getHeight() * .65}}, calculate_ui_size(USERNAME_INPUT_WINDOW_SIZE[1], USERNAME_INPUT_WINDOW_SIZE[2]), love.graphics.newFont(20, "none"));
    USERNAME_INPUTBOX:setText(#player_username > 0 and player_username or "Enter your username...");
    USERNAME_INPUTBOX:addTextAlignment({.5, .5});
    USERNAME_INPUTBOX:setBoxScaling({1, 0});

    CONNECT_BUTTON = textbutton.new("ConnectButton", {{0, 0.25, 1, 1}}, {.5, 0}, {{love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.75}}, calculate_ui_size(ENTER_CHAT_BUTTON_SIZE[1], ENTER_CHAT_BUTTON_SIZE[2]), love.graphics.newFont(20, "none"));
    CONNECT_BUTTON:setText({{1, 1, 1}, "Connect!"}, 0, 0);
    CONNECT_BUTTON:addTextAlignment({.5, .5});

    CHAT_INPUTBOX = inputbox.new("ChatInputbox", {}, {.5, 1}, {{love.graphics.getWidth() * .5, love.graphics.getHeight()}, {3, 5}}, CHAT_INPUT_WINDOW_SIZE, love.graphics.newFont(18, "none"));
    CHAT_INPUTBOX:setText(#chat_message > 0 and chat_message or "Enter a message here to send to chat...");
    CHAT_INPUTBOX:addTextAlignment({0, 0});
    CHAT_INPUTBOX:setBoxScaling({0, 1});

    CHAT_WINDOW = scrolling_window.new("ChatWindow", {0, 0, 0, 0}, {0, 0}, CHAT_WINDOW_SIZE, love.graphics.newFont(18, "none"));
end

function love.draw()
    if not is_connected then
        love.graphics.setCanvas(main_canvas);
        love.graphics.clear();

        USERNAME_INPUTBOX:draw();
        CONNECT_BUTTON:draw();

        USERNAME_INPUTBOX:setText(#player_username > 0 and player_username or "Enter your username...");

        CONNECT_BUTTON:onClick(function()
            is_connected = true;
        end)

        love.graphics.setCanvas();

        love.graphics.draw(main_canvas);
    else
        love.graphics.setCanvas(chat_canvas);
        love.graphics.clear();

        CHAT_WINDOW:draw();
        CHAT_INPUTBOX:draw();

        CHAT_INPUTBOX:setText(#chat_message > 0 and chat_message or "Enter a message here to send to chat...");

        love.graphics.setCanvas();

        love.graphics.draw(chat_canvas);
    end
end

local client_callback_list = {
    ["Connect"] = function(peer, data) -- Function that will be fired everytime new player joins the chat
        local username = data[2];
    
        local content = string.format("%s has joined the chat!", username);
        CHAT_WINDOW:addContent(content);
    end,

    ["Disconnect"] = function(peer, data) -- Function that will be fired everytime player leaves the chat 
        local username = data[2];
    
        local content = string.format("%s has left the chat!", username);
        CHAT_WINDOW:addContent(content);
    end,

    ["Receive"] = function(peer, data) -- Function that will be fired everytime player receives data from the server
        local username = data[2];
        local message = data[3];

        local content = string.format("[%s]: %s", username, message);
        CHAT_WINDOW:addContent(content);
    end,
}

function love.resize()
    CHAT_WINDOW:onWindowScaled({0, 0}, {love.graphics.getWidth(), love.graphics.getHeight() * 0.75});
end

function love.update(dt)
    USERNAME_INPUTBOX:updatePositionAndSize({{love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.65}});
    CONNECT_BUTTON:updatePositionAndSize({{love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.75}});
    CHAT_INPUTBOX:updatePositionAndSize({{love.graphics.getWidth() * 0.5, love.graphics.getHeight()}, {3, 5}}, {love.graphics.getWidth(), 0});
    CHAT_WINDOW:updatePositionAndSize({0, 0}, {love.graphics.getWidth(), love.graphics.getHeight() * 0.75});

    if is_connected then
        local event = host:service();

        while event do
            if event.type == "connect" then
                local data = serialization.encode({"Connect", player_username});
                event.peer:send(data);
    
            elseif event.type == "receive" then
                local data = serialization.decode(event.data);
                if not data then return; end

                local method = data[1];
                client_callback_list[method](event.peer, data);
            end

            event = host:service();
        end
    end
end