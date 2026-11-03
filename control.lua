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
  local radius = tonumber(param)
  if radius and (radius ~= radius or radius <= 0 or radius > 1000 or radius == math.huge) then
    radius = nil
  end

  if param ~= "" and lower_param ~= "all" and not radius then
    local help_msg = "Usage: /refill-infinite-resources [all | <radius>]"
    if player then
      player.print(help_msg)
    else
      print(help_msg)
      if rcon then rcon.print(help_msg) end
      log(help_msg)
    end
    return
  end

  if radius and not player then
    local err_msg = "[Zero-Cost Infinite Resources] Error: Radius argument requires an in-game player."
    print(err_msg)
    if rcon then rcon.print(err_msg) end
    log(err_msg)
    return
  end

  local surfaces_to_scan = {}
  if lower_param == "all" then
    for _, s in pairs(game.surfaces) do
      if not s.platform then
        table.insert(surfaces_to_scan, s)
      end
    end
    table.sort(surfaces_to_scan, function(a, b) return a.index < b.index end)
  else
    local target_surface = (player and player.surface) or (player and player.physical_surface) or game.surfaces[1]
    if target_surface and target_surface.platform then
      if player then
        player.print("[Zero-Cost Infinite Resources] Space platforms do not have ground resource patches.")
        return
      else
        target_surface = nil
        local candidates = {}
        for _, s in pairs(game.surfaces) do
          if not s.platform then table.insert(candidates, s) end
        end
        table.sort(candidates, function(a, b) return a.index < b.index end)
        target_surface = candidates[1]
      end
    end
    if target_surface and not target_surface.platform then
      table.insert(surfaces_to_scan, target_surface)
    end
  end

  local filter = {type = "resource"}
  if radius and player then
    filter.position = player.position or player.physical_position
    filter.radius = radius
  end

  local blacklist_str = settings.startup["zcir-resource-blacklist"] and settings.startup["zcir-resource-blacklist"].value or ""
  local blacklist = {}
  for entry in string.gmatch(blacklist_str, "([^,%s;'\"\\]+)") do
    blacklist[string.lower(entry)] = true
  end
  local enable_fluids = settings.startup["zcir-infinite-fluids"].value

  local refilled_count = 0
  for _, surface in ipairs(surfaces_to_scan) do
    local resources = surface.find_entities_filtered(filter)
    for _, entity in pairs(resources) do
      if entity.valid and entity.prototype.infinite_resource and not blacklist[string.lower(entity.name)] then
        local is_fluid = (entity.prototype.resource_category == "basic-fluid")
        if not (is_fluid and not enable_fluids) then
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

  local message = {"command-message.refill-success", tostring(refilled_count)}
  if player then
    player.print(message)
  else
    local msg = string.format("[Zero-Cost Infinite Resources] Refilled %d infinite resource entities.", refilled_count)
    print(msg)
    if rcon then
      rcon.print(msg)
    end
    log(msg)
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
  log("[Zero-Cost Infinite Resources] Configuration updated. Operating with 0 UPS runtime overhead.")
  game.print("[Zero-Cost Infinite Resources] Mod active. If upgrading an existing save, run '/refill-infinite-resources' to replenish legacy outposts.")
end)
