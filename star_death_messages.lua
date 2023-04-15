-- name: Star + Death Messages
-- description: Star + Death Messages\nby \\#437fcc\\Gaming32\\#ffffff\\\n\nShows popups when players die or collect a star!

POPUP_BASE_COLOR = "\\#dcdcdc\\"
MESSAGE_CHAT_COLOR = "\\#ffff55\\"

isDead = false
fellOutOfWorld = -1

gGlobalSyncTable.sdmInChat = true

function updateHook()
    if gMarioStates[0].health >= 0x0100 then
        isDead = false
    end
    if gNetworkPlayers[0].currLevelNum ~= fellOutOfWorld then
        fellOutOfWorld = -1
    end
end

---@param message string
---@param lines integer
function showTheMessage(message, lines)
    if gGlobalSyncTable.sdmInChat then
        message = message:gsub("\n", " ")
        djui_chat_message_create(MESSAGE_CHAT_COLOR .. message .. POPUP_BASE_COLOR)
    else
        djui_popup_create(message, lines)
    end
end

---@param message string
---@param lines integer
function popupBroadcast(message, lines)
    showTheMessage(message, lines)
    network_send(true, {message = message, lines = lines})
end

---@param player NetworkPlayer?
---@return string
function getDisplayName(player)
    if player == nil then
        player = gNetworkPlayers[0]
    end
    ---@type string
    local baseColor
    if gGlobalSyncTable.sdmInChat then
        baseColor = MESSAGE_CHAT_COLOR
    else
        baseColor = POPUP_BASE_COLOR
    end
    return network_get_player_text_color_string(player.localIndex) .. player.name .. baseColor
end

---@param interactor MarioState
---@param interactee Object
---@param interactType InteractionType
---@param interactValue boolean
function starMessageHook(interactor, interactee, interactType, interactValue)
    if (interactor.playerIndex ~= 0) or (interactType ~= INTERACT_STAR_OR_KEY) then return end
    ---@type integer
    local courseId = gNetworkPlayers[0].currCourseNum
    local starId = (interactee.oBehParams >> 24) & 0x1F
    popupBroadcast(string.format(
        "%s got a star!\n%s",
        getDisplayName(),
        get_star_name(courseId, starId + 1)
    ), 2)
end

---@type Object | nil
hurtMario = nil

---@param localMario MarioState
function deathMessageHook(localMario)
    if localMario.playerIndex ~= 0 then
        return true
    end
    if isDead then
        return true
    end
    isDead = true
    local message = "%s died."
    if localMario.action == ACT_DROWNING then
        message = "%s drowned."
    elseif localMario.action == ACT_CAUGHT_IN_WHIRLPOOL then
        message = "%s was sucked into a whirlpool."
    elseif localMario.action == ACT_LAVA_BOOST then
        message = "%s lit their bum on fire."
    elseif localMario.action == ACT_QUICKSAND_DEATH then
        message = "%s drowned in sand."
    elseif localMario.action == ACT_EATEN_BY_BUBBA then
        message = "%s was eaten alive."
    elseif localMario.action == ACT_SQUISHED then
        message = "%s got squished inside a wall."
    elseif localMario.action == ACT_ELECTROCUTION then
        message = "%s felt the power."
    elseif localMario.action == ACT_SUFFOCATION then
        message = "%s was smoked out."
    elseif localMario.action == ACT_SUFFOCATION then
        message = "%s was smoked out."
    elseif localMario.action == ACT_STANDING_DEATH then
        if localMario.prevAction == ACT_BURNING_GROUND then
            message = "%s burned to death."
        end
    elseif (localMario.action == ACT_DEATH_ON_BACK) or (localMario.action == ACT_DEATH_ON_STOMACH) then
        if hurtMario ~= nil then
            local behavior = get_id_from_behavior(hurtMario.behavior)
            local spacedName = ""
            if behavior == id_bhvMario then
                spacedName = getDisplayName(network_player_from_global_index(hurtMario.globalPlayerIndex))
            else
                local objName = get_behavior_name_from_id(behavior)
                for i = 4, #objName do
                    local c = objName:sub(i, i)
                    if (#spacedName > 0) and (c:upper() == c) then
                        spacedName = spacedName .. " "
                    end
                    spacedName = spacedName .. c
                end
            end
            hurtMario = nil
            message = "%s was killed by " .. spacedName .. "."
        else
            message = "%s fell from a high place."
        end
    elseif (localMario.floor.type == SURFACE_DEATH_PLANE) and (localMario.pos.y < localMario.floorHeight + 2048) then
        ---@type NetworkPlayer
        local networkPlayer = gNetworkPlayers[0]
        local level = networkPlayer.currLevelNum
        if level == fellOutOfWorld then
            return
        end
        fellOutOfWorld = level
        message = "%s fell out of " .. get_level_name(
            networkPlayer.currCourseNum, level, networkPlayer.currAreaIndex
        ) .. "."
    end
    popupBroadcast(string.format(message, getDisplayName()), 1)
    return true
end

---@param mario MarioState
function marioDamageKbHook(mario)
    if mario.interactObj == nil then return end
    if (mario.interactObj.oInteractStatus & INT_STATUS_ATTACKED_MARIO) ~= 0 then
        hurtMario = mario.interactObj
    end
end

---@param dataTable table
function packetReceiveHook(dataTable)
    showTheMessage(dataTable.message, dataTable.lines)
end

---@param text string
function parseBoolean(text)
    text = text:lower()
    local firstLetter = text:sub(1, 1)
    if (firstLetter == "t" or firstLetter == "y" or text == "on") then
        return true
    end
    if (firstLetter == "f" or firstLetter == "n" or text == "off") then
        return false
    end
    return nil
end

---@param msg string
function showInPopupCommand(msg)
    if #msg > 0 then
        local value = parseBoolean(msg)
        if value == nil then
            djui_chat_message_create("\\#ff0000\\Unknown boolean value " .. msg .. ".\\#ffffff\\")
            return true
        end
        gGlobalSyncTable.sdmInChat = value
    end
    djui_chat_message_create("sdm-in-chat is currently " .. tostring(gGlobalSyncTable.sdmInChat))
    return true
end

hook_event(HOOK_UPDATE, updateHook)
hook_event(HOOK_ON_INTERACT, starMessageHook)
hook_event(HOOK_ON_DEATH, deathMessageHook)
hook_event(HOOK_ON_SET_MARIO_ACTION, marioDamageKbHook)
hook_event(HOOK_ON_PACKET_RECEIVE, packetReceiveHook)

if network_is_server() then
    hook_chat_command(
        "sdm-in-chat",
        "Whether to display Star + Death Messages in chat (as opposed to a popup). Default is true.",
        showInPopupCommand
    )
end
