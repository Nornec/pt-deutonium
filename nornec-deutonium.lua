print("")
print("[ Deutonium Mod, By Nornec")
print("[ An in-joke-made-real, with my partner and I, about Deuterium Oxide")
print("[ Deutonium is a fictional, intensely radioactive crystal of DEUT.")
print("")

local kelvin_conversion = 273.15
local creation_temp = 50 + kelvin_conversion
local critical_temp = 500 + kelvin_conversion
local subcritical_pressure = 5
local subcritical_temp = 100 + kelvin_conversion
local fissile_bounds = 500000
local fissile_strength = 499990
local heat_xfer_amt = 80
local adjacent_heat_xfer_amt = 0.008
local dutm_life = 150

local function get_table_length(t)
  local count = 0
  for _ in pairs(t) do 
    count = count + 1 
  end
  return count
end

local function part_set_temp(part, temp)
  sim.partProperty(part, "temp", temp)
end

local function part_heat_up(part, amount)
  sim.partProperty(part, "temp", sim.partProperty(part, "temp") + amount)
end

local function part_hurt(part)
  sim.partProperty(part, "life", sim.partProperty(part, "life") - 1)
end

local function radio_activate(source, part, energy)
  
  if energy == elem.DEFAULT_PT_NEUT then
    part_heat_up(source, heat_xfer_amt/2)
  elseif energy == elem.DEFAULT_PT_PROT then
    part_heat_up(source, heat_xfer_amt)
  end

  if sim.partProperty(source, "temp") > critical_temp then  
		part_x, part_y = sim.partPosition(part)
		new_part = sim.partCreate(-3, part_x, part_y, energy)
		part_set_temp(new_part, sim.partProperty(source, "temp"))
    part_heat_up(source, 80)
		part_hurt(source)
  end

end

local function check_neighbors(source, x, y, n_type)
  neighbors = sim.partNeighbors(x, y, 1, n_type)
  if get_table_length(neighbors) > 0 then
    if n_type == elem.NOR_PT_DUTM then
      for idx, part in pairs(neighbors) do
        part_heat_up(part, adjacent_heat_xfer_amt)
      end
    else
			rand = math.random(0, fissile_bounds)
			if rand > fissile_strength then
				part_x, part_y = sim.partPosition(source)
				sim.partCreate(-3, part_x, part_y, n_type)
			end

			for idx, part in pairs(neighbors) do
				radio_activate(source, part, n_type)
			end
    end
  end
end

local function dutm_update(i, x, y, s, nt)
  check_neighbors(i, x, y, elem.DEFAULT_PT_NEUT)
  check_neighbors(i, x, y, elem.DEFAULT_PT_PROT)
  check_neighbors(i, x, y, elem.NOR_PT_DUTM)

  if sim.pressure(x/4,y/4) > subcritical_pressure or sim.partProperty(i, "temp") > subcritical_temp then
    rand = math.random(0,fissile_bounds)
    if rand > fissile_strength - (sim.partProperty(i, "temp") * 3) then
      sim.partCreate(-3, x, y, elem.DEFAULT_PT_NEUT)
      part_hurt(i)
    end
  end
end

local function dutm_create(i, x, y, s, nt)
  sim.partProperty(i, "life", dutm_life)
end

local dutm = elem.allocate("NOR", "DUTM")
elem.element(dutm, elem.element(elem.DEFAULT_PT_DEUT))
elem.property(dutm, "Name", "DUTM")
elem.property(dutm, "Description", "Deutonium. Extremely radioactive. Releases NEUT under heat or pressure. Slightly warming.")
elem.property(dutm, "Color", 0x3333CC)
elem.property(dutm, "Flammable", 0)
elem.property(dutm, "Explosive", 0)
elem.property(dutm, "Properties", elem.TYPE_PART+elem.PROP_RADIOACTIVE+elem.PROP_NEUTPASS+elem.PROP_LIFE_KILL)
elem.property(dutm, "Weight", 80)
elem.property(dutm, "Gravity", 0.6)
elem.property(dutm, "Diffusion", 0)
elem.property(dutm, "AirLoss", 0.8)
elem.property(dutm, "AirDrag", 0.04)
elem.property(dutm, "Falldown", 1)
elem.property(dutm, "Temperature", creation_temp)
elem.property(dutm, "Update", dutm_update)
elem.property(dutm, "Create", dutm_create)