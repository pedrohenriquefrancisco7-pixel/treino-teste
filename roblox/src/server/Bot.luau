--[[
	Bot do 1v1: cápsula amarela com cabeça redonda, mesma lógica do 1v1.html.
	- Vendo você: vira para você, faz "strafe" (anda de lado) e atira depois do tempo de reação.
	- Sem ver: procura você pelo mapa com o PathfindingService (refaz o caminho a cada 0,6 s).
	O modelo é ancorado e movido por script (PivotTo), então não depende de física.
]]
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Duelo"):WaitForChild("Config"))

local M = Config.M
local Bot = {}
Bot.__index = Bot

-- Medidas em studs, no tamanho de um avatar do Roblox (~5,4 studs), para o duelo ser justo.
local BODY_R = 0.9 -- raio da cápsula
local BODY_MID = 2.4 -- parte reta da cápsula
local HEAD_R = 0.55
local HEAD_Y = 4.85
Bot.EYE = HEAD_Y
Bot.RADIUS = 1.2 -- raio para colisão com o mapa

local function makePart(model, name, shape, size, hit)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Anchored = true
	p.CanCollide = false -- sem colisão: senão o próprio bot vira obstáculo no cálculo de caminho
	p.CanQuery = true -- mas os tiros (raycast) acertam
	p.CastShadow = true
	p.Color = Config.ENEMY_COLOR
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("Hit", hit) -- "head" tira 3 vidas, "body" tira 1
	p.Parent = model
	return p
end

function Bot.new(parent: Instance, mapModel: Instance)
	local self = setmetatable({}, Bot)
	local model = Instance.new("Model")
	model.Name = "Bot"

	-- cápsula: cilindro (eixo X do Roblox, então gira 90°) + duas esferas
	local d = BODY_R * 2
	local base = makePart(model, "Base", Enum.PartType.Ball, Vector3.new(d, d, d), "body")
	local corpo = makePart(model, "Corpo", Enum.PartType.Cylinder, Vector3.new(BODY_MID, d, d), "body")
	local topo = makePart(model, "Topo", Enum.PartType.Ball, Vector3.new(d, d, d), "body")
	local pescoco = makePart(model, "Pescoco", Enum.PartType.Cylinder, Vector3.new(0.45, 0.42, 0.42), "body")
	local cabeca = makePart(model, "Cabeca", Enum.PartType.Ball, Vector3.new(HEAD_R * 2, HEAD_R * 2, HEAD_R * 2), "head")
	-- posições relativas aos pés (CFrame de referência = pés, olhando para -Z)
	self.offsets = {
		[base] = CFrame.new(0, BODY_R, 0),
		[corpo] = CFrame.new(0, BODY_R + BODY_MID / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		[topo] = CFrame.new(0, BODY_R + BODY_MID, 0),
		[pescoco] = CFrame.new(0, BODY_R * 2 + BODY_MID - 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		[cabeca] = CFrame.new(0, HEAD_Y, 0),
	}
	model.PrimaryPart = corpo
	model.Parent = parent

	self.model = model
	self.map = mapModel
	self.pos = Vector3.zero -- pés
	self.yaw = 0
	self.vel = Vector3.zero
	self.dead = false
	self.fall = 0
	self.walk = 0

	self.losParams = RaycastParams.new()
	self.losParams.FilterType = Enum.RaycastFilterType.Include
	self.losParams.FilterDescendantsInstances = { mapModel }

	self.path = PathfindingService:CreatePath({
		AgentRadius = 1.6,
		AgentHeight = 5.5,
		AgentCanJump = false,
		WaypointSpacing = 3,
	})
	self:resetState()
	return self
end

function Bot:resetState()
	self.waypoints = {}
	self.repath = 0
	self.pathBusy = false
	self.react = 0
	self.fire = 0.4
	self.mag = Config.MAG
	self.reload = 0
	self.strafe = 0
	self.strafeT = 0
	self.lastSeen = nil
	self.vel = Vector3.zero
end

function Bot:place()
	local root = CFrame.new(self.pos) * CFrame.Angles(0, self.yaw, 0)
	if self.fall > 0 then
		-- cai para trás girando pelos pés
		root = root * CFrame.Angles(self.fall * 1.45, 0, 0)
	elseif self.vel.Magnitude > 2 then
		root = root * CFrame.Angles(0, 0, math.sin(self.walk) * 0.05) -- balanço leve ao andar
	end
	for p, off in pairs(self.offsets) do
		p.CFrame = root * off
	end
end

function Bot:reset(spawnCF: CFrame)
	self:resetState()
	self.dead = false
	self.fall = 0
	self.pos = Vector3.new(spawnCF.Position.X, 0, spawnCF.Position.Z)
	local look = spawnCF.LookVector
	self.yaw = math.atan2(-look.X, -look.Z)
	self:place()
end

function Bot:muzzlePosition(): Vector3
	local root = CFrame.new(self.pos) * CFrame.Angles(0, self.yaw, 0)
	return (root * CFrame.new(0.5, 3.6, -1.3)).Position
end

-- só o mapa segura a visão
function Bot:clear(a: Vector3, b: Vector3): boolean
	local dir = b - a
	return workspace:Raycast(a, dir * ((dir.Magnitude - 0.2) / math.max(dir.Magnitude, 1e-3)), self.losParams) == nil
end

local function turnTo(cur, target, rate)
	local d = target - cur
	while d > math.pi do
		d -= math.pi * 2
	end
	while d < -math.pi do
		d += math.pi * 2
	end
	return cur + math.clamp(d, -rate, rate)
end

function Bot:computePath(target: Vector3)
	if self.pathBusy then
		return
	end
	self.pathBusy = true
	local from = self.pos + Vector3.new(0, 2.5, 0)
	task.spawn(function()
		local ok = pcall(function()
			self.path:ComputeAsync(from, target)
		end)
		local list = {}
		if ok and self.path.Status == Enum.PathStatus.Success then
			for _, w in ipairs(self.path:GetWaypoints()) do
				table.insert(list, Vector3.new(w.Position.X, 0, w.Position.Z))
			end
		end
		self.waypoints = list
		self.pathBusy = false
	end)
end

-- anda até onde dá: se a parede estiver na frente, para (e troca o lado do strafe)
function Bot:step(move: Vector3)
	if move.Magnitude < 1e-4 then
		return
	end
	local origin = self.pos + Vector3.new(0, 2.5, 0)
	local hit = workspace:Raycast(origin, move.Unit * (move.Magnitude + Bot.RADIUS), self.losParams)
	if hit then
		self.strafe = -self.strafe
		return
	end
	self.pos += move
end

--[[
	ctx = {
		live = boolean,
		targetChar = Model?  (personagem do jogador)
		diff = tabela de Config.DIFFS
		shoot = function(seeHead, seeBody, distMeters)  -- chamado quando o bot dispara
	}
]]
function Bot:update(dt: number, ctx)
	if self.dead then
		self.fall = math.min(1, self.fall + dt * 3.6)
		self.vel = Vector3.zero
		self:place()
		return
	end
	local char = ctx.targetChar
	local head = char and char:FindFirstChild("Head")
	local torso = char and char:FindFirstChild("HumanoidRootPart")
	if not ctx.live or not head or not torso then
		self.vel = Vector3.zero
		self:place()
		return
	end

	local D = ctx.diff
	local eye = self.pos + Vector3.new(0, Bot.EYE, 0)
	local seeHead = self:clear(eye, head.Position)
	local seeBody = self:clear(eye, torso.Position)
	local sees = seeHead or seeBody
	local flat = Vector3.new(torso.Position.X - self.pos.X, 0, torso.Position.Z - self.pos.Z)
	local dist = flat.Magnitude
	local wish = Vector3.zero
	local speed = 0

	if self.reload > 0 then
		self.reload -= dt
		if self.reload <= 0 then
			self.mag = Config.MAG
		end
	end

	if sees then
		self.lastSeen = Vector3.new(torso.Position.X, 0, torso.Position.Z)
		self.react += dt
		self.yaw = turnTo(self.yaw, math.atan2(-flat.X, -flat.Z), dt * 9)
		self.strafeT -= dt
		if self.strafeT <= 0 then
			self.strafe = ({ -1, 0, 1 })[math.random(1, 3)]
			self.strafeT = 0.25 + math.random() * 0.6
		end
		if self.strafe ~= 0 and dist > 0 then
			wish = Vector3.new(-flat.Z / dist * self.strafe, 0, flat.X / dist * self.strafe)
			speed = 3.6 * M
		end
		self.fire -= dt
		if self.react >= D.react and self.fire <= 0 and self.reload <= 0 then
			if self.mag <= 0 then
				self.reload = Config.RELOAD
			else
				self.mag -= 1
				self.fire = D.fire * (0.85 + math.random() * 0.5)
				ctx.shoot(seeHead, seeBody, dist / M)
				if self.mag == 0 then
					self.reload = Config.RELOAD
				end
			end
		end
	else
		self.react = math.max(0, self.react - dt * 1.5)
		self.repath -= dt
		if self.repath <= 0 or #self.waypoints == 0 then
			self.repath = 0.6
			local tgt = if self.lastSeen and math.random() < 0.5
				then self.lastSeen
				else Vector3.new(torso.Position.X, 0, torso.Position.Z)
			self:computePath(tgt + Vector3.new(0, 2.5, 0))
			self.lastSeen = nil
		end
		while #self.waypoints > 0 and (self.waypoints[1] - self.pos).Magnitude < 1 do
			table.remove(self.waypoints, 1)
		end
		local nextPoint = self.waypoints[1]
		if not nextPoint and not self.pathBusy and dist > 2 then
			-- sem caminho calculado: vai direto (o passo para na parede)
			nextPoint = Vector3.new(torso.Position.X, 0, torso.Position.Z)
		end
		if nextPoint and (nextPoint - self.pos).Magnitude > 1e-3 then
			wish = (nextPoint - self.pos).Unit
			speed = 5.0 * M
			self.yaw = turnTo(self.yaw, math.atan2(-wish.X, -wish.Z), dt * 7)
		end
	end

	local k = math.min(1, dt * 12)
	self.vel += (wish * speed - self.vel) * k
	self:step(self.vel * dt)
	self.walk += self.vel.Magnitude / M * dt * 2.2
	self:place()
end

function Bot:destroy()
	self.model:Destroy()
end

return Bot
