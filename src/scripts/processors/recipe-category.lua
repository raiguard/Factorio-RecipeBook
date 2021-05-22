local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(game.recipe_category_prototypes) do
    recipe_book.recipe_category[name] = {
      class = "recipe_category",
      enabled_at_start = true,
      fluids = {},
      items = {},
      prototype_name = name,
      recipes = {},
    }
    util.add_string(strings, {dictionary = "recipe_category", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "recipe_category_description",
      internal = name,
      localised = prototype.localised_description
    })
  end
end