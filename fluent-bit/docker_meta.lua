-- Cache container ID -> name lookups to avoid repeated file reads
local name_cache = {}

-- Lua {n} quantifiers don't exist; build a pattern for exactly 64 hex chars
local hex8 = "[%x][%x][%x][%x][%x][%x][%x][%x]"
local hex64 = hex8:rep(8)

function add_container_name(tag, timestamp, record)
  local container_id = tag:match(hex64)
  if not container_id then
    return 0, timestamp, record
  end

  if name_cache[container_id] == nil then
    local path = "/var/lib/docker/containers/" .. container_id .. "/config.v2.json"
    local f = io.open(path, "r")
    if f then
      local content = f:read("*a")
      f:close()
      local name = content:match('"Name":"/([^"]+)"')
      name_cache[container_id] = name or ""
    else
      name_cache[container_id] = ""
    end
  end

  local name = name_cache[container_id]
  if name ~= "" then
    record["container"] = name
  end

  return 1, timestamp, record
end
