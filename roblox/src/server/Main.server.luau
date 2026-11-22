--[[
	Servidor do Duelo 1v1.
	- Uma partida por servidor: você contra o bot, ou dois jogadores (Contra Player).
	- O servidor manda em tudo que importa: munição, cadência, erro de mira e acertos.
	  O jogador só envia "atirei daqui, nesta direção"; o raio é calculado aqui.
	Regras: 3 vidas por rodada, peito tira 1, cabeça tira 3, quem zerar o outro ganha 1 ponto,
	primeiro a 10 vence. Contagem 3 → 0 antes de cada rodada.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Duelo")
local Config = require(Shared:WaitForChild("Config"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))
local Bot = require(script.Parent:WaitForChild("Bot"))

local M = Config.M

---------------------------------------------------------------- remotos
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local FireRE = remote("Fire") -- C→S (origem, direção)
local ReloadRE = remote("Reload") -- C→S
local ReadyRE = remote("Ready") -- C→S ("bot" | "pvp", dificuldade)
local LeaveRE = remote("Leave") -- C→S
local StateRE = remote("State") -- S→C (estado da partida)
local EffectRE = remote("Effect") -- S→C (traçante e marca de tiro)
local HitRE = remote("Hit") -- S→C só para quem acertou (cabeça?)
remotes.Parent = Shared -- só depois de criar todos, para o cliente achar tudo de uma vez

---------------------------------------------------------------- mapa
local map = MapBuilder.build()
local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "Efeitos"
effectsFolder.Parent = workspace

---------------------------------------------------------------- estado
local S = {
	phase = "menu", -- menu | countdown | live | roundEnd | over
	mode = "bot",
	diff = "normal",
	score = { 0, 0 },
	lives = { Config.MAX_LIVES, Config.MAX_LIVES },
	names = { "", "" },
	userIds = { 0, 0 }, -- 0 = bot
	cdEnd = 0, -- hora do servidor em que a contagem termina
	winner = 0,
	waiting = {}, -- nomes de quem está esperando adversário (Contra Player)
}
local slots = { nil, nil } -- [1], [2] = Player ou "bot"
local bot = nil
local roundEndAt = 0
local wantPvp = {} -- [Player] = true
local guns = {} -- [Player] = { mag, last, reloadEnd, token }

local function now()
	return workspace:GetServerTimeNow()
end

local function publicState()
	local waiting = {}
	for p in pairs(wantPvp) do
		table.insert(waiting, p.Name)
	end
	S.waiting = waiting
	return S
end

local function broadcast()
	StateRE:FireAllClients(publicState())
end

local function slotOf(player)
	if slots[1] == player then
		return 1
	elseif slots[2] == player then
		return 2
	end
	return nil
end

local function charOfSlot(i)
	local s = slots[i]
	if typeof(s) == "Instance" and s:IsA("Player") then
		return s.Character
	end
	return nil
end

---------------------------------------------------------------- arma do jogador (no servidor)
local function gunOf(player)
	local g = guns[player]
	if not g then
		g = { mag = Config.MAG, last = 0, reloadEnd = 0, token = 0 }
		guns[player] = g
	end
	return g
end

local function refillGun(player)
	local g = gunOf(player)
	g.mag = Config.MAG
	g.reloadEnd = 0
	g.token += 1
	player:SetAttribute("Mag", g.mag)
	player:SetAttribute("Reloading", false)
end

local function startReload(player)
	local g = gunOf(player)
	if g.reloadEnd > os.clock() or g.mag == Config.MAG then
		return
	end
	g.reloadEnd = os.clock() + Config.RELOAD
	g.token += 1
	local token = g.token
	player:SetAttribute("Reloading", true)
	task.delay(Config.RELOAD, function()
		if guns[player] == g and g.token == token then
			g.mag = Config.MAG
			g.reloadEnd = 0
			player:SetAttribute("Mag", g.mag)
			player:SetAttribute("Reloading", false)
		end
	end)
end

---------------------------------------------------------------- rodadas
local function placeAtSpawn(i)
	local cf = MapBuilder.spawnCFrame(i)
	local s = slots[i]
	if s == "bot" then
		if bot then
			bot:reset(cf)
		end
	else
		local char = charOfSlot(i)
		if char and char.PrimaryPart then
			char:PivotTo(cf)
			char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
		end
		if s then
			refillGun(s)
		end
	end
end

local function newRound()
	S.lives = { Config.MAX_LIVES, Config.MAX_LIVES }
	S.phase = "countdown"
	S.cdEnd = now() + Config.COUNTDOWN
	placeAtSpawn(1)
	placeAtSpawn(2)
	broadcast()
end

local function endMatch(reason)
	slots = { nil, nil }
	if bot then
		bot:destroy()
		bot = nil
	end
	S.phase = "menu"
	S.names = { "", "" }
	S.userIds = { 0, 0 }
	S.score = { 0, 0 }
	S.lives = { Config.MAX_LIVES, Config.MAX_LIVES }
	S.note = reason
	broadcast()
	S.note = nil
end

local function startMatch(a, b, mode, diff)
	slots = { a, b }
	S.mode = mode
	S.diff = diff or S.diff
	S.score = { 0, 0 }
	S.winner = 0
	S.names = { a.Name, if b == "bot" then "Bot " .. Config.DIFFS[S.diff].name else b.Name }
	S.userIds = { a.UserId, if b == "bot" then 0 else b.UserId }
	if bot then
		bot:destroy()
		bot = nil
	end
	if b == "bot" then
		bot = Bot.new(workspace, map)
	end
	newRound()
end

-- Só o servidor chama: tira vidas, marca ponto, fecha rodada ou partida.
local function applyHit(victim, part)
	if S.phase ~= "live" or S.lives[victim] <= 0 then
		return
	end
	local dmg = if part == "head" then Config.HEAD_DAMAGE else Config.BODY_DAMAGE
	S.lives[victim] = math.max(0, S.lives[victim] - dmg)
	if S.lives[victim] == 0 then
		local winner = 3 - victim
		S.score[winner] += 1
		if slots[victim] == "bot" and bot then
			bot.dead = true
		end
		if S.score[winner] >= Config.WIN_SCORE then
			S.phase = "over"
			S.winner = winner
		else
			S.phase = "roundEnd"
			roundEndAt = os.clock() + Config.ROUND_END
		end
	end
	broadcast()
end

---------------------------------------------------------------- tiros dos jogadores
local function applySpread(dir: Vector3, deg: number): Vector3
	local sp = math.rad(deg) * math.sqrt(math.random())
	local a = math.random() * math.pi * 2
	local right = dir:Cross(Vector3.yAxis)
	if right.Magnitude < 1e-3 then
		right = Vector3.xAxis
	end
	right = right.Unit
	local up = right:Cross(dir).Unit
	local t = math.tan(sp)
	return (dir + right * math.cos(a) * t + up * math.sin(a) * t).Unit
end

-- O que a bala acertou: (slot da vítima, "head"/"body") ou nil
local function targetOf(inst: Instance)
	if bot and inst:IsDescendantOf(bot.model) then
		for i = 1, 2 do
			if slots[i] == "bot" then
				return i, inst:GetAttribute("Hit") or "body"
			end
		end
	end
	local model = inst:FindFirstAncestorOfClass("Model")
	local player = model and Players:GetPlayerFromCharacter(model)
	local i = player and slotOf(player)
	if i then
		return i, if inst.Name == "Head" then "head" else "body"
	end
	return nil
end

FireRE.OnServerEvent:Connect(function(player, origin, dir)
	if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" then
		return
	end
	local slot = slotOf(player)
	if not slot or S.phase ~= "live" or S.lives[slot] <= 0 then
		return
	end
	if dir.Magnitude < 0.5 or dir.Magnitude ~= dir.Magnitude then
		return
	end
	local g = gunOf(player)
	local t = os.clock()
	if t - g.last < Config.FIRE_INTERVAL * 0.8 or g.reloadEnd > t then
		return
	end
	if g.mag <= 0 then
		startReload(player)
		return
	end
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not head or not root then
		return
	end
	g.mag -= 1
	g.last = t
	player:SetAttribute("Mag", g.mag)

	-- a origem tem que estar perto da cabeça (a câmera em 1ª pessoa fica ali)
	if (origin - head.Position).Magnitude > 4 then
		origin = head.Position
	end
	dir = dir.Unit
	-- erro de mira calculado aqui, pela velocidade que o servidor vê
	local v = root.AssemblyLinearVelocity
	local spread = Config.spreadForSpeed(Vector3.new(v.X, 0, v.Z).Magnitude / M)
	if spread > 0 then
		dir = applySpread(dir, spread)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, effectsFolder }
	local res = workspace:Raycast(origin, dir * Config.RANGE, params)
	local endPos = if res then res.Position else origin + dir * Config.RANGE
	local decalNormal = nil
	if res then
		local victim, part = targetOf(res.Instance)
		if victim and victim ~= slot then
			HitRE:FireClient(player, part == "head")
			applyHit(victim, part)
		elseif not victim then
			decalNormal = res.Normal
		end
	end
	EffectRE:FireAllClients(player.UserId, origin, endPos, decalNormal)
	if g.mag == 0 then
		task.delay(0.25, function()
			if g.mag == 0 then
				startReload(player)
			end
		end)
	end
end)

ReloadRE.OnServerEvent:Connect(function(player)
	if slotOf(player) then
		startReload(player)
	end
end)

---------------------------------------------------------------- tiros do bot
local function botShoot(seeHead, seeBody, distM)
	local victim = if slots[1] == "bot" then 2 else 1
	local char = charOfSlot(victim)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")
	if not root or not head or not bot then
		return
	end
	local D = Config.DIFFS[S.diff]
	local pv = root.AssemblyLinearVelocity
	local pSpeed = Vector3.new(pv.X, 0, pv.Z).Magnitude / M
	local bSpeed = bot.vel.Magnitude / M
	local chance = D.acc
		* (if pSpeed > 2 then 0.7 else 1)
		* (if bSpeed > 1 then 0.8 else 1)
		* math.clamp(1.15 - distM / 40, 0.6, 1.1)
	if not seeBody then
		chance *= 0.55
	end
	local from = bot:muzzlePosition()
	if math.random() < chance then
		local part = if not seeBody then "head" elseif math.random() < D.head then "head" else "body"
		local to = if part == "head" then head.Position else root.Position
		EffectRE:FireAllClients(0, from, to, nil)
		applyHit(victim, part)
	else
		-- erra para o lado e um pouco para cima ou para baixo
		local side = Vector3.new(-(root.Position.Z - from.Z), 0, root.Position.X - from.X)
		side = if side.Magnitude > 0 then side.Unit else Vector3.xAxis
		local to = root.Position
			+ side * ((if math.random() < 0.5 then -1 else 1) * (0.45 + math.random() * 0.6) * M)
			+ Vector3.new(0, (math.random() - 0.3) * 0.8 * M, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { map }
		local dir = (to - from).Unit
		local res = workspace:Raycast(from, dir * Config.RANGE, params)
		EffectRE:FireAllClients(0, from, if res then res.Position else from + dir * 80, if res then res.Normal else nil)
	end
end

---------------------------------------------------------------- menu: começar partida
ReadyRE.OnServerEvent:Connect(function(player, mode, diff)
	if mode ~= "bot" and mode ~= "pvp" then
		return
	end
	if typeof(diff) ~= "string" or not Config.DIFFS[diff] then
		diff = "normal"
	end
	local busy = S.phase ~= "menu" and S.phase ~= "over"
	if busy and not slotOf(player) then
		return -- já tem partida rolando neste servidor
	end
	if mode == "bot" then
		wantPvp[player] = nil
		startMatch(player, "bot", "bot", diff)
		return
	end
	-- Contra Player: espera outra pessoa também pedir
	wantPvp[player] = true
	for other in pairs(wantPvp) do
		if other ~= player and other.Parent == Players then
			wantPvp[player] = nil
			wantPvp[other] = nil
			startMatch(other, player, "pvp", diff)
			return
		end
	end
	if S.phase == "over" and slotOf(player) then
		-- revanche contra player: volta para a espera
		S.phase = "menu"
	end
	broadcast()
end)

LeaveRE.OnServerEvent:Connect(function(player)
	wantPvp[player] = nil
	if slotOf(player) then
		endMatch(player.Name .. " saiu da partida.")
	else
		broadcast()
	end
end)

---------------------------------------------------------------- jogadores
local function setupCharacter(player, char)
	-- chapéus e acessórios não seguram tiro (só cabeça e corpo contam)
	local function noQuery(d)
		if d:IsA("BasePart") and d:FindFirstAncestorOfClass("Accessory") then
			d.CanQuery = false
		end
	end
	for _, d in ipairs(char:GetDescendants()) do
		noQuery(d)
	end
	char.DescendantAdded:Connect(noQuery)
	local i = slotOf(player)
	if i then
		task.defer(function()
			placeAtSpawn(i)
		end)
	end
end

local function onPlayer(player)
	player:SetAttribute("Mag", Config.MAG)
	player:SetAttribute("Reloading", false)
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
	task.defer(function()
		StateRE:FireClient(player, publicState())
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p) -- quem entrou antes deste script rodar (acontece no Studio)
end

Players.PlayerRemoving:Connect(function(player)
	wantPvp[player] = nil
	guns[player] = nil
	if slotOf(player) then
		endMatch(player.Name .. " saiu do jogo.")
	end
end)

---------------------------------------------------------------- laço principal
local nextSync = 0
RunService.Heartbeat:Connect(function(dt)
	if S.phase == "countdown" and now() >= S.cdEnd then
		S.phase = "live"
		broadcast()
	elseif S.phase == "roundEnd" and os.clock() >= roundEndAt then
		if bot then
			bot.dead = false
		end
		newRound()
	end
	if bot then
		local victim = if slots[1] == "bot" then 2 else 1
		bot:update(dt, {
			live = S.phase == "live" and S.lives[if victim == 1 then 2 else 1] > 0,
			targetChar = charOfSlot(victim),
			diff = Config.DIFFS[S.diff],
			shoot = botShoot,
		})
	end
	-- reenvia o estado de vez em quando (quem entrou atrasado ou perdeu um pacote)
	if os.clock() >= nextSync then
		nextSync = os.clock() + 1
		broadcast()
	end
end)
