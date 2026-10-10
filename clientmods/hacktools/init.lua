-- hacktools/init.lua

local BASE_SPEED = 4.317

local function apply_speed(bps)
	local mult = bps / BASE_SPEED
	local lp = core.localplayer
	if not lp then
		return false, "Sin jugador local"
	end

	local ok, err = pcall(function()
		if lp.set_physics_override then
			lp:set_physics_override({
				speed_walk = mult,
				speed_fast = mult * 2,
				speed_crouch = mult * 0.5,
				speed_climb = mult,
			})
		elseif lp.physics_override then
			lp.physics_override.speed_walk = mult
			lp.physics_override.speed_fast = mult * 2
			lp.physics_override.speed_crouch = mult * 0.5
			lp.physics_override.speed_climb = mult
		else
			core.settings:set("movement_speed_walk", mult)
			core.settings:set("movement_speed_fast", mult * 2)
			core.settings:set("movement_speed_crouch", mult * 0.5)
			core.settings:set("movement_speed_climb", mult)
		end
	end)

	if not ok then
		return false, "Error: " .. tostring(err)
	end
	return true, "Velocidad: " .. bps .. " bloques/s"
end

core.register_chatcommand("speed", {
	params = "<bloques_por_segundo>",
	description = "Velocidad en bloques/segundo",
	func = function(param)
		local bps = tonumber(param)
		if not bps or bps <= 0 then
			return false, "Uso: .speed <bloques_por_segundo>"
		end
		return apply_speed(bps)
	end
})

core.register_chatcommand("hackhelp", {
	description = "Ayuda de hacktools",
	func = function()
		return true,
			"Comandos:\n" ..
			"  .speed <bps>  - Velocidad en bloques/segundo\n" ..
			"  .hackhelp     - Esta ayuda"
	end
})