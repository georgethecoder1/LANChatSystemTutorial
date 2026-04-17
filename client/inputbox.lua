local love = require("love");

local inputbox = {};
inputbox.__index = inputbox;

inputbox.new = function(name, colors, anchor_point, positions, size, font)
    local self = setmetatable({}, inputbox);
    self.name = name or "";
    self.box_color = colors[1] or {1, 1, 1};
    self.anchor_point = anchor_point or {0, 0};
    self.position = positions[1] or {0, 0};
    self.size = size or {0, 0};
    self.box_scaling = {0, 0};

    self.font = font or love.graphics.getFont();
    self.text_color = colors[2] or {1, 1, 1};
    self.text_position = positions[2] or {0, 0};
    self.text = love.graphics.newText(self.font);
    self.text_alignment = {0, 0};

    return self;
end

local function calculate_position_for_inputbox(pos, ap, size)
    return {pos[1] - ap[1] * size[1], pos[2] - ap[2] * size[2]};
end

local function calculate_position_for_inputbox_text(inputbox, pos, size)
    local hor_offset = (size[1] - inputbox.text:getWidth()) * inputbox.text_alignment[1];
    local ver_offset = (size[2] - inputbox.text:getHeight()) * inputbox.text_alignment[2];

    return {pos[1] + hor_offset + inputbox.text_position[1], pos[2] + ver_offset + inputbox.text_position[2]};
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

        if accumulated_width + 20 > love.graphics.getWidth() then 
            real_msg = real_msg .. "\n"; 
            table.insert(tab, accumulated_width); 
        end
    end

    return real_msg;
end

function inputbox:draw()
    local prev_color = {love.graphics.getColor()};

    local box_color = self.box_color;
    local box_ap = self.anchor_point;
    local box_pos = self.position;
    local box_size = {self.size[1] + math.max(10 + self.text:getWidth() - self.size[1], 0) * self.box_scaling[1], self.size[2] + (10 + self.text:getHeight() - self.size[2]) * self.box_scaling[2]};

    local text_color = self.text_color;

    local inputbox_pos = calculate_position_for_inputbox(box_pos, box_ap, box_size);
    local inputbox_text_pos = calculate_position_for_inputbox_text(self, inputbox_pos, box_size);

    love.graphics.setColor(box_color[1], box_color[2], box_color[3], box_color[4]);
    love.graphics.rectangle("line", inputbox_pos[1], inputbox_pos[2], box_size[1], box_size[2]);

    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4]);
    love.graphics.draw(self.text, inputbox_text_pos[1], inputbox_text_pos[2]);

    love.graphics.setColor(prev_color[1], prev_color[2], prev_color[3], prev_color[4]);
end

function inputbox:setBoxScaling(scaling)
    self.box_scaling = scaling;
end

function inputbox:updatePositionAndSize(pos, size)
    self.position = pos[1] or self.position[1];
    self.size = size or self.size;
end

function inputbox:addTextAlignment(alignment)
    self.text_alignment = alignment;
end

function inputbox:addText(...)
    local content = calculate_lines_for_content(..., self.text);
    self.text:clear();

    self.text:add({{1, 1, 1}, content}, 0, 0);
end

function inputbox:setText(...)
    local content = calculate_lines_for_content(..., self.text);
    self.text:clear();

    self.text:set({{1, 1, 1}, content}, 0, 0);
end

return inputbox;