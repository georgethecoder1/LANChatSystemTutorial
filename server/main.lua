local love = require("love");
local enet = require("enet");

local players = {};

local server = enet.host_create("*:5000");

local function encode_data(data_to_encode)
    if type(data_to_encode) ~= "table" then return end

    local encoded_data = "";

    for i, k in pairs(data_to_encode) do
        local data = i .. ":" .. k .. ";";
        encoded_data = encoded_data .. data;
    end

    return encoded_data;
end

local function decode_data(data_to_decode)
    if type(data_to_decode) ~= "string" then return end

    local decoded_data = {};

    for line in string.gmatch(data_to_decode, "([^;]+)") do
        local index, key = string.match(line, "([^:]+):([^:]+)");

        table.insert(decoded_data, index, key);
    end

    return decoded_data;
end

local function get_peer_from_username(username)
    local peer = nil;

    for i, k in pairs(players) do
        if k == username then
            peer = i;
            break;
        end
    end

    return peer;
end

local function get_username_from_peer(peer)
    local username = nil;

    for i, k in pairs(players) do
        if i == peer then
            username = k;
            break;
        end
    end

    return username;
end


local server_responses = {
    ["Connect"] = function(peer, data) -- Function that will be fired everytime new player joins the chat
        local username = data[2];
    
        print(string.format("[SERVER]: %s has connected to the chat!", username));

        players[peer] = username;
    end,

    ["Disconnect"] = function(peer) -- Function that will be fired everytime player leaves the chat 
        local username = get_username_from_peer(peer);

        print(string.format("[SERVER]: % has disconnected from the chat!", username));

        players[peer] = nil;
    end,

    ["Receive"] = function(peer, data)
        local username = get_username_from_peer(peer);

        server:broadcast(encode_data({"Receive", username, data[2]})); -- Sending message data to all the clients
    end,
}

function love.update(dt)
    local event = server:service();

    while event do
        if event.type == "connect" then
            event.peer:timeout(32, 100, 250);

        elseif event.type == "disconnect" then
            print(string.format("%s peer disconnecting...", event.peer));

        elseif event.type == "receive" then
            local data = decode_data(event.data);
            if not data then return end

            local method = data[1];
            server_responses[method](event.peer, data);
        end

        event = server:service();
    end
end