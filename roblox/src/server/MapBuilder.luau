--[[
	Monta o galpão do 1v1 a partir do Config (mesma planta do 1v1.html).
	Tudo é criado por script, então o place não precisa de nada pronto no Workspace.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Duelo"):WaitForChild("Config"))

local M = Config.M
local MapBuilder = {}

local COLORS = {
	floor = Color3.fromRGB(135, 132, 124),
	wall = Color3.fromRGB(214, 195, 160),
	wood = Color3.fromRGB(143, 108, 71),
	metal = Color3.fromRGB(86, 104, 122),
	beam = Color3.fromRGB(110, 79, 51),
	ceiling = Color3.fromRGB(59, 49, 41),
}
local MATERIALS = {
	floor = Enum.Material.Concrete,
	wall = Enum.Material.Plaster,
	wood = Enum.Material.WoodPlanks,
	metal = Enum.Material.DiamondPlate,
	beam = Enum.Material.Wood,
	ceiling = Enum.Material.Wood,
}

local function part(parent, name, kind, sizeM: Vector3, cf: CFrame, opts)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = sizeM * M
	p.CFrame = cf
	p.Color = COLORS[kind] or COLORS.wall
	p.Material = MATERIALS[kind] or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts then
		for k, v in pairs(opts) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- posição em metros → CFrame em studs
local function at(x: number, y: number, z: number, deg: number?)
	return CFrame.new(x * M, y * M, z * M) * CFrame.Angles(0, math.rad(deg or 0), 0)
end

function MapBuilder.build(): Model
	local old = workspace:FindFirstChild("Galpao")
	if old then
		old:Destroy()
	end
	local map = Instance.new("Model")
	map.Name = "Galpao"

	local RX, RZ, CX, CZ = Config.ROOM_X, Config.ROOM_Z, Config.COR_X, Config.COR_Z
	local H, T = Config.WALL_H, Config.WALL_T

	-- chão e teto
	local fw, fd = RX * 2 + 2, CZ * 2 + 2
	part(map, "Chao", "floor", Vector3.new(fw, 0.2, fd), at(0, -0.1, 0))
	part(map, "Teto", "ceiling", Vector3.new(fw, 0.2, fd), at(0, H + 1.3, 0), { CastShadow = false })
	local beams = Instance.new("Folder")
	beams.Name = "Vigas"
	beams.Parent = map
	local z = -RZ + 1.5
	while z < RZ do
		part(beams, "Viga", "beam", Vector3.new(RX * 2, 0.35, 0.3), at(0, H + 0.9, z), { CanQuery = false })
		z += 3.2
	end
	for _, x in ipairs({ -4, 4 }) do
		part(beams, "Viga", "beam", Vector3.new(0.35, 0.4, RZ * 2), at(x, H + 0.7, 0), { CanQuery = false })
	end

	-- paredes do salão e dos dois corredores
	local walls = Instance.new("Folder")
	walls.Name = "Paredes"
	walls.Parent = map
	local function wall(x, zz, w, d)
		part(walls, "Parede", "wall", Vector3.new(w, H, d), at(x, H / 2, zz))
	end
	local segW = RX - CX
	wall(-RX - T / 2, 0, T, RZ * 2)
	wall(RX + T / 2, 0, T, RZ * 2)
	for _, s in ipairs({ -1, 1 }) do
		wall(-(CX + segW / 2), s * (RZ + T / 2), segW + T, T)
		wall(CX + segW / 2, s * (RZ + T / 2), segW + T, T)
		local cl = CZ - RZ
		wall(-CX - T / 2, s * (RZ + cl / 2), T, cl + T)
		wall(CX + T / 2, s * (RZ + cl / 2), T, cl + T)
		wall(0, s * (CZ + T / 2), CX * 2 + T * 2, T)
	end

	-- rodapé e pilares de madeira (enfeite: não segura tiro, como no jogo web)
	local trims = Instance.new("Folder")
	trims.Name = "Acabamento"
	trims.Parent = map
	for _, s in ipairs({ -1, 1 }) do
		part(trims, "Rodape", "beam", Vector3.new(0.12, 0.8, RZ * 2), at(s * (RX - 0.06), 0.4, 0), { CanQuery = false })
		local pz = -RZ + 2
		while pz < RZ do
			part(trims, "Pilar", "beam", Vector3.new(0.22, H, 0.3), at(s * (RX - 0.11), H / 2, pz), { CanQuery = false, CanCollide = false })
			pz += 4.4
		end
	end

	-- caixas
	local boxes = Instance.new("Folder")
	boxes.Name = "Caixas"
	boxes.Parent = map
	for i, b in ipairs(Config.BOXES) do
		part(boxes, "Caixa" .. i, b.kind, Vector3.new(b.w, b.h, b.d), at(b.x, b.h / 2, b.z, b.deg))
	end

	-- marcação dos locais de nascimento (azul = jogador 1, amarelo = jogador 2)
	for i, sp in ipairs(Config.SPAWNS) do
		part(map, "Base" .. i, "floor", Vector3.new(CX * 2 - 0.2, 0.02, 3), at(sp.x, 0.01, sp.z), {
			Color = if i == 1 then Config.ACCENT else Config.ENEMY_COLOR,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.6,
			CanCollide = false,
			CanQuery = false,
		})
	end

	-- onde todo mundo aparece antes da partida (no centro há uma caixa, então fica na lateral do salão)
	local lobby = Instance.new("SpawnLocation")
	lobby.Name = "Entrada"
	lobby.Anchored = true
	lobby.Neutral = true
	lobby.Duration = 0 -- sem campo de força
	lobby.Size = Vector3.new(6, 0.2, 6)
	lobby.CFrame = at(RX - 2.5, 0.01, -7)
	lobby.Transparency = 1
	lobby.CanCollide = false
	lobby.CanQuery = false
	lobby.Parent = map

	map.Parent = workspace
	return map
end

-- CFrame de nascimento (studs) olhando para o centro do mapa
function MapBuilder.spawnCFrame(index: number): CFrame
	local sp = Config.SPAWNS[index]
	local pos = Vector3.new(sp.x * M, 3, sp.z * M)
	return CFrame.lookAt(pos, Vector3.new(0, 3, 0))
end

return MapBuilder
