local function table_copy(source)
  local result = {}

  for key, value in pairs(source) do
    if type(value) == "table" then
      result[key] = table_copy(value)
    else
      result[key] = value
    end
  end

  return result
end

local function table_merge(...)
  -- Validate arguments
  local arguments = { ... }

  for index = 1, select("#", ...) do
    assert(type(arguments[index]) == "table", "Expected table-only argument, got " .. type(arguments[index]) .. " at index " .. index)
  end

  assert(#arguments >= 2, "Expected at least two tables to merge")

  -- Generate merged table
  local result = {}

  for _, source in pairs(arguments) do
    for key, value in pairs(source) do
      if type(value) == "table" then
        result[key] = table_copy(value)
      else
        result[key] = value
      end
    end
  end

  return result
end

local function registerClass(name, superClasses, definition)
  -- Look for a previous class and merge it with new definition
  local partialClass = _G[name]
  if partialClass and type(partialClass) == "table" then
    definition = table_merge(partialClass, definition)
  end

  -- Generate class list
  local classList = { definition }
  local addedClasses = {}

  local function insertClassSuper(super)
    if not addedClasses[super] then
      -- Block this class from being added
      addedClasses[super] = true

      -- Insert this class
      table.insert(classList, 1, super)

      -- Insert class parents
      local behavior = getmetatable(super)
      if behavior and behavior.__classlist then
        for _, superClass in pairs(behavior.__classlist) do
          insertClassSuper(superClass)
        end
      end
    end
  end

  for _, super in pairs(superClasses) do
    insertClassSuper(super)
  end

  -- Define class behavior
  local behavior = { __classlist = classList }

  function behavior:__tostring()
    return name
  end

  function behavior:__index(key)
    for _, super in pairs(behavior.__classlist) do
      local value = rawget(super, key)
      if value ~= nil then
        return value
      end
    end

    return nil
  end

  function behavior:__call(...)
    -- Generate instance
    local object = {}
    
    setmetatable(
      object,
      {
        __class = definition,
        __unm = definition.__unm,
        __add = definition.__add,
        __sub = definition.__sub,
        __mul = definition.__mul,
        __div = definition.__div,
        __mod = definition.__mod,
        __pow = definition.__pow,
        __unm = definition.__unm,
        __concat = definition.__concat,
        __len = definition.__len,
        __eq = definition.__eq,
        __lt = definition.__lt,
        __le = definition.__le,

        __tostring = function()
          return name
        end,

        __index = function(_, key)
          local value

          local classIndex = definition.__index
          if classIndex and type(classIndex) == "function" then
            value = classIndex(object, key)
          end

          if value == nil then
            value = definition[key]
          end

          return value
        end,

        __newindex = function(_, key, value)
          local classNewIndex = definition.__newindex
          if classNewIndex and type(classNewIndex) == "function" then
            local result = classNewIndex(object, key, value)
            if result == true then
              return true
            end
          end

          return rawset(object, key, value)
        end,
      }
    )

    -- Call constructor(s)
    recursiveCall(object, "constructor")

    -- Disable constructor
    rawset(object, "constructor", false)

    return object
  end

  function definition:destroy()
    -- Call destructor(s)
    recursiveCall(self, true, "destructor")

    -- Disable destructor
    rawset(self, "destructor", false)

    -- Remove attached metatable
    setmetatable(self, nil)
  end

  setmetatable(definition, behavior)

  -- Register class into global environment
  _G[name] = definition
end

local function parseClass(name, ...)
  -- Validate argument list
  local arguments = { ... }

  for index = 1, select("#", ...) do
    assert(arguments[index] ~= nil, "A nil parameter was passed to class " .. name .. ", check scope or spell")
    assert(type(arguments[index]) == "table", "Non-table parameter passed to class " .. name .. " - " .. type(arguments[index]))
  end

  assert(#arguments ~= 0, "Can't create class without super classes or definition")

  -- Handle class creation if we dont have any super classes
  if #arguments == 1 and not getmetatable(arguments[1]) then
    return registerClass(name, {}, arguments[1])
  end

  -- Return a function that will listen for definition
  return function(definition)
    assert(type(definition) == "table", "Expected definition body for class")
    assert(not getmetatable(definition), "Class definition isn't valid as it has an attached metatable")

    return registerClass(name, arguments, definition)
  end
end

function class(name)
  assert(type(name) == "string", "Expected [string] name for class constructor, got " .. type(name))

  return function(...)
    return parseClass(name, ...)
  end
end

local function table_reverse(source)
  local result = {}

  for _, value in pairs(source) do
    table.insert(result, 1, value)
  end

  return result
end

function recursiveCall(object, method, ...)
  local reversed = false
  local arguments = { ... }

  if type(method) == "boolean" then
    reversed = method
    method = arguments[1]
    table.remove(arguments, 1)
  end

  if method then
    local class = classof(object)
    local behavior = getmetatable(class)

    if behavior and behavior.__classlist then
      local classList = behavior.__classlist
      if reversed then
        classList = table_reverse(classList)
      end

      for _, class in pairs(classList) do
        local funct = rawget(class, method)
        if funct and type(funct) == "function" then
          funct(object, unpack(arguments))
        end
      end
    end
  end

  return false
end

function classinherits(derived, parent)
  if isclass(derived) and isclass(parent) then
    local behavior = getmetatable(derived)
    if behavior and behavior.__classlist then
      for _, class in pairs(behavior.__classlist) do
        if class == parent then
          return true
        end
      end
    end
  end

  return false
end

function instanceof(object, class)
  if isinstance(object) and isclass(class) then
    if classinherits(classof(object), class) then
      return true
    end
  end

  return false
end

function typeof(value)
  if isinstance(value) then
    value = classof(value)
  else
    value = type(value)
  end

  return tostring(value)
end

function classof(object)
  if isinstance(object) then
    local behavior = getmetatable(object)
    if behavior and behavior.__class then
      return behavior.__class
    end
  end

  return false
end

function isclass(value)
  if type(value) == "table" then
    local behavior = getmetatable(value)
    if behavior then
      if behavior.__call then
        return true
      end
    end
  end

  return false
end

function isinstance(value)
  if type(value) == "table" then
    local behavior = getmetatable(value)
    if behavior then
      if behavior.__class then
        return true
      end
    end
  end

  return false
end
