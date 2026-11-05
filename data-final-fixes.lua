local enable_solid = settings.startup["zcir-infinite-solid-ores"].value
local enable_fluids = settings.startup["zcir-infinite-fluids"].value
local prevent_depletion = settings.startup["zcir-prevent-depletion"].value
local min_yield_percent = math.min(100, math.max(1, settings.startup["zcir-minimum-yield"].value))
local solid_normal = settings.startup["zcir-solid-ore-normal"].value
local fluid_normal = settings.startup["zcir-fluid-normal"].value
local blacklist_str = settings.startup["zcir-resource-blacklist"] and settings.startup["zcir-resource-blacklist"].value or ""

local blacklist = {}
for entry in string.gmatch(blacklist_str, "([^,%s;'\"\\]+)") do
  blacklist[string.lower(entry)] = true
end

local function is_resource_fluid(resource)
  if resource.category == "basic-fluid" then
    return true
  end
  local minable = resource.minable
  if minable then
    if minable.result and data.raw.fluid and data.raw.fluid[minable.result] then
      return true
    end
    if minable.results then
      for _, product in pairs(minable.results) do
        local prod_name = product.name or product[1]
        local prod_type = product.type or "item"
        if prod_type == "fluid" or (prod_name and data.raw.fluid and data.raw.fluid[prod_name] ~= nil) then
          return true
        end
      end
    end
  end
  return false
end

if data.raw.resource then
  for name, resource in pairs(data.raw.resource) do
    if resource.minable and not blacklist[string.lower(name)] then
      local is_fluid = is_resource_fluid(resource)
      if (is_fluid and enable_fluids) or (not is_fluid and enable_solid) then
        local was_infinite = resource.infinite
        resource.infinite = true
        local default_normal = is_fluid and fluid_normal or solid_normal
        if not was_infinite or not resource.normal then
          resource.normal = default_normal
        end
        if not was_infinite or not resource.minimum then
          local min_amount = math.max(1, math.floor(resource.normal * (min_yield_percent / 100)))
          resource.minimum = min_amount
        end
        if prevent_depletion then
          resource.infinite_depletion_amount = 0
        end
        if resource.stage_counts and not is_fluid then
          for i = 1, #resource.stage_counts do
            resource.stage_counts[i] = 0
          end
        end
      end
    end
  end
end
