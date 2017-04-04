local Scriptname,Version,Author,LVersion = "TRUSt in my Kalista","v1.0","TRUS","7.6"
if myHero.charName ~= "Kalista" then return end
keybindings = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6}


function GetInventorySlotItem(itemID)
	assert(type(itemID) == "number", "GetInventorySlotItem: wrong argument types (<number> expected)")
	for _, j in pairs({ ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}) do
		if myHero:GetItemData(j).itemID == itemID and myHero:GetSpellData(j).currentCd == 0 then return j end
	end
	return nil
end

function UseBotrk()
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(300, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(300,"AD"))
	if target then 
		local botrkitem = GetInventorySlotItem(3153) or GetInventorySlotItem(3144)
		if botrkitem then
			Control.CastSpell(keybindings[botrkitem],target.pos)
		end
	end
end

class "Kalista"
require "DamageLib"
function Kalista:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local orbwalkername = ""
	if _G.SDK then
		orbwalkername = "IC'S orbwalker"
		_G.SDK.Orbwalker:OnPreMovement(function(arg) 
			if blockmovement then
				arg.Process = false
			end
		end)
		
		_G.SDK.Orbwalker:OnPostAttack(function() 
			local combomodeactive = _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]
			local harassactive = _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]
			if (combomodeactive or harassactive) then
				self:CastQ(_G.SDK.Orbwalker:GetTarget())
			end
		end)
		
		_G.SDK.Orbwalker:OnPreAttack(function(arg) 		
			if blockattack then
				arg.Process = false
			end
		end)
	elseif _G.GOS then
		orbwalkername = "Noddy orbwalker"
		
	else
		orbwalkername = "Orbwalker not found"
		
	end
	PrintChat(Scriptname.." "..Version.." - Loaded...."..orbwalkername)
end
blockattack = false
blockmovement = false

local lastpick = 0
--[[Spells]]
function Kalista:LoadSpells()
	Q = {Range = 1150, width = 40, Delay = 0.25, Speed = 2100}
	E = {Range = 1000}
end

function Kalista:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "TRUStinymyKalista", name = Scriptname})
	
	--[[Combo]]
	self.Menu:MenuElement({id = "UseBOTRK", name = "Use botrk", value = true})
	self.Menu:MenuElement({id = "DrawE", name = "Draw Killable with E", value = true})
	self.Menu:MenuElement({id = "DrawColor", name = "Color for Killable circle", color = Draw.Color(0xBF3F3FFF)})
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	self.Menu.Combo:MenuElement({id = "comboUseQ", name = "Use Q", value = true})
	self.Menu.Combo:MenuElement({id = "comboUseE", name = "Use E", value = true})
	
	--[[Harass]]
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	self.Menu.Harass:MenuElement({id = "harassUseQ", name = "Use Q", value = true})
	self.Menu.Harass:MenuElement({id = "harassUseELasthit", name = "Use E Harass when lasthit", value = true})
	self.Menu.Harass:MenuElement({id = "harassUseERange", name = "Use E when out of range", value = true})
	self.Menu.Harass:MenuElement({id = "HarassMinEStacks", name = "Min E stacks: ", value = 3, min = 0, max = 10})
	self.Menu.Harass:MenuElement({id = "harassMana", name = "Minimal mana percent:", value = 30, min = 0, max = 101, identifier = "%"})
	
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so (thx Noddy for this one)", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5, identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function Kalista:Tick()
	if myHero.dead or (not _G.SDK and not _G.GOS) then return end
	local combomodeactive = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") 
	local harassactive = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") 
	local canmove = (_G.SDK and _G.SDK.Orbwalker:CanMove()) or (_G.GOS and _G.GOS:CanMove())
	local canattack = (_G.SDK and _G.SDK.Orbwalker:CanAttack()) or (_G.GOS and _G.GOS:CanAttack())
	local currenttarget = (_G.SDK and _G.SDK.Orbwalker:GetTarget()) or (_G.GOS and _G.GOS:GetTarget())
	local HarassMinMana = self.Menu.Harass.harassMana:Value()
	
	
	if combomodeactive and self.Menu.UseBOTRK:Value() then
		UseBotrk()
	end
	
	if ((combomodeactive) or (harassactive and myHero.maxMana * HarassMinMana * 0.01 < myHero.mana)) and (canmove or not currenttarget) then
		self:CastQ(currenttarget,combomodeactive or false)
		self:CastE(currenttarget,combomodeactive or false)
	end
	
	if (harassactive or combomodeactive) and self:CanCast(_E) then
		if self.Menu.Harass.harassUseERange:Value() then 
			self:UseERange()
		end
		if self.Menu.Harass.harassUseELasthit:Value() then
			
		end
	end
	
end


local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}



function EnableMovement()
	--unblock movement
	blockattack = false
	blockmovement = false
	if _G.GOS then
		_G.GOS.BlockAttack = false
		_G.GOS.BlockMovement = false
	end
	onetimereset = true
	castSpell.state = 0
end

function ReturnCursor(pos)
	Control.SetCursorPos(pos)
	DelayAction(EnableMovement,0.1)
end

function LeftClick(pos)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
	DelayAction(ReturnCursor,0.05,{pos})
end

function Kalista:CastSpell(spell,pos)
	local customcast = self.Menu.CustomSpellCast:Value()
	if not customcast then
		Control.CastSpell(spell, pos)
		return
	else
		local delay = self.Menu.delay:Value()
		local ticker = GetTickCount()
		if castSpell.state == 0 and ticker > castSpell.casting then
			castSpell.state = 1
			castSpell.mouse = mousePos
			castSpell.tick = ticker
			if ticker - castSpell.tick < Game.Latency() then
				--block movement
				blockattack = true
				blockmovement = true
				if _G.GOS then
					_G.GOS.BlockAttack = true
					_G.GOS.BlockMovement = true
				end
				Control.SetCursorPos(pos)
				Control.KeyDown(spell)
				Control.KeyUp(spell)
				DelayAction(LeftClick,delay/1000,{castSpell.mouse})
				castSpell.casting = ticker + 500
			end
		end
	end
end


function Kalista:GetBuffs(unit)
	self.T = {}
	for i = 0, unit.buffCount do
		local Buff = unit:GetBuff(i)
		if Buff.count > 0 then
			table.insert(self.T, Buff)
		end
	end
	return self.T
end

function Kalista:GetSpears(unit, buffname)
	for K, Buff in pairs(self:GetBuffs(unit)) do
		if Buff.name:lower() == "kalistaexpungemarker" then
			return Buff.count
		end
	end
	return 0
end

function Kalista:UseERange()
	local heroeslist = (_G.SDK and _G.SDK.ObjectManager:GetEnemyHeroes(1100)) or (_G.GOS and _G.GOS:GetEnemyHeroes())
	local useE = false
	for i, hero in pairs(heroeslist) do
		if self:GetSpears(hero) >= self.Menu.Harass.HarassMinEStacks:Value() then
			if myHero.pos:DistanceTo(hero.pos)<1100 and myHero.pos:DistanceTo(hero:GetPrediction(math.huge,0.25).pos) < 600 then
				return
			end
			if myHero.pos:DistanceTo(hero.pos)<1100 and myHero.pos:DistanceTo(hero:GetPrediction(math.huge,0.25).pos) > 1100 then
				useE = true
			end
		end
	end
	if useE then
		Control.CastSpell(_E)
	end
end

function Kalista:GetETarget()
	self.KillableHeroes = {}
	local heroeslist = (_G.SDK and _G.SDK.ObjectManager:GetEnemyHeroes(1200)) or (_G.GOS and _G.GOS:GetEnemyHeroes())
	local level = myHero:GetSpellData(_E).level
	for i, hero in pairs(heroeslist) do
		if self:GetSpears(hero) > 0 then 
			local EDamage = getdmg("E",hero,myHero)
			if hero.health and EDamage and EDamage > hero.health and myHero.pos:DistanceTo(hero.pos)<E.Range then
				table.insert(self.KillableHeroes, hero)
			end
		end
	end
	return self.KillableHeroes
end

--[[CastQ]]
function Kalista:CastQ(target, combo)
	if (not _G.SDK and not _G.GOS) then return end
	local target = target or (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.Range, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.Range,"AD"))
	if target and target.type == "AIHeroClient" and self:CanCast(_Q) and ((combo and self.Menu.Combo.comboUseQ:Value()) or (combo == false and self.Menu.Harass.harassUseQ:Value())) and target:GetCollision(Q.Width,Q.Speed,Q.Delay) == 0 then
		local castPos = target:GetPrediction(Q.Speed,Q.Delay)
		local newpos = myHero.pos:Extended(castPos,math.random(100,300))
		self:CastSpell(HK_Q, newpos)
	end
end


--[[CastE]]
function Kalista:CastE(target,combo)
	if #self:GetETarget() > 0 then
		Control.CastSpell(HK_E)
	end
end



function Kalista:IsReady(spellSlot)
	return myHero:GetSpellData(spellSlot).currentCd == 0 and myHero:GetSpellData(spellSlot).level > 0
end

function Kalista:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Kalista:CanCast(spellSlot)
	return self:IsReady(spellSlot) and self:CheckMana(spellSlot)
end

function Kalista:Draw()
	if self.Menu.DrawE:Value() then
		local ETarget = self:GetETarget()
		for i, hero in pairs(ETarget) do
			Draw.Circle(hero.pos, 60, 3, self.Menu.DrawColor:Value())
		end
	end
end

function OnLoad()
	Kalista()
end