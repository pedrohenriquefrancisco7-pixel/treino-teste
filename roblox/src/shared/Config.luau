--[[
	Configuração do Duelo 1v1 (as mesmas regras do 1v1.html).
	Distâncias do jogo web estão em metros; aqui tudo vira studs com M (studs por metro).
]]
local Config = {}

Config.M = 3.5 -- studs por metro (um avatar de ~5 studs fica com ~1,5 m de tronco+cabeça)

-- Regras
Config.MAX_LIVES = 3
Config.WIN_SCORE = 10
Config.HEAD_DAMAGE = 3
Config.BODY_DAMAGE = 1
Config.COUNTDOWN = 3 -- segundos (3 → 0)
Config.ROUND_END = 1.8 -- pausa depois de alguém zerar as vidas
Config.FIRE_INTERVAL = 0.15 -- ~6,7 tiros/s
Config.MAG = 12
Config.RELOAD = 1.75
Config.RANGE = 300 -- studs

-- Movimento (m/s → studs/s)
Config.RUN_SPEED = 5.6 * Config.M
Config.WALK_SPEED = 2.9 * Config.M

-- Erro de mira por velocidade (m/s → graus), igual ao 1v1.html:
-- parado = cravado; andando com Shift = abre pouco; correndo = abre muito.
function Config.spreadForSpeed(metersPerSecond: number): number
	if metersPerSecond > 2.9 + 0.3 then
		return 7.5
	elseif metersPerSecond > 1.0 then
		return 2.2
	elseif metersPerSecond > 0.5 then
		return 0.8
	end
	return 0
end

-- Dificuldades do bot (mesmos números do jogo web)
Config.DIFFS = {
	facil = { name = "Fácil", react = 0.75, acc = 0.22, head = 0.04, fire = 0.45 },
	normal = { name = "Normal", react = 0.45, acc = 0.35, head = 0.10, fire = 0.30 },
	dificil = { name = "Difícil", react = 0.27, acc = 0.50, head = 0.18, fire = 0.21 },
}
Config.DIFF_ORDER = { "facil", "normal", "dificil" }

-- Mapa (metros). Galpão com corredores nas duas pontas.
Config.ROOM_X = 11.94
Config.ROOM_Z = 15.78
Config.COR_X = 2.88
Config.COR_Z = 22.0
Config.WALL_H = 6.5
Config.WALL_T = 0.5

-- Caixas: metade da planta (unidade da planta = 0,12 m, centro em 222,5 × 223,5);
-- a outra metade é espelhada pelo centro, trocando madeira por metal.
local SC, PX, PY = 0.12, 222.5, 223.5
local HALF = {
	{ 223, 132.5, 46, 15, 0, 1.25, "wood" },
	{ 172, 158, 15, 15, 28, 1.0, "metal" },
	{ 251, 178, 24, 15, 22, 2.0, "metal" },
	{ 272, 192, 18, 13, 22, 1.15, "wood" },
	{ 139, 200, 32, 12, 0, 2.0, "wood" },
	{ 133, 212, 20, 11, 0, 1.1, "metal" },
}

-- Lista final de caixas: { x, z, largura, profundidade, altura, rotaçãoGraus, tipo } em metros
Config.BOXES = {}
local function addBox(px, py, w, d, deg, h, kind)
	table.insert(Config.BOXES, {
		x = (px - PX) * SC,
		z = (py - PY) * SC,
		w = w * SC,
		d = d * SC,
		h = h,
		deg = deg,
		kind = kind,
	})
end
for _, b in ipairs(HALF) do
	addBox(b[1], b[2], b[3], b[4], b[5], b[6], b[7])
end
for _, b in ipairs(HALF) do
	addBox(445 - b[1], 447 - b[2], b[3], b[4], b[5], b[6], if b[7] == "wood" then "metal" else "wood")
end
addBox(222.5, 223.5, 20, 20, 0, 2.3, "metal")

-- Nascimento (metros): cada um numa ponta, olhando para o outro
Config.SPAWNS = {
	{ x = 0, z = -(22.0 - 1.6) },
	{ x = 0, z = 22.0 - 1.6 },
}

-- Cores
Config.ENEMY_COLOR = Color3.fromRGB(242, 194, 48) -- cápsula amarela
Config.ACCENT = Color3.fromRGB(95, 212, 232)

return Config
