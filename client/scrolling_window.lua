local love = require("love");

local scrolling_window = {};
scrolling_window.__index = scrolling_window;

scrolling_window.new = function(name, color, position, size, font)
    local self = setmetatable({}, scrolling_window);
    self.name = name;
    self.window_color = color or {1, 1, 1};
    self.position = position or {0, 0};
    self.size = size or {0, 0};
    self.contents = {};

    self.content_pos = 0;
    self.content_size = 0;

    self.font = font;

    return self;
end

local function accumulate_chat_message_width(message, tab)
    local width = message:getWidth();

    for _, s in ipairs(tab) do
        width = width - s;
    end

    return width;
end

local function calculate_lines_for_content(content, container)
    local message_to_draw = content;
    local real_msg = "";
    local fake_msg = "";

    local accumulated_width = 0;
    local tab = {};

    for c in message_to_draw:gmatch(".") do
        real_msg = real_msg .. c;
        fake_msg = fake_msg .. c;

        container:set({{1, 1, 1}, fake_msg}, 0, 0);

        accumulated_width = accumulate_chat_message_width(container, tab);

        if accumulated_width + 20 > love.graphics.getWidth() then real_msg = real_msg .. "\n"; table.insert(tab, accumulated_width); end
    end

    return real_msg;
end

local function calculate_total_scrolling_offset(win)
    local scrolling_offset = 0;

    for i = 1, #win.contents do
        local container = love.graphics.newText(win.font);
        local content = calculate_lines_for_content(win.contents[i], container);

        container:set({{1, 1, 1}, content}, 0, 0);
        scrolling_offset = scrolling_offset + container:getHeight();
    end

    local final_offset = math.max(scrolling_offset - win.size[2], 0);

    win.content_size = final_offset;

    return final_offset;
end

function scrolling_window:scroll(x, y)
    local sensitivity = 10;
    local pos = {x * sensitivity, y * sensitivity};

    self.content_pos = math.max(math.min(self.content_pos + pos[2], self.content_size), 0);
end

function scrolling_window:draw()
    local prev_color = {love.graphics.getColor()};

    local win_color = self.window_color;
    local win_pos = self.position;
    local win_size = self.size;

    love.graphics.setColor(1, 1, 1, 1);

    local vertical_offset = 0;
    local scrolling_offset = calculate_total_scrolling_offset(self);

    for i = 1, #self.contents do

        local container = love.graphics.newText(self.font);
        local content = calculate_lines_for_content(self.contents[i], container);

        container:set({{1, 1, 1, (vertical_offset - self.content_pos > win_size[2] or vertical_offset - self.content_pos < 0) and 0 or 1}, content}, 0, 0);
        love.graphics.draw(container, 0, vertical_offset - self.content_pos);

        vertical_offset = vertical_offset + container:getHeight();
    end

    love.graphics.setColor(win_color[1], win_color[2], win_color[3], win_color[4]);
    love.graphics.rectangle("fill", win_pos[1], win_pos[2], win_size[1], win_size[2]);

    love.graphics.setColor(prev_color[1], prev_color[2], prev_color[3], prev_color[4]);
end

function scrolling_window:addContent(message)
    self.content_pos = self.content_size;

    table.insert(self.contents, message);
end

return scrolling_window;