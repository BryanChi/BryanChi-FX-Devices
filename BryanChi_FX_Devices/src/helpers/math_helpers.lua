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


return math_helpers
