WFC = require('libraries.wfc.wfc')
CONFIG = require('assets.sample.config')
DIMENSION = 30
SIZE = love.graphics.getWidth() / DIMENSION

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    WFCEngine = WFC.new(CONFIG, DIMENSION, SIZE)
    WFCEngine:init()
end

function love.draw()
    WFCEngine:draw()
    WFCEngine:update()
end
