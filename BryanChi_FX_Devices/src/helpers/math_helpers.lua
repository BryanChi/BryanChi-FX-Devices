local math_helpers = {}

---@param Input number
---@param Min number
---@param Max number
---@return number
function math_helpers.SetMinMax(Input, Min, Max)
    if Input >= Max then
        Input = Max
    elseif Input <= Min then
        Input = Min
    else
        Input = Input
    end
    return Input
end

function math_helpers.Normalize_Val(V1, V2, ActualV, Bipolar)
    local Range = math.abs((math.max(V1, V2) - math.min(V1, V2)))

    local NormV = (math.min(V1, V2) + Range - ActualV) / Range

    if Bipolar then
        return -1 + (NormV) * 2
    else
        return NormV
    end
end

function math_helpers.Curve_3pt_Bezier(startX, startY, controlX, controlY, endX, endY)
    local X, Y = {}, {}
    for t = 0, 1, 0.1 do
        local x = (1 - t) * (1 - t) * startX + 2 * (1 - t) * t * controlX + t * t * endX
        local y = (1 - t) * (1 - t) * startY + 2 * (1 - t) * t * controlY + t * t * endY
        table.insert(X, x)
        table.insert(Y, y)
    end
    return X, Y
end

---@param num number|nil|string
---@param numDecimalPlaces number
---@return number|nil
function math_helpers.round(num, numDecimalPlaces)
    num = tonumber(num)
    if num then
        local mult = 10 ^ (numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end
end

---@param num number
---@param multipleOf number
---@return number
function math_helpers.roundUp(num, multipleOf)
    return math.floor((num + multipleOf / 2) / multipleOf) * multipleOf;
end

return math_helpers
