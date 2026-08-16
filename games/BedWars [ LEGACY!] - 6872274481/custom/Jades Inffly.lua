local BOOST_SPEED = 100
local BOOST_DURATION = 1.2
local FINAL_SPEED = 23

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local folder = ReplicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"]
if not folder then return end

-- Find all RemoteEvent children inside the folder
local remotes = {}
for _, child in ipairs(folder:GetChildren()) do
    if child:IsA("RemoteEvent") then
        table.insert(remotes, child)
    end
end
if #remotes == 0 then return end

local boostActive = false
local endTime = 0
local heartbeatConnection

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function applyBoost()
    local humanoid = getHumanoid()
    if not humanoid then return end

    boostActive = true
    endTime = tick() + BOOST_DURATION
    humanoid.WalkSpeed = BOOST_SPEED

    if not heartbeatConnection or not heartbeatConnection.Connected then
        heartbeatConnection = RunService.Heartbeat:Connect(function()
            local h = getHumanoid()
            if not h then return end

            if boostActive then
                if tick() < endTime then
                    h.WalkSpeed = BOOST_SPEED
                else
                    boostActive = false
                    h.WalkSpeed = FINAL_SPEED
                    heartbeatConnection:Disconnect()
                end
            end
        end)
    end
end

for _, remote in ipairs(remotes) do
    remote.OnClientEvent:Connect(function(targetModel, action)
        if action == "void_axe_jump" then
            applyBoost()
        end
    end)
end