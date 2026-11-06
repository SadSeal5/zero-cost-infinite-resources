local function print_help(player)
  local help_msg = "Usage: /refill-infinite-resources [<radius 1-1000> | surface | <surface_name> | all] (Console/Headless requires explicit parameters)"
  if player then
    player.print(help_msg)
  else
    print(help_msg)
    if rcon then rcon.print(help_msg) end
    log(help_msg)
  end
end

local function get_player_ground_surface(player)
  local surface = player.surface
  if surface and surface.platform and player.physical_surface and not player.physical_surface.platform then
    surface = player.physical_surface
  end
  return surface
end

local function get_default_headless_surface()
  local target = game.surfaces[1]
  if not target or target.platform then
    local candidates = {}
    for _, s in pairs(game.surfaces) do
      if not s.platform then
        table.insert(candidates, s)
      end
    end
    table.sort(candidates, function(a, b) return a.index < b.index end)
    target = candidates[1]
  end
  return target
end

local function refill_resources(command)
  local player = command.player_index and game.get_player(command.player_index)
  if command.player_index and (not player or not player.admin) then
    if player then
      player.print({"cant-run-command-not-admin", "refill-infinite-resources"})
    end
    return
  end

  local param = command.parameter and string.match(command.parameter, "^%s*(.-)%s*$") or ""
  local lower_param = string.lower(param)
  local caller_name = player and player.name or "<server>"

  local radius = nil
  local surfaces_to_scan = {}
  local scope_str = ""

  if param == "" then
    if player then
      local target_surface = get_player_ground_surface(player)
      if not target_surface or target_surface.platform then
        player.print("[Zero-Cost Infinite Resources] Space platforms do not have ground resource patches.")
        return
      end
      radius = 100
      table.insert(surfaces_to_scan, target_surface)
      scope_str = string.format("radius %d on %s", radius, target_surface.name)
    else
      print_help(nil)
      return
    end
  else
    local num = tonumber(param)
    if num then
      if num > 0 and num <= 1000 and num == num and num ~= math.huge then
        if not player then
          local err_msg = "[Zero-Cost Infinite Resources] Error: Radius argument requires an in-game player."
          print(err_msg)
          if rcon then rcon.print(err_msg) end
          log(err_msg)
          return
        end
        local target_surface = get_player_ground_surface(player)
        if not target_surface or target_surface.platform then
          player.print("[Zero-Cost Infinite Resources] Space platforms do not have ground resource patches.")
          return
        end
        radius = num
        table.insert(surfaces_to_scan, target_surface)
        scope_str = string.format("radius %d on %s", radius, target_surface.name)
      else
        print_help(player)
        return
      end
    elseif lower_param == "all" then
      for _, s in pairs(game.surfaces) do
        if not s.platform then
          table.insert(surfaces_to_scan, s)
        end
      end
      table.sort(surfaces_to_scan, function(a, b) return a.index < b.index end)
      scope_str = "all"
    elseif lower_param == "surface" then
      if player then
        local target_surface = get_player_ground_surface(player)
        if not target_surface or target_surface.platform then
          player.print("[Zero-Cost Infinite Resources] Space platforms do not have ground resource patches.")
          return
        end
        table.insert(surfaces_to_scan, target_surface)
        scope_str = string.format("surface %s", target_surface.name)
      else
        local target_surface = get_default_headless_surface()
        if not target_surface then
          log("[Zero-Cost Infinite Resources] Error: No ground surfaces found.")
          return
        end
        table.insert(surfaces_to_scan, target_surface)
        scope_str = string.format("surface %s", target_surface.name)
      end
    else
      local specific_surface = game.surfaces[param] or game.surfaces[lower_param]
      if specific_surface then
        if specific_surface.platform then
          local msg = "[Zero-Cost Infinite Resources] Space platforms do not have ground resource patches."
          if player then
            player.print(msg)
          else
            print(msg)
            if rcon then rcon.print(msg) end
            log(msg)
          end
          return
        end
        table.insert(surfaces_to_scan, specific_surface)
        scope_str = string.format("surface %s", specific_surface.name)
      else
        print_help(player)
        return
      end
    end
  end

  local filter = {type = "resource"}
  if radius and player then
    local target_surface = surfaces_to_scan[1]
    local pos
    if player.controller_type == defines.controllers.remote and player.surface == target_surface then
      pos = player.position or player.physical_position
    else
      pos = player.physical_position or player.position
    end
    filter.position = pos
    filter.radius = radius
  end

  local blacklist_str = settings.startup["zcir-resource-blacklist"] and settings.startup["zcir-resource-blacklist"].value or ""
  local blacklist = {}
  for entry in string.gmatch(blacklist_str, "([^,%s;'\"\\]+)") do
    blacklist[string.lower(entry)] = true
  end
  local enable_solid = settings.startup["zcir-infinite-solid-ores"].value
  local enable_fluids = settings.startup["zcir-infinite-fluids"].value

  local refilled_count = 0
  for _, surface in ipairs(surfaces_to_scan) do
    local resources = surface.find_entities_filtered(filter)
    for _, entity in pairs(resources) do
      if entity.valid and entity.prototype.infinite_resource and not blacklist[string.lower(entity.name)] then
        local is_fluid = (entity.prototype.resource_category == "basic-fluid")
        if not is_fluid and entity.prototype.mineable_properties and entity.prototype.mineable_properties.products then
          for _, prod in pairs(entity.prototype.mineable_properties.products) do
            if prod.type == "fluid" then
              is_fluid = true
              break
            end
          end
        end

        if (is_fluid and enable_fluids) or (not is_fluid and enable_solid) then
          local normal = entity.prototype.normal_resource_amount or 1000
          local target = math.max(entity.amount or 0, entity.initial_amount or 0, normal)
          if entity.amount < target then
            entity.amount = target
            refilled_count = refilled_count + 1
          end
          if not entity.initial_amount or entity.initial_amount < target then
            entity.initial_amount = target
          end
        end
      end
    end
  end

  local audit_msg = string.format("[Zero-Cost Infinite Resources] %s executed /refill-infinite-resources (scope: '%s', refilled: %d entities).", caller_name, scope_str, refilled_count)
  log(audit_msg)

  if player then
    player.print({"command-message.refill-success", tostring(refilled_count), scope_str})
  else
    print(audit_msg)
    if rcon then
      rcon.print(audit_msg)
    end
  end
end

commands.add_command(
  "refill-infinite-resources",
  {"command-help.refill-infinite-resources"},
  refill_resources
)

script.on_init(function()
  log("[Zero-Cost Infinite Resources] Initialized. Operating with 0 UPS runtime overhead.")
end)

script.on_configuration_changed(function(data)
  if data.mod_changes and data.mod_changes["zero-cost-infinite-resources"] then
    log("[Zero-Cost Infinite Resources] Configuration updated. Operating with 0 UPS runtime overhead.")
    game.print("[Zero-Cost Infinite Resources] Mod active. If upgrading an existing save, run '/refill-infinite-resources' to replenish legacy outposts.")
  end
end)
