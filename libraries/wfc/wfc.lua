Model = require('libraries.wfc.model')
DeepCopy = require('helpers.deepcopy')

WFC = {}
MetaWFC = {}
MetaWFC.__index = WFC

POSITION_TOP = 1
POSITION_RIGHT = 2
POSITION_BOTTOM = 3
POSITION_LEFT = 4

function WFC.new(config, dimension, size)
    local instance = setmetatable({}, MetaWFC)
    instance.config = config
    instance.dimension = dimension
    instance.size = size
    instance.tiles = {}
    instance.waves = {}
    instance.states = {}
    instance.backtracking = false
    instance.initialized = false
    instance.maximum_backtracking_state = 100

    return instance
end

function WFC:init()
    -- Map all tiles into global tiles variable
    -- This is a list of our tiles than can be used
    -- to get a random tile from the list
    for _, value in ipairs(self.config) do
        local model = Model.new({
            path = value.path,
            rules = value.rules,
            size = self.size,
            id = value.id
        })
        table.insert(self.tiles, model)
    end

    -- Create the random position of the waves
    initial_position = love.math.random(1, self.dimension * self.dimension)
    initial_tile = self.tiles[love.math.random(1, #self.tiles)]
    initial_image = initial_tile.image
    initial_rules = initial_tile.rules
    initial_scale = initial_tile.scale

    -- Initial the first waves
    for row = 1, self.dimension * self.dimension do
        collapsed = initial_position == row
        local wave = {
            id = row,
            scale = collapsed and initial_scale or 1,
            image = collapsed and initial_image or nil,
            options = DeepCopy(self.tiles),
            collapsed = collapsed,
            rules = initial_rules
        }
        table.insert(self.waves, wave)
    end

    -- Save the states to be used for backtracking
    -- self:save_state()
end

function WFC:draw()
    next_wave_id = nil
    if self.initialized then
        available_waves = {}
        for _, wave in ipairs(self.waves) do
            if not wave.collapsed and #wave.options > 0 then
                table.insert(available_waves, wave)
            end
        end

        table.sort(available_waves, function(a, b) return #a.options < #b.options end)
        next_wave_id = available_waves[1] and available_waves[1].id or nil
    end

    -- if next_wave_id and #self.waves[next_wave_id].options == 0 then
    --     print(#self.waves[next_wave_id].options)
    --     self:backtrack()
    -- else
    --     self:save_state()
    -- end

    for row = 1, self.dimension do
        for col = 1, self.dimension do
            position = col + row * self.dimension - self.dimension
            if not self.backtracking and position == next_wave_id then
                target_wave = self.waves[position].options[math.random(#self.waves[position].options)]
                if target_wave then
                    self.waves[position].collapsed = true
                    self.waves[position].image = target_wave.image
                    self.waves[position].scale = target_wave.scale
                    self.waves[position].rules = target_wave.rules
                end
            end
            wave = self.waves[position]
            if wave.collapsed then
                love.graphics.draw(wave.image, (col - 1) * self.size, (row - 1) * self.size, 0, wave.scale, wave.scale)
            else
                love.graphics.rectangle('line', (col - 1) * self.size, (row - 1) * self.size, self.size, self.size)
            end
        end
    end

    self.initialized = true
end

function WFC:get_target_position(position)
    if position == POSITION_TOP then
        return POSITION_BOTTOM
    elseif position == POSITION_RIGHT then
        return POSITION_LEFT
    elseif position == POSITION_BOTTOM then
        return POSITION_TOP
    elseif position == POSITION_LEFT then
        return POSITION_RIGHT
    end
end

function WFC:compare_availability(collapsed_wave_rules, target_rules)
    for _, wave_rule in pairs(collapsed_wave_rules) do
        for _, target_rule in pairs(target_rules) do
            if wave_rule == target_rule then return true end
        end
    end

    return false
end

function WFC:save_state()
    self.backtracking = false
    print('backtracking', self.backtracking)
    if #self.states >= self.maximum_backtracking_state then
        total_data_removed = 50
        while total_data_removed > 0 do
            table.remove(self.states, 1)
            total_data_removed = total_data_removed - 1
        end
    end
    table.insert(self.states, DeepCopy(self.waves))
end

function WFC:backtrack()
    self.backtracking_counter = self.backtracking_counter + 1
    self.backtracking = true
    table.remove(self.states, #self.states)
    self.waves = DeepCopy(self.states[#self.states])
end

function WFC:propagates(next_tile_position, collapsed_wave_rules, position)
    next_wave = self.waves[next_tile_position]
    if not next_wave.collapsed then
        target_position = self:get_target_position(position)
        new_options = {}

        for _, value_options in ipairs(next_wave.options) do
            target_rules = value_options.rules[target_position]
            if self:compare_availability(collapsed_wave_rules, target_rules) then
                table.insert(new_options, value_options)
            end
        end

        self.waves[next_tile_position].options = new_options
    end
end

function WFC:update()
    for row = 1, self.dimension do
        for col = 1, self.dimension do
            wave = self.waves[col + row * self.dimension - self.dimension]
            if wave.collapsed then
                -- Check top wave's neighbors
                if row - 1 > 0 then
                    local next_tile_position = col + (row - 1) * self.dimension - self.dimension
                    collapsed_wave_rules = wave.rules[POSITION_TOP]
                    self:propagates(next_tile_position, collapsed_wave_rules, POSITION_TOP)
                end

                -- Check right wave's neighbors
                if col + 1 <= self.dimension then
                    local next_tile_position = (col + 1) + row * self.dimension - self.dimension
                    collapsed_wave_rules = wave.rules[POSITION_RIGHT]
                    self:propagates(next_tile_position, collapsed_wave_rules, POSITION_RIGHT)
                end

                -- Check bottom wave's neighbors
                if row + 1 <= self.dimension then
                    local next_tile_position = col + (row + 1) * self.dimension - self.dimension
                    collapsed_wave_rules = wave.rules[POSITION_BOTTOM]
                    self:propagates(next_tile_position, collapsed_wave_rules, POSITION_BOTTOM)
                end

                -- Check left wave's neighbors
                if col - 1 > 0 then
                    local next_tile_position = (col - 1) + row * self.dimension - self.dimension
                    collapsed_wave_rules = wave.rules[POSITION_LEFT]
                    self:propagates(next_tile_position, collapsed_wave_rules, POSITION_LEFT)
                end
            end
        end
    end
end

return WFC
