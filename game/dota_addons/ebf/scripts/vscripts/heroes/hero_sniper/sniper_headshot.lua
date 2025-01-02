sniper_headshot = class({})

function sniper_headshot:GetIntrinsicModifierName()
	return "modifier_sniper_headshot_handler"
end

modifier_sniper_headshot_handler = class({})
LinkLuaModifier( "modifier_sniper_headshot_handler","heroes/hero_sniper/sniper_headshot.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_sniper_headshot_handler:OnCreated()
	self:OnRefresh()
end

function modifier_sniper_headshot_handler:OnRefresh()
	self.duration = self:GetSpecialValueFor("slow_duration")
	self.damage = self:GetSpecialValueFor("damage")
	self.proc_chance = self:GetSpecialValueFor("proc_chance")
	self.proc_chance_min_range = self:GetSpecialValueFor("proc_chance_min_range")
	self.proc_chance_max_range = self:GetSpecialValueFor("proc_chance_max_range")
	self.proc_chance_max_chance = self:GetSpecialValueFor("proc_chance_max_chance")
	
	if not IsEntitySafe( self.assassinate ) then
		self.assassinate = self:GetCaster():FindAbilityByName("sniper_assassinate")
	end
	if IsEntitySafe(self.assassinate) then
		self.assassinate_damage = self.assassinate:GetSpecialValueFor("headshot_damage")
	else
		self.assassinate_damage = 0
	end
	self.recordsProc = {}
end

function modifier_sniper_headshot_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
	return funcs
end

function modifier_sniper_headshot_handler:OnAttackLanded( params )
	if IsServer() and params.attacker == self:GetParent() and self.recordsProc[params.record] then
		local caster = params.attacker
		local target = params.target
		local ability = self:GetAbility()
		
		for i = 1, self.recordsProc[params.record] do
			Timers:CreateTimer( 0.1*(i-1), function() EmitSoundOn( "Hero_Sniper.MKG_impact", target ) end )
		end
		if self.assassinate_damage > 0 and not params.attacker:GetAttackData( params.record ).abilityIndex and ( self.recordsProc[params.record] > 1 or target:HasModifier("modifier_sniper_headshot_root") ) then
			self.assassinate:LaunchAssassinate( params.target, self.assassinate_damage / 100 )
		end
		target:AddNewModifier(caster, self:GetAbility(), "modifier_sniper_headshot_root", {Duration = self.duration * self.recordsProc[params.record]})
		self.recordsProc[params.record] = nil
	end
end

function modifier_sniper_headshot_handler:GetModifierPreAttack_BonusDamage(params)
	if IsServer() and params.attacker and params.target then
		local caster = params.attacker
		local target = params.target
		
		local damage = self.damage
		local duration = self.duration
		local chance = self:GetSpecialValueFor("proc_chance")
		local maxChance = self:GetSpecialValueFor("proc_chance_max_chance")
		if maxChance > 0 then
			local chanceDiff = (maxChance - chance)
			local rangeDiff = self.proc_chance_min_range - self.proc_chance_max_range 
			local distance = CalculateDistance( caster, target ) - self.proc_chance_max_range
			chance = chance + chanceDiff * math.min( math.max( 0, (rangeDiff-distance)/rangeDiff ), 1 )
		end
		local power = 0
		while chance > 0 do
			if caster:RollPRNG( chance ) then
				damage = damage + self.damage
				power = power + 1
			end
			chance = chance - 100
		end
		
		if caster == self:GetCaster() and power > 0 then
			self.recordsProc[params.record] = power
			return damage
		end
	end
end

function modifier_sniper_headshot_handler:IsPurgeException()
	return false
end

function modifier_sniper_headshot_handler:IsPurgable()
	return false
end

function modifier_sniper_headshot_handler:IsHidden()
	return true
end

modifier_sniper_headshot_root = class({})
LinkLuaModifier( "modifier_sniper_headshot_root","heroes/hero_sniper/sniper_headshot.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_sniper_headshot_root:OnRefresh()
	self.miss_chance = self:GetSpecialValueFor("miss_chance")
end

function modifier_sniper_headshot_root:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_sniper_headshot_root:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_sniper_headshot_handler:GetModifierMiss_Percentage()
	return self.miss_chance
end

function modifier_sniper_headshot_root:GetEffectName()
	return "particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf"
end

function modifier_sniper_headshot_root:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_sniper_headshot_root:IsDebuff()
	return true
end