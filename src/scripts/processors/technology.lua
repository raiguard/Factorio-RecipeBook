local math = require("__flib__.math")

local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, strings, metadata)
  for name, prototype in pairs(game.technology_prototypes) do
    local unlocks_fluids = {}
    local unlocks_items = {}
    local unlocks_recipes = {}
    local research_ingredients_per_unit = {}

    -- research units and ingredients per unit
    for _, ingredient in ipairs(prototype.research_unit_ingredients) do
      research_ingredients_per_unit[#research_ingredients_per_unit + 1] = {
        class = ingredient.type,
        name = ingredient.name,
        amount_string = ingredient.amount.."x"
      }
    end

    local research_unit_count
    local formula = prototype.research_unit_count_formula
    if not formula then
      research_unit_count = prototype.research_unit_count
    end

    -- unlocks recipes, materials, crafter / lab / offshore pump
    for _, modifier in ipairs(prototype.effects) do
      if modifier.type == "unlock-recipe" then
        local recipe_data = recipe_book.recipe[modifier.recipe]
        recipe_data.unlocked_by[#recipe_data.unlocked_by + 1] = {class = "technology", name = name}
        recipe_data.researched_forces = {}
        unlocks_recipes[#unlocks_recipes + 1] = {class = "recipe", name = modifier.recipe}
        for _, product in pairs(recipe_data.products) do
          local product_name = product.name
          local product_data = recipe_book[product.class][product_name]

          product_data.researched_forces = {}

          local product_ident = {class = product_data.class, name = product_data.prototype_name}

          product_data.unlocked_by[#product_data.unlocked_by + 1] = {class = "technology", name = name}

          if product_data.class == "item" then
            if not unlocks_items[product_ident.name] then
              unlocks_items[#unlocks_items+1] = product_ident
              unlocks_items[product_ident.name] = true
            end
          elseif product_data.class == "fluid" then
            if not unlocks_fluids[product_ident.name] then
              unlocks_fluids[#unlocks_fluids+1] = product_ident
              unlocks_fluids[product_ident.name] = true
            end
          end

          -- crafter / lab / offshore pump
          local place_result = product_data.place_result
          if place_result then
            local machine_data = recipe_book.crafter[place_result]
              or recipe_book.lab[place_result]
              or recipe_book.offshore_pump[place_result]
            if machine_data then
              machine_data.researched_forces = {}
              machine_data.unlocked_by[#machine_data.unlocked_by + 1] = {class = "technology", name = name}

              local subtable_name = "associated_"..machine_data.class.."s"
              recipe_data[subtable_name][#recipe_data[subtable_name] + 1] = place_result
            end
          end
        end
      end
    end

    local level = prototype.level
    local max_level = prototype.max_level

    recipe_book.technology[name] = {
      class = "technology",
      hidden = prototype.hidden,
      max_level = max_level,
      min_level = level,
      prerequisite_of = {},
      prerequisites = {},
      prototype_name = name,
      research_ingredients_per_unit = research_ingredients_per_unit,
      research_unit_count = research_unit_count,
      research_unit_count_formula = formula,
      research_unit_energy = prototype.research_unit_energy / 60,
      researched_forces = {},
      unlocks_fluids = unlocks_fluids,
      unlocks_items = unlocks_items,
      unlocks_recipes = unlocks_recipes,
      upgrade = prototype.upgrade
    }

    -- assemble name
    local localised_name
    if level ~= max_level then
      localised_name = {
        "",
        prototype.localised_name,
        " ("..level.."-"..(max_level == math.max_uint and "∞" or max_level)..")"
      }
    else
      localised_name = prototype.localised_name
    end

    util.add_string(strings, {
      dictionary = "technology",
      internal = prototype.name,
      localised = localised_name
    })
    util.add_string(strings, {
      dictionary = "technology_description",
      internal = name,
      localised = prototype.localised_description
    })
  end

  -- generate prerequisites and prerequisite_of
  for name, technology in pairs(recipe_book.technology) do
    local prototype = game.technology_prototypes[name]

    if prototype.prerequisites then
      for prerequisite_name, _ in pairs(prototype.prerequisites) do
        technology.prerequisites[#technology.prerequisites + 1] = {class = "technology", name = prerequisite_name}
        local prerequisite_data = recipe_book.technology[prerequisite_name]
        prerequisite_data.prerequisite_of[#prerequisite_data.prerequisite_of + 1] = {class = "technology", name = name}
      end
    end
  end
end
