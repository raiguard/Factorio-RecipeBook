local search_page = {}

local gui = require("__flib__.gui")

local constants = require("constants")
local util = require("scripts.util")

local string = string

gui.add_handlers{
  search = {
    category_drop_down = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        player_table.gui.main.search.category = constants.search_categories[e.element.selected_index]
        gui.handlers.search.textfield.on_gui_text_changed(e)
      end
    },
    textfield = {
      on_gui_text_changed = function(e)
        local player = game.get_player(e.player_index)
        local force_index = player.force.index
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.search
        local query = string.lower(gui_data.textfield.text)

        local player_info = {
          force_index = force_index,
          translations = player_table.translations
        }

        --! ---------------------------------------------------------------------------
        --! TODO: spread out over multiple ticks

        local category = gui_data.category
        local translations = player_table.translations[gui_data.category]
        local scroll = gui_data.results_scroll_pane
        local rb_data = global.recipe_book[category]
        local formatter = util["format_"..category.."_item"]

        -- hide limit frame, show it again later if there's more than 50 results
        local limit_frame = gui_data.limit_frame
        limit_frame.visible = false

        -- don't show anything if there are zero or one letters in the query
        if string.len(query) < 2 then
          scroll.clear()
          return
        end

        -- fuzzy search
        if player_table.settings.use_fuzzy_search then
          query = string.gsub(query, ".", "%1.*")
        end

        -- input sanitization
        for pattern, replacement in pairs(constants.input_sanitisers) do
          query = string.gsub(query, pattern, replacement)
        end

        gui_data.query = query

        -- settings
        local show_hidden = player_table.settings.show_hidden
        local show_unavailable = player_table.settings.show_unavailable

        -- match queries and add or modify children
        local children = scroll.children
        local add = scroll.add
        local i = 0
        for internal, translation in pairs(translations) do
          if string.find(string.lower(translation), query) then
            -- check hidden status
            local obj_data = rb_data[internal]
            local is_hidden = obj_data.hidden
            local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[force_index]
            if (show_hidden or not is_hidden) and (show_unavailable or is_available) then
              i = i + 1
              -- create or modify element
              -- TODO optimize formatters to be passed the results of is_hidden and is_available from parent function and just not be sucky in general
              local style, caption, tooltip = formatter(
                category == "material" and {name=obj_data.prototype_name} or internal,
                obj_data,
                category,
                player_info
              )
              local child = children[i]
              if child then
                child.style = style
                child.caption = caption
                child.tooltip = tooltip
              else
                add{type="button", name="rb_list_box_item__"..i, style=style, caption=caption, tooltip=tooltip}
              end
            end
          end
        end

        -- remove extraneous children, if any
        if i < 50 then
          for j = i + 1, #scroll.children do
            children[j].destroy()
          end
        end

        --! ---------------------------------------------------------------------------
      end
    }
  }
}

function search_page.build()
  return {
    {type="frame", style="subheader_frame", children={
      {type="label", style="subheader_caption_label", caption={"rb-gui.search-by"}},
      {template="pushers.horizontal"},
      {type="drop-down", items=constants.search_categories, selected_index=2, handlers="search.category_drop_down", save_as="search.category_drop_down"}
    }},
    {type="flow", style_mods={padding=12, top_padding=8, vertical_spacing=10}, direction="vertical", children={
      {type="textfield", style_mods={width=250}, handlers="search.textfield", save_as="search.textfield"},
      {type="frame", style="deep_frame_in_shallow_frame", style_mods={horizontally_stretchable=true, height=420}, direction="vertical", children={
        {type="frame", style="rb_search_results_subheader_frame", elem_mods={visible=false}, save_as="search.limit_frame", children={
          {type="label", style="info_label", caption={"", "[img=info] ", {"rb-gui.results-limited"}}}
        }},
        {type="scroll-pane", style="rb_list_box_scroll_pane", style_mods={horizontally_stretchable=true, vertically_stretchable=true},
          save_as="search.results_scroll_pane"}
      }}
    }}
  }
end

function search_page.setup(player, player_table, gui_data)
  gui_data.search.category = "recipe"
  return gui_data
end

return search_page