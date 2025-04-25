local love = require("love");
local enet = require("enet");

local serialization = require("shared.serialization");

local players = {};
local total_joins = 0;

local host = enet.host_create("*:5000");

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

local function send_all_users(data, sender)
    if sender then
        for peer in pairs(players) do
            if sender == peer then goto continue end

            peer:send(data);

            ::continue::
        end
    else
        host:broadcast(data);
    end
end

local server_callback_list = {
    ["Connect"] = function(peer, data) -- Function that will be fired everytime new player joins the chat
        local username = data[2];

        players[peer] = username;
        total_joins = total_joins + 1;

        local data_to_send = serialization.encode({"Connect", username});
        send_all_users(data_to_send, peer);
    end,

    ["Disconnect"] = function(peer) -- Function that will be fired everytime player leaves the chat 
        local username = get_username_from_peer(peer);

        players[peer] = nil;
        
        local data_to_send = serialization.encode({"Disconnect", username});
        send_all_users(data_to_send, peer);
    end,

    ["Receive"] = function(peer, data)
        local username = get_username_from_peer(peer);

        local data_to_send = serialization.encode({"Receive", username, data[2]});
        send_all_users(data_to_send, false);
    end,
}

local function get_total_players()
    local total = 0;

    for _ in pairs(players) do
        total = total + 1;
    end

    return total;
end

local function force_server_shutdown()
    for peer in pairs(players) do -- Disconnects any remaining clients if there are any
        players[peer] = nil;
        peer:disconnect();
    end

    host:destroy(); -- Destroys server (host) instance
    love.event.push("quit"); -- Pushes quit event to notify Love about abandoment
end

local server_running = true;

function love.update(dt)
    while server_running do
        local event = host:service();

        if event and event.type == "receive" then
            local data = serialization.decode(event.data);
            if not data then return end

            local method = data[1];          
            server_callback_list[method](event.peer, data);
        end

        if total_joins > 0 and get_total_players() == 0 then
            server_running = false;
        end

        love.timer.sleep(.01);
    end

    force_server_shutdown();
end