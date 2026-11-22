--[[
	Cliente do Duelo 1v1: telas, placar, mira, pistola em 1ª pessoa e efeitos.
	O cliente só pede ("atirei", "recarregar", "quero jogar"); quem decide é o servidor.
	Controles: WASD andar · Shift andar devagar (tiro preciso) · Clique atirar · R recarregar · P menu da partida
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Duelo")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = Shared:WaitForChild("Remotes")
local FireRE = Remotes:WaitForChild("Fire")
local ReloadRE = Remotes:WaitForChild("Reload")
local ReadyRE = Remotes:WaitForChild("Ready")
local LeaveRE = Remotes:WaitForChild("Leave")
local StateRE = Remotes:WaitForChild("State")
local EffectRE = Remotes:WaitForChild("Effect")
local HitRE = Remotes:WaitForChild("Hit")

local camera = workspace.CurrentCamera

-- esconde mochila e barra de vida padrão (aqui a vida são as 3 vidas do placar)
task.spawn(function()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)
		if ok then
			break
		end
		task.wait(0.5)
	end
end)

---------------------------------------------------------------- cores e fontes
local C = {
	bg = Color3.fromRGB(10, 18, 22),
	panel = Color3.fromRGB(16, 27, 33),
	panel2 = Color3.fromRGB(22, 37, 45),
	line = Color3.fromRGB(34, 53, 64),
	fg = Color3.fromRGB(232, 240, 243),
	muted = Color3.fromRGB(138, 161, 173),
	accent = Config.ACCENT,
	ink = Color3.fromRGB(4, 34, 42),
	enemy = Config.ENEMY_COLOR,
	bad = Color3.fromRGB(255, 93, 108),
	good = Color3.fromRGB(110, 231, 168),
}
local F_BOLD = Enum.Font.GothamBold
local F_TEXT = Enum.Font.Gotham
local F_MONO = Enum.Font.RobotoMono

---------------------------------------------------------------- ajudantes de interface
local function make(class, props, children)
	local o = Instance.new(class)
	local parent = props.Parent
	for k, v in pairs(props) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = o
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end
local function corner(r)
	return make("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function stroke(color, thickness)
	return make("UIStroke", { Color = color, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(px)
	return make("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end
local function list(dir, gap, align)
	return make("UIListLayout", {
		FillDirection = dir,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
	})
end
local function text(props)
	local t = make("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or F_TEXT,
		TextSize = props.TextSize or 16,
		TextColor3 = props.TextColor3 or C.fg,
		Text = props.Text or "",
		TextWrapped = true,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	return t
end
local function button(label, primary, parent, order)
	return make("TextButton", {
		Text = label,
		Font = F_BOLD,
		TextSize = 17,
		TextColor3 = if primary then C.ink else C.fg,
		BackgroundColor3 = if primary then C.accent else C.panel2,
		AutoButtonColor = true,
		Modal = true, -- solta o mouse da 1ª pessoa enquanto a tela está aberta
		Size = UDim2.new(0, 0, 0, 42),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = order or 0,
		Parent = parent,
	}, {
		corner(8),
		stroke(if primary then C.accent else C.line),
		make("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
end
local function row(parent, order, gap)
	return make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 0,
		Parent = parent,
	}, { list(Enum.FillDirection.Horizontal, gap or 10) })
end
local function card(parent, name)
	return make("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 560, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.panel,
		Visible = false,
		Parent = parent,
	}, { corner(12), stroke(C.line), pad(24), list(Enum.FillDirection.Vertical, 14) })
end

---------------------------------------------------------------- tela
local gui = make("ScreenGui", {
	Name = "DueloGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
local hud = make("Frame", { Name = "HUD", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = gui })

-- vinheta vermelha ao tomar tiro
local dmgFx = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 40, 60),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Parent = hud,
})

-- placar
local scoreBar = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0, 0, 0, 52),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = C.bg,
	BackgroundTransparency = 0.2,
	Parent = hud,
}, { corner(10), stroke(C.line), list(Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Center), make("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }) })
local function pips(parent, order, color)
	local f = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 44, 0, 12), LayoutOrder = order, Parent = parent }, {
		list(Enum.FillDirection.Horizontal, 4),
	})
	local out = {}
	for i = 1, Config.MAX_LIVES do
		out[i] = make("Frame", { BackgroundColor3 = color, Size = UDim2.new(0, 12, 0, 12), LayoutOrder = i, Parent = f }, { corner(3) })
	end
	return out
end
local function scoreText(order, color, size, font)
	return text({ Parent = scoreBar, LayoutOrder = order, TextColor3 = color, TextSize = size, Font = font, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center })
end
local nmMe = scoreText(1, C.muted, 15, F_BOLD)
nmMe.Text = "VOCÊ"
local lvMe = pips(scoreBar, 2, C.accent)
local scMe = scoreText(3, C.accent, 30, F_MONO)
local mid = scoreText(4, C.muted, 12, F_BOLD)
mid.Text = "PRIMEIRO A " .. Config.WIN_SCORE
local scOp = scoreText(5, C.enemy, 30, F_MONO)
local lvOp = pips(scoreBar, 6, C.enemy)
local nmOp = scoreText(7, C.muted, 15, F_BOLD)

-- mira: 4 traços com contorno escuro + ponto
local xh = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Parent = hud })
local function bar(x, y, w, h)
	make("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y), Size = UDim2.new(0, w, 0, h), Parent = xh }, { stroke(Color3.new(0, 0, 0), 1) })
end
bar(-12, 0, 9, 2)
bar(12, 0, 9, 2)
bar(0, -12, 2, 9)
bar(0, 12, 2, 9)
bar(0, 0, 3, 3)

-- marcador de acerto (X)
local hitm = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 34, 0, 34), BackgroundTransparency = 1, Visible = false, Parent = hud })
local hitBars = {}
for _, p in ipairs({ { -1, -1, 45 }, { 1, -1, -45 }, { -1, 1, -45 }, { 1, 1, 45 } }) do
	table.insert(hitBars, make("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, p[1] * 10, 0.5, p[2] * 10),
		Size = UDim2.new(0, 10, 0, 3),
		Rotation = p[3],
		Parent = hitm,
	}))
end

local cdLabel = text({ Parent = hud, Font = F_MONO, TextSize = 110, TextXAlignment = Enum.TextXAlignment.Center })
cdLabel.AnchorPoint = Vector2.new(0.5, 0.5)
cdLabel.Position = UDim2.fromScale(0.5, 0.36)
cdLabel.Size = UDim2.new(0, 300, 0, 120)
cdLabel.AutomaticSize = Enum.AutomaticSize.None
cdLabel.TextStrokeTransparency = 0.5

local msgLabel = text({ Parent = hud, Font = F_BOLD, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center })
msgLabel.AnchorPoint = Vector2.new(0.5, 0.5)
msgLabel.Position = UDim2.fromScale(0.5, 0.62)
msgLabel.Size = UDim2.new(0, 600, 0, 40)
msgLabel.AutomaticSize = Enum.AutomaticSize.None
msgLabel.TextStrokeTransparency = 0.4

local ammoBox = make("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -20),
	Size = UDim2.new(0, 0, 0, 50),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = C.bg,
	BackgroundTransparency = 0.3,
	Parent = hud,
}, { corner(8), stroke(C.line), list(Enum.FillDirection.Horizontal, 8), make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
local ammoLabel = text({ Parent = ammoBox, Font = F_MONO, TextSize = 30, LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X })
local reloadLabel = text({ Parent = ammoBox, Font = F_BOLD, TextSize = 12, TextColor3 = C.enemy, LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "RECARREGANDO" })

local keysLabel = text({ Parent = hud, TextSize = 13, TextColor3 = C.muted, Text = "WASD andar · Shift andar devagar · R recarregar · P menu da partida" })
keysLabel.AnchorPoint = Vector2.new(0, 1)
keysLabel.Position = UDim2.new(0, 20, 1, -20)
keysLabel.Size = UDim2.new(0, 520, 0, 20)
keysLabel.AutomaticSize = Enum.AutomaticSize.None

---------------------------------------------------------------- telas (menu, fim, pausa)
local settings = { diff = "normal", sens = 1 }

local menu = card(gui, "Menu")
text({ Parent = menu, LayoutOrder = 1, Font = F_BOLD, TextSize = 12, TextColor3 = C.muted, Text = "TREINO DE MIRA" })
text({ Parent = menu, LayoutOrder = 2, Font = F_BOLD, TextSize = 44, Text = "MODO 1 V 1" })
text({ Parent = menu, LayoutOrder = 3, TextColor3 = C.muted, Text = "Cada um tem 3 vidas. Tiro no peito tira 1, na cabeça tira as 3. Zerou as vidas do outro, ganha 1 ponto. Quem fizer 10 primeiro vence." })
local menuNote = text({ Parent = menu, LayoutOrder = 4, TextColor3 = C.bad, TextSize = 14 })
local modeRow = row(menu, 5, 10)
local btnBot = button("Contra Bot", true, modeRow, 1)
local btnPvp = button("Contra Player", false, modeRow, 2)
local btnCancel = button("Cancelar espera", false, modeRow, 3)
local diffRow = row(menu, 6, 6)
text({ Parent = diffRow, LayoutOrder = 0, Font = F_BOLD, TextSize = 12, TextColor3 = C.muted, Text = "DIFICULDADE DO BOT", Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X })
local diffButtons = {}
for i, key in ipairs(Config.DIFF_ORDER) do
	diffButtons[key] = button(Config.DIFFS[key].name, false, diffRow, i)
end
local sensRow = row(menu, 7, 6)
text({ Parent = sensRow, LayoutOrder = 0, Font = F_BOLD, TextSize = 12, TextColor3 = C.muted, Text = "SENSIBILIDADE", Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X })
local sensMinus = button("−", false, sensRow, 1)
local sensValue = text({ Parent = sensRow, LayoutOrder = 2, Font = F_MONO, TextSize = 18, Size = UDim2.new(0, 64, 0, 30), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center })
local sensPlus = button("+", false, sensRow, 3)
text({ Parent = menu, LayoutOrder = 8, TextColor3 = C.muted, TextSize = 13, Text = "A sensibilidade multiplica a do Roblox (Configurações → Sensibilidade da câmera). Contra Player: os dois precisam estar neste servidor; convide pela lista de amigos." })

local endCard = card(gui, "Fim")
text({ Parent = endCard, LayoutOrder = 1, Font = F_BOLD, TextSize = 12, TextColor3 = C.muted, Text = "FIM DE PARTIDA" })
local endTitle = text({ Parent = endCard, LayoutOrder = 2, Font = F_BOLD, TextSize = 48 })
local endScore = text({ Parent = endCard, LayoutOrder = 3, Font = F_MONO, TextSize = 44, TextXAlignment = Enum.TextXAlignment.Center })
local endRow = row(endCard, 4, 10)
local btnRematch = button("Revanche", true, endRow, 1)
local btnEndMenu = button("Menu", false, endRow, 2)

local pauseCard = card(gui, "Pausa")
text({ Parent = pauseCard, LayoutOrder = 1, Font = F_BOLD, TextSize = 12, TextColor3 = C.muted, Text = "A PARTIDA CONTINUA" })
text({ Parent = pauseCard, LayoutOrder = 2, Font = F_BOLD, TextSize = 36, Text = "MENU DA PARTIDA" })
local pauseRow = row(pauseCard, 3, 10)
local btnBack = button("Voltar ao jogo", true, pauseRow, 1)
local btnQuit = button("Sair da partida", false, pauseRow, 2)
local pauseSensRow = row(pauseCard, 4, 6)
text({ Parent = pauseSensRow, LayoutOrder = 0, Font = F_BOLD, TextSize = 12, TextColor3 = C.muted, Text = "SENSIBILIDADE", Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X })
local pSensMinus = button("−", false, pauseSensRow, 1)
local pSensValue = text({ Parent = pauseSensRow, LayoutOrder = 2, Font = F_MONO, TextSize = 18, Size = UDim2.new(0, 64, 0, 30), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center })
local pSensPlus = button("+", false, pauseSensRow, 3)

---------------------------------------------------------------- estado vindo do servidor
local S = {
	phase = "menu",
	mode = "bot",
	score = { 0, 0 },
	lives = { Config.MAX_LIVES, Config.MAX_LIVES },
	names = { "", "" },
	userIds = { 0, 0 },
	cdEnd = 0,
	winner = 0,
	waiting = {},
}
local mySlot = nil
local pauseOpen = false
local goT, hitT, dmgT, msgT = 0, 0, 0, 0

local function inMatch()
	return mySlot ~= nil and S.phase ~= "menu"
end
local function opSlot()
	return if mySlot == 1 then 2 else 1
end

local function showMsg(t, color, seconds)
	msgLabel.Text = t
	msgLabel.TextColor3 = color
	msgT = seconds or 1.3
end

local function amWaiting()
	for _, n in ipairs(S.waiting or {}) do
		if n == player.Name then
			return true
		end
	end
	return false
end

local function refreshSettings()
	for key, b in pairs(diffButtons) do
		local on = key == settings.diff
		b.BackgroundColor3 = if on then C.accent else C.panel2
		b.TextColor3 = if on then C.ink else C.fg
	end
	local s = string.format("%.1f×", settings.sens)
	sensValue.Text = s
	pSensValue.Text = s
	UserInputService.MouseDeltaSensitivity = settings.sens
end

local function render()
	local mine = mySlot
	local op = opSlot()
	hud.Visible = inMatch()
	if mine then
		scMe.Text = tostring(S.score[mine])
		scOp.Text = tostring(S.score[op])
		nmOp.Text = string.upper(S.names[op] or "")
		for i = 1, Config.MAX_LIVES do
			lvMe[i].BackgroundTransparency = if i <= S.lives[mine] then 0 else 0.8
			lvOp[i].BackgroundTransparency = if i <= S.lives[op] then 0 else 0.8
		end
	end
	-- telas
	local busyOther = S.phase ~= "menu" and not mine
	menu.Visible = not inMatch()
	endCard.Visible = inMatch() and S.phase == "over"
	pauseCard.Visible = inMatch() and pauseOpen and S.phase ~= "over"
	local waiting = amWaiting()
	btnCancel.Visible = waiting
	btnBot.Visible = not waiting
	btnPvp.Visible = not waiting
	if busyOther then
		menuNote.Text = "Partida em andamento: " .. (S.names[1] or "") .. " × " .. (S.names[2] or "") .. ". Espere ela acabar."
		menuNote.TextColor3 = C.muted
	elseif waiting then
		menuNote.Text = "Esperando outro jogador clicar em Contra Player…"
		menuNote.TextColor3 = C.accent
	elseif S.note then
		menuNote.Text = S.note
		menuNote.TextColor3 = C.bad
	else
		menuNote.Text = ""
	end
	if endCard.Visible then
		local win = S.winner == mine
		endTitle.Text = if win then "VITÓRIA" else "DERROTA"
		endTitle.TextColor3 = if win then C.good else C.bad
		endScore.Text = S.score[mine] .. " × " .. S.score[op]
	end
end

StateRE.OnClientEvent:Connect(function(st)
	local old = S
	S = st
	local oldSlot = mySlot
	mySlot = if st.userIds[1] == player.UserId then 1 elseif st.userIds[2] == player.UserId then 2 else nil
	if mySlot and oldSlot == mySlot then
		local op = opSlot()
		if st.lives[mySlot] < old.lives[mySlot] then
			dmgT = if old.lives[mySlot] - st.lives[mySlot] >= 3 then 0.9 else 0.5
		end
		if st.lives[op] == 0 and old.lives[op] > 0 then
			showMsg("+1 PONTO", C.good)
		end
		if st.lives[mySlot] == 0 and old.lives[mySlot] > 0 then
			showMsg("VOCÊ MORREU", C.bad)
		end
		if old.phase == "countdown" and st.phase == "live" then
			goT = 0.7
		end
	end
	if st.phase ~= "live" and st.phase ~= "countdown" and st.phase ~= "roundEnd" then
		pauseOpen = false
	end
	render()
end)

---------------------------------------------------------------- botões
btnBot.MouseButton1Click:Connect(function()
	ReadyRE:FireServer("bot", settings.diff)
end)
btnPvp.MouseButton1Click:Connect(function()
	ReadyRE:FireServer("pvp", settings.diff)
end)
btnCancel.MouseButton1Click:Connect(function()
	LeaveRE:FireServer()
end)
for key, b in pairs(diffButtons) do
	b.MouseButton1Click:Connect(function()
		settings.diff = key
		refreshSettings()
	end)
end
local function sensStep(d)
	settings.sens = math.clamp(math.floor((settings.sens + d) * 10 + 0.5) / 10, 0.2, 3)
	refreshSettings()
end
sensMinus.MouseButton1Click:Connect(function()
	sensStep(-0.1)
end)
sensPlus.MouseButton1Click:Connect(function()
	sensStep(0.1)
end)
pSensMinus.MouseButton1Click:Connect(function()
	sensStep(-0.1)
end)
pSensPlus.MouseButton1Click:Connect(function()
	sensStep(0.1)
end)
btnRematch.MouseButton1Click:Connect(function()
	ReadyRE:FireServer(S.mode, settings.diff)
end)
btnEndMenu.MouseButton1Click:Connect(function()
	LeaveRE:FireServer()
end)
btnBack.MouseButton1Click:Connect(function()
	pauseOpen = false
	render()
end)
btnQuit.MouseButton1Click:Connect(function()
	pauseOpen = false
	LeaveRE:FireServer()
end)

---------------------------------------------------------------- pistola em 1ª pessoa
local vm = Instance.new("Model")
vm.Name = "Pistola"
local function vmPart(size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = vm
	return { part = p, offset = cf }
end
local black = Color3.fromRGB(36, 40, 44)
local frameCol = Color3.fromRGB(26, 29, 32)
local glove = Color3.fromRGB(58, 66, 73)
local vmParts = {
	vmPart(Vector3.new(0.12, 0.13, 0.7), CFrame.new(0, 0.04, -0.05), black, Enum.Material.Metal), -- ferrolho
	vmPart(Vector3.new(0.11, 0.08, 0.6), CFrame.new(0, -0.03, -0.02), frameCol), -- armação
	vmPart(Vector3.new(0.1, 0.36, 0.15), CFrame.new(0, -0.22, 0.17) * CFrame.Angles(-0.25, 0, 0), frameCol), -- cabo
	vmPart(Vector3.new(0.05, 0.05, 0.05), CFrame.new(0, 0.12, -0.36), C.accent, Enum.Material.Neon), -- massa de mira
	vmPart(Vector3.new(0.1, 0.03, 0.03), CFrame.new(0, 0.12, 0.25), black), -- alça de mira
	vmPart(Vector3.new(0.17, 0.17, 0.2), CFrame.new(0, -0.21, 0.19) * CFrame.Angles(-0.25, 0, 0), glove), -- mão
	vmPart(Vector3.new(0.2, 0.2, 0.7), CFrame.new(-0.02, -0.33, 0.62) * CFrame.Angles(-0.25, 0, 0), glove), -- antebraço
}
local flashPart = vmPart(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.04, -0.47), Color3.fromRGB(255, 214, 120), Enum.Material.Neon, Enum.PartType.Ball)
flashPart.part.Transparency = 1
local flashLight = Instance.new("PointLight")
flashLight.Color = Color3.fromRGB(255, 200, 112)
flashLight.Range = 14
flashLight.Brightness = 0
flashLight.Parent = flashPart.part
local MUZZLE = CFrame.new(0, 0.04, -0.42)
local VM_OFFSET = CFrame.new(0.55, -0.5, -1.25)
vm.Parent = camera

local localFx = Instance.new("Folder")
localFx.Name = "EfeitosLocais"
localFx.Parent = workspace

-- traçantes (pool)
local tracers = {}
for i = 1, 24 do
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Transparency = 1
	p.Size = Vector3.new(0.06, 0.06, 1)
	p.Parent = localFx
	tracers[i] = { part = p, life = 0 }
end
local tracerNext = 1
local TRACER_LIFE = 0.09
local function tracer(from: Vector3, to: Vector3, color: Color3)
	local t = tracers[tracerNext]
	tracerNext = tracerNext % #tracers + 1
	local len = (to - from).Magnitude
	if len < 0.1 then
		return
	end
	t.part.Size = Vector3.new(0.06, 0.06, len)
	t.part.CFrame = CFrame.lookAt((from + to) / 2, to)
	t.part.Color = color
	t.part.Transparency = 0.15
	t.life = TRACER_LIFE
end

-- marcas de tiro (pool de 60 discos)
local decals = {}
for i = 1, 60 do
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.02, 0.22, 0.22)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = Color3.fromRGB(26, 22, 18)
	p.Transparency = 1
	p.Parent = localFx
	decals[i] = p
end
local decalNext = 1
local function decal(pos: Vector3, normal: Vector3)
	local p = decals[decalNext]
	decalNext = decalNext % #decals + 1
	-- o eixo do cilindro é o X: gira 90° para ele ficar na direção da normal
	p.CFrame = CFrame.lookAt(pos + normal * 0.012, pos + normal * 2) * CFrame.Angles(0, math.rad(90), 0)
	p.Transparency = 0.15
end
local function clearDecals()
	for _, p in ipairs(decals) do
		p.Transparency = 1
	end
end

EffectRE.OnClientEvent:Connect(function(shooterId, from, to, normal)
	local color = Color3.fromRGB(255, 211, 107)
	if shooterId == player.UserId then
		from = (camera.CFrame * VM_OFFSET * MUZZLE).Position -- sai da sua pistola na tela
		color = Color3.fromRGB(255, 240, 176)
	end
	tracer(from, to, color)
	if normal then
		decal(to, normal)
	end
end)

HitRE.OnClientEvent:Connect(function(head)
	hitT = 0.18
	for _, b in ipairs(hitBars) do
		b.BackgroundColor3 = if head then C.bad else Color3.new(1, 1, 1)
	end
end)

---------------------------------------------------------------- tiro e teclas
local kick, flashT, lastShot = 0, 0, 0
local function canAct()
	return inMatch() and S.phase == "live" and mySlot and S.lives[mySlot] > 0 and not pauseOpen
end
local function tryShoot()
	if not canAct() then
		return
	end
	if player:GetAttribute("Reloading") then
		return
	end
	if (player:GetAttribute("Mag") or 0) <= 0 then
		ReloadRE:FireServer()
		return
	end
	local t = os.clock()
	if t - lastShot < Config.FIRE_INTERVAL then
		return
	end
	lastShot = t
	kick = 1
	flashT = 0.045
	FireRE:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not processed then
			tryShoot()
		end
	elseif input.KeyCode == Enum.KeyCode.R and not processed then
		if inMatch() then
			ReloadRE:FireServer()
		end
	elseif input.KeyCode == Enum.KeyCode.P and not processed then
		if inMatch() and S.phase ~= "over" then
			pauseOpen = not pauseOpen
			render()
		end
	end
end)

---------------------------------------------------------------- laço por quadro
local lastRound = 0
local defaultJump = nil
RunService.RenderStepped:Connect(function(dt)
	-- movimento: travado na contagem/fim de rodada; Shift anda devagar (tiro preciso)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if defaultJump == nil then
			defaultJump = { hum.JumpPower, hum.JumpHeight }
		end
		local frozen = inMatch() and (S.phase ~= "live" or (mySlot and S.lives[mySlot] <= 0))
		local slow = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		local ws = if frozen then 0 elseif slow then Config.WALK_SPEED else Config.RUN_SPEED
		if hum.WalkSpeed ~= ws then
			hum.WalkSpeed = ws
		end
		local jp = if frozen then 0 else defaultJump[1]
		if hum.JumpPower ~= jp then
			hum.JumpPower = jp
			hum.JumpHeight = if frozen then 0 else defaultJump[2]
		end
	end

	-- contagem 3 → 0
	if inMatch() and S.phase == "countdown" then
		local n = math.max(1, math.ceil(S.cdEnd - workspace:GetServerTimeNow()))
		cdLabel.Text = tostring(n)
		if lastRound ~= S.cdEnd then
			lastRound = S.cdEnd
			clearDecals()
		end
	elseif goT > 0 then
		goT -= dt
		cdLabel.Text = "0"
	else
		cdLabel.Text = ""
	end

	-- munição
	local mag = player:GetAttribute("Mag") or Config.MAG
	ammoLabel.Text = mag .. " / " .. Config.MAG
	reloadLabel.Visible = player:GetAttribute("Reloading") == true

	-- marcador, vinheta e mensagem
	hitT = math.max(0, hitT - dt)
	hitm.Visible = hitT > 0
	dmgT = math.max(0, dmgT - dt)
	dmgFx.BackgroundTransparency = 1 - math.min(1, dmgT * 1.6) * 0.45
	msgT = math.max(0, msgT - dt)
	msgLabel.TextTransparency = if msgT > 0 then 0 else 1
	msgLabel.TextStrokeTransparency = if msgT > 0 then 0.4 else 1

	-- mouse: aparece só com alguma tela aberta
	local screenOpen = menu.Visible or endCard.Visible or pauseCard.Visible
	if UserInputService.MouseIconEnabled ~= screenOpen then
		UserInputService.MouseIconEnabled = screenOpen
	end
	xh.Visible = not screenOpen

	-- pistola: segue a câmera com recuo, recarga e balanço ao andar
	kick = math.max(0, kick - dt * 9)
	flashT = math.max(0, flashT - dt)
	local reloading = player:GetAttribute("Reloading") == true
	local rl = if reloading then math.sin(os.clock() * 3.6 % math.pi) else 0
	local speed = 0
	if char and char.PrimaryPart then
		local v = char.PrimaryPart.AssemblyLinearVelocity
		speed = Vector3.new(v.X, 0, v.Z).Magnitude / Config.RUN_SPEED
	end
	local bob = os.clock() * 9
	local showGun = inMatch() and mySlot ~= nil and S.lives[mySlot] > 0
	local base = camera.CFrame
		* VM_OFFSET
		* CFrame.new(math.sin(bob) * 0.012 * speed, math.abs(math.cos(bob)) * 0.012 * speed - rl * 0.25, kick * 0.12)
		* CFrame.Angles(kick * 0.22 - rl * 0.5, 0, rl * 0.6)
	for _, e in ipairs(vmParts) do
		e.part.CFrame = base * e.offset
		e.part.Transparency = if showGun then 0 else 1
	end
	flashPart.part.CFrame = base * flashPart.offset
	flashPart.part.Transparency = if flashT > 0 and showGun then 0.1 else 1
	flashLight.Brightness = if flashT > 0 then 3 else 0

	-- traçantes somem em 90 ms
	for _, t in ipairs(tracers) do
		if t.life > 0 then
			t.life -= dt
			t.part.Transparency = if t.life > 0 then 1 - (t.life / TRACER_LIFE) * 0.85 else 1
		end
	end
end)

refreshSettings()
render()
