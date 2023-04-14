-- name: Star + Death Messages
-- description: Star + Death Messages\nby \\#437fcc\\Gaming32\\#ffffff\\\n\nShows popups when players die or collect a star!

---@param message string
---@param lines integer
function popupBroadcast(message, lines)
    djui_popup_create(message, lines)
    network_send(true, {message = message, lines = lines})
end

---@return string
function getDisplayName()
    return network_get_player_text_color_string(0) .. network_player_from_global_index(0).name .. "\\#dcdcdc\\"
end

---@param interactor MarioState
---@param interactee Object
---@param interactType InteractionType
---@param interactValue boolean
function starMessageHook(interactor, interactee, interactType, interactValue)
    if (interactor.playerIndex ~= 0) or (interactType ~= INTERACT_STAR_OR_KEY) then
        return
    end
    ---@type integer
    local courseId = gNetworkPlayers[0].currCourseNum
    local starId = (interactee.oBehParams >> 24) & 0x1F
    popupBroadcast(string.format(
        "%s got a star!\n%s",
        getDisplayName(),
        get_star_name(courseId, starId + 1)
    ), 2)
end

---@param localMario MarioState
function deathMessageHook(localMario)
    if localMario.playerIndex ~= 0 then
        return true
    end
    local message = "%s died."
    if localMario.action == ACT_DROWNING then
        message = "%s drowned."
    elseif localMario.action == ACT_CAUGHT_IN_WHIRLPOOL then
        message = "%s was sucked into a whirlpool."
    elseif localMario.action == ACT_LAVA_BOOST then
        message = "%s tried to skip with a lava bounce."
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
    elseif localMario.action == ACT_DEATH_ON_BACK then
        if localMario.prevAction == ACT_HARD_BACKWARD_GROUND_KB then
            message = "%s fell from a high place."
        end
    elseif localMario.action == ACT_DEATH_ON_STOMACH then
        if localMario.prevAction == ACT_HARD_FORWARD_GROUND_KB then
            message = "%s fell from a high place."
        end
    end
    popupBroadcast(string.format(message, getDisplayName()), 1)
    return true
end

---@param dataTable table
function packetReceiveHook(dataTable)
    djui_popup_create(dataTable.message, dataTable.lines)
end

hook_event(HOOK_ON_INTERACT, starMessageHook)
hook_event(HOOK_ON_DEATH, deathMessageHook)
hook_event(HOOK_ON_PACKET_RECEIVE, packetReceiveHook)
