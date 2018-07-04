if GetObjectName(GetMyHero()) ~= "Pyke" then return end
local castSpell = {state = 0, tick = LocalGetTickCount(), casting = LocalGetTickCount() - 1000, mouse = mousePos}
function CastSpell(spell,pos,range,delay)
    local range = range or _huge
    local delay = delay or 250
    local ticker = LocalGetTickCount()

	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + LocalGameLatency() and pos:ToScreen().onScreen then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < LocalGameLatency() then
			LocalControlSetCursorPos(pos)
			LocalControlKeyDown(spell)
			LocalControlKeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					LocalControlSetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,LocalGameLatency()/1000)
		end
		if ticker - castSpell.casting > LocalGameLatency() then
			LocalControlSetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

function CastSpellMM(spell,pos,range,delay)
local range = range or _huge
local delay = delay or 250
local ticker = LocalGetTickCount()
	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + LocalGameLatency() then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < LocalGameLatency() then
			local castPosMM = pos:ToMM()
			LocalControlSetCursorPos(castPosMM.x,castPosMM.y)
			LocalControlKeyDown(spell)
			LocalControlKeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					LocalControlSetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,LocalGameLatency()/1000)
		end
		if ticker - castSpell.casting > LocalGameLatency() then
			LocalControlSetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

function ReleaseSpell(spell,pos,range,delay)
    local delay = delay or 250
    local ticker = LocalGetTickCount()
	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + LocalGameLatency() then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < LocalGameLatency() then
			if not pos:ToScreen().onScreen then
				pos = myHero.pos + Vector(myHero.pos,pos):Normalized() * _random(530,760)
				LocalControlSetCursorPos(pos)
				LocalControlKeyUp(spell)
			else
				LocalControlSetCursorPos(pos)
				LocalControlKeyUp(spell)
			end
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					LocalControlSetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,LocalGameLatency()/1000)
		end
		if ticker - castSpell.casting > LocalGameLatency() then
			LocalControlSetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

local 	BDE = MenuElement({id = "BDE", name = "Brain.exe "..myHero.charName, type = MENU})
		BDE:MenuElement({id = "Combo", name = "Combo", type = MENU})
		BDE:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
		BDE:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
		BDE:MenuElement({id = "Prediction", name = "Hitchance Manager", type = MENU})

class "Pyke"	
require('Inspired')
require('DeftLib')
require('IPrediction')
function Pyke:Menu()
	BDE.Combo:MenuElement({id = "useQ", name = "Use Q", value = true})
    BDE.Combo:MenuElement({id = "useE", name = "Use E", value = true})
    BDE.Combo:MenuElement({id = "order", name = "Skill Order", value = 1, drop = {"Q first","E first"}})
	
    BDE.Killsteal:MenuElement({id = "useR", name = "Use R to killsteal", value = true})

	BDE.Drawings:MenuElement({id = "drawQ", name = "Draw Q", value = false})
	BDE.Drawings:MenuElement({id = "drawmaxQ", name = "Draw max Q", value = true})
    BDE.Drawings:MenuElement({id = "drawE", name = "Draw E", value = true})
	BDE.Drawings:MenuElement({id = "drawR", name = "Draw R", value = true})
	
	BDE.Prediction:MenuElement({id = "QhitChance", name = "Q", value = 1, drop = {"1: Normal","2: Punish Movementation","3: Punish Basic Attacks","4: Punish Spell Casting","5: Undodgeable"}})
	BDE.Prediction:MenuElement({id = "EhitChance", name = "E", value = 2, drop = {"1: Normal","2: Punish Movementation","3: Punish Basic Attacks","4: Punish Spell Casting","5: Undodgeable"}})
	BDE.Prediction:MenuElement({id = "RhitChance", name = "R", value = 3, drop = {"1: Normal","2: Punish Movementation","3: Punish Basic Attacks","4: Punish Spell Casting","5: Undodgeable"}})
end

function Pyke:Tick()
	if Game.IsChatOpen() then return end
	if self.Qchannel then
		SetAttacks(false)
	else
		SetAttacks(true)
	end
	self:Qmanager()
	if myHero.dead then return end
	if GetMode() == "Combo" then
		self:Combo()
	end
	self:Killsteal()
end

function Pyke:Combo()
	if BDE.Combo.useE:Value() then
		self:Elogic()
	end
	if BDE.Combo.useQ:Value() then
		self:Qlogic()
	end
end

function Pyke:Killsteal()
	if LocalGameCanUseSpell(_R) == 0 and self.Qchannel == false and castSpell.state == 0 and LocalGameTimer() - self.Rtimer > 0.3 then
		for i = 1, LocalGameHeroCount() do
        	local unit = LocalGameHero(i)
			if unit.isEnemy and unit.IsValidTarget and not unit.dead and not unit.isImmortal and unit.isTargetable then
				local myLevel = myHero.levelData.lvl
				local BaseRdamage = ({0,0,0,0,0,190,240,290,340,390,440,475,510,545,580,615,635,655})[myLevel]
				local multiplier = myHero.bonusDamage * 0.6
				local Rdmg = BaseRdamage + multiplier
				local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, unit, self.R.range, self.E.delay, self.E.speed, self.E.width, false)
				if hitChance and hitChance >= BDE.Prediction.RhitChance:Value() and Rdmg >= unit.health then
					self:CastR(unit,aimPosition)
				end
			end
        end
    end
end

function Pyke:Qlogic()
	if LocalGameCanUseSpell(_Q) == 0 and castSpell.state == 0 then
		local target = GetTarget(1100,"AD")
		if target then
			local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, target, 1100, 0.25 + LocalGameLatency()/1000, 2000, 70, true)
			local hitChance2, aimPosition2 = HPred:GetHitchance(myHero.pos, target, 1100, 1, 2000, 70, false)
			if hitChance and hitChance2 then
				if GetDistance(myHero.pos,aimPosition2) < 1200 then
					self:TriggerQ(target)
				end
				if LocalGameTimer() - self.Qtimer > 0.5 then
					if hitChance >= BDE.Prediction.QhitChance:Value() and self.Qchannel == true then
						self:ReleaseQ(target,aimPosition)
					end
				end
			end
		end
	end
end

function Pyke:TriggerQ(target)
	local trigger = true
	if BDE.Combo.useE:Value() and LocalGameCanUseSpell(_E) == 0 and GetDistance(target.pos,myHero.pos) < 550 and BDE.Combo.order:Value() == 2 then trigger = false end
	if LocalGameCanUseSpell(_Q) == 0 and self.Qchannel == false and trigger == true then
		LocalControlKeyDown(HK_Q)
	end
end

function Pyke:ReleaseQ(target,QcastPos)
	if LocalGameTimer() - OnWaypoint(target).time > 0.05 and (((LocalGameTimer() - OnWaypoint(target).time < 0.15 or LocalGameTimer() - OnWaypoint(target).time > 1.0) and OnVision(target).state == true) or (OnVision(target).state == false)) and GetDistance(myHero.pos,QcastPos) < self.Q.range - target.boundingRadius then
		ReleaseSpell(HK_Q,QcastPos,self.Q.range,100)
	end
end

function Pyke:Qmanager()
	if self.Qchannel == true then
		self.Q.range = 400 + (LocalGameTimer() - (self.Qtimer + 0.5)) * 1400
		if self.Q.range > 1100 then self.Q.range = 1100 end
	end
	local QchannelBuff = GetBuffData(myHero,"PykeQ")
	if self.Qchannel == false and QchannelBuff.count > 0 then
		self.Qtimer = LocalGameTimer()
		self.Qchannel = true
	end
	if self.Qchannel == true and QchannelBuff.count == 0 then
		self.Qchannel = false
		if LocalControlIsKeyDown(HK_Q) == true then
			self.Q.range = 400
			LocalControlKeyUp(HK_Q)
		end
	end
	if LocalControlIsKeyDown(HK_Q) == true and self.Qchannel == false then
		DelayAction(function()
			if LocalControlIsKeyDown(HK_Q) == true and self.Qchannel == false then
				self.Q.range = 400
				LocalControlKeyUp(HK_Q)
			end
		end,0.3)
	end
	if LocalControlIsKeyDown(HK_Q) == true and LocalGameCanUseSpell(_Q) ~= 0 then
		DelayAction(function()
			if LocalControlIsKeyDown(HK_Q) == true then
				self.Q.range = 400
				LocalControlKeyUp(HK_Q)
			end
		end,0.01)
	end
end

function Pyke:Elogic()
	if LocalGameCanUseSpell(_E) == 0 and self.Qchannel == false and castSpell.state == 0 then
		local Qtarget = GetTarget(1100,"AD")
		if Qtarget and BDE.Combo.useQ:Value() and LocalGameCanUseSpell(_Q) == 0 and GetDistance(Qtarget.pos,myHero.pos) < 1100 and Qtarget:GetCollision(self.Q.width, self.Q.speed, self.Q.delay) == 0 and BDE.Combo.order:Value() == 1 then return end
		local target = GetTarget(self.E.range,"AD")
		if target then
			local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, target, self.E.range, self.E.delay, self.E.speed, self.E.width, false)
			if hitChance and hitChance >= BDE.Prediction.EhitChance:Value() then
				self:CastE(target,aimPosition)
			end
		end
	end
end

function Pyke:CastE(target,EcastPos)
	if LocalGameTimer() - OnWaypoint(target).time > 0.05 and (LocalGameTimer() - OnWaypoint(target).time < 0.125 or LocalGameTimer() - OnWaypoint(target).time > 1.25) and GetDistance(myHero.pos,EcastPos) < self.E.range then
		if GetDistance(myHero.pos,EcastPos) <= 550 then
			CastSpell(HK_E,EcastPos,self.E.range)
		end
	end
end

function Pyke:CastR(target,RcastPos)
	if LocalGameTimer() - OnWaypoint(target).time > 0.05 and GetDistance(myHero.pos,RcastPos) < self.R.range then
		CastSpell(HK_R,RcastPos,self.R.range)
		self.Rtimer = LocalGameTimer()
	end
end

function Pyke:Draw()
	if myHero.dead then return end
	if BDE.Drawings.drawQ:Value() and LocalGameCanUseSpell(_Q) == 0 then
		LocalDrawCircle(myHero.pos, 400, 3, LocalDrawColor(255,000,000,255))
	end
	if BDE.Drawings.drawmaxQ:Value() and LocalGameCanUseSpell(_Q) == 0 then
		LocalDrawCircle(myHero.pos, 1100, 3, LocalDrawColor(255,000,000,255))
	end
	if BDE.Drawings.drawE:Value() and LocalGameCanUseSpell(_E) == 0 then
		LocalDrawCircle(myHero.pos, self.E.range, 3, LocalDrawColor(255,000,255,000))
	end
	if BDE.Drawings.drawR:Value() and LocalGameCanUseSpell(_R) == 0 then
		LocalDrawCircle(myHero.pos, self.R.range, 3, LocalDrawColor(255,255,000,000))
	end
end
