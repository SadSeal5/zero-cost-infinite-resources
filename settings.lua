data:extend({
  {
    type = "bool-setting",
    name = "zcir-infinite-solid-ores",
    setting_type = "startup",
    default_value = true,
    order = "a"
  },
  {
    type = "bool-setting",
    name = "zcir-infinite-fluids",
    setting_type = "startup",
    default_value = true,
    order = "b"
  },
  {
    type = "bool-setting",
    name = "zcir-prevent-depletion",
    setting_type = "startup",
    default_value = true,
    order = "c"
  },
  {
    type = "int-setting",
    name = "zcir-minimum-yield",
    setting_type = "startup",
    default_value = 100,
    minimum_value = 1,
    maximum_value = 100,
    order = "d"
  },
  {
    type = "int-setting",
    name = "zcir-solid-ore-normal",
    setting_type = "startup",
    default_value = 1000,
    minimum_value = 100,
    maximum_value = 1000000,
    order = "e"
  },
  {
    type = "int-setting",
    name = "zcir-fluid-normal",
    setting_type = "startup",
    default_value = 300000,
    minimum_value = 1000,
    maximum_value = 10000000,
    order = "f"
  },
  {
    type = "string-setting",
    name = "zcir-resource-blacklist",
    setting_type = "startup",
    default_value = "",
    allow_blank = true,
    order = "g"
  }
})
