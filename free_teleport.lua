-- name: Free Teleport
-- description: Free Teleport\nby \\#437fcc\\Gaming32\\#ffffff\\\n\nAllows you to teleport to any player

---@type Vec3f | nil
destPos = nil

-- https://github.com/djoslin0/sm64ex-coop/blob/f99b5c05bb421910516841e71c4f3d6ca5ef0743/src/pc/chat_commands.c#L18-L39
---@param name string
function chat_get_network_player(name)
    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and tostring(i) == name then
            return gNetworkPlayers[i]
        end
    end
    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and gNetworkPlayers[i].name == name then
            return gNetworkPlayers[i]
        end
    end
    return nil
end

function warpHook()
    if destPos == nil then return end
    ---@type MarioState
    local m = gMarioStates[0]
    m.pos.x = destPos.x
    m.pos.y = destPos.y
    m.pos.z = destPos.z
    destPos = nil
end

---@param msg string
function teleportCommand(msg)
    local player = chat_get_network_player(msg)
    if player == nil then
        return false
    end
    ---@type NetworkPlayer
    local localPlayer = gNetworkPlayers[0]
    destPos = gMarioStates[player.localIndex].pos
    if (localPlayer.currLevelNum ~= player.currLevelNum) or
        (localPlayer.currAreaIndex ~= player.currAreaIndex) or
        (localPlayer.currActNum ~= player.currActNum)
    then
        warp_to_level(player.currLevelNum, player.currAreaIndex, player.currActNum)
    else
        warpHook()
    end
    return true
end

hook_event(HOOK_ON_WARP, warpHook)

hook_chat_command("tp", "[PLAYER] - Teleport to another player", teleportCommand)
