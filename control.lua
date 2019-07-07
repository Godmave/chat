require("mod-gui")

local function addTab(root, flow, id, caption, active)
    local tab

    root['tabs'] = root['tabs'] or {}

    root['tabs'][id] = {}

    root['tabs'][id].inactive = flow.add{type="button", name="chat-tab-"..id, style="image_tab_slot", caption=caption}
    tab = root['tabs'][id].inactive
    tab.visible = not active
    tab.style.height = 30
    tab.style.width = 120

    root['tabs'][id].active = flow.add{type="button", name="chat-tab-"..id.."-selected", style="image_tab_selected_slot", caption=caption}
    tab =root['tabs'][id].active
    tab.visible = active
    tab.style.height = 30
    tab.style.width = 120

end


local function tickToTime(tick)
    local seconds = tick / 60
    local days = math.floor(seconds / 86400)
    seconds = seconds - days * 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds - hours * 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60

    return string.format("%dd %02d:%02d:%02d", days, hours, minutes, seconds)
end

local function addMessage(table, row)
    local color, who, message, player

    if row.player_index then
        player = game.players[row.player_index]
        color = player.color.r .. ',' .. player.color.g .. ',' .. player.color.b
        who = "[color=" .. color .. "]" .. player.name .. '[/color]'
        if player.admin then
            who = who .. " (Admin)"
        end
    else
        who = "SYSTEM"
    end

    table.add{type="label", caption=tickToTime(row.tick)}

    table.add{type="label", caption=who .. "    "}

    local x
    x = table.add{type="text-box", style="stretchable_textfield", text=row.message}
    x.read_only = true
    x.style.horizontally_stretchable = true
    x.style.vertically_stretchable = true

    table.parent.scroll_to_bottom()
end


local function removeOldestMessagee(chat)
    local _, ele = next(chat.children)
    ele.destroy()
    local _, ele = next(chat.children)
    ele.destroy()
    local _, ele = next(chat.children)
    ele.destroy()
    table.remove(chat.children, 1)
    table.remove(chat.children, 1)
    table.remove(chat.children, 1)
end

local function removeMessageLive(row)
    for _, chat in pairs(global.chat) do
        if row.type ~= "command" then
            removeOldestMessagee(chat.messageTable['all'])
        end
        if row.type == "chat" then
            removeOldestMessagee(chat.messageTable['chat'])
        end
        if row.type == "ping" then
            removeOldestMessagee(chat.messageTable['ping'])
        end
        if row.type == "command" then
            removeOldestMessagee(chat.messageTable['command'])
        end
    end
end

local function addMessageLive(row)
    if not global.chat then
        return
    end

    for _, chat in pairs(global.chat) do
        if row.type ~= "command" then
            addMessage(chat.messageTable['all'], row)
        end
        if row.type == "chat" then
            addMessage(chat.messageTable['chat'], row)
        end
        if row.type == "ping" then
            addMessage(chat.messageTable['ping'], row)
        end
        if row.type == "command" then
            addMessage(chat.messageTable['command'], row)
        end

    end
end


local function gui_chat(player_index)
    if global.chat == nil then
        global.chat = {}
    end

    local player = game.players[player_index]

    if global.chat[player_index] then
        if global.chat[player_index].gui.visible then
            global.chat[player_index].gui.visible = false
            return
        else
            global.chat[player_index].gui.visible = true
        end
    else
        global.chat[player_index] = {}
        global.chat[player_index].gui = player.gui.center.add{type = 'frame', name = 'chat-gui', direction = 'vertical', caption = 'Chat'}

        local root = global.chat[player_index]
        local gui = root.gui

        local tightFrame = gui.add{type="table", column_count=1}
        tightFrame.style.horizontal_spacing = 0
        tightFrame.style.vertical_spacing = 0

        local tabFlow = tightFrame.add{type="table", column_count=6}
        tabFlow.style.horizontal_spacing = 0
        tabFlow.style.vertical_spacing = 0

        addTab(root, tabFlow, "all", "All", true)
        addTab(root, tabFlow, "chat", "Chat", false)
        addTab(root, tabFlow, "ping", "Ping", false)
        addTab(root, tabFlow, "command", "Commands", false)


        root.tabpanes = root.tabpanes or {}

        local scrollpane, table
        root.messageTable = {}

--
        root.tabpanes['all'] = tightFrame.add{type="frame", name="chat-all"}
        root.tabpanes['all'].visible = true
        scrollpane = root.tabpanes['all'].add{type="scroll-pane"}
        scrollpane.style.maximal_height = 700
        scrollpane.style.minimal_height = 700
        scrollpane.style.minimal_width = 1000
        scrollpane.style.horizontally_stretchable = true

        table = scrollpane.add{type="table", column_count=3}
        table.style.horizontally_stretchable = true
        root.messageTable['all'] = table
        for _, row in pairs(global.chatlog) do
            if row.type ~= "command" then
                addMessage(table, row)
            end
        end


--
        root.tabpanes['chat'] = tightFrame.add{type="frame", name="chat-chat"}
        root.tabpanes['chat'].visible = false
        scrollpane = root.tabpanes['chat'].add{type="scroll-pane"}
        scrollpane.style.maximal_height = 700
        scrollpane.style.minimal_height = 700
        scrollpane.style.minimal_width = 1000
        scrollpane.style.horizontally_stretchable = true

        table = scrollpane.add{type="table", column_count=3}
        table.style.horizontally_stretchable = true
        root.messageTable['chat'] = table
        for _, row in pairs(global.chatlog) do
            if row.type == "chat" then
                addMessage(table, row)
            end
        end

--
        root.tabpanes['ping'] = tightFrame.add{type="frame", name="chat-ping"}
        root.tabpanes['ping'].visible = false
        scrollpane = root.tabpanes['ping'].add{type="scroll-pane"}
        scrollpane.style.maximal_height = 700
        scrollpane.style.minimal_height = 700
        scrollpane.style.minimal_width = 1000
        scrollpane.style.horizontally_stretchable = true

        table = scrollpane.add{type="table", column_count=3}
        table.style.horizontally_stretchable = true
        root.messageTable['ping'] = table
        for _, row in pairs(global.chatlog) do
            if row.type == "ping" then
                addMessage(table, row)
            end
        end

--
        root.tabpanes['command'] = tightFrame.add{type="frame", name="chat-command"}
        root.tabpanes['command'].visible = false
        scrollpane = root.tabpanes['command'].add{type="scroll-pane"}
        scrollpane.style.maximal_height = 700
        scrollpane.style.minimal_height = 700
        scrollpane.style.minimal_width = 1000
        scrollpane.style.horizontally_stretchable = true

        table = scrollpane.add{type="table", column_count=3}
        table.style.horizontally_stretchable = true
        root.messageTable['command'] = table
        for _, row in pairs(global.chatlog) do
            if row.type == "command" then
                addMessage(table, row)
            end
        end




    end
end


local function initialize()
    global.chatlog = global.chatlog or {}
end

script.on_load(function()
    initialize()
end)

script.on_init(function()
    initialize()

    for _, player in pairs(game.players) do
        local anchorpoint = mod_gui.get_button_flow(player)
        local button = anchorpoint["chat"]

        if button then
            button.destroy()
            button = nil
        end

        if not button then
            button = anchorpoint.add{
                type = "sprite-button",
                name = "chat",
                sprite = "utility/tick_custom",
                style = mod_gui.button_style
            }
        end
    end

end)

script.on_event(defines.events.on_console_chat, function(event)
    local type = "chat"

    if string.find(event.message, '[gps=',1,true) then
        type = "ping"
    end

    local row = {
        player_index = event.player_index,
        message = event.message,
        type = type,
        tick = event.tick
    }
    table.insert(global.chatlog, row)

    if #global.chatlog > 1000 then
        local removedRow = global.chatlog[1]
        removeMessageLive(removedRow)
        table.remove(global.chatlog, 1)
    end

    addMessageLive(row)
end)

script.on_event(defines.events.on_console_command, function(event)
    local type = "command"

    local row = {
        player_index = event.player_index,
        message = "/" .. event.command .. " " .. event.parameters,
        type = type,
        tick = event.tick
    }
    table.insert(global.chatlog, row)

    if #global.chatlog > 1000 then
        local removedRow = global.chatlog[1]
        removeMessageLive(removedRow)
        table.remove(global.chatlog, 1)
    end

    addMessageLive(row)
end)


script.on_event(defines.events.on_player_joined_game, function(e)
    local player = game.players[e.player_index]

    local anchorpoint = mod_gui.get_button_flow(player)
    local button = anchorpoint["chat"]

    if button then
        button.destroy()
        button = nil
    end

    if not button then
        button = anchorpoint.add{
            type = "sprite-button",
            name = "chat",
            sprite = "utility/tick_custom",
            style = mod_gui.button_style
        }
    end
end)


script.on_event(defines.events.on_gui_click, function(event)
    local element_name = event.element.name

    if element_name == "chat" then
        gui_chat(event.player_index)
        return
    end

    if string.find(element_name, 'chat-',1,true) then
        local gui = global.chat[event.player_index]


        -- tabs
        for _ in pairs(gui['tabs']) do
            if element_name == "chat-tab-" .. _ then
                for __ in pairs(gui['tabs']) do
                    gui['tabs'][__].inactive.visible = true
                    gui['tabs'][__].active.visible = false
                    if gui['tabpanes'][__] then
                        gui['tabpanes'][__].visible = false
                    end
                end
                gui['tabs'][_].inactive.visible = false
                gui['tabs'][_].active.visible = true

                if gui['tabpanes'][_] then
                    gui['tabpanes'][_].visible = true
                end
            end
        end
    end
end)