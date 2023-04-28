-- A simple static utility class

local ipairs = ipairs;
local null = nil;

local random = math.random;
local PI = math.pi;
local HALF_PI = PI / 2;
local DOUBLE_PI = PI * 2;


---@class utility
utility = {}

---@exports Utility exports.
utility.PI = PI;
utility.HALF_PI = HALF_PI;
utility.DOUBLE_PI = DOUBLE_PI;


---Under/over flows angle to stay within boundary of -pi to pi.
---@param angle number Input yaw.
---@return number number Corrected yaw.
utility.wrap_angle = function(angle)
    if angle < -PI then
        return angle + DOUBLE_PI
    elseif angle > PI then
        return angle - DOUBLE_PI
    end
    return angle
end


---X precision of float equality (x ^ 2 == 100 or 0.00)
---@param comparitor1 number
---@param comparitor2 number
---@param precision integer Float precision past the decimal point.
---@return boolean boolean Equality of comparitor1 and comparitor2 within float precision.
utility.yaw_equals = function(comparitor1, comparitor2, precision)
    local multiplier = 10 ^ precision
    local x = math.floor(comparitor1 * multiplier + 0.5) / multiplier
    local y = math.floor(comparitor2 * multiplier + 0.5) / multiplier
    return x == y or x + y == 0
end

---Selects a random element from the given table.
---@param inputTable table The table in which to select items from.
---@return any any The selected item from the table. Or null if nothing.
utility.randomTableSelection = function(inputTable)
    ---@immutable <- Does nothing for now
    local count = #inputTable
    if (count == 0) then return null end
    return inputTable[random(1, count)]
end

---1 dimensional linear interpolation.
---@param origin number Starting point.
---@param amount number Amount, 0.0 to 1.0.
---@param destination number Destination point.
---@return number number Interpolated float along 1 dimensional axis.
local function fma(origin, amount, destination)
    return (origin * amount) + destination
end

-- This is wrappered to make this more understandable

---1 dimensional linear interpolation.
---@param start number Starting point.
---@param finish number Finishing point.
---@param amount number Point between the two. Valid: 0.0 to 1.0.
---@return number
utility.lerp = function(start, finish, amount)
    return fma(finish - start, amount, start)
end

---Capitalizes the first letter in a string.
---@param inputString string Input string to capitalize the first letter of.
---@return string Returns string with capitalized first letter.
utility.capitalizeFirstLetter = function(inputString)
    ---@immutable <- Does nothing for now
    local output = inputString:gsub("^%l",string.upper);
    return output;
end

---Converts a dynamic mutable table into an immutable table.
---@param inputTable table The table which will become immutable.
---@return table The new immutable table.
utility.makeImmutable = function(inputTable)
    local proxy = {};
    local meta = {
        __index = inputTable,
        __newindex = function (table,key,value)
            error(
                "ERROR! Attempted to modify an immutable table!\n" ..
                "Pointer: " .. tostring(table) .. "\n" ..
                "Key: " .. key .. "\n" ..
                "Value: " .. value .. "\n"
            );
        end
    }
    setmetatable(proxy, meta);
    return proxy;
end

---Auto dispatcher for readonly enumerators via functions & direct values.
---@param dataSet { [string]: any } Input data set of key value enumerators.
---@return function[] Immutable data output getters.
utility.dispatchGetterTable = function(dataSet)
    ---@type function[]
    local output = {};
    ---Creates hanging references so the GC does not collect them.
    for key,value in pairs(dataSet) do
        ---@immutable <- Does nothing for now
        local fieldGetterName = "get" .. utility.capitalizeFirstLetter(key);
        ---OOP style. Example: data.getName();
        output[fieldGetterName] = function ()
            return value;
        end
        ---Functional style. Example: data.name; 
        output[key] = output[fieldGetterName]();
    end
    return utility.makeImmutable(output);
end

---Basic data return gate. Boolean case -> (true data | false data)
---@param case boolean
---@param trueResult any
---@param falseResult any
---@return any
utility.ternary = function(case, trueResult, falseResult)
    if (case) then
        return trueResult;
    end
    return falseResult;
end

---Basic function exectution gate. Boolean case -> (true function | false function)
---@param case boolean
---@param trueFunction function
---@param falseFunction function
---@return any
utility.ternaryExec = function(case, trueFunction, falseFunction)
    if (case) then
        return trueFunction();
    end
    return falseFunction();
end

---Basic function execution gate with parameters. Bool case (parameters...) -> (true function ... | false function ...)
---@param case boolean
---@param trueFunction function
---@param falseFunction function
---@param ...  any A collection of parameters which you define.
---@return any
utility.ternaryExecParam = function(case, trueFunction, falseFunction, ...)
    if (case) then
        return trueFunction(...);
    end
    return falseFunction(...);
end


---This function piggybacks on top of error simply because I like using the word throw more.
---@param errorOutput string The error message.
---@return nil
utility.throw = function(errorOutput)
    error(errorOutput);
end
