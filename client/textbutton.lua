local love = require("love");

local textbutton = {};
textbutton.__index = textbutton;

textbutton.new = function(name, colors, anchor_point, positions, size, font)
    local self = setmetatable({}, textbutton);
    self.name = name;
    self.button_color = colors[1] or {1, 1, 1};
    self.anchor_point = anchor_point or {0, 0};
    self.position = positions[1] or {0, 0};
    self.size = size or {0, 0};

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

local function calculate_position_for_inputbox_text(inputbox, pos)
    local hor_offset = (inputbox.size[1] - inputbox.text:getWidth()) * inputbox.text_alignment[1];
    local ver_offset = (inputbox.size[2] - inputbox.text:getHeight()) * inputbox.text_alignment[2];

    return {pos[1] + hor_offset + inputbox.text_position[1], pos[2] + ver_offset + inputbox.text_position[2]};
end

local function does_mouse_hover_button(pos, size)
    local mouse_pos = {love.mouse.getX(), love.mouse.getY()};

    local button_center = {pos[1] + size[1] * 0.5, pos[2] + size[2] * 0.5};

    local within_hor = math.abs(mouse_pos[1] - button_center[1]) <= size[1] * 0.5;
    local within_ver = math.abs(mouse_pos[2] - button_center[2]) <= size[2] * 0.5;

    return within_hor and within_ver;
end

function textbutton:draw()
    local prev_color = {love.graphics.getColor()};

    local button_color = self.button_color;
    local button_ap = self.anchor_point;
    local button_pos = self.position;
    local button_size = self.size;

    local text_color = self.text_color;

    local button_real_pos = calculate_position_for_inputbox(button_pos, button_ap, button_size);
    local button_text_real_pos = calculate_position_for_inputbox_text(self, button_real_pos);

    love.graphics.setColor(button_color[1], button_color[2], button_color[3], button_color[4]);
    love.graphics.rectangle("fill", button_real_pos[1], button_real_pos[2], button_size[1], button_size[2]);

    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4]);
    love.graphics.draw(self.text, button_text_real_pos[1], button_text_real_pos[2]);

    love.graphics.setColor(prev_color[1], prev_color[2], prev_color[3], prev_color[4]);
end

function textbutton:onClick(f)
    local hovers_button = does_mouse_hover_button({love.graphics.getWidth() * 0.5 - self.size[1] * 0.5, love.graphics.getHeight() * 0.75}, self.size);
    local button_pressed = love.mouse.isDown(1) and hovers_button;

    if button_pressed then
        return f();
    end
end

function textbutton:updatePositionAndSize(pos, size)
    self.position = pos[1] or self.position[1];
    self.size = size or self.size;
end

function textbutton:addTextAlignment(alignment)
    self.text_alignment = alignment;
end

function textbutton:addText(...)
    self.text:add(...);
end

function textbutton:setText(...)
    self.text:set(...);
end

return textbutton;