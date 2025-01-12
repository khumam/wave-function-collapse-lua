Model = {}
MetaModel = {}
MetaModel.__index = Model

function Model.new(object)
    local instance = setmetatable({}, MetaModel)
    local image = love.graphics.newImage(object.path)
    instance.image = image
    instance.rules = object.rules
    instance.scale = image and object.size / image:getWidth()
    return instance
end

return Model
