-- 为了不超过 Lua 的 200 个局部变量上限: 跨部分使用的变量在这里统一声明,
-- 每个部分各自放进 do ... end, 部分内部的局部变量用完即释放。
local CoreGui, DBG_METHODS, HOOK_VER, HttpService, Lighting, PL_TELEPORTS, Players, RunService
local S, SA, Stats, TeleportService, UIS, VirtualUser, WindUI, Window
local Workspace, addSlider, addToggle, aimPos, applyBodyScale, applyClock, applyFullbright, applyGuns
local applyHideNames, applyNoFog, applyNoParticle, applyNoShadow, applySmoothSpeed, applySpectate, cam, connect
local conns, controlModule, dbgRecord, errorLog, espData, espFolder, findStruggleRemote, fovCircle
local fpsLabel, genv, getClosestTarget, getContainers, getHum, getMoveVector, getRoot, getStruggleEvent
local getTargetPlayer, getTargetRoot, giveItem, giverNames, goRefuge, hitmarkerDrawing, installHooks, isChar
local joinLowPing, lastCharRefresh, lastFind, lastSafeCF, lastStruggle, leaveRefuge, listGrabRemotes, loadConfig
local loadErr, lp, names, nextRefuge, notify, orbitAngle, origFov, origGravity
local origJump, origSpeed, origZoom, originals, plDiagnose, plTeleport, ragChar, refreshChars
local removeESP, reportError, restoreFtap, restoreGuns, restoreHitbox, restoreHitboxOne, restoreNds, restoreVisualEnv
local safeCb, saveConfig, saveWaypoint, savedCF, setRagdollStates, showDebug, silentCircle, smoothSpeed
local startFly, stopFly, teleportHighest, tpOnce, tpToWaypoint, tracerLine, undoTeleport, updateAutoClick
local updateAutoFire, updateAutoJump, updateBhop, updateCrouch, updateESP, updateFly, updateHitbox, updateHitmarker
local updateRecoilComp, updateTracer, updateTriggerBot, wallOK, waypoints
do
-- ============================================================
-- 第 1 部分：头部 / 服务 / WindUI / 状态 / 工具函数
-- ============================================================
--[[ Omega hub · Roblox 通用脚本 (增强版)
     执行器: Delta    UI: WindUI
]]

genv = (getgenv and getgenv()) or _G
if genv.OmegaUnload then pcall(genv.OmegaUnload) end

Players = game:GetService("Players")
RunService = game:GetService("RunService")
UIS = game:GetService("UserInputService")
TeleportService = game:GetService("TeleportService")
HttpService = game:GetService("HttpService")
VirtualUser = game:GetService("VirtualUser")
Workspace = game:GetService("Workspace")
CoreGui = game:GetService("CoreGui")
Lighting = game:GetService("Lighting")
Stats = game:GetService("Stats")

lp = Players.LocalPlayer

local WIND_URLS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
}
for _, url in ipairs(WIND_URLS) do
    local ok, res = pcall(function() return loadstring(game:HttpGet(url))() end)
    if ok and res then WindUI = res break end
    loadErr = res
end
if not WindUI then
    warn("[Omega hub] WindUI 加载失败: " .. tostring(loadErr))
    return
end

function notify(msg, dur)
    pcall(function()
        WindUI:Notify({ Title = "Omega hub", Content = msg, Duration = dur or 3 })
    end)
end

local reportedErrors, reportedCount = {}, 0
errorLog = {}
function reportError(where, err)
    local key = where .. "|" .. tostring(err)
    if reportedErrors[key] then return end
    reportedCount = reportedCount + 1
    if reportedCount > 200 then reportedErrors, reportedCount = {}, 1 end -- 防止不同错误文字无限堆积
    reportedErrors[key] = true
    warn("[Omega hub] " .. where .. " 出错: " .. tostring(err))
    table.insert(errorLog, { t = os.time(), where = where, err = tostring(err) })
    if #errorLog > 50 then table.remove(errorLog, 1) end
    notify(where .. " 出错: " .. string.sub(tostring(err), 1, 140), 8)
end

S = {
    fly = false, flySpeed = 60,
    noclip = false,
    speedOn = false, speed = 50,
    cfSpeedOn = false, cfSpeed = 50,
    trSpeedOn = false, trSpeed = 50,
    velSpeedOn = false, velSpeed = 50,
    jumpOn = false, jump = 100,
    autoJump = false,
    bhop = false, bhopBoost = 1.0,
    sprint = false, sprintSpeed = 60,
    crouch = false,
    speedSmooth = true, speedSmoothRate = 5,
    fovOn = false, fov = 90,
    touchSens = false, touchSensX = 1, touchSensY = 1,
    fullbright = false, noFog = false, noShadow = false, noParticle = false,
    clockOn = false, clockTime = 12,
    bodyScaleOn = false, bodyScale = 1,
    hideNames = false, fpsShow = false,
    freecam = false, freecamSpeed = 50,
    hitbox = false, hitboxSize = 12, hitboxTrans = 0.7, hitboxTeam = true, hitboxPart = "HumanoidRootPart",
    silentNpc = false, silentNpcOnly = false, aimNpc = false,
    silentLock = false, silentLockFallback = false,
    espNpc = false, espNpcName = true, espNpcInfo = true, espNpcMax = 1500,
    tpRight = 0, tpUp = 0, tpBack = 3,
    aim = false, aimPart = "Head", aimFov = 150, aimSmooth = 4,
    aimTeam = true, aimWall = true, aimShowFov = true, aimHold = false,
    silent = false, silentPart = "Head", silentFov = 150, silentChance = 100, silentPredict = 0,
    silentTeam = true, silentWall = true, silentShowFov = true,
    silentRay = true, silentMouse = true,
    wallbang = false, wallTeam = true,
    wallMinLen = 20, wallNeedTool = false, debugRays = false,
    triggerBot = false, triggerFov = 40, triggerDelay = 0.05,
    autoFire = false, autoFireRate = 0.1, autoReload = false,
    tracer = false, hitmarker = false,
    infJump = false,
    antiFling = false, antiFlingMax = 100, antiRagdoll = false, antiVoid = false,
    antiTp = false, antiFreeze = false, antiKnock = false,
    zoomOn = false, zoom = 400, autoStruggle = false,
    refugeH = 1500, autoRefuge = false, refugeDelay = 0.5, highRadius = 200,
    noFall = false, noFallCap = 55, gravOn = false, grav = 80,
    gunMod = false, gunInfAmmo = true, gunFast = true, gunRate = 0.03,
    gunAuto = true, gunNoSpread = true, gunReload = true, gunRange = false,
    autoGive = false, respawnHere = false, fastRespawn = false,
    recoilComp = false, plTeamMark = true,
    esp = false, espName = true, espInfo = true, espHL = true, espTeam = false,
    boxEsp = false, healthBar = false, visCheck = false,
    target = nil,
    tpLoop = false, tpOrbit = false,
    orbitR = 10, orbitSpeed = 3, orbitH = 2,
    spectate = false,
    antiAfk = true,
    autoClick = false, autoClickCps = 8,
    perfMode = false,
    plTp = nil, giveSel = nil,
    -- 内部状态
    sprintActive = false, crouchOn = false,
}

genv.OmegaSilent = genv.OmegaSilent or {}
SA = genv.OmegaSilent
SA.internal = false

conns = {}
function connect(signal, fn)
    local okL, line = pcall(function() return debug.info(fn, "l") end)
    local where = "事件@" .. tostring(okL and line or "?")
    local c = signal:Connect(function(...)
        local ok, err = pcall(fn, ...)
        if not ok then reportError(where, err) end
    end)
    table.insert(conns, c)
    return c
end

-- 玩家列表缓存: 每帧都在跑的循环不再反复调用 GetPlayers() ——
-- 每次调用都会新建一张表, 垃圾积多了 Roblox 会周期性地"卡一下"
do
    local plist = Players:GetPlayers()
    connect(Players.PlayerAdded, function(p)
        if not table.find(plist, p) then plist[#plist + 1] = p end
    end)
    connect(Players.PlayerRemoving, function(p)
        local i = table.find(plist, p)
        if i then table.remove(plist, i) end
    end)
    function SA.players() return plist end
end

function getHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
function getRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
function cam() return Workspace.CurrentCamera end

function getContainers()
    local list = {}
    local bp = lp:FindFirstChildOfClass("Backpack")
    if bp then table.insert(list, bp) end
    local char = lp.Character
    if char then table.insert(list, char) end
    return list
end

-- 保存原值
originals = {
    speed = 16, jump = 50, fov = 70,
    ambient = Lighting.Ambient, outdoor = Lighting.OutdoorAmbient,
    fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
    brightness = Lighting.Brightness,
    gravity = Workspace.Gravity,
    clockTime = Lighting.ClockTime,
}-- ============================================================
end

do
-- 第 2 部分：飞行 / 移动补全
-- ============================================================
pcall(function()
    local pm = lp:WaitForChild("PlayerScripts", 5):WaitForChild("PlayerModule", 5)
    controlModule = require(pm):GetControls()
end)

function getMoveVector()
    if controlModule then
        local ok, v = pcall(function() return controlModule:GetMoveVector() end)
        if ok and typeof(v) == "Vector3" then return v end
    end
    local hum = getHum()
    if hum then return cam().CFrame:VectorToObjectSpace(hum.MoveDirection) end
    return Vector3.zero
end

local flyBV, flyBG
function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum, root = getHum(), getRoot()
    if hum then hum.PlatformStand = false end
    if root then root.AssemblyLinearVelocity = Vector3.zero end
end

function startFly()
    stopFly()
    local root, hum = getRoot(), getHum()
    if not root or not hum then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 9e4
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root
    hum.PlatformStand = true
end

function updateFly()
    local root, hum = getRoot(), getHum()
    if not root or not hum then return end
    if not flyBV or flyBV.Parent ~= root then startFly() end
    if not flyBV then return end
    local c = cam()
    local m = getMoveVector()
    local vel = Vector3.zero
    if m.Magnitude > 0 then
        vel = c.CFrame.LookVector * (-m.Z) + c.CFrame.RightVector * m.X
        if vel.Magnitude > 0 then vel = vel.Unit * math.min(m.Magnitude, 1) end
    end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then
        vel -= Vector3.new(0, 1, 0)
    end
    flyBV.Velocity = vel * S.flySpeed
    local look = c.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude > 0.01 then
        flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
    end
end

-- 无限跳
connect(UIS.JumpRequest, function()
    if S.infJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Auto Jump
local lastAutoJump = 0
function updateAutoJump()
    if not S.autoJump then return end
    local hum = getHum()
    if not hum or hum.Health <= 0 then return end
    if os.clock() - lastAutoJump < 0.1 then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
        lastAutoJump = os.clock()
    end
end

-- Bunny Hop
local bhopWasGround = false
local bhopSavedV = Vector3.zero
function updateBhop(dt)
    if not S.bhop or S.fly then return end
    local hum, root = getHum(), getRoot()
    if not hum or not root then return end
    local onGround = hum.FloorMaterial ~= Enum.Material.Air
    if onGround and not bhopWasGround then
        local h = Vector3.new(bhopSavedV.X, 0, bhopSavedV.Z)
        if h.Magnitude > 1 then
            local v = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(h.X * S.bhopBoost, v.Y, h.Z * S.bhopBoost)
        end
    end
    if not onGround then
        local v = root.AssemblyLinearVelocity
        local hv = Vector3.new(v.X, 0, v.Z)
        if hv.Magnitude > bhopSavedV.Magnitude then bhopSavedV = v end
    end
    bhopWasGround = onGround
end

-- 冲刺
connect(UIS.InputBegan, function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then S.sprintActive = true end
end)
connect(UIS.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then S.sprintActive = false end
end)

-- 蹲下
local origHipHeight
function updateCrouch()
    local hum = getHum()
    if not hum then return end
    if S.crouch and not S.crouchOn then
        origHipHeight = hum.HipHeight
        hum.HipHeight = math.max(0, origHipHeight - 1.5)
        S.crouchOn = true
    elseif not S.crouch and S.crouchOn then
        hum.HipHeight = origHipHeight or hum.HipHeight
        S.crouchOn = false
    end
end

-- 速度平滑辅助
smoothSpeed = 16
function applySmoothSpeed(target)
    if S.speedSmooth then
        smoothSpeed = smoothSpeed + (target - smoothSpeed) * math.clamp(S.speedSmoothRate * 0.05, 0.05, 1)
        return smoothSpeed
    end
    return target
end
-- ============================================================
end

do
-- 第 3 部分：穿墙 / Hitbox / 自瞄
-- ============================================================
local noclipParts, noclipChar, noclipAt = {}, nil, 0
local function applyNoclip()
    if not S.noclip then return end
    local c = lp.Character
    if not c then return end
    -- 零件列表每 0.5 秒 (或换角色时) 重建一次, 其余帧只遍历缓存, 不产生垃圾
    local now = os.clock()
    if noclipChar ~= c or now - noclipAt > 0.5 then
        noclipChar, noclipAt = c, now
        noclipParts = {}
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                local inTool = false
                local anc = p.Parent
                while anc and anc ~= c do
                    if anc:IsA("Tool") then inTool = true break end
                    anc = anc.Parent
                end
                if not inTool then noclipParts[#noclipParts + 1] = p end
            end
        end
    end
    for i = 1, #noclipParts do
        local p = noclipParts[i]
        if p.CanCollide then p.CanCollide = false end
    end
end
connect(RunService.Stepped, applyNoclip)
connect(RunService.Heartbeat, applyNoclip)
connect(lp.CharacterAdded, function()
    task.wait(0.2)
    applyNoclip()
    if S.fly then
        local r = getRoot()
        if r then startFly() end
    end
end)

origSpeed, origJump, origFov = 16, 50, 70

-- Hitbox
local hbOriginal = {}
local hbSizeN, hbSizeV = nil, nil
function restoreHitboxOne(plr)
    local d = hbOriginal[plr]
    if d then
        if d.part and d.part.Parent then
            d.part.Size = d.size
            d.part.Transparency = d.trans
            d.part.CanCollide = d.coll
        end
        hbOriginal[plr] = nil
    end
end
function restoreHitbox()
    for plr in pairs(hbOriginal) do restoreHitboxOne(plr) end
end
function updateHitbox()
    if not S.hitbox and next(hbOriginal) == nil then return end -- 没开 / 没有要还原的东西就直接跳过
    for _, plr in ipairs(SA.players()) do
        if plr ~= lp then
            local char = plr.Character
            local part = char and char:FindFirstChild(S.hitboxPart or "HumanoidRootPart")
            local skip = S.hitboxTeam and plr.Team ~= nil and plr.Team == lp.Team
            if S.hitbox and part and not skip then
                local d = hbOriginal[plr]
                if d and d.part ~= part then
                    restoreHitboxOne(plr) -- 切换部位 / 重生后, 先还原旧的
                    d = nil
                end
                if not d then
                    hbOriginal[plr] = {
                        part = part, size = part.Size,
                        trans = part.Transparency, coll = part.CanCollide,
                    }
                end
                if hbSizeN ~= S.hitboxSize then
                    hbSizeN = S.hitboxSize
                    hbSizeV = Vector3.new(hbSizeN, hbSizeN, hbSizeN)
                end
                if part.Size ~= hbSizeV then part.Size = hbSizeV end
                if part.Transparency ~= S.hitboxTrans then part.Transparency = S.hitboxTrans end
                if part.CanCollide then part.CanCollide = false end
            else
                restoreHitboxOne(plr)
            end
        end
    end
end

-- 自瞄 FOV 圈
if Drawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 1
        fovCircle.Visible = false
    end)
end

-- NPC 缓存: 场景里所有带 Humanoid 但不是玩家角色的模型。
-- 只在用到 NPC 功能时才启动 (默认完全不占性能); 现有场景分帧遍历, 不会一次性建出超大的表。
local npcSet = {}
local npcTracking = false
local npcConns = {}
local npcScanId = 0
local npcCache, npcCacheAt = {}, 0

local function tryAddNpc(inst)
    if inst.ClassName == "Humanoid" then
        local m = inst.Parent
        if m and m:IsA("Model") then npcSet[m] = inst end
    end
end

local function startNpcTracking()
    if npcTracking then return end
    npcTracking = true
    npcScanId += 1
    local myScan = npcScanId
    npcConns[1] = Workspace.DescendantAdded:Connect(tryAddNpc)
    npcConns[2] = Workspace.DescendantRemoving:Connect(function(inst)
        if inst.ClassName == "Humanoid" then
            local m = inst.Parent
            if m then npcSet[m] = nil end
        end
    end)
    -- 分帧扫描: 用栈逐层往下找, 不进入零件内部 (Humanoid 只会在 Model 里), 每帧最多处理约 1500 个节点
    task.spawn(function()
        local stack = { Workspace }
        local budget = 0
        while #stack > 0 and npcTracking and npcScanId == myScan do
            local node = stack[#stack]
            stack[#stack] = nil
            local children = node:GetChildren()
            for i = 1, #children do
                local child = children[i]
                tryAddNpc(child)
                if not child:IsA("BasePart") then stack[#stack + 1] = child end
            end
            budget = budget + #children + 1
            if budget >= 1500 then
                budget = 0
                task.wait()
            end
        end
    end)
end

local function stopNpcTracking()
    if not npcTracking then return end
    npcTracking = false
    npcScanId += 1
    for i = 1, #npcConns do
        npcConns[i]:Disconnect()
        npcConns[i] = nil
    end
    npcSet = {}
    npcCache = {}
end

-- NPC 功能全关了就停止跟踪, 释放资源
do
    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        acc = acc + dt
        if acc < 2 then return end
        acc = 0
        if npcTracking and not (S.silentNpc or S.silentNpcOnly or S.aimNpc or S.espNpc) then
            stopNpcTracking()
        end
    end)
end

-- 返回当前活着的 NPC 列表: { model, hum, root } (结果缓存 0.2 秒, 不会每帧重算)
function SA.getNpcs()
    if not npcTracking then startNpcTracking() end
    local now = os.clock()
    if now - npcCacheAt < 0.2 then return npcCache end
    npcCacheAt = now
    local list = {}
    local myChar = lp.Character
    for m, hum in pairs(npcSet) do
        if not m.Parent or not hum.Parent then
            npcSet[m] = nil
        elseif m ~= myChar and not Players:GetPlayerFromCharacter(m) and hum.Health > 0 then
            local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
            if root then list[#list + 1] = { model = m, hum = hum, root = root } end
        end
    end
    npcCache = list
    return list
end

function getClosestTarget(fov, partName, teamCheck, wallCheck, includeNpc, npcOnly, onlyName)
    fov = fov or S.aimFov
    partName = partName or S.aimPart
    if teamCheck == nil then teamCheck = S.aimTeam end
    if wallCheck == nil then wallCheck = S.aimWall end
    if partName == "Random" then
        partName = (math.random(1, 2) == 1) and "Head" or "HumanoidRootPart"
    end
    local c = cam()
    local center = c.ViewportSize / 2
    local best, bestDist = nil, fov
    local myChar = lp.Character
    local camPos = c.CFrame.Position
    local wallParams, wallFilter -- 墙体检测用的射线参数: 一次调用里只创建一份, 重复使用

    -- 评估一个候选 (玩家角色或 NPC 模型)
    -- force = true: 指定玩家锁定, 不受屏幕范围限制 (在屏幕外 / 身后也照样锁)
    local function consider(char, hum, force)
        local part = char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
            or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
        if not (hum and hum.Health > 0 and part) then return end
        local d = 0
        if not force then
            local pos, onScreen = c:WorldToViewportPoint(part.Position)
            if not onScreen then return end
            d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if d >= bestDist then return end
        end
        local visible = true
        if wallCheck then
            if not wallParams then
                wallParams = RaycastParams.new()
                wallParams.FilterType = Enum.RaycastFilterType.Exclude
                wallParams.IgnoreWater = true
                wallFilter = {}
            end
            wallFilter[1] = char
            wallFilter[2] = myChar -- 可能为 nil, 放在最后不影响数组
            wallParams.FilterDescendantsInstances = wallFilter
            SA.internal = true
            local okR, hit = pcall(Workspace.Raycast, Workspace, camPos, part.Position - camPos, wallParams)
            SA.internal = false
            visible = okR and hit == nil
        end
        if visible then best, bestDist = part, d end
    end

    if onlyName then
        local plr = Players:FindFirstChild(onlyName)
        local char = plr and plr ~= lp and plr.Character
        if char then consider(char, char:FindFirstChildOfClass("Humanoid"), true) end
        return best
    end

    if not npcOnly then
        for _, plr in ipairs(SA.players()) do
            if plr ~= lp then
                local char = plr.Character
                local isTeam = teamCheck and plr.Team ~= nil and plr.Team == lp.Team
                if char and not isTeam then
                    consider(char, char:FindFirstChildOfClass("Humanoid"))
                end
            end
        end
    end
    if includeNpc or npcOnly then
        for _, n in ipairs(SA.getNpcs()) do
            consider(n.model, n.hum)
        end
    end
    return best
end
-- ============================================================
end

do
-- 第 4 部分：Silent Aim 状态 / 目标 / 调试 / Tracer / TriggerBot
-- ============================================================
SA.on, SA.ray, SA.mouseOn = false, true, true
SA.chance, SA.predict = 100, 0
SA.wall = false
SA.charList, SA.charSet = {}, {}
SA.wallMin, SA.needTool, SA.hasTool, SA.debug = 20, false, false, false
SA.dbg, SA.dbgLen = {}, {}
SA.target = nil
SA.mouse = lp:GetMouse()

if Drawing then
    pcall(function()
        silentCircle = Drawing.new("Circle")
        silentCircle.Thickness = 1.5
        silentCircle.NumSides = 64
        silentCircle.Filled = false
        silentCircle.Color = Color3.fromRGB(255, 70, 70)
        silentCircle.Transparency = 1
        silentCircle.Visible = false
    end)
end

function aimPos()
    local t = SA.target
    if not t or not t.Parent then return nil end
    if SA.chance < 100 and math.random(1, 100) > SA.chance then return nil end
    return t.Position + t.AssemblyLinearVelocity * SA.predict
end

lastCharRefresh = 0
function refreshChars()
    local list, set = {}, {}
    for _, plr in ipairs(SA.players()) do
        local char = plr.Character
        if plr ~= lp and char then
            local isTeam = S.wallTeam and plr.Team ~= nil and plr.Team == lp.Team
            if not isTeam then
                list[#list + 1] = char
                set[char] = true
            end
        end
    end
    if S.silentNpc or S.silentNpcOnly then
        for _, n in ipairs(SA.getNpcs()) do
            list[#list + 1] = n.model
            set[n.model] = true
        end
    end
    SA.charList, SA.charSet = list, set
end

function isChar(inst)
    local p = inst
    while p and p ~= Workspace do
        if SA.charSet[p] then return true end
        p = p.Parent
    end
    return false
end

HOOK_VER = 3
DBG_METHODS = {
    Raycast = true, FindPartOnRay = true, FindPartOnRayWithIgnoreList = true,
    FindPartOnRayWithWhitelist = true, ViewportPointToRay = true, ScreenPointToRay = true,
}
function dbgRecord(method, exec, ...)
    local key = (exec and "[脚本自己]" or "") .. method
    SA.dbg[key] = (SA.dbg[key] or 0) + 1
    local len
    if method == "Raycast" then
        local _, d = ...
        if typeof(d) == "Vector3" then len = d.Magnitude end
    elseif method ~= "ViewportPointToRay" and method ~= "ScreenPointToRay" then
        local r = ...
        if typeof(r) == "Ray" then len = r.Direction.Magnitude end
    end
    if len and len > (SA.dbgLen[key] or 0) then SA.dbgLen[key] = len end
end
function showDebug()
    local items = {}
    for k, n in pairs(SA.dbg) do items[#items + 1] = { k, n, SA.dbgLen[k] } end
    if #items == 0 then
        notify("没有记录到任何射线调用。可能是: 开关没开 / hook 没生效 / 这个游戏不用射线判定命中", 8)
        return
    end
    table.sort(items, function(a, b) return a[2] > b[2] end)
    local parts = {}
    for i = 1, math.min(#items, 6) do
        local it = items[i]
        parts[#parts + 1] = string.format("%s ×%d%s", it[1], it[2],
            it[3] and (" 最长" .. math.floor(it[3])) or "")
    end
    local msg = table.concat(parts, "\n")
    print("[Omega hub] 射线调试:\n" .. msg)
    notify(msg, 10)
    SA.dbg, SA.dbgLen = {}, {}
end
function wallOK(len)
    return SA.wall and len >= SA.wallMin and (not SA.needTool or SA.hasTool)
end

-- ============================================================
-- Tracer（瞄准指示线）
-- ============================================================
if Drawing then
    pcall(function()
        tracerLine = Drawing.new("Line")
        tracerLine.Thickness = 1.5
        tracerLine.Color = Color3.fromRGB(0, 255, 140)
        tracerLine.Transparency = 1
        tracerLine.Visible = false
    end)
end
function updateTracer()
    if not tracerLine then return end
    if not S.tracer then tracerLine.Visible = false return end
    local t = SA.target
    if not t or not t.Parent then tracerLine.Visible = false return end
    local c = cam()
    local screenPos, onScreen = c:WorldToViewportPoint(t.Position)
    if not onScreen then tracerLine.Visible = false return end
    tracerLine.From = c.ViewportSize / 2
    tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
    tracerLine.Visible = true
end

-- ============================================================
-- Hitmarker（准星命中提示）
-- ============================================================
local hitmarkerUntil = 0
if Drawing then
    pcall(function()
        hitmarkerDrawing = Drawing.new("Circle")
        hitmarkerDrawing.Thickness = 2
        hitmarkerDrawing.NumSides = 4
        hitmarkerDrawing.Filled = false
        hitmarkerDrawing.Color = Color3.fromRGB(255, 60, 60)
        hitmarkerDrawing.Visible = false
    end)
end
local function flashHitmarker()
    hitmarkerUntil = os.clock() + 0.12
    if hitmarkerDrawing then
        hitmarkerDrawing.Position = cam().ViewportSize / 2
        hitmarkerDrawing.Radius = 14
        hitmarkerDrawing.Visible = true
    end
end
function updateHitmarker()
    if hitmarkerDrawing then
        if os.clock() < hitmarkerUntil then
            hitmarkerDrawing.Position = cam().ViewportSize / 2
        else
            hitmarkerDrawing.Visible = false
        end
    end
end

-- ============================================================
-- TriggerBot 辅助
-- ============================================================
local lastTrigger = 0
function updateTriggerBot()
    if not S.triggerBot then return end
    if os.clock() - lastTrigger < S.triggerDelay then return end
    -- 只在按住右键或用鼠标时生效? 这里保持"随时"触发, UI 可配
    local t = getClosestTarget(S.triggerFov, "Head", true, false)
    if not t then t = getClosestTarget(S.triggerFov, "HumanoidRootPart", true, false) end
    if t then
        pcall(function() VirtualUser:ClickButton1(cam().ViewportSize / 2) end)
        if S.hitmarker then flashHitmarker() end
        lastTrigger = os.clock()
    end
end

-- ============================================================
-- AutoFire（自动开火 / 换弹）
-- ============================================================
local lastAutoFire = 0
function updateAutoFire()
    if not S.autoFire then return end
    if os.clock() - lastAutoFire < S.autoFireRate then return end
    local char = lp.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        lastAutoFire = os.clock()
    end
end
-- ============================================================
end

do
-- 第 5 部分：installHooks
-- ============================================================
function installHooks()
    if genv.OmegaHookVer == HOOK_VER then return true end
    if not (hookmetamethod and getnamecallmethod) then return false end

    local ncc = newcclosure or function(f) return f end
    local chk
    if checkcaller then
        chk = checkcaller
    else
        chk = function() return SA.internal == true end
    end
    local MIN_LEN = 50

    local okN = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", ncc(function(self, ...)
            local method = getnamecallmethod()
            local silent = SA.on and SA.ray and SA.target
            if silent or SA.wall or SA.debug then
                local exec = chk()
                if SA.debug and DBG_METHODS[method] then dbgRecord(method, exec, ...) end
                if not exec then
                    if self == Workspace then
                        if method == "Raycast" then
                            local origin, direction = ...
                            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                                local len = direction.Magnitude
                                local doS = silent and len >= MIN_LEN
                                local doW = wallOK(len)
                                if doS or doW then
                                    local dir = direction
                                    if doS then
                                        local p = aimPos()
                                        if p and (p - origin).Magnitude > 0.01 then
                                            dir = (p - origin).Unit * len
                                        end
                                    end
                                    local res = oldNamecall(self, origin, dir, select(3, ...))
                                    if doW and res and not isChar(res.Instance) then
                                        local rp = RaycastParams.new()
                                        rp.FilterType = Enum.RaycastFilterType.Include
                                        rp.FilterDescendantsInstances = SA.charList
                                        local res2 = Workspace.Raycast(Workspace, origin, dir, rp)
                                        if res2 then return res2 end
                                    end
                                    return res
                                end
                            end
                        elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList"
                            or method == "FindPartOnRayWithWhitelist" then
                            local ray = ...
                            if typeof(ray) == "Ray" then
                                local len = ray.Direction.Magnitude
                                local doS = silent and len >= MIN_LEN
                                local doW = wallOK(len)
                                if doS or doW then
                                    local newRay = ray
                                    if doS then
                                        local p = aimPos()
                                        if p and (p - ray.Origin).Magnitude > 0.01 then
                                            newRay = Ray.new(ray.Origin, (p - ray.Origin).Unit * len)
                                        end
                                    end
                                    local r1, r2, r3, r4 = oldNamecall(self, newRay, select(2, ...))
                                    if doW and r1 and not isChar(r1) then
                                        local p2, pos2, n2, m2 = Workspace.FindPartOnRayWithWhitelist(Workspace, newRay, SA.charList)
                                        if p2 then return p2, pos2, n2, m2 end
                                    end
                                    return r1, r2, r3, r4
                                end
                            end
                        end
                    elseif silent and (method == "ViewportPointToRay" or method == "ScreenPointToRay") then
                        if self == Workspace.CurrentCamera then
                            local r = oldNamecall(self, ...)
                            local p = aimPos()
                            if p and (p - r.Origin).Magnitude > 0.01 then
                                return Ray.new(r.Origin, (p - r.Origin).Unit)
                            end
                            return r
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end)

    local okI = pcall(function()
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", ncc(function(self, key)
            if SA.on and SA.mouseOn and SA.target and self == SA.mouse
                and (key == "Hit" or key == "Target") and not chk() then
                local p = aimPos()
                if p then
                    if key == "Hit" then return CFrame.new(p) end
                    return SA.target
                end
            end
            return oldIndex(self, key)
        end))
    end)

    if okN or okI then genv.OmegaHookVer = HOOK_VER end
    return okN or okI
end
-- ============================================================
end

do
-- 第 6 部分：手机端灵敏度 / 渲染循环 / 自由视角 / FPS
-- ============================================================
local touchActive = {}
local lastPitch, lastYaw
connect(UIS.TouchStarted, function(input, gp)
    if not gp then touchActive[input] = true end
end)
connect(UIS.TouchEnded, function(input)
    touchActive[input] = nil
end)
local function applyTouchSens(c)
    if not S.touchSens or not lastPitch then return end
    local n = 0
    for _ in pairs(touchActive) do n += 1 end
    if n ~= 1 then return end
    local pitch, yaw = c.CFrame:ToOrientation()
    local dYaw = ((yaw - lastYaw + math.pi) % (2 * math.pi)) - math.pi
    local dPitch = pitch - lastPitch
    if math.abs(dYaw) < 1e-5 and math.abs(dPitch) < 1e-5 then return end
    local newPitch = math.clamp(lastPitch + dPitch * S.touchSensY, -1.45, 1.45)
    local newYaw = lastYaw + dYaw * S.touchSensX
    local oldCF = c.CFrame
    local oldRot = oldCF - oldCF.Position
    local focusPos = c.Focus.Position
    local offset = oldRot:VectorToObjectSpace(oldCF.Position - focusPos)
    local newRot = CFrame.fromOrientation(newPitch, newYaw, 0)
    c.CFrame = CFrame.new(focusPos + newRot:VectorToWorldSpace(offset)) * newRot
end

-- 自由视角
local freecamCF = nil
local freecamLastMouse = nil
local function updateFreecam(dt)
    local c = cam()
    if S.freecam then
        if not freecamCF then
            freecamCF = c.CFrame
            c.CameraType = Enum.CameraType.Scriptable
        end
        local mv = getMoveVector()
        local speed = S.freecamSpeed * dt
        freecamCF = freecamCF + freecamCF.LookVector * (-mv.Z * speed) + freecamCF.RightVector * (mv.X * speed)
        if UIS:IsKeyDown(Enum.KeyCode.Space) then freecamCF = freecamCF + Vector3.new(0, speed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then freecamCF = freecamCF - Vector3.new(0, speed, 0) end
        local md = UIS:GetMouseDelta()
        if md.Magnitude > 0 then
            local rx = CFrame.Angles(0, -md.X * 0.003, 0)
            local ry = CFrame.Angles(-md.Y * 0.003, 0, 0)
            freecamCF = freecamCF * rx * ry
        end
        c.CFrame = freecamCF
    elseif freecamCF then
        freecamCF = nil
        c.CameraType = Enum.CameraType.Custom
    end
end

-- FPS 显示
local fpsValue, fpsAccum, fpsFrames = 0, 0, 0
if Drawing then
    pcall(function()
        fpsLabel = Drawing.new("Text")
        fpsLabel.Size = 16
        fpsLabel.Color = Color3.fromRGB(0, 255, 120)
        fpsLabel.Outline = true
        fpsLabel.Visible = false
    end)
end
local function updateFps(dt)
    fpsAccum += dt
    fpsFrames += 1
    if fpsAccum >= 0.5 then
        fpsValue = math.floor(fpsFrames / fpsAccum)
        fpsAccum = 0
        fpsFrames = 0
        -- 文字每 0.5 秒才刷新一次 (以前每帧都读 Stats 并重新拼字符串)
        if fpsLabel then
            fpsLabel.Visible = S.fpsShow
            if S.fpsShow then
                fpsLabel.Position = Vector2.new(20, 20)
                local ping = "?"
                pcall(function()
                    local ps = Stats.Network.ServerStatsItem["Data Ping"]
                    if ps then ping = math.floor(ps:GetValue()) end
                end)
                fpsLabel.Text = string.format("FPS: %d  Ping: %s", fpsValue, tostring(ping))
            end
        end
    end
end

-- Drawing 的属性写入开销不小, 只在值真的变了才写
SA.fovSt, SA.silentSt = {}, {}
local function syncCircle(circle, st, visible, radius, vp)
    if visible then
        if not st.vis then
            circle.Visible = true
            st.vis = true
        end
        if st.r ~= radius then
            circle.Radius = radius
            st.r = radius
        end
        if st.vp ~= vp then
            circle.Position = vp / 2
            st.vp = vp
        end
    elseif st.vis then
        circle.Visible = false
        st.vis = false
    end
end

pcall(function() RunService:UnbindFromRenderStep("OmegaAim") end)
local function omegaRender(dt)
    local c = cam()
    if S.fovOn then c.FieldOfView = S.fov end

    updateFreecam(dt)
    if S.freecam then return end

    applyTouchSens(c)

    local vp = c.ViewportSize
    if fovCircle then syncCircle(fovCircle, SA.fovSt, S.aim and S.aimShowFov, S.aimFov, vp) end

    SA.on = S.silent
    SA.ray = S.silentRay
    SA.mouseOn = S.silentMouse
    SA.chance = S.silentChance
    SA.predict = S.silentPredict
    SA.wall = S.wallbang
    SA.wallMin = S.wallMinLen
    SA.needTool = S.wallNeedTool
    SA.debug = S.debugRays
    if S.wallbang and S.wallNeedTool then
        local ch = lp.Character
        SA.hasTool = ch ~= nil and ch:FindFirstChildOfClass("Tool") ~= nil
    end
    if S.wallbang and os.clock() - lastCharRefresh > 0.2 then
        lastCharRefresh = os.clock()
        refreshChars()
    end
    if S.silent then
        local part
        local wallCheck = S.silentWall and not S.wallbang
        if S.silentLock and S.silentLockName then
            -- 只锁指定的人; 他不在 / 死了 -> 可选改追最近的人
            part = getClosestTarget(math.huge, S.silentPart, false, wallCheck, false, false, S.silentLockName)
            if not part and S.silentLockFallback then
                part = getClosestTarget(S.silentFov, S.silentPart, S.silentTeam, wallCheck, S.silentNpc, S.silentNpcOnly)
            end
        else
            part = getClosestTarget(S.silentFov, S.silentPart, S.silentTeam, wallCheck, S.silentNpc, S.silentNpcOnly)
        end
        SA.target = part
    else
        SA.target = nil
    end
    if silentCircle then syncCircle(silentCircle, SA.silentSt, S.silent and S.silentShowFov, S.silentFov, vp) end

    if S.aim and not (S.aimHold and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
        local part = getClosestTarget(nil, nil, nil, nil, S.aimNpc)
        if part then
            local goal = CFrame.lookAt(c.CFrame.Position, part.Position)
            local alpha = math.clamp(1 / S.aimSmooth, 0.03, 1)
            c.CFrame = c.CFrame:Lerp(goal, alpha)
        end
    end

    updateTracer()
    updateHitmarker()
    updateFps(dt)

    lastPitch, lastYaw = c.CFrame:ToOrientation()
end
RunService:BindToRenderStep("OmegaAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local ok, err = pcall(omegaRender, dt)
    if not ok then reportError("渲染步骤", err) end
end)
-- ============================================================
end

do
-- 第 7 部分：ESP 增强 / 传送 / 防挂机 / 低Ping / 自动点击
-- ============================================================
espFolder = Instance.new("Folder")
espFolder.Name = "OmegaESP"
do
    local ok = pcall(function()
        espFolder.Parent = (gethui and gethui()) or CoreGui
    end)
    if not ok then espFolder.Parent = lp:WaitForChild("PlayerGui") end
end

espData = {}
local boxDrawings = {}

function removeESP(plr)
    local d = espData[plr]
    if d then
        if d.hl then d.hl:Destroy() end
        if d.bb then d.bb:Destroy() end
        espData[plr] = nil
    end
    local b = boxDrawings[plr]
    if b then
        for _, line in ipairs(b) do pcall(function() line:Remove() end) end
        boxDrawings[plr] = nil
    end
end

local function ensureBox(plr)
    local b = boxDrawings[plr]
    if b then return b end
    if not Drawing then return nil end
    local lines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(255, 60, 60)
        line.Transparency = 1
        line.Visible = false
        lines[i] = line
    end
    boxDrawings[plr] = lines
    return lines
end

local ESP_RED = Color3.fromRGB(255, 60, 60)
local ESP_GREEN = Color3.fromRGB(60, 220, 60)
local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
visParams.IgnoreWater = true
local visFilter = {}

function updateESP()
    local c = cam()
    for _, plr in ipairs(SA.players()) do
        if plr ~= lp then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local skipTeam = S.espTeam and plr.Team ~= nil and plr.Team == lp.Team
            if S.esp and char and hrp and hum and hum.Health > 0 and not skipTeam then
                local d = espData[plr]
                if not d or d.char ~= char then
                    removeESP(plr)
                    d = { char = char }
                    d.hl = Instance.new("Highlight")
                    d.hl.FillTransparency = 0.65
                    d.hl.OutlineTransparency = 0
                    d.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    d.hl.Adornee = char
                    d.hl.Parent = espFolder
                    d.bb = Instance.new("BillboardGui")
                    d.bb.Size = UDim2.fromOffset(200, 50)
                    d.bb.StudsOffset = Vector3.new(0, 3, 0)
                    d.bb.AlwaysOnTop = true
                    d.bb.Adornee = char:FindFirstChild("Head") or hrp
                    d.bb.Parent = espFolder
                    d.label = Instance.new("TextLabel")
                    d.label.BackgroundTransparency = 1
                    d.label.Size = UDim2.new(1, 0, 0.6, 0)
                    d.label.Font = Enum.Font.GothamBold
                    d.label.TextSize = 13
                    d.label.TextStrokeTransparency = 0
                    d.label.Parent = d.bb
                    if S.healthBar then
                        d.hpBg = Instance.new("Frame")
                        d.hpBg.Size = UDim2.new(0.8, 0, 0.18, 0)
                        d.hpBg.Position = UDim2.new(0.1, 0, 0.72, 0)
                        d.hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        d.hpBg.BorderSizePixel = 0
                        d.hpBg.Parent = d.bb
                        d.hpFill = Instance.new("Frame")
                        d.hpFill.Size = UDim2.new(1, 0, 1, 0)
                        d.hpFill.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
                        d.hpFill.BorderSizePixel = 0
                        d.hpFill.Parent = d.hpBg
                    end
                    espData[plr] = d
                end
                local color = (S.espTeam and plr.Team ~= nil) and plr.TeamColor.Color or ESP_RED
                if d.color ~= color then
                    d.color = color
                    d.hl.FillColor = color
                    d.hl.OutlineColor = color
                    d.label.TextColor3 = color
                end
                if d.hlOn ~= S.espHL then
                    d.hlOn = S.espHL
                    d.hl.Enabled = S.espHL
                end
                local dist, hp, maxHp = 0, 0, 0
                if S.espInfo then
                    local myRoot = getRoot()
                    dist = myRoot and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0
                    hp, maxHp = math.floor(hum.Health), math.floor(hum.MaxHealth)
                end
                -- 文字只在内容真的变了才重新拼接 / 写入, 不再每次都产生新字符串
                if d.nameOn ~= S.espName or d.infoOn ~= S.espInfo or d.dist ~= dist or d.hp ~= hp or d.maxHp ~= maxHp then
                    d.nameOn, d.infoOn, d.dist, d.hp, d.maxHp = S.espName, S.espInfo, dist, hp, maxHp
                    local text = ""
                    if S.espName then text = plr.DisplayName .. " (@" .. plr.Name .. ")" end
                    if S.espInfo then
                        local info = string.format("[%dm]  HP %d/%d", dist, hp, maxHp)
                        text = (text ~= "") and (text .. "\n" .. info) or info
                    end
                    d.label.Text = text
                    d.hasText = text ~= ""
                end
                local bbOn = d.hasText or (d.hpBg ~= nil)
                if d.bbOn ~= bbOn then
                    d.bbOn = bbOn
                    d.bb.Enabled = bbOn
                end
                if d.hpFill then
                    d.hpFill.Size = UDim2.new(math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1), 0, 1, 0)
                end
                -- 方框
                if S.boxEsp and Drawing then
                    local bl = ensureBox(plr)
                    if bl then
                        local pos, onScreen = c:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local top = c:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                            local bottom = c:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            local h = math.abs(top.Y - bottom.Y)
                            local w = h * 0.55
                            local x, y = pos.X - w / 2, math.min(top.Y, bottom.Y)
                            local corners = {
                                Vector2.new(x, y), Vector2.new(x + w, y),
                                Vector2.new(x + w, y + h), Vector2.new(x, y + h),
                            }
                            local visColor = ESP_GREEN
                            if S.visCheck then
                                visFilter[1], visFilter[2] = char, lp.Character
                                visParams.FilterDescendantsInstances = visFilter
                                SA.internal = true
                                local okR, hit = pcall(Workspace.Raycast, Workspace, c.CFrame.Position, hrp.Position - c.CFrame.Position, visParams)
                                SA.internal = false
                                if not okR or hit then visColor = ESP_RED end
                            end
                            for i = 1, 4 do
                                local a = corners[i]
                                local b2 = corners[(i % 4) + 1]
                                bl[i].From = a
                                bl[i].To = b2
                                bl[i].Color = visColor
                                bl[i].Visible = true
                            end
                        else
                            for i = 1, 4 do bl[i].Visible = false end
                        end
                    end
                elseif boxDrawings[plr] then
                    for _, line in ipairs(boxDrawings[plr]) do line.Visible = false end
                end
            else
                removeESP(plr)
            end
        end
    end
end

connect(Players.PlayerRemoving, function(plr)
    removeESP(plr)
    restoreHitboxOne(plr)
end)

-- 传送辅助
function getTargetPlayer()
    if S.target then return Players:FindFirstChild(S.target) end
end
function getTargetRoot()
    local p = getTargetPlayer()
    local c = p and p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
-- 传送偏移: 相对目标朝向, 右 / 上 / 后 为正
function SA.tpOffset()
    return CFrame.new(S.tpRight, S.tpUp, S.tpBack)
end
function tpOnce()
    local r, t = getRoot(), getTargetRoot()
    if r and t then
        r.CFrame = t.CFrame * SA.tpOffset()
        r.AssemblyLinearVelocity = Vector3.zero
    else
        notify("未找到目标玩家或其角色")
    end
end
function applySpectate()
    local c = cam()
    if S.spectate then
        local p = getTargetPlayer()
        local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then c.CameraSubject = h end
    else
        local h = getHum()
        if h then c.CameraSubject = h end
    end
end
orbitAngle = 0

-- 防挂机
connect(lp.Idled, function()
    if S.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

-- 自动点击
local lastAutoClick = 0
function updateAutoClick()
    if not S.autoClick then return end
    local interval = 1 / math.max(1, S.autoClickCps)
    if os.clock() - lastAutoClick < interval then return end
    pcall(function() VirtualUser:ClickButton1(cam().ViewportSize / 2) end)
    lastAutoClick = os.clock()
end

-- 低 Ping 服务器
local searching = false
function joinLowPing()
    if searching then return end
    searching = true
    notify("正在搜索低Ping服务器...")
    task.spawn(function()
        local placeId = tostring(game.PlaceId)
        local servers, cursor = {}, ""
        for _ = 1, 4 do
            local url = "https://games.roblox.com/v1/games/" .. placeId
                .. "/servers/Public?sortOrder=Asc&limit=100"
                .. (cursor ~= "" and ("&cursor=" .. cursor) or "")
            local ok, body = pcall(function() return game:HttpGet(url) end)
            if not ok then break end
            local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
            if not ok2 or type(data) ~= "table" or not data.data then break end
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                    table.insert(servers, s)
                end
            end
            if data.nextPageCursor then cursor = data.nextPageCursor else break end
            task.wait(0.4)
        end
        if #servers == 0 then
            notify("没有找到可用服务器(可能被限流,稍后再试)")
            searching = false
            return
        end
        table.sort(servers, function(a, b) return (a.ping or 9999) < (b.ping or 9999) end)
        local pick = servers[math.random(1, math.min(3, #servers))]
        notify("正在加入服务器 (Ping: " .. tostring(pick.ping or "未知") .. "ms)")
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, lp) end)
        task.wait(5)
        searching = false
    end)
end
-- ============================================================
end

do
-- 第 8 部分：Fling 防护 / 自动挣脱 / 额外防护
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
function getStruggleEvent()
    local ce = ReplicatedStorage:FindFirstChild("CharacterEvents")
    return ce and ce:FindFirstChild("Struggle")
end
origZoom = lp.CameraMaxZoomDistance

function setRagdollStates(hum, enabled)
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
    end)
end
function restoreFtap()
    local h = getHum()
    if h then setRagdollStates(h, true) end
    ragChar = nil
    pcall(function() lp.CameraMaxZoomDistance = origZoom end)
end

-- 防甩飞(1): 记录并还原其他玩家 CanCollide
local flingOrig = setmetatable({}, { __mode = "k" })
connect(RunService.Stepped, function()
    if S.antiFling then
        for _, plr in ipairs(SA.players()) do
            if plr ~= lp then
                local c = plr.Character
                if c then
                    for _, part in ipairs(c:GetChildren()) do
                        if part:IsA("BasePart") then
                            if flingOrig[part] == nil then flingOrig[part] = part.CanCollide end
                            if part.CanCollide then part.CanCollide = false end
                        end
                    end
                end
            end
        end
    else
        for part, orig in pairs(flingOrig) do
            if part.Parent then part.CanCollide = orig end
            flingOrig[part] = nil
        end
    end
end)

-- Anti TP
local lastRootPos = nil
local antiTpGrace = 0
local function updateAntiTp()
    if not S.antiTp then lastRootPos = nil return end
    local root = getRoot()
    if not root then return end
    if os.clock() < antiTpGrace then lastRootPos = root.Position return end
    if lastRootPos then
        local d = (root.Position - lastRootPos).Magnitude
        if d > 120 then
            root.CFrame = CFrame.new(lastRootPos + Vector3.new(0, 2, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
    lastRootPos = root.Position
end
genv.OmegaAntiTpGrace = function(sec)
    antiTpGrace = os.clock() + (sec or 2)
end

-- 反冻结 / 反击退
local lastWalkSpeed = nil
local lastVelMag = 0
local function updateAntiFreezeKnock()
    local hum, root = getHum(), getRoot()
    if not hum or not root then return end
    if S.antiFreeze then
        if not S.speedOn and not S.sprintActive and hum.WalkSpeed < 1 and (lastWalkSpeed or 16) > 1 then
            hum.WalkSpeed = lastWalkSpeed or 16
        end
        lastWalkSpeed = hum.WalkSpeed
    end
    if S.antiKnock then
        local v = root.AssemblyLinearVelocity
        local hm = Vector3.new(v.X, 0, v.Z).Magnitude
        if lastVelMag > 60 and hm < lastVelMag * 0.3 then
            local back = Vector3.new(v.X, 0, v.Z).Unit * lastVelMag
            root.AssemblyLinearVelocity = Vector3.new(back.X, v.Y, back.Z)
        end
        lastVelMag = math.max(hm, lastVelMag * 0.9)
    end
end

-- 防护 Heartbeat（防甩飞2 / 布娃娃 / 虚空 / 视角 / AntiTp / AntiFreeze）
connect(RunService.Heartbeat, function()
    local char = lp.Character
    local hum = getHum()
    local root = getRoot()
    if not (char and hum and root) then return end

    if S.antiFling and not S.fly then
        local limit = S.antiFlingMax
        if S.speedOn then limit = math.max(limit, S.speed + 20) end
        if S.velSpeedOn then limit = math.max(limit, S.velSpeed + 20) end
        local v = root.AssemblyLinearVelocity
        local horiz = Vector3.new(v.X, 0, v.Z).Magnitude
        if horiz > limit or v.Y > limit then
            root.AssemblyLinearVelocity = Vector3.new(0, math.min(v.Y, 0), 0)
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    if S.antiRagdoll then
        if ragChar ~= char then
            ragChar = char
            setRagdollStates(hum, false)
        end
        if hum.PlatformStand and not S.fly then hum.PlatformStand = false end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    if S.antiVoid then
        if hum.FloorMaterial ~= Enum.Material.Air and hum.Health > 0 then lastSafeCF = root.CFrame end
        if lastSafeCF and root.Position.Y < Workspace.FallenPartsDestroyHeight + 40 then
            root.CFrame = lastSafeCF + Vector3.new(0, 5, 0)
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end

    if S.zoomOn then lp.CameraMaxZoomDistance = S.zoom end

    updateAntiTp()
    updateAntiFreezeKnock()
end)

-- 自动挣脱
local struggleRemote
lastFind, lastStruggle = 0, 0
function findStruggleRemote()
    if struggleRemote and struggleRemote.Parent then return struggleRemote end
    struggleRemote = nil
    if os.clock() - lastFind < 60 then return nil end -- 没找到时一分钟才重新扫一次 (扫描整个 ReplicatedStorage 很耗时)
    lastFind = os.clock()
    for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
        if inst:IsA("RemoteEvent") and string.find(string.lower(inst.Name), "struggle", 1, true) then
            struggleRemote = inst
            break
        end
    end
    return struggleRemote
end
local function isBeingHeld()
    local held = lp:FindFirstChild("IsHeld")
    if held and held:IsA("BoolValue") then return held.Value == true end
    local hum, root = getHum(), getRoot()
    if not hum or not root or hum.Sit then return false end
    local st = hum:GetState()
    if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown or hum.PlatformStand then
        return true
    end
    if isnetworkowner then
        local ok, mine = pcall(isnetworkowner, root)
        if ok and mine == false then return true end
    end
    return false
end
local function doStruggle()
    local ev = getStruggleEvent()
    if ev then
        pcall(function() ev:FireServer(lp) end)
        local root = getRoot()
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        return
    end
    local r = findStruggleRemote()
    if r then pcall(function() r:FireServer() end) end
    local hum = getHum()
    if hum then
        hum.Jump = true
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end
connect(RunService.Heartbeat, function()
    if not S.autoStruggle or S.fly then return end
    local now = os.clock()
    local interval = lp:FindFirstChild("IsHeld") and 0 or 0.2
    if now - lastStruggle < interval then return end
    if isBeingHeld() then
        lastStruggle = now
        doStruggle()
    end
end)

function listGrabRemotes()
    local keys = { "struggle", "grab", "ragdoll", "escape", "release", "free" }
    local found = {}
    for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
        if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
            local n = string.lower(inst.Name)
            for _, k in ipairs(keys) do
                if string.find(n, k, 1, true) then found[#found + 1] = inst:GetFullName() break end
            end
        end
    end
    if #found == 0 then
        notify("没有找到相关事件 (这个游戏可能不在 ReplicatedStorage 里放这类事件)", 6)
        return
    end
    local show = {}
    for i = 1, math.min(#found, 12) do show[i] = found[i] end
    local msg = table.concat(show, "\n")
    print("[Omega hub] 相关事件:\n" .. msg)
    notify(msg, 10)
end
-- ============================================================
end

do
-- 第 9 部分：自然灾害 / 视觉环境
-- ============================================================
local refugeFolder, refugePos, returnCF
local inRefuge = false
nextRefuge = 0
origGravity = Workspace.Gravity

local function buildRefuge(center)
    if refugeFolder then refugeFolder:Destroy() end
    refugeFolder = Instance.new("Folder")
    refugeFolder.Name = "OmegaRefuge"
    local W = 60
    local function mk(size, cf, transparency)
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = true
        part.CanTouch = false
        part.CastShadow = false
        part.Material = Enum.Material.Glass
        part.Color = Color3.fromRGB(90, 170, 255)
        part.Transparency = transparency
        part.Size = size
        part.CFrame = cf
        part.Parent = refugeFolder
    end
    mk(Vector3.new(W, 2, W), CFrame.new(center), 0.35)
    for _, d in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
        mk(Vector3.new(d.X ~= 0 and 1 or W, 24, d.Z ~= 0 and 1 or W),
            CFrame.new(center + d * (W / 2) + Vector3.new(0, 12, 0)), 1)
    end
    refugeFolder.Parent = Workspace
    refugePos = center
end

function goRefuge()
    local root, hum = getRoot(), getHum()
    if not root or not hum or hum.Health <= 0 then return end
    if inRefuge and refugeFolder and refugeFolder.Parent then
        notify("你已经在避难所里了")
        return
    end
    inRefuge = false
    returnCF = root.CFrame
    local p = root.Position
    buildRefuge(Vector3.new(p.X, p.Y + S.refugeH, p.Z))
    root.CFrame = CFrame.new(refugePos + Vector3.new(0, 4, 0))
    root.AssemblyLinearVelocity = Vector3.zero
    inRefuge = true
    if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(3) end
end
function leaveRefuge()
    if S.autoRefuge then
        notify("请先关闭「自动避难」再返回")
        return
    end
    local root = getRoot()
    if root and returnCF then
        root.CFrame = returnCF
        root.AssemblyLinearVelocity = Vector3.zero
    end
    inRefuge = false
    if refugeFolder then refugeFolder:Destroy() refugeFolder = nil end
    if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(2) end
end

function teleportHighest()
    local root = getRoot()
    if not root then return end
    local origin = root.Position
    local ignore = {}
    for _, plr in ipairs(SA.players()) do
        if plr.Character then table.insert(ignore, plr.Character) end
    end
    if refugeFolder then table.insert(ignore, refugeFolder) end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local R, step = S.highRadius, 12
    local best, bestY = nil, -math.huge
    local topY = origin.Y + 2000
    for dx = -R, R, step do
        for dz = -R, R, step do
            if dx * dx + dz * dz <= R * R then
                SA.internal = true
                local okR, res = pcall(function()
                    return Workspace:Raycast(
                        Vector3.new(origin.X + dx, topY, origin.Z + dz),
                        Vector3.new(0, -4000, 0), params)
                end)
                SA.internal = false
                if okR and res and res.Normal.Y > 0.7 and res.Position.Y > bestY then
                    best, bestY = res.Position, res.Position.Y
                end
            end
        end
    end
    if best then
        root.CFrame = CFrame.new(best + Vector3.new(0, 4, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(2) end
        notify(string.format("已传送到附近最高点 (高度 %d)", math.floor(best.Y)))
    else
        notify("附近没有找到可站立的位置, 试试加大搜索范围")
    end
end

function restoreNds()
    if refugeFolder then refugeFolder:Destroy() refugeFolder = nil end
    inRefuge = false
    pcall(function() Workspace.Gravity = origGravity end)
end

connect(RunService.Heartbeat, function()
    local hum = getHum()
    local root = getRoot()
    if not (hum and root) then return end
    if inRefuge and refugePos and (root.Position - refugePos).Magnitude > 80 then
        inRefuge = false
        nextRefuge = os.clock() + S.refugeDelay
    end
    if S.autoRefuge and not inRefuge and hum.Health > 0 and os.clock() >= nextRefuge then
        goRefuge()
    end
    if S.noFall and not S.fly then
        local v = root.AssemblyLinearVelocity
        if v.Y < -S.noFallCap then
            root.AssemblyLinearVelocity = Vector3.new(v.X, -S.noFallCap, v.Z)
        end
    end
    if S.gravOn then Workspace.Gravity = S.grav end
end)

-- ============================================================
-- 视觉环境
-- ============================================================
function applyFullbright()
    if S.fullbright then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = originals.ambient
        Lighting.OutdoorAmbient = originals.outdoor
        Lighting.Brightness = originals.brightness
    end
end
function applyNoFog()
    if S.noFog then
        Lighting.FogStart = 1e6
        Lighting.FogEnd = 1e6
    else
        Lighting.FogStart = originals.fogStart
        Lighting.FogEnd = originals.fogEnd
    end
end
function applyClock()
    if S.clockOn then
        Lighting.ClockTime = S.clockTime
    else
        Lighting.ClockTime = originals.clockTime
    end
end
local noShadowSaved = {}
function applyNoShadow()
    if S.noShadow then
        noShadowSaved = {}
        for _, inst in ipairs(Lighting:GetDescendants()) do
            if inst:IsA("Light") and inst.Shadows then
                noShadowSaved[inst] = true
                inst.Shadows = false
            end
        end
    else
        for inst in pairs(noShadowSaved) do
            if inst.Parent then inst.Shadows = true end
        end
        noShadowSaved = {}
    end
end
local particleSaved = {}
function applyNoParticle()
    if S.noParticle then
        particleSaved = {}
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst:IsA("ParticleEmitter") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
                if inst.Enabled then
                    particleSaved[inst] = true
                    inst.Enabled = false
                end
            end
        end
    else
        for inst in pairs(particleSaved) do
            if inst.Parent then inst.Enabled = true end
        end
        particleSaved = {}
    end
end
function applyBodyScale()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        if S.bodyScaleOn then
            if hum:FindFirstChild("BodyHeightScale") then
                hum.BodyHeightScale.Value = S.bodyScale
                hum.BodyWidthScale.Value = S.bodyScale
                hum.BodyDepthScale.Value = S.bodyScale
                hum.HeadScale.Value = S.bodyScale
            end
        else
            if hum:FindFirstChild("BodyHeightScale") then
                hum.BodyHeightScale.Value = 1
                hum.BodyWidthScale.Value = 1
                hum.BodyDepthScale.Value = 1
                hum.HeadScale.Value = 1
            end
        end
    end)
end
local hiddenNames = {}
function applyHideNames()
    if S.hideNames then
        for _, plr in ipairs(SA.players()) do
            if plr ~= lp then
                local head = plr.Character and plr.Character:FindFirstChild("Head")
                if head then
                    for _, g in ipairs(head:GetChildren()) do
                        if g:IsA("BillboardGui") and g.Enabled then
                            hiddenNames[g] = true
                            g.Enabled = false
                        end
                    end
                end
            end
        end
    else
        for g in pairs(hiddenNames) do
            if g.Parent then g.Enabled = true end
        end
        hiddenNames = {}
    end
end
function restoreVisualEnv()
    S.fullbright = false S.noFog = false S.noShadow = false
    S.noParticle = false S.clockOn = false S.bodyScaleOn = false S.hideNames = false
    applyFullbright() applyNoFog() applyNoShadow()
    applyNoParticle() applyClock() applyBodyScale() applyHideNames()
end
-- ============================================================
end

do
-- 第 10 部分：监狱人生 / 多路点 / 传送历史
-- ============================================================
PL_TELEPORTS = {
    { "监狱入口", CFrame.new(474.655701, 98.1900101, 2250.36841) },
    { "守卫室",   CFrame.new(798.664368, 99.9900055, 2264.11157) },
    { "罪犯基地", CFrame.new(-942.058838, 94.1287842, 2056.36914) },
    { "操场",     CFrame.new(767.570129, 97.9999466, 2461.25659) },
    { "牢房",     CFrame.new(916.622131, 99.9899902, 2465.79858) },
    { "食堂",     CFrame.new(960.83783, 99.9899597, 2340.33911) },
    { "主塔楼",   CFrame.new(823.287292, 130.039948, 2587.73975) },
    { "厨房",     CFrame.new(941.972778, 99.9899597, 2222.83716) },
    { "车库",     CFrame.new(614.918396, 98.2000275, 2512.02368) },
}
local function plRemote(name)
    local r = Workspace:FindFirstChild("Remote")
    return r and r:FindFirstChild(name)
end
local function giverFolder()
    local pi = Workspace:FindFirstChild("Prison_ITEMS")
    return pi and pi:FindFirstChild("giver")
end
function giverNames()
    local list = {}
    local g = giverFolder()
    if g then
        for _, it in ipairs(g:GetChildren()) do
            if it:FindFirstChild("ITEMPICKUP") then table.insert(list, it.Name) end
        end
        table.sort(list)
    end
    return list
end
local function hasTool(name)
    local bp = lp:FindFirstChildOfClass("Backpack")
    return (bp and bp:FindFirstChild(name)) or (lp.Character and lp.Character:FindFirstChild(name)) or nil
end
local function toolCount()
    local n = 0
    for _, container in ipairs(getContainers()) do
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") then n += 1 end
        end
    end
    return n
end
local function callHandler(handler, pickup)
    if handler:IsA("RemoteFunction") then
        return pcall(function() return handler:InvokeServer(pickup) end)
    end
    return pcall(function() handler:FireServer(pickup) end)
end
function giveItem(name)
    if hasTool(name) then return true end
    local g = giverFolder()
    local it = g and g:FindFirstChild(name)
    local pickup = it and it:FindFirstChild("ITEMPICKUP")
    local handler = plRemote("ItemHandler")
    if not (pickup and handler) then return false end
    local before = toolCount()
    callHandler(handler, pickup)
    task.wait(0.15)
    if hasTool(name) or toolCount() > before then return true end
    local root = getRoot()
    local pos = pickup:IsA("BasePart") and pickup.Position
    if not (root and pos) then return false end
    local back = root.CFrame
    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    task.wait(0.25)
    callHandler(handler, pickup)
    task.wait(0.2)
    root.CFrame = back
    return (hasTool(name) ~= nil) or toolCount() > before
end
function plTeleport(name)
    local root = getRoot()
    if not root then return end
    for _, t in ipairs(PL_TELEPORTS) do
        if t[1] == name then
            root.CFrame = t[2] + Vector3.new(0, 3, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(2) end
            return
        end
    end
end

local gunOrig = setmetatable({}, { __mode = "k" })
local function getGunModules()
    local list = {}
    for _, container in ipairs(getContainers()) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local ms = tool:FindFirstChild("GunStates")
                if ms and ms:IsA("ModuleScript") then
                    local ok, mod = pcall(require, ms)
                    if ok and type(mod) == "table" then list[#list + 1] = mod end
                end
            end
        end
    end
    return list
end
local function setField(mod, key, value, kind)
    if type(mod[key]) ~= (kind or "number") then return false end
    local o = gunOrig[mod]
    if not o then o = {} gunOrig[mod] = o end
    if o[key] == nil then o[key] = mod[key] end
    mod[key] = value
    return true
end
function applyGuns()
    local mods = getGunModules()
    local changed = 0
    for _, mod in ipairs(mods) do
        if S.gunInfAmmo then
            if setField(mod, "MaxAmmo", 9999) then changed += 1 end
            if setField(mod, "StoredAmmo", 9999) then changed += 1 end
            if type(mod.CurrentAmmo) == "number" and mod.CurrentAmmo < 9999 then mod.CurrentAmmo = 9999 end
        end
        if S.gunFast and type(mod.FireRate) == "number" then
            local base = (gunOrig[mod] and gunOrig[mod].FireRate) or mod.FireRate
            if setField(mod, "FireRate", math.min(base, S.gunRate)) then changed += 1 end
        end
        if S.gunAuto and setField(mod, "AutoFire", true, "boolean") then changed += 1 end
        if S.gunNoSpread then
            for _, key in ipairs({ "Spread", "SpreadRadius", "Recoil" }) do
                if setField(mod, key, 0) then changed += 1 end
            end
        end
        if S.gunReload and setField(mod, "ReloadTime", 0.05) then changed += 1 end
        if S.gunRange and setField(mod, "Range", 5000) then changed += 1 end
    end
    return #mods, changed
end
function restoreGuns()
    for mod, o in pairs(gunOrig) do
        for k, v in pairs(o) do mod[k] = v end
        if type(mod.CurrentAmmo) == "number" and type(mod.MaxAmmo) == "number" and mod.CurrentAmmo > mod.MaxAmmo then
            mod.CurrentAmmo = mod.MaxAmmo
        end
        gunOrig[mod] = nil
    end
end
function plDiagnose()
    local lines = {}
    local pi = Workspace:FindFirstChild("Prison_ITEMS")
    lines[#lines + 1] = "Prison_ITEMS: " .. (pi and "有" or "没有")
    lines[#lines + 1] = "giver 物品数: " .. #giverNames()
    local h = plRemote("ItemHandler")
    lines[#lines + 1] = "ItemHandler: " .. (h and h.ClassName or "没有")
    local lc = plRemote("loadchar")
    lines[#lines + 1] = "loadchar: " .. (lc and lc.ClassName or "没有")
    local guns = 0
    for _, container in ipairs(getContainers()) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and guns < 5 then
                guns += 1
                local ms = tool:FindFirstChild("GunStates")
                if not ms then
                    lines[#lines + 1] = tool.Name .. ": 没有 GunStates"
                else
                    local ok, mod = pcall(require, ms)
                    if ok and type(mod) == "table" then
                        local keys = {}
                        for k, v in pairs(mod) do
                            if type(v) == "number" or type(v) == "boolean" then keys[#keys + 1] = tostring(k) end
                        end
                        table.sort(keys)
                        lines[#lines + 1] = tool.Name .. ": " .. table.concat(keys, ",")
                    else
                        lines[#lines + 1] = tool.Name .. ": require 失败"
                    end
                end
            end
        end
    end
    if guns == 0 then lines[#lines + 1] = "背包里没有任何道具 (先领取一把枪)" end
    local msg = table.concat(lines, "\n")
    print("[Omega hub] 监狱人生诊断:\n" .. msg)
    notify(msg, 15)
end
local gunTimer = 0
connect(RunService.Heartbeat, function(dt)
    gunTimer += dt
    if gunTimer < 0.4 then return end
    gunTimer = 0
    if S.gunMod then pcall(applyGuns) end
end)

-- 后坐力补偿: 记录开火瞬间相机朝向, 之后把相机拉回
local recoilCF = nil
function updateRecoilComp(dt)
    if not S.recoilComp then recoilCF = nil return end
    local c = cam()
    local mouseDown = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if mouseDown then
        if not recoilCF then recoilCF = c.CFrame end
    else
        recoilCF = nil
    end
    if recoilCF then
        c.CFrame = c.CFrame:Lerp(recoilCF, math.clamp(8 * dt, 0, 1))
    end
end

-- 死亡重生
local deathCF
local function hookDeath(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.Died:Connect(function()
        local r = char:FindFirstChild("HumanoidRootPart")
        if r then deathCF = r.CFrame end
        if S.fastRespawn then
            local lc = plRemote("loadchar")
            if lc then
                task.spawn(function()
                    task.wait(0.2)
                    pcall(function() lc:InvokeServer("LocalPlayer") end)
                end)
            end
        end
    end)
end
connect(lp.CharacterAdded, function(char)
    task.spawn(hookDeath, char)
    task.spawn(function()
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if not root then return end
        task.wait(1)
        if S.respawnHere and deathCF then
            root.CFrame = deathCF
            deathCF = nil
        end
        if S.autoGive then
            for _, n in ipairs({ "Remington 870", "AK-47", "M9" }) do
                giveItem(n)
                task.wait(0.2)
            end
        end
        applyBodyScale()
        applyHideNames()
    end)
end)
if lp.Character then task.spawn(hookDeath, lp.Character) end

-- 多路点 + 传送历史
waypoints = {}
local tpHistory = {}
local function pushHistory()
    local r = getRoot()
    if not r then return end
    table.insert(tpHistory, r.CFrame)
    if #tpHistory > 10 then table.remove(tpHistory, 1) end
    if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(2) end
end
function tpToWaypoint(name)
    local cf = waypoints[name]
    local r = getRoot()
    if cf and r then
        pushHistory()
        r.CFrame = cf
        r.AssemblyLinearVelocity = Vector3.zero
    end
end
function undoTeleport()
    local r = getRoot()
    if r and #tpHistory > 0 then
        r.CFrame = table.remove(tpHistory)
        r.AssemblyLinearVelocity = Vector3.zero
        if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(2) end
    else
        notify("没有可撤销的传送")
    end
end
function saveWaypoint(name)
    local r = getRoot()
    if r and name and name ~= "" then
        waypoints[name] = r.CFrame
        notify("已保存路点: " .. name)
    end
end
-- ============================================================
end

do
-- 第 11 部分：主循环 / 配置 / 聊天命令 / 热键
-- ============================================================
local espTimer = 0
local espTicks = 0
local antiTpWait = 0
connect(RunService.Heartbeat, function(dt)
    local hum = getHum()
    if hum then
        -- 优先级：冲刺 > 速度
        local targetSpeed = nil
        if S.sprint and S.sprintActive then targetSpeed = S.sprintSpeed
        elseif S.speedOn then targetSpeed = S.speed end
        if targetSpeed then
            local want = S.speedSmooth and applySmoothSpeed(targetSpeed) or targetSpeed
            if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
        else
            smoothSpeed = 16
        end
        if S.jumpOn then
            if not hum.UseJumpPower then hum.UseJumpPower = true end
            if hum.JumpPower ~= S.jump then hum.JumpPower = S.jump end
        end
    end

    if S.fly then updateFly() end
    if S.autoJump then updateAutoJump() end
    if S.bhop then updateBhop(dt) end
    updateCrouch()

    -- 加速模式
    if not S.fly and hum and (S.cfSpeedOn or S.trSpeedOn or S.velSpeedOn) then
        local root = getRoot()
        local md = hum.MoveDirection
        if root and md.Magnitude > 0 then
            if S.cfSpeedOn then root.CFrame = root.CFrame + md * S.cfSpeed * dt end
            if S.trSpeedOn then lp.Character:TranslateBy(md * S.trSpeed * dt) end
            if S.velSpeedOn then
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(md.X * S.velSpeed, v.Y, md.Z * S.velSpeed)
            end
        end
    end

    updateHitbox()
    updateTriggerBot()
    updateAutoFire()
    updateAutoClick()
    updateRecoilComp(dt)

    espTimer += dt
    if espTimer >= 0.1 then
        espTimer = 0
        updateESP()
        espTicks = espTicks + 1
        if S.hideNames and espTicks % 5 == 0 then applyHideNames() end
    end

    if S.tpOrbit or S.tpLoop then
        local r, t = getRoot(), getTargetRoot()
        if r and t then
            if S.tpOrbit then
                orbitAngle += S.orbitSpeed * dt
                local center = t.Position
                local pos = center + Vector3.new(
                    math.cos(orbitAngle) * S.orbitR, S.orbitH, math.sin(orbitAngle) * S.orbitR)
                r.CFrame = CFrame.lookAt(pos, center)
            else
                r.CFrame = t.CFrame * SA.tpOffset()
            end
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(1) end
        end
    end

    if S.spectate then
        local p = getTargetPlayer()
        local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h and cam().CameraSubject ~= h then cam().CameraSubject = h end
    end
end)

-- ============================================================
-- 配置保存 / 加载
-- ============================================================
local CONFIG_PATH = "OmegaHub_config.json"
local function serializeS()
    local out = {}
    for k, v in pairs(S) do
        local t = type(v)
        if t == "boolean" or t == "number" or t == "string" then
            out[k] = v
        end
    end
    return HttpService:JSONEncode(out)
end
function loadConfig()
    if not (readfile and writefile) then notify("当前执行器不支持文件读写", 6) return end
    local ok, data = pcall(function() return readfile(CONFIG_PATH) end)
    if not ok or not data then notify("没有找到配置文件", 5) return end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if not ok2 or type(decoded) ~= "table" then notify("配置文件损坏", 5) return end
    for k, v in pairs(decoded) do
        if S[k] ~= nil then S[k] = v end
    end
    notify("配置已加载 (部分开关需重新点一次生效)", 6)
end
function saveConfig()
    if not (writefile) then notify("当前执行器不支持文件写入", 6) return end
    local ok, data = pcall(serializeS)
    if not ok then notify("保存失败", 5) return end
    local ok2 = pcall(function() writefile(CONFIG_PATH, data) end)
    if ok2 then notify("配置已保存到 " .. CONFIG_PATH, 5) else notify("写入失败", 5) end
end

-- ============================================================
-- 聊天命令
-- ============================================================
local function handleCommand(msg)
    local cmd, arg = msg:match("^/(%w+)%s*(.*)$")
    if not cmd then return false end
    cmd = cmd:lower()
    if cmd == "fly" then S.fly = not S.fly
        if S.fly then startFly() else stopFly() end
        notify("飞行: " .. tostring(S.fly))
    elseif cmd == "speed" then
        local n = tonumber(arg)
        if n then S.speed = n S.speedOn = true notify("速度: " .. n) end
    elseif cmd == "tp" then
        if arg and arg ~= "" then
            S.target = arg
            tpOnce()
        end
    elseif cmd == "esp" then
        S.esp = not S.esp
        notify("ESP: " .. tostring(S.esp))
    elseif cmd == "aim" then
        S.aim = not S.aim
        notify("自瞄: " .. tostring(S.aim))
    elseif cmd == "silent" then
        S.silent = not S.silent
        if S.silent then installHooks() end
        notify("子弹追踪: " .. tostring(S.silent))
    elseif cmd == "goto" then
        if arg and arg ~= "" then
            local cf = waypoints[arg]
            if cf then tpToWaypoint(arg) notify("传送到路点: " .. arg) else notify("路点不存在") end
        end
    elseif cmd == "help" then
        notify("/fly /speed N /tp 名 /esp /aim /silent /goto 路点", 10)
    else
        return false
    end
    return true
end
connect(lp.Chatted, function(msg)
    if type(msg) == "string" and msg:sub(1,1) == "/" then
        pcall(handleCommand, msg)
    end
end)

-- ============================================================
-- 热键系统
-- ============================================================
local keybinds = {}
local function bindKey(key, fn) keybinds[key] = fn end
bindKey(Enum.KeyCode.X, function()
    S.fly = not S.fly
    if S.fly then startFly() else stopFly() end
    notify("飞行: " .. tostring(S.fly))
end)
bindKey(Enum.KeyCode.C, function()
    S.aim = not S.aim
    notify("自瞄: " .. tostring(S.aim))
end)
bindKey(Enum.KeyCode.V, function()
    S.esp = not S.esp
    if not S.esp then for p in pairs(espData) do removeESP(p) end end
    notify("ESP: " .. tostring(S.esp))
end)
bindKey(Enum.KeyCode.Z, function()
    S.silent = not S.silent
    if S.silent then installHooks() end
    notify("子弹追踪: " .. tostring(S.silent))
end)
bindKey(Enum.KeyCode.F, function()
    tpOnce()
end)
connect(UIS.InputBegan, function(input, gp)
    if gp then return end
    local fn = keybinds[input.KeyCode]
    if fn then pcall(fn) end
end)
-- ============================================================
end

do
-- 第 12 部分：UI（窗口 / 移动 / 视觉 / 战斗 / 传送 / Fling）
-- ============================================================
Window = WindUI:CreateWindow({
    Title = "Omega hub",
    Icon = "zap",
    Author = "Omega hub · Delta",
    Folder = "OmegaHub",
    Size = UDim2.fromOffset(560, 360),
    Theme = "Dark",
    Transparent = true,
    SideBarWidth = 140,
})
pcall(function()
    Window:EditOpenButton({
        Title = "Omega hub",
        Icon = "zap",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        Draggable = true,
    })
end)
pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)

function addToggle(tab, title, key, fn)
    tab:Toggle({
        Title = title, Value = S[key], Default = S[key],
        Callback = function(v)
            S[key] = v
            if fn then
                local ok, err = pcall(fn, v)
                if not ok then reportError("开关「" .. title .. "」", err) end
            end
        end,
    })
end
function addSlider(tab, title, key, min, max, step, fn)
    tab:Slider({
        Title = title, Step = step or 1,
        Value = { Min = min, Max = max, Default = S[key] },
        Callback = function(v)
            S[key] = v
            if fn then
                local ok, err = pcall(fn, v)
                if not ok then reportError("滑条「" .. title .. "」", err) end
            end
        end,
    })
end
function safeCb(name, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then reportError("按钮「" .. name .. "」", err) end
    end
end

---------------- 移动 ----------------
local TabMove = Window:Tab({ Title = "移动", Icon = "move" })
TabMove:Section({ Title = "飞行" })
addToggle(TabMove, "飞行", "fly", function(v) if v then startFly() else stopFly() end end)
addSlider(TabMove, "飞行速度", "flySpeed", 10, 300, 1)
TabMove:Section({ Title = "基础" })
addToggle(TabMove, "穿墙", "noclip")
addToggle(TabMove, "修改速度", "speedOn")
addSlider(TabMove, "速度", "speed", 16, 300, 1)
addToggle(TabMove, "速度平滑 (防检测)", "speedSmooth")
addSlider(TabMove, "平滑速率", "speedSmoothRate", 1, 20, 0.5)
addToggle(TabMove, "冲刺 (按住 Shift)", "sprint")
addSlider(TabMove, "冲刺速度", "sprintSpeed", 16, 300, 1)
addToggle(TabMove, "蹲下", "crouch")
TabMove:Section({ Title = "跳跃" })
addToggle(TabMove, "修改跳跃", "jumpOn")
addSlider(TabMove, "跳跃力度", "jump", 50, 500, 1)
addToggle(TabMove, "无限跳", "infJump")
addToggle(TabMove, "Auto Jump (落地自动跳)", "autoJump")
addToggle(TabMove, "Bunny Hop (落地保留速度)", "bhop")
addSlider(TabMove, "Bhop 倍率", "bhopBoost", 1, 2, 0.05)
TabMove:Section({ Title = "加速模式" })
addToggle(TabMove, "CFrame 加速", "cfSpeedOn")
addSlider(TabMove, "CFrame 速度", "cfSpeed", 1, 300, 1)
addToggle(TabMove, "Translate 加速", "trSpeedOn")
addSlider(TabMove, "Translate 速度", "trSpeed", 1, 300, 1)
addToggle(TabMove, "Velocity 加速", "velSpeedOn")
addSlider(TabMove, "Velocity 速度", "velSpeed", 1, 300, 1)

---------------- 视觉 ----------------
local TabVisual = Window:Tab({ Title = "视觉", Icon = "eye" })
TabVisual:Section({ Title = "FOV" })
addToggle(TabVisual, "修改 FOV", "fovOn", function(v)
    if v then originals.fov = cam().FieldOfView else cam().FieldOfView = originals.fov end
end)
addSlider(TabVisual, "FOV 大小", "fov", 30, 120, 1)
TabVisual:Section({ Title = "环境" })
addToggle(TabVisual, "全亮度", "fullbright", function() applyFullbright() end)
addToggle(TabVisual, "去雾", "noFog", function() applyNoFog() end)
addToggle(TabVisual, "去阴影", "noShadow", function() applyNoShadow() end)
addToggle(TabVisual, "去粒子", "noParticle", function() applyNoParticle() end)
addToggle(TabVisual, "修改时间", "clockOn", function() applyClock() end)
addSlider(TabVisual, "时间 (0-24)", "clockTime", 0, 24, 0.5, function() if S.clockOn then applyClock() end end)
addToggle(TabVisual, "修改角色大小", "bodyScaleOn", function() applyBodyScale() end)
addSlider(TabVisual, "角色大小倍率", "bodyScale", 0.5, 3, 0.05, function() if S.bodyScaleOn then applyBodyScale() end end)
addToggle(TabVisual, "隐藏其他玩家名字", "hideNames", function() applyHideNames() end)
TabVisual:Section({ Title = "镜头 / 显示" })
addToggle(TabVisual, "手机端灵敏度", "touchSens")
addSlider(TabVisual, "水平灵敏度", "touchSensX", 0.2, 5, 0.1)
addSlider(TabVisual, "垂直灵敏度", "touchSensY", 0.2, 5, 0.1)
addToggle(TabVisual, "自由视角", "freecam")
addSlider(TabVisual, "自由视角速度", "freecamSpeed", 10, 200, 1)
addToggle(TabVisual, "FPS / Ping 显示", "fpsShow")
TabVisual:Section({ Title = "ESP" })
addToggle(TabVisual, "开启 ESP", "esp", function(v)
    if not v then for plr in pairs(espData) do removeESP(plr) end end
end)
addToggle(TabVisual, "显示名字", "espName")
addToggle(TabVisual, "显示距离 / 血量", "espInfo")
addToggle(TabVisual, "高亮轮廓", "espHL")
addToggle(TabVisual, "使用队伍颜色", "espTeam")
addToggle(TabVisual, "NPC ESP", "espNpc", function(v)
    if not v and SA.clearNpcEsp then SA.clearNpcEsp() end
end)
addToggle(TabVisual, "NPC 显示名字", "espNpcName")
addToggle(TabVisual, "NPC 显示距离 / 血量", "espNpcInfo")
addSlider(TabVisual, "NPC ESP 最远距离", "espNpcMax", 100, 5000, 50)
addToggle(TabVisual, "方框", "boxEsp")
addToggle(TabVisual, "血条", "healthBar")
addToggle(TabVisual, "可见性标记 (绿/红方框)", "visCheck")

---------------- 战斗 ----------------
local TabCombat = Window:Tab({ Title = "战斗", Icon = "crosshair" })
TabCombat:Section({ Title = "自瞄" })
addToggle(TabCombat, "开启自瞄", "aim")
local partMap = { ["头部"] = "Head", ["躯干"] = "HumanoidRootPart" }
TabCombat:Dropdown({
    Title = "瞄准部位", Values = { "头部", "躯干" }, Value = "头部",
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.aimPart = partMap[v] or "Head"
    end,
})
addSlider(TabCombat, "自瞄范围", "aimFov", 30, 500, 1)
addSlider(TabCombat, "平滑度", "aimSmooth", 1, 20, 1)
addToggle(TabCombat, "显示 FOV 圈", "aimShowFov")
addToggle(TabCombat, "忽略队友", "aimTeam")
addToggle(TabCombat, "自瞄也锁 NPC", "aimNpc")
addToggle(TabCombat, "墙体检测", "aimWall")
addToggle(TabCombat, "仅按住右键", "aimHold")
TabCombat:Section({ Title = "TriggerBot / 自动开火" })
addToggle(TabCombat, "TriggerBot (准星有敌人自动开火)", "triggerBot")
addSlider(TabCombat, "TriggerBot 范围", "triggerFov", 10, 200, 1)
addSlider(TabCombat, "TriggerBot 延迟", "triggerDelay", 0.01, 0.5, 0.01)
addToggle(TabCombat, "自动开火 (按住左键连发)", "autoFire")
addSlider(TabCombat, "开火间隔", "autoFireRate", 0.02, 0.5, 0.01)
TabCombat:Section({ Title = "子弹追踪 (Silent Aim)" })
addToggle(TabCombat, "开启子弹追踪", "silent", function(v)
    if v and not installHooks() then
        notify("当前执行器不支持 hookmetamethod")
    end
end)
local silentPartMap = { ["头部"] = "Head", ["躯干"] = "HumanoidRootPart", ["随机"] = "Random" }
TabCombat:Dropdown({
    Title = "命中部位", Values = { "头部", "躯干", "随机" }, Value = "头部",
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.silentPart = silentPartMap[v] or "Head"
    end,
})
addSlider(TabCombat, "追踪范围", "silentFov", 30, 500, 1)
addSlider(TabCombat, "命中率 (%)", "silentChance", 1, 100, 1)
addSlider(TabCombat, "预判", "silentPredict", 0, 0.3, 0.01)
addToggle(TabCombat, "显示追踪圈", "silentShowFov")
addToggle(TabCombat, "忽略队友", "silentTeam")
addToggle(TabCombat, "锁定 NPC (子弹追踪也追 NPC)", "silentNpc")
addToggle(TabCombat, "只锁 NPC (不追玩家)", "silentNpcOnly")

-- 指定玩家锁定
local function lockNames()
    local t = {}
    for _, p in ipairs(SA.players()) do
        if p ~= lp then t[#t + 1] = p.Name end
    end
    table.sort(t)
    if #t == 0 then t = { "(暂无其他玩家)" } end
    return t
end
local lockList = lockNames()
S.silentLockName = Players:FindFirstChild(lockList[1]) and lockList[1] or nil
addToggle(TabCombat, "只锁定指定玩家", "silentLock", function(v)
    if v and not S.silentLockName then notify("请先在下面选择要锁定的玩家", 4) end
end)
local LockDropdown = TabCombat:Dropdown({
    Title = "锁定的玩家",
    Values = lockList,
    Value = lockList[1],
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.silentLockName = Players:FindFirstChild(v) and v or nil
    end,
})
local function refreshLock()
    local list = lockNames()
    if S.silentLockName and not Players:FindFirstChild(S.silentLockName) then S.silentLockName = nil end
    pcall(function() LockDropdown:Refresh(list) end)
end
connect(Players.PlayerAdded, function() task.defer(refreshLock) end)
connect(Players.PlayerRemoving, function() task.defer(refreshLock) end)
TabCombat:Button({ Title = "刷新锁定列表", Callback = safeCb("刷新锁定列表", refreshLock) })
addToggle(TabCombat, "锁定的人不在时改追最近的人", "silentLockFallback")
addToggle(TabCombat, "墙体检测", "silentWall")
addToggle(TabCombat, "射线类", "silentRay")
addToggle(TabCombat, "鼠标类", "silentMouse")
TabCombat:Section({ Title = "辅助显示" })
addToggle(TabCombat, "Tracer (瞄准指示线)", "tracer")
addToggle(TabCombat, "Hitmarker (命中提示)", "hitmarker")
TabCombat:Section({ Title = "子弹穿墙" })
addToggle(TabCombat, "开启子弹穿墙", "wallbang", function(v)
    if v and not installHooks() then
        notify("当前执行器不支持 hookmetamethod")
    end
end)
addToggle(TabCombat, "穿墙忽略队友", "wallTeam")
addSlider(TabCombat, "穿墙最短射线长度", "wallMinLen", 2, 100, 1)
addToggle(TabCombat, "仅手持道具时生效", "wallNeedTool")
addToggle(TabCombat, "射线调试", "debugRays", function(v)
    if v then installHooks() notify("开几枪后点「查看调试结果」", 5) end
end)
TabCombat:Button({ Title = "查看调试结果", Callback = showDebug })
TabCombat:Section({ Title = "通用范围 (Hitbox)" })
addToggle(TabCombat, "开启范围扩大", "hitbox", function(v) if not v then restoreHitbox() end end)
addSlider(TabCombat, "范围大小", "hitboxSize", 2, 60, 1)
TabCombat:Dropdown({
    Title = "范围部位",
    Values = { "躯干", "头部" },
    Value = "躯干",
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.hitboxPart = (v == "头部") and "Head" or "HumanoidRootPart"
        restoreHitbox()
    end,
})
addSlider(TabCombat, "透明度", "hitboxTrans", 0, 1, 0.05)
addToggle(TabCombat, "忽略队友", "hitboxTeam")

---------------- 传送 ----------------
local TabTp = Window:Tab({ Title = "传送", Icon = "map-pin" })
local function playerNames()
    local t = {}
    for _, p in ipairs(SA.players()) do
        if p ~= lp then table.insert(t, p.Name) end
    end
    table.sort(t)
    return t
end
names = playerNames()
if #names == 0 then names = { "(暂无其他玩家)" } end
S.target = Players:FindFirstChild(names[1]) and names[1] or nil
TabTp:Section({ Title = "选择玩家" })
local PlayerDropdown = TabTp:Dropdown({
    Title = "目标玩家", Values = names, Value = names[1],
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.target = v
        if S.spectate then applySpectate() end
    end,
})
local function refreshPlayers()
    local list = playerNames()
    if #list == 0 then list = { "(暂无其他玩家)" } end
    if S.target and not Players:FindFirstChild(S.target) then S.target = nil end
    pcall(function() PlayerDropdown:Refresh(list) end)
end
connect(Players.PlayerAdded, function() task.defer(refreshPlayers) end)
connect(Players.PlayerRemoving, function() task.defer(refreshPlayers) end)
TabTp:Button({ Title = "刷新玩家列表", Callback = refreshPlayers })
TabTp:Section({ Title = "传送方式" })
TabTp:Button({ Title = "传送一次", Callback = tpOnce })
addToggle(TabTp, "循环传送", "tpLoop")
addToggle(TabTp, "绕圈传送", "tpOrbit")
addToggle(TabTp, "观战目标", "spectate", function() applySpectate() end)
TabTp:Section({ Title = "传送偏移 (一次传送 / 循环传送 都生效)" })
addSlider(TabTp, "左右 (负=左 正=右)", "tpRight", -100, 100, 1)
addSlider(TabTp, "上下 (负=下 正=上)", "tpUp", -100, 100, 1)
addSlider(TabTp, "前后 (正=身后 负=身前)", "tpBack", -100, 100, 1)
addSlider(TabTp, "绕圈半径", "orbitR", 3, 60, 1)
addSlider(TabTp, "绕圈速度", "orbitSpeed", 0.5, 20, 0.5)
addSlider(TabTp, "绕圈高度", "orbitH", -10, 30, 1)
TabTp:Section({ Title = "路点 / 历史" })
local wpInput = ""
local waypointValues = { "(还没有路点)" }
local WaypointDropdown
WaypointDropdown = TabTp:Dropdown({
    Title = "已保存路点", Values = waypointValues, Value = waypointValues[1],
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.plTp = v
    end,
})
local function refreshWaypoints()
    local list = {}
    for k in pairs(waypoints) do table.insert(list, k) end
    table.sort(list)
    if #list == 0 then list = { "(还没有路点)" } end
    pcall(function() WaypointDropdown:Refresh(list) end)
end
TabTp:Button({
    Title = "保存当前位置为路点",
    Callback = safeCb("保存路点", function()
        local r = getRoot()
        if r then
            local n = "wp_" .. tostring(os.time())
            saveWaypoint(n)
            refreshWaypoints()
        end
    end),
})
TabTp:Button({
    Title = "跳转到所选路点",
    Callback = safeCb("跳转", function()
        if S.plTp and waypoints[S.plTp] then tpToWaypoint(S.plTp) end
    end),
})
TabTp:Button({ Title = "撤销上一次传送", Callback = undoTeleport })
-- ============================================================
end

do
-- 第 13 部分：UI（Fling / 灾害 / 监狱 / 工具 / 其他）/ 卸载
-- ============================================================
---------------- Fling ----------------
local TabFling = Window:Tab({ Title = "Fling", Icon = "wind" })
TabFling:Section({ Title = "防护" })
addToggle(TabFling, "防甩飞", "antiFling")
addSlider(TabFling, "被甩速度上限", "antiFlingMax", 30, 300, 1)
addToggle(TabFling, "防布娃娃", "antiRagdoll", function(v)
    if not v then
        local h = getHum()
        if h then setRagdollStates(h, true) end
        ragChar = nil
    end
end)
addToggle(TabFling, "自动挣脱", "autoStruggle", function(v)
    if v then
        if lp:FindFirstChild("IsHeld") and getStruggleEvent() then
            notify("已检测到抓取数据, 被抓住时会自动挣脱", 4)
            return
        end
        lastFind = 0
        local r = findStruggleRemote()
        if r then notify("已找到挣脱事件: " .. r:GetFullName(), 5)
        else notify("没找到名字含 struggle 的事件", 6) end
    end
end)
TabFling:Button({ Title = "检测挣脱相关事件", Callback = listGrabRemotes })
TabFling:Section({ Title = "额外防护" })
addToggle(TabFling, "Anti TP (防被传送)", "antiTp")
addToggle(TabFling, "Anti Freeze (防减速/冻结)", "antiFreeze")
addToggle(TabFling, "Anti Knock (反击退)", "antiKnock")
TabFling:Section({ Title = "位置" })
addToggle(TabFling, "防掉虚空", "antiVoid")
TabFling:Button({
    Title = "保存当前位置",
    Callback = function()
        local r = getRoot()
        if r then savedCF = r.CFrame notify("已保存") end
    end,
})
TabFling:Button({
    Title = "回到保存位置",
    Callback = function()
        local r = getRoot()
        if r and savedCF then
            r.CFrame = savedCF
            r.AssemblyLinearVelocity = Vector3.zero
            if genv.OmegaAntiTpGrace then genv.OmegaAntiTpGrace(2) end
        else
            notify("还没保存过位置")
        end
    end,
})
TabFling:Section({ Title = "视角" })
addToggle(TabFling, "解锁镜头缩放", "zoomOn", function(v)
    if not v then pcall(function() lp.CameraMaxZoomDistance = origZoom end) end
end)
addSlider(TabFling, "最大缩放距离", "zoom", 20, 2000, 10)

---------------- 灾害 ----------------
local TabNds = Window:Tab({ Title = "灾害", Icon = "cloud-lightning" })
TabNds:Section({ Title = "天空避难所" })
addToggle(TabNds, "自动避难", "autoRefuge", function(v) if v then nextRefuge = 0 end end)
addSlider(TabNds, "避难高度", "refugeH", 100, 10000, 50)
addSlider(TabNds, "进入前等待 (秒)", "refugeDelay", 0, 5, 0.1)
TabNds:Button({ Title = "立即进入避难所", Callback = goRefuge })
TabNds:Button({ Title = "返回原来的位置", Callback = leaveRefuge })
TabNds:Section({ Title = "找高处" })
addSlider(TabNds, "搜索范围", "highRadius", 50, 400, 10)
TabNds:Button({ Title = "传送到附近最高点", Callback = teleportHighest })
TabNds:Section({ Title = "防护" })
addToggle(TabNds, "防摔落伤害", "noFall")
addSlider(TabNds, "最大下落速度", "noFallCap", 20, 120, 1)
addToggle(TabNds, "修改重力", "gravOn", function(v)
    if not v then pcall(function() Workspace.Gravity = origGravity end) end
end)
addSlider(TabNds, "重力值", "grav", 5, 300, 1)

---------------- 监狱人生 ----------------
local TabPl = Window:Tab({ Title = "监狱人生", Icon = "shield" })
TabPl:Section({ Title = "传送" })
local plNames = {}
for _, t in ipairs(PL_TELEPORTS) do plNames[#plNames + 1] = t[1] end
S.plTp = plNames[1]
TabPl:Dropdown({
    Title = "地点", Values = plNames, Value = plNames[1],
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.plTp = v
    end,
})
TabPl:Button({ Title = "传送到所选地点", Callback = safeCb("传送", function() plTeleport(S.plTp) end) })
TabPl:Button({ Title = "诊断监狱人生", Callback = safeCb("诊断", plDiagnose) })
TabPl:Section({ Title = "武器 / 道具" })
local giveList = giverNames()
if #giveList == 0 then giveList = { "(未检测到监狱人生)" } end
S.giveSel = giveList[1]
local GiveDropdown = TabPl:Dropdown({
    Title = "选择物品", Values = giveList, Value = giveList[1],
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v[1] end
        S.giveSel = v
    end,
})
TabPl:Button({
    Title = "领取选中物品",
    Callback = safeCb("领取", function()
        task.spawn(function()
            local n = S.giveSel
            if giveItem(n) then notify("已获得: " .. tostring(n))
            else notify("没拿到: " .. tostring(n) .. " (可能需通行证/队伍限制)", 5) end
        end)
    end),
})
TabPl:Button({
    Title = "领取全部物品",
    Callback = safeCb("领取全部", function()
        task.spawn(function()
            local names = giverNames()
            if #names == 0 then notify("没找到物品列表") return end
            local ok, failed = 0, {}
            for _, n in ipairs(names) do
                if giveItem(n) then ok += 1 else failed[#failed + 1] = n end
                task.wait(0.2)
            end
            local msg = string.format("领取完成: 成功 %d / %d", ok, #names)
            if #failed > 0 then msg = msg .. "\n未获得: " .. table.concat(failed, ", ") end
            notify(msg, 8)
        end)
    end),
})
TabPl:Button({
    Title = "刷新物品列表",
    Callback = function()
        local list = giverNames()
        if #list == 0 then list = { "(未检测到监狱人生)" } end
        pcall(function() GiveDropdown:Refresh(list) end)
        S.giveSel = list[1]
    end,
})
addToggle(TabPl, "重生后自动拿枪 (870/AK/M9)", "autoGive")
TabPl:Section({ Title = "枪械改造" })
addToggle(TabPl, "开启枪械改造", "gunMod", function(v)
    if v then
        local guns, changed = applyGuns()
        if guns == 0 then notify("没找到枪, 先领一把枪", 5)
        else notify(string.format("已改造 %d 把枪 / %d 个参数", guns, changed), 5) end
    else
        restoreGuns()
    end
end)
addToggle(TabPl, "无限弹药", "gunInfAmmo", function() restoreGuns() end)
addToggle(TabPl, "极速射击", "gunFast", function() restoreGuns() end)
addSlider(TabPl, "射击间隔", "gunRate", 0.01, 0.3, 0.01)
addToggle(TabPl, "全自动", "gunAuto", function() restoreGuns() end)
addToggle(TabPl, "无散布/后坐", "gunNoSpread", function() restoreGuns() end)
addToggle(TabPl, "秒换弹", "gunReload", function() restoreGuns() end)
addToggle(TabPl, "超远射程", "gunRange", function() restoreGuns() end)
addToggle(TabPl, "后坐力补偿 (开火时锁定视角)", "recoilComp")
TabPl:Section({ Title = "复活" })
addToggle(TabPl, "死亡后回到原地", "respawnHere")
addToggle(TabPl, "快速重生", "fastRespawn")

---------------- 工具 / 其他 ----------------
local TabMisc = Window:Tab({ Title = "其他", Icon = "server" })
TabMisc:Section({ Title = "服务器" })
TabMisc:Button({
    Title = "加入低 Ping 服务器", Desc = "搜索公开服务器,优先最低延迟",
    Callback = joinLowPing,
})
TabMisc:Section({ Title = "自动化" })
addToggle(TabMisc, "防挂机", "antiAfk")
addToggle(TabMisc, "自动点击器", "autoClick")
addSlider(TabMisc, "点击 CPS", "autoClickCps", 1, 30, 1)
TabMisc:Section({ Title = "配置" })
TabMisc:Button({ Title = "保存配置", Callback = safeCb("保存", saveConfig) })
TabMisc:Button({ Title = "加载配置", Callback = safeCb("加载", loadConfig) })
addToggle(TabMisc, "性能模式 (关闭高消耗功能)", "perfMode", function(v)
    if v then
        S.boxEsp = false S.visCheck = false S.tracer = false
        S.healthBar = false S.noParticle = false
        applyNoParticle()
        notify("性能模式已开启 (方框/血条/可见性已关闭)", 5)
    end
end)
TabMisc:Section({ Title = "信息" })
TabMisc:Button({ Title = "查看错误日志", Callback = function()
    if #errorLog == 0 then notify("没有错误记录") return end
    local lines = {}
    for i = math.max(1, #errorLog - 8), #errorLog do
        local e = errorLog[i]
        lines[#lines + 1] = string.format("[%d] %s: %s", e.t % 10000, e.where,
            string.sub(e.err, 1, 80))
    end
    local msg = table.concat(lines, "\n")
    print("[Omega hub] 错误日志:\n" .. msg)
    notify(msg, 12)
end })
TabMisc:Button({ Title = "卸载脚本", Callback = function()
    if genv.OmegaUnload then genv.OmegaUnload() end
end })

-- ============================================================
-- 卸载
-- ============================================================
local function unload()
    for _, k in ipairs({ "fly", "noclip", "speedOn", "cfSpeedOn", "trSpeedOn", "velSpeedOn",
        "jumpOn", "infJump", "autoJump", "bhop", "sprint", "crouch",
        "fovOn", "hitbox", "aim", "silent", "wallbang", "debugRays", "triggerBot", "autoFire",
        "tracer", "hitmarker", "freecam", "fpsShow", "boxEsp", "healthBar", "visCheck",
        "antiFling", "antiRagdoll", "antiVoid", "antiTp", "antiFreeze", "antiKnock",
        "zoomOn", "autoStruggle", "autoRefuge", "noFall", "gravOn",
        "gunMod", "autoGive", "respawnHere", "fastRespawn", "recoilComp",
        "esp", "tpLoop", "tpOrbit", "spectate", "touchSens", "autoClick" }) do
        S[k] = false
    end
    stopFly()
    restoreHitbox()
    restoreFtap()
    restoreNds()
    restoreGuns()
    restoreVisualEnv()
    local hum = getHum()
    if hum then hum.WalkSpeed = origSpeed hum.JumpPower = origJump end
    pcall(function() cam().FieldOfView = origFov end)
    pcall(function() cam().CameraType = Enum.CameraType.Custom end)
    applySpectate()
    pcall(function() RunService:UnbindFromRenderStep("OmegaAim") end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for plr in pairs(espData) do removeESP(plr) end
    pcall(function() espFolder:Destroy() end)
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if tracerLine then pcall(function() tracerLine:Remove() end) end
    if hitmarkerDrawing then pcall(function() hitmarkerDrawing:Remove() end) end
    if fpsLabel then pcall(function() fpsLabel:Remove() end) end
    SA.on = false SA.wall = false SA.debug = false SA.target = nil
    if silentCircle then pcall(function() silentCircle:Remove() end) end
    pcall(function() Window:Destroy() end)
    genv.OmegaUnload = nil
end
genv.OmegaUnload = unload

pcall(function() Window:SelectTab(1) end)
notify(string.format("Omega hub 已加载\nhook:%s  Drawing:%s  require:%s",
    (hookmetamethod and getnamecallmethod) and "支持" or "不支持",
    Drawing and "支持" or "不支持",
    controlModule and "支持" or "不支持"), 6)
end

do
-- ============================================================
-- 第 14 部分：躲避 (Evade)
-- 游戏结构 (已从公开资料确认): workspace.Game.Players 里放着玩家角色和 Nextbot,
--                              workspace.Game.Effects.Tickets 里放着门票
-- 其余能力 (倒地队友的救援提示等) 靠运行时搜索, 找不到时会说明原因
-- ============================================================
local evDefaults = {
    evNbEsp = false, evNbWarn = true, evNbWarnDist = 80, evNbMaxDist = 1500,
    evFlee = false, evFleeDist = 45, evFleeStep = 70,
    evTicketEsp = false, evTicketCollect = false, evTicketRange = 400, evSafeCollect = true,
    evRevive = false, evReviveRange = 400,
}
for k, v in pairs(evDefaults) do
    if S[k] == nil then S[k] = v end
end

local function gameSub(...)
    local cur = Workspace
    for _, n in ipairs({ ... }) do
        cur = cur and cur:FindFirstChild(n)
    end
    return cur
end

-- Nextbot: Game.Players 里不属于任何玩家的模型
local function getNextbots()
    local list = {}
    local folder = gameSub("Game", "Players")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
                local part = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                if part then list[#list + 1] = { model = m, part = part } end
            end
        end
    end
    return list
end

local function nextbotNear(pos, dist)
    for _, b in ipairs(getNextbots()) do
        if (b.part.Position - pos).Magnitude < dist then return true end
    end
    return false
end

local function getTickets(root)
    local list = {}
    local folder = gameSub("Game", "Effects", "Tickets")
    if folder and root then
        for _, t in ipairs(folder:GetChildren()) do
            local part = t:IsA("BasePart") and t
                or (t:IsA("Model") and (t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart")))
            if part then
                list[#list + 1] = { inst = t, part = part, dist = (part.Position - root.Position).Magnitude }
            end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
    end
    return list
end

local function findRevivePrompt(char)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local t = string.lower(tostring(d.ActionText) .. " " .. tostring(d.ObjectText) .. " " .. d.Name)
            if string.find(t, "revive", 1, true) or string.find(t, "复活", 1, true) or string.find(t, "救", 1, true) then
                return d
            end
        end
    end
    return nil
end

-- ESP 容器
local evFolder = Instance.new("Folder")
evFolder.Name = "OmegaEvadeESP"
do
    local ok = pcall(function() evFolder.Parent = (gethui and gethui()) or CoreGui end)
    if not ok then evFolder.Parent = lp:WaitForChild("PlayerGui") end
end

local nbObjs, tkObjs = {}, {}

local function makeTag(target, labelPart, color)
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.FillColor = color
    hl.OutlineColor = color
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = target
    hl.Parent = evFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(170, 36)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = labelPart
    bb.Parent = evFolder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Parent = bb
    return { hl = hl, bb = bb, label = label }
end

local function dropTag(t)
    if t then
        pcall(function() t.hl:Destroy() end)
        pcall(function() t.bb:Destroy() end)
    end
end

local function clearTags(tbl)
    for k, t in pairs(tbl) do
        dropTag(t)
        tbl[k] = nil
    end
end

-- 自动躲避: 在远离最近 Nextbot 的方向上找落脚点, 要求比现在离所有 Nextbot 都更远
local function flee(nearest)
    local root = getRoot()
    if not root then return false end
    local away = root.Position - nearest.part.Position
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
    away = away.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    if lp.Character then ignore[#ignore + 1] = lp.Character end
    local gp = gameSub("Game", "Players")
    if gp then ignore[#ignore + 1] = gp end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true

    local bots = getNextbots()
    local curDist = (nearest.part.Position - root.Position).Magnitude
    local best, bestScore
    for _, ang in ipairs({ 0, 40, -40, 80, -80, 140, -140 }) do
        local dir = CFrame.Angles(0, math.rad(ang), 0):VectorToWorldSpace(away)
        local cand = root.Position + dir * S.evFleeStep
        local hit = Workspace:Raycast(cand + Vector3.new(0, 60, 0), Vector3.new(0, -220, 0), params)
        if hit and hit.Normal.Y > 0.6 and math.abs(hit.Position.Y - root.Position.Y) < 70 then
            local minD = math.huge
            for _, b in ipairs(bots) do
                local d = (b.part.Position - hit.Position).Magnitude
                if d < minD then minD = d end
            end
            if minD > curDist and (not bestScore or minD > bestScore) then
                best, bestScore = hit.Position, minD
            end
        end
    end
    if best then
        root.CFrame = CFrame.new(best + Vector3.new(0, 4, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    return false
end

local busy = false
local attempts = setmetatable({}, { __mode = "k" })
local reviveCD = {}

local function collectOne()
    local root = getRoot()
    if not root then return end
    local tickets = getTickets(root)
    local t = tickets[1]
    if not t or t.dist > S.evTicketRange then return end
    if S.evSafeCollect and nextbotNear(t.part.Position, 60) then return end

    attempts[t.part] = (attempts[t.part] or 0) + 1
    if firetouchinterest and attempts[t.part] % 2 == 1 then
        pcall(function()
            firetouchinterest(root, t.part, 0)
            task.wait(0.05)
            firetouchinterest(root, t.part, 1)
        end)
    else
        local back = root.CFrame
        root.CFrame = CFrame.new(t.part.Position + Vector3.new(0, 3, 0))
        task.wait(0.2)
        root.CFrame = back
    end
end

local function reviveOne()
    local root = getRoot()
    if not root then return end
    local now = os.clock()
    for _, plr in ipairs(SA.players()) do
        local char = plr ~= lp and plr.Character
        if char and (reviveCD[plr] or 0) < now then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local prompt = hrp and findRevivePrompt(char)
            if prompt and (hrp.Position - root.Position).Magnitude <= S.evReviveRange
                and not nextbotNear(hrp.Position, 40) then
                reviveCD[plr] = now + 4
                local back = root.CFrame
                root.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 2))
                task.wait(0.15)
                pcall(function()
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt)
                end)
                task.wait(0.35)
                root.CFrame = back
                return
            end
        end
    end
end

local lastWarn, lastFlee, lastCollect, lastRevive = 0, 0, 0, 0
local inEvade, inEvadeAt = false, -10
local acc = 0
connect(RunService.Heartbeat, function(dt)
    acc = acc + dt
    if acc < 0.1 then return end
    acc = 0

    local now = os.clock()
    -- 不在躲避里 (没有 Game.Players) 或躲避功能全关: 每 2 秒才检查一次, 平时什么都不做
    if now - inEvadeAt > 2 then
        inEvadeAt = now
        inEvade = gameSub("Game", "Players") ~= nil
    end
    local anyOn = S.evNbEsp or S.evNbWarn or S.evFlee or S.evTicketEsp or S.evTicketCollect or S.evRevive
    if not (inEvade and anyOn) then
        if next(nbObjs) then clearTags(nbObjs) end
        if next(tkObjs) then clearTags(tkObjs) end
        return
    end

    local root = getRoot()
    local bots = getNextbots()

    local nearest, nd
    if root then
        for _, b in ipairs(bots) do
            local d = (b.part.Position - root.Position).Magnitude
            if not nd or d < nd then nearest, nd = b, d end
        end
    end

    -- Nextbot ESP
    if S.evNbEsp then
        local seen = {}
        for _, b in ipairs(bots) do
            local d = root and (b.part.Position - root.Position).Magnitude or 0
            if d <= S.evNbMaxDist then
                seen[b.model] = true
                local t = nbObjs[b.model]
                if not t then
                    t = makeTag(b.model, b.part, Color3.fromRGB(255, 50, 50))
                    nbObjs[b.model] = t
                end
                t.label.Text = string.format("%s  [%dm]", b.model.Name, math.floor(d))
            end
        end
        for m, t in pairs(nbObjs) do
            if not seen[m] then dropTag(t) nbObjs[m] = nil end
        end
    else
        clearTags(nbObjs)
    end

    -- 门票 ESP (最近的 15 个)
    if S.evTicketEsp and root then
        local seen = {}
        for i, t in ipairs(getTickets(root)) do
            if i > 15 then break end
            seen[t.inst] = true
            local o = tkObjs[t.inst]
            if not o then
                o = makeTag(t.inst, t.part, Color3.fromRGB(255, 210, 60))
                tkObjs[t.inst] = o
            end
            o.label.Text = string.format("门票 [%dm]", math.floor(t.dist))
        end
        for inst, o in pairs(tkObjs) do
            if not seen[inst] then dropTag(o) tkObjs[inst] = nil end
        end
    else
        clearTags(tkObjs)
    end

    -- 靠近预警
    if S.evNbWarn and nearest and nd < S.evNbWarnDist and now - lastWarn > 3 then
        lastWarn = now
        notify(string.format("Nextbot 靠近: %s  %dm", nearest.model.Name, math.floor(nd)), 2)
    end

    -- 自动躲避
    if S.evFlee and nearest and nd < S.evFleeDist and now - lastFlee > 0.6 then
        lastFlee = now
        flee(nearest)
    end

    -- 自动收集门票 / 自动救援 (有传送和等待, 用 busy 防止重叠)
    if not busy and root then
        if S.evTicketCollect and now - lastCollect > 0.35 then
            lastCollect = now
            busy = true
            task.spawn(function()
                local ok, err = pcall(collectOne)
                busy = false
                if not ok then reportError("躲避-收集门票", err) end
            end)
        elseif S.evRevive and fireproximityprompt and now - lastRevive > 0.6 then
            lastRevive = now
            busy = true
            task.spawn(function()
                local ok, err = pcall(reviveOne)
                busy = false
                if not ok then reportError("躲避-自动救援", err) end
            end)
        end
    end
end)

-- 手动按钮
local function tpNearestTicket()
    local root = getRoot()
    local t = root and getTickets(root)[1]
    if not t then notify("附近没有找到门票") return end
    root.CFrame = CFrame.new(t.part.Position + Vector3.new(0, 3, 0))
    root.AssemblyLinearVelocity = Vector3.zero
end

local function tpDowned()
    local root = getRoot()
    if not root then return end
    for _, plr in ipairs(SA.players()) do
        local char = plr ~= lp and plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (char:GetAttribute("Downed") == true or findRevivePrompt(char)) then
            root.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 2))
            root.AssemblyLinearVelocity = Vector3.zero
            notify("已传送到倒地的队友: " .. plr.Name)
            return
        end
    end
    notify("没有找到倒地的队友")
end

local function evDiagnose()
    local lines = {}
    local gp = gameSub("Game", "Players")
    lines[#lines + 1] = "Game.Players: " .. (gp and ("有 (" .. #gp:GetChildren() .. " 个子对象)") or "没有")
    local bots = getNextbots()
    local names = {}
    for i, b in ipairs(bots) do
        if i <= 5 then names[#names + 1] = b.model.Name end
    end
    lines[#lines + 1] = "Nextbot: " .. #bots .. (#names > 0 and (" (" .. table.concat(names, ", ") .. ")") or "")
    local tf = gameSub("Game", "Effects", "Tickets")
    lines[#lines + 1] = "门票文件夹: " .. (tf and ("有 (" .. #tf:GetChildren() .. " 个)") or "没有")
    lines[#lines + 1] = "firetouchinterest: " .. (firetouchinterest and "支持" or "不支持")
    lines[#lines + 1] = "fireproximityprompt: " .. (fireproximityprompt and "支持" or "不支持")
    local prompts = 0
    for _, plr in ipairs(SA.players()) do
        if plr ~= lp and plr.Character and findRevivePrompt(plr.Character) then prompts += 1 end
    end
    lines[#lines + 1] = "可救援的队友(找到救援提示): " .. prompts
    local msg = table.concat(lines, "\n")
    print("[Omega hub] 躲避诊断:\n" .. msg)
    notify(msg, 15)
end

-- UI
local TabEv = Window:Tab({ Title = "躲避", Icon = "ghost" })

TabEv:Section({ Title = "Nextbot" })
addToggle(TabEv, "Nextbot ESP (高亮 + 名字 + 距离)", "evNbEsp", function(v)
    if not v then clearTags(nbObjs) end
end)
addSlider(TabEv, "ESP 最远距离", "evNbMaxDist", 100, 3000, 50)
addToggle(TabEv, "靠近预警", "evNbWarn")
addSlider(TabEv, "预警距离", "evNbWarnDist", 20, 300, 5)
addToggle(TabEv, "自动躲避 (靠近时传送到远处)", "evFlee")
addSlider(TabEv, "触发距离", "evFleeDist", 15, 150, 1)
addSlider(TabEv, "每次躲避的距离", "evFleeStep", 30, 250, 5)

TabEv:Section({ Title = "门票" })
addToggle(TabEv, "门票 ESP", "evTicketEsp", function(v)
    if not v then clearTags(tkObjs) end
end)
addToggle(TabEv, "自动收集门票", "evTicketCollect")
addSlider(TabEv, "收集范围", "evTicketRange", 50, 1500, 10)
addToggle(TabEv, "Nextbot 在门票附近时不去捡", "evSafeCollect")
TabEv:Button({ Title = "传送到最近的门票", Callback = safeCb("传送门票", tpNearestTicket) })

TabEv:Section({ Title = "队友" })
addToggle(TabEv, "自动救援倒地队友", "evRevive", function(v)
    if v and not fireproximityprompt then
        notify("当前执行器不支持 fireproximityprompt, 自动救援无法使用", 6)
    end
end)
addSlider(TabEv, "救援范围", "evReviveRange", 50, 1500, 10)
TabEv:Button({ Title = "传送到倒地的队友", Callback = safeCb("传送队友", tpDowned) })

TabEv:Section({ Title = "排查" })
TabEv:Button({ Title = "诊断躲避 (出问题时点这个)", Callback = safeCb("诊断躲避", evDiagnose) })

-- 卸载时一并清理
local prevUnload = genv.OmegaUnload
genv.OmegaUnload = function()
    S.evNbEsp, S.evTicketEsp, S.evFlee, S.evTicketCollect, S.evRevive = false, false, false, false, false
    clearTags(nbObjs)
    clearTags(tkObjs)
    pcall(function() evFolder:Destroy() end)
    if prevUnload then prevUnload() end
end
end


do
-- ============================================================
-- 第 15 部分：NPC ESP
-- ============================================================
local npcFolder = Instance.new("Folder")
npcFolder.Name = "OmegaNpcESP"
do
    local ok = pcall(function() npcFolder.Parent = (gethui and gethui()) or CoreGui end)
    if not ok then npcFolder.Parent = lp:WaitForChild("PlayerGui") end
end

local tags = {}
local color = Color3.fromRGB(255, 170, 40)

local function makeTag(model, root)
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.65
    hl.OutlineTransparency = 0
    hl.FillColor = color
    hl.OutlineColor = color
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = npcFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(200, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = model:FindFirstChild("Head") or root
    bb.Parent = npcFolder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Parent = bb
    return { hl = hl, bb = bb, label = label }
end

local function dropTag(t)
    pcall(function() t.hl:Destroy() end)
    pcall(function() t.bb:Destroy() end)
end

function SA.clearNpcEsp()
    for m, t in pairs(tags) do
        dropTag(t)
        tags[m] = nil
    end
end

local acc = 0
connect(RunService.Heartbeat, function(dt)
    acc = acc + dt
    if acc < 0.15 then return end
    acc = 0

    if not S.espNpc then
        if next(tags) then SA.clearNpcEsp() end
        return
    end

    local root = getRoot()
    local list = SA.getNpcs()
    for _, n in ipairs(list) do
        n.dist = root and (n.root.Position - root.Position).Magnitude or 0
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)

    local seen = {}
    for i, n in ipairs(list) do
        if i > 25 or n.dist > S.espNpcMax then break end -- 高亮数量有上限, 只显示最近的 25 个
        seen[n.model] = true
        local t = tags[n.model]
        if not t then
            t = makeTag(n.model, n.root)
            tags[n.model] = t
        end
        local lines = {}
        if S.espNpcName then lines[#lines + 1] = n.model.Name end
        if S.espNpcInfo then
            lines[#lines + 1] = string.format("[%dm]  HP %d/%d",
                math.floor(n.dist), math.floor(n.hum.Health), math.floor(n.hum.MaxHealth))
        end
        t.label.Text = table.concat(lines, "\n")
        t.bb.Enabled = #lines > 0
    end
    for m, t in pairs(tags) do
        if not seen[m] then
            dropTag(t)
            tags[m] = nil
        end
    end
end)

local prevUnload = genv.OmegaUnload
genv.OmegaUnload = function()
    S.espNpc = false
    SA.clearNpcEsp()
    pcall(function() npcFolder:Destroy() end)
    if prevUnload then prevUnload() end
end
end


do
-- ============================================================
-- 第 16 部分：FE (工具 / 饰品轨道)
-- 移植自「工具轨道 v4.3」: 把手上的工具、身上的饰品拆下来, 绕着自己或指定玩家旋转。
-- 原脚本的悬浮窗口换成了 WindUI 的控件, 轨道和物理处理逻辑保持不变。
-- ============================================================
local feDefaults = { feTools = false, feDist = 8, feSpeed = 1, feSpin = 1, feSmooth = 1, feMode = 1 }
for k, v in pairs(feDefaults) do
    if S[k] == nil then S[k] = v end
end

local FE_VELOCITY_Y = 220.290009
local FE_SIM_RADIUS = 2147483647
local FE_RESYNC_COOLDOWN = 2
local FE_MAX_ORBIT_DISTANCE = 8 -- 物品离轨道零件超过这个距离, 就重新同步

local feChar, feHrp
local handles, orbitParts, toolNames = {}, {}, {}
local movers, connections, lastResync = {}, {}, {}
local rot = 0
local lastHRPPos, hrpVel = nil, Vector3.zero
local feAlive = true
local toolAddedConn, gripConn

local function refreshRefs()
    feChar = lp.Character
    feHrp = feChar and feChar:FindFirstChild("HumanoidRootPart") or nil
end
refreshRefs()

local function waitHRP()
    local t0 = os.clock()
    while not (feHrp and feHrp.Parent) and os.clock() - t0 < 5 do
        refreshRefs()
        if not (feHrp and feHrp.Parent) then task.wait() end
    end
    return feHrp ~= nil and feHrp.Parent ~= nil
end

-- 轨道目标: 选了玩家就绕他, 他不在 / 没选就绕自己
local function targetRoot()
    local name = S.feTarget
    if name then
        local p = Players:FindFirstChild(name)
        local c = p and p.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then return r end
    end
    return feHrp
end

local function cleanupTool(h)
    local index = table.find(handles, h)
    if not index then return end
    lastResync[h] = nil
    if orbitParts[index] then orbitParts[index]:Destroy() end
    local m = movers[h]
    if m then
        for _, inst in ipairs({ m.align, m.angular, m.att0, m.att1 }) do
            if inst then pcall(function() inst:Destroy() end) end
        end
        movers[h] = nil
    end
    if connections[h] then
        connections[h]:Disconnect()
        connections[h] = nil
    end
    table.remove(orbitParts, index)
    table.remove(handles, index)
    table.remove(toolNames, index)
end

local function cleanupAll()
    for i = #handles, 1, -1 do
        cleanupTool(handles[i])
    end
    pcall(function() settings().Physics.AllowSleep = true end)
end

local function setupOrbitingItem(item, handle)
    if not handle or not handle.Parent then return end
    if table.find(handles, handle) then
        cleanupTool(handle)
        task.wait()
    end
    if not waitHRP() then return end

    -- 饰品: 彻底解除物理限制并重置速度
    if item:IsA("Accessory") then
        handle.Massless = true
        handle.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        handle.CanCollide = false
        handle:BreakJoints()
        for _, w in ipairs(handle:GetChildren()) do
            if w:IsA("Weld") or w:IsA("Motor6D") then w:Destroy() end
        end
        handle.AssemblyLinearVelocity = Vector3.zero
        handle.AssemblyAngularVelocity = Vector3.zero
    end

    -- 工具: 清除手部握持
    if item:IsA("Tool") then
        local rightArm = feChar:FindFirstChild("Right Arm") or feChar:FindFirstChild("RightHand")
        if rightArm then
            local grip = rightArm:FindFirstChild("RightGrip")
            if grip then grip:Destroy() end
        end
        if item.Parent ~= feChar then item.Parent = feChar end
    end

    -- 物品离开角色时清理
    connections[handle] = item.AncestryChanged:Connect(function(_, parent)
        if parent ~= feChar then cleanupTool(handle) end
    end)

    table.insert(handles, handle)
    table.insert(toolNames, item.Name)
    local index = #handles
    lastResync[handle] = 0

    -- 轨道参考零件
    local p = Instance.new("Part")
    p.Name = "OrbitReference_" .. item.Name
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 1
    p.Size = Vector3.new(0.2, 0.2, 0.2)
    p.Position = feHrp.Position
    p.Parent = Workspace
    orbitParts[index] = p

    -- 自转
    local av = Instance.new("BodyAngularVelocity")
    av.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    av.P = 1250
    av.Parent = handle

    -- 位置对齐
    local att0 = Instance.new("Attachment")
    att0.Parent = handle
    local att1 = Instance.new("Attachment")
    att1.Parent = p
    local ap = Instance.new("AlignPosition")
    ap.MaxForce = math.huge
    ap.MaxVelocity = math.huge
    ap.Responsiveness = 200
    ap.Enabled = true
    ap.Attachment0 = att0
    ap.Attachment1 = att1
    ap.Parent = handle

    movers[handle] = { align = ap, angular = av, att0 = att0, att1 = att1 }

    -- 强制把 Handle 移到轨道零件位置, 多次刷新确保生效
    handle.CFrame = p.CFrame
    task.defer(function()
        if handle and handle.Parent then handle.CFrame = p.CFrame end
        task.wait(0.05)
        if handle and handle.Parent then handle.CFrame = p.CFrame end
    end)
end

local function setupTool(v)
    if not S.feTools then return end
    local h = v:FindFirstChild("Handle")
    if h then setupOrbitingItem(v, h) end
end

local function setupAccessory(v)
    local h = v:FindFirstChild("Handle")
    if h then setupOrbitingItem(v, h) end
end

local function removeAllTools()
    for i = #handles, 1, -1 do
        local h = handles[i]
        local parent = h and h.Parent
        if parent and parent:IsA("Tool") then cleanupTool(h) end
    end
end

local function addAllExistingTools()
    if not S.feTools or not feChar then return end
    for _, v in ipairs(feChar:GetChildren()) do
        if v:IsA("Tool") then setupTool(v) end
    end
end

-- 握持销毁: 只在「工具环绕」开着时才拆掉右手握持
local function destroyGrips(character)
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("Motor6D") and obj.Name == "RightGrip" then obj:Destroy() end
    end
end

local function bindCharacter()
    if toolAddedConn then toolAddedConn:Disconnect() toolAddedConn = nil end
    if gripConn then gripConn:Disconnect() gripConn = nil end
    if not feChar then return end
    toolAddedConn = feChar.ChildAdded:Connect(function(c)
        task.wait()
        if c:IsA("Tool") and S.feTools then setupTool(c) end
    end)
    gripConn = feChar.DescendantAdded:Connect(function(obj)
        if S.feTools and obj:IsA("Motor6D") and obj.Name == "RightGrip" then obj:Destroy() end
    end)
end
bindCharacter()

-- 轨道循环
connect(RunService.RenderStepped, function(dt)
    local n = #orbitParts
    if n == 0 then return end
    local target = targetRoot()
    if not target or not target.Parent then return end

    rot = rot + S.feSpeed
    local time = os.clock()
    local offset = S.feDist
    local mode = math.floor(S.feMode)
    local smooth = S.feSmooth
    local spin = S.feSpin

    for i, p in ipairs(orbitParts) do
        if p and p.Parent then
            local angle = math.rad(rot + (360 / n) * i)
            local cf

            if mode == 0 then
                local fixedAngle = math.rad((i - 1) * (360 / n))
                cf = target.CFrame * CFrame.Angles(0, fixedAngle, 0) * CFrame.new(offset, 0, 0)
            elseif mode == 1 then
                cf = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(offset, 0, 0)
            elseif mode == 2 then
                cf = target.CFrame * CFrame.new(math.cos(angle) * offset, math.sin(time * 2 + i) * 2, math.sin(angle) * offset)
            elseif mode == 3 then
                cf = target.CFrame * CFrame.Angles(angle, angle, 0) * CFrame.new(offset, 0, 0)
            elseif mode == 4 then
                cf = CFrame.new(target.Position) * CFrame.Angles(0, angle, 0) * CFrame.new(offset, 0, 0)
            elseif mode == 5 then
                cf = target.CFrame * CFrame.new(math.cos(angle) * offset, math.sin(angle) * offset, math.sin(angle) * offset)
            elseif mode == 6 then
                cf = target.CFrame * CFrame.Angles(angle, 0, angle) * CFrame.new(offset, 0, 0)
            else
                local subType = mode % 8
                local safeSpeed = time * (1 + (mode % 5) / 10)
                if subType == 0 then
                    local petalCount = (mode % 5) + 3
                    local wave = math.sin(angle * petalCount + safeSpeed)
                    local currentOffset = offset + (wave * (offset / 3))
                    cf = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(currentOffset, 0, 0)
                elseif subType == 1 then
                    local tiltX = math.rad((mode * 15) % 360) + (time * 0.5)
                    local tiltZ = math.rad((mode * 45) % 360)
                    cf = target.CFrame * CFrame.Angles(tiltX, angle, tiltZ) * CFrame.new(offset, 0, 0)
                elseif subType == 2 then
                    local height = math.sin(angle + (time * 2)) * (offset * 0.8)
                    local twist = math.cos(safeSpeed + (i / 2)) * 2
                    cf = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(offset + twist, height, 0)
                elseif subType == 3 then
                    local noiseX = math.sin(angle * ((mode % 3) + 1))
                    local noiseY = math.cos(angle * ((mode % 2) + 1))
                    cf = target.CFrame * CFrame.Angles(angle, 0, angle) * CFrame.new(offset * noiseX, offset * noiseY, 0)
                elseif subType == 4 then
                    local fig8X = math.cos(angle) * offset
                    local fig8Z = math.sin(angle * 2) * offset
                    cf = target.CFrame * CFrame.new(fig8X, 0, fig8Z)
                elseif subType == 5 then
                    local spikeFreq = (mode % 4) + 3
                    local height = math.abs(math.sin(angle * spikeFreq)) * (offset * 0.8)
                    cf = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(offset, height - (offset / 2), 0)
                elseif subType == 6 then
                    local band = (i % 3)
                    local tiltAngle = math.rad(60 * band)
                    cf = target.CFrame * CFrame.Angles(tiltAngle, angle, 0) * CFrame.new(offset, 0, 0)
                else
                    local pulse = math.sin(safeSpeed * 2) * (offset * 0.4)
                    cf = target.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(offset + pulse, 0, 0)
                end

                if mode > 20 then
                    local slowWobble = math.rad(math.sin(time) * 15)
                    cf = cf * CFrame.Angles(slowWobble, 0, slowWobble)
                end
            end

            local alpha = 1 - math.exp(-smooth * dt)
            p.CFrame = p.CFrame:Lerp(cf, alpha)

            local h = handles[i]
            if h and movers[h] then
                local spinVar = (mode % 30)
                movers[h].angular.AngularVelocity = Vector3.new(0, spin * (10 + spinVar), 0)
            end
        end
    end

    if sethiddenproperty then
        pcall(function() sethiddenproperty(lp, "SimulationRadius", math.huge) end)
    end
end)

-- 物理辅助: 有环绕物品时才生效
connect(RunService.Stepped, function()
    if #handles == 0 then return end
    pcall(function() settings().Physics.AllowSleep = false end)
    pcall(function() lp.SimulationRadius = FE_SIM_RADIUS end)
end)

connect(RunService.PostSimulation, function(dt)
    if #handles == 0 or not feHrp or not feHrp.Parent then return end
    local currentTime = os.clock()
    local currentPos = feHrp.Position
    if lastHRPPos and dt > 0 then hrpVel = (currentPos - lastHRPPos) / dt end
    lastHRPPos = currentPos
    local predicted = currentPos + hrpVel * 0.1
    local antiSleep = Vector3.new(0, math.sin(currentTime * 15) * 0.0015, 0)
    local gravityAxis = FE_VELOCITY_Y + math.sin(currentTime)
    for _, h in ipairs(handles) do
        if h and h:IsA("BasePart") then
            local dir = predicted - h.Position
            local xz = Vector3.new(dir.X, 0, dir.Z)
            local velXZ = Vector3.zero
            if xz.Magnitude > 0 then velXZ = xz.Unit * xz.Magnitude * 2 end
            h.AssemblyLinearVelocity = Vector3.new(velXZ.X, gravityAxis, velXZ.Z)
            h.AssemblyAngularVelocity = Vector3.new(0, math.huge, math.huge)
            h.CFrame = h.CFrame + antiSleep
        end
    end
end)

-- 脱轨同步守护: 物品飘离轨道就重新抓取一次
task.spawn(function()
    while feAlive do
        task.wait(#handles == 0 and 0.5 or 0.1) -- 没有环绕物品时降低检查频率
        local now = os.clock()
        for i = #handles, 1, -1 do
            local h = handles[i]
            local orbitPart = orbitParts[i]
            if h and h.Parent and orbitPart and feChar then
                if (h.Position - orbitPart.Position).Magnitude > FE_MAX_ORBIT_DISTANCE then
                    local lastTime = lastResync[h] or 0
                    if now - lastTime >= FE_RESYNC_COOLDOWN then
                        local item = h.Parent
                        if item:IsA("Tool") and item.Parent == feChar then
                            cleanupTool(h)
                            setupTool(item)
                            lastResync[h] = now
                        elseif item:IsA("Accessory") and item.Parent == feChar then
                            item.Parent = nil
                            task.wait()
                            item.Parent = feChar
                            lastResync[h] = now
                        end
                    end
                end
            end
        end
    end
end)

-- 角色重生: 彻底重置
connect(lp.CharacterAdded, function(c)
    c:WaitForChild("HumanoidRootPart", 10)
    task.wait(0.1)
    refreshRefs()
    cleanupAll()
    rot = 0
    lastHRPPos = feHrp and feHrp.Position or nil
    bindCharacter()
    if S.feTools and feChar then
        for _, v in ipairs(feChar:GetChildren()) do
            if v:IsA("Tool") then task.spawn(setupTool, v) end
        end
    end
    -- 饰品不会自动捕获, 需要手动点「捕获饰品」
end)

-- 手动操作
local function equipAll()
    local backpack = lp:FindFirstChildOfClass("Backpack")
    if not (backpack and feChar) then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then tool.Parent = feChar end
    end
end

local function unequipAll()
    local backpack = lp:FindFirstChildOfClass("Backpack")
    if not (backpack and feChar) then return end
    for _, tool in ipairs(feChar:GetChildren()) do
        if tool:IsA("Tool") then tool.Parent = backpack end
    end
end

local function captureAccessories()
    task.wait(0.2)
    refreshRefs()
    if not (feChar and waitHRP()) then return end
    local count = 0
    for _, child in ipairs(feChar:GetChildren()) do
        if child:IsA("Accessory") and child:FindFirstChild("Handle") then
            local h = child.Handle
            if table.find(handles, h) then
                cleanupTool(h)
                task.wait()
            end
            setupAccessory(child)
            count += 1
        end
    end
    notify("已捕获 " .. count .. " 个饰品")
end

local stopConfirm = false
local function stopAndRespawn()
    if not stopConfirm then
        stopConfirm = true
        notify("再点一次确认: 会停止环绕并让角色重生 (拆下的饰品需要重生才能还原)", 3)
        task.delay(3, function() stopConfirm = false end)
        return
    end
    stopConfirm = false
    cleanupAll()
    local hum = getHum()
    if hum then hum.Health = 0 end
end

local function feStatus()
    local names = {}
    for i, n in ipairs(toolNames) do
        if i <= 8 then names[#names + 1] = n end
    end
    notify(string.format("环绕中的物品: %d%s", #handles, #names > 0 and ("\n" .. table.concat(names, ", ")) or ""), 5)
end

-- UI
local TabFE = Window:Tab({ Title = "FE", Icon = "orbit" })

TabFE:Section({ Title = "工具环绕" })
addToggle(TabFE, "工具环绕", "feTools", function(v)
    task.spawn(function()
        refreshRefs()
        if v then
            if feChar then destroyGrips(feChar) end
            addAllExistingTools()
        else
            removeAllTools()
        end
    end)
end)
TabFE:Button({ Title = "装备背包里的全部工具", Callback = safeCb("装备全部", equipAll) })
TabFE:Button({ Title = "卸下全部工具", Callback = safeCb("卸下全部", unequipAll) })

TabFE:Section({ Title = "饰品" })
TabFE:Button({
    Title = "捕获饰品 (让身上的饰品也环绕)",
    Callback = safeCb("捕获饰品", function() task.spawn(captureAccessories) end),
})

TabFE:Section({ Title = "轨道参数" })
addSlider(TabFE, "距离", "feDist", 1, 100, 1)
addSlider(TabFE, "环绕速度 (负数反向)", "feSpeed", -20, 20, 0.5)
addSlider(TabFE, "自转速度 (负数反向)", "feSpin", -20, 20, 0.5)
addSlider(TabFE, "平滑度 (�                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        