local love = require("love");
local enet = require("enet");

local textbutton = require("textbutton");
local inputbox = require("inputbox");
local scrolling_window = require("scrolling_window");

local IP_ADDRESS = "192.168.229.94";

local host = enet.host_create();
local peer = host:connect(IP_ADDRESS .. ":5000");

local main_canvas = love.graphics.newCanvas(1920, 1080);
local chat_canvas = love.graphics.newCanvas(1920, 1080);

local player_username = "";
local chat_message = "";

local is_connected = false;

local INPUT_WINDOW_SIZE = {250 / love.graphics.getWidth(), 40 / love.graphics.getHeight()};
local ENTER_CHAT_BUTTON_SIZE = {150 / love.graphics.getWidth(), 40 / love.graphics.getHeight()};

local prevWidth = love.graphics.getWidth();

local function does_mouse_hover_button(pos, size)
    local mouse_pos = {love.mouse.getX(), love.mouse.getY()};

    local button_center = {pos[1] + size[1] / 2, pos[2] + size[2] / 2};

    local within_hor = math.abs(mouse_pos[1] - button_center[1]) <= size[1] * .5;
    local within_ver = math.abs(mouse_pos[2] - button_center[2]) <= size[2] * .5;

    return within_hor and within_ver;
end

local methods = {
    ["backspace"] = function(t)
        return string.sub(t, 1, #t - 1);
    end,

    ["return"] = function(t)
        if #t == 0 then return end

        peer:send(encode_data({"Receive", t}));
        return "";
    end
}

function love.keypressed(key) -- Special detection for backspace key
    love.keyboard.setKeyRepeat(true);

    if not methods[key] then return end

    if not is_connected then
        local res = methods[key](player_username);
        player_username = res or "";
    else
        local res = methods[key](chat_message);
        chat_message = res or "";
    end
end

function love.textinput(key) -- Adds pressed keys to the player username
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

function love.load()
    USERNAME_INPUTBOX = inputbox.new("UsernameInputbox", {}, {.5, 0}, {{love.graphics.getWidth() * .5, love.graphics.getHeight() * .65}}, {love.graphics.getWidth() * INPUT_WINDOW_SIZE[1], love.graphics.getHeight() * INPUT_WINDOW_SIZE[2]}, love.graphics.newFont(20, "none"));
    USERNAME_INPUTBOX:setText({{1, 1, 1}, #player_username > 0 and player_username or "Enter your username..."}, 0, 0);
    USERNAME_INPUTBOX:addTextAlignment({.5, .5});
    USERNAME_INPUTBOX:setBoxScaling({1, 0});

    CONNECT_BUTTON = textbutton.new("ConnectButton", {{0, 0.25, 1, 1}}, {.5, 0}, {{love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.75}}, {love.graphics.getWidth() * ENTER_CHAT_BUTTON_SIZE[1], love.graphics.getHeight() * ENTER_CHAT_BUTTON_SIZE[2]}, love.graphics.newFont(20, "none"));
    CONNECT_BUTTON:setText({{1, 1, 1}, "Connect!"}, 0, 0);
    CONNECT_BUTTON:addTextAlignment({.5, .5});

    CHAT_INPUTBOX = inputbox.new("ChatInputbox", {}, {.5, 1}, {{love.graphics.getWidth() * .5, love.graphics.getHeight()}, {3, 5}}, {love.graphics.getWidth(), 0}, love.graphics.newFont(18, "none"));
    CHAT_INPUTBOX:setText({{1, 1, 1}, #chat_message > 0 and chat_message or "Enter a message here to send to chat..."}, 0, 0);
    CHAT_INPUTBOX:addTextAlignment({0, 0});
    CHAT_INPUTBOX:setBoxScaling({0, 1});

    CHAT_WINDOW = scrolling_window.new("ChatWindow", {0, 0, 0, 0}, {0, 0}, {love.graphics.getWidth(), love.graphics.getHeight() * .75}, love.graphics.newFont(18, "none"));
end

local function accumulate_chat_message_width(message, tab)
    local width = message:getWidth();

    for _, s in ipairs(tab) do
        width = width - s;
    end

    return width;
end

function love.draw()
    if not is_connected then
        love.graphics.setCanvas(main_canvas);
        love.graphics.clear();

        USERNAME_INPUTBOX:draw();
        CONNECT_BUTTON:draw();

        local message_to_draw = #player_username > 0 and player_username or "Enter your username...";
        local real_msg = "";
        local fake_msg = "";

        local accumulated_width = 0;
        local tab = {};

        for c in message_to_draw:gmatch(".") do
            real_msg = real_msg .. c;
            fake_msg = fake_msg .. c;

            USERNAME_INPUTBOX:setText({{1, 1, 1}, fake_msg}, 0, 0);

            accumulated_width = accumulate_chat_message_width(USERNAME_INPUTBOX.text, tab);

            if accumulated_width + 20 > love.graphics.getWidth() then real_msg = real_msg .. "\n"; table.insert(tab, accumulated_width); end
        end

        USERNAME_INPUTBOX:setText({{1, 1, 1}, real_msg}, 0, 0);

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

        local message_to_draw = #chat_message > 0 and chat_message or "Enter your username...";
        local real_msg = "";
        local fake_msg = "";

        local accumulated_width = 0;
        local tab = {};

        for c in message_to_draw:gmatch(".") do
            real_msg = real_msg .. c;
            fake_msg = fake_msg .. c;

            CHAT_INPUTBOX:setText({{1, 1, 1}, fake_msg}, 0, 0);

            accumulated_width = accumulate_chat_message_width(CHAT_INPUTBOX.text, tab);

            if accumulated_width + 20 > love.graphics.getWidth() then real_msg = real_msg .. "\n"; table.insert(tab, accumulated_width); end
        end

        CHAT_INPUTBOX:setText({{1, 1, 1}, real_msg}, 0, 0);

        love.graphics.setCanvas();

        love.graphics.draw(chat_canvas);
    end
end

function encode_data(data_to_encode)
    if type(data_to_encode) ~= "table" then return end

    local encoded_data = "";

    for i, k in pairs(data_to_encode) do
        local data = i .. ":" .. k .. ";";
        encoded_data = encoded_data .. data;
    end

    return encoded_data;
end

function decode_data(data_to_decode)
    if type(data_to_decode) ~= "string" then return end

    local decoded_data = {};

    for line in string.gmatch(data_to_decode, "([^;]+)") do
        local index, key = string.match(line, "([^:]+):([^:]+)");

        table.insert(decoded_data, index, key);
    end

    return decoded_data;
end

local client_responses = {
    ["Connect"] = function(peer, username) -- Function that will be fired everytime new player joins the chat
    end,

    ["Disconnect"] = function(peer) -- Function that will be fired everytime player leaves the chat 
    end,

    ["Receive"] = function(peer, data) -- Function that will be fired everytime player receives data from the server
        local username = data[2];
        local message = data[3];

        local content = string.format("[%s]: %s", username, message);
        CHAT_WINDOW:addContent(content);
    end,
}

function love.update(dt)
    --main_canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight());

    USERNAME_INPUTBOX:updatePositionAndSize({{love.graphics.getWidth() * .5, love.graphics.getHeight() * .65}});
    CONNECT_BUTTON:updatePositionAndSize({{love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.75}});
    CHAT_INPUTBOX:updatePositionAndSize({{love.graphics.getWidth() * .5, love.graphics.getHeight()}, {3, 5}}, {love.graphics.getWidth(), 0});

    if is_connected then
        local event = host:service();

        while event do
            if event.type == "connect" then
                local data = encode_data({"Connect", player_username});
                event.peer:send(data);
    
                event.peer:timeout(32, 100, 250);
    
            elseif event.type == "disconnect" then
                print("Client disconnecting...");
    
            elseif event.type == "receive" then
                local data = decode_data(event.data);
                if not data then return end
    
                local method = data[1];
                client_responses[method](event.peer, data);
            end
    
            event = host:service();
        end
    end
end