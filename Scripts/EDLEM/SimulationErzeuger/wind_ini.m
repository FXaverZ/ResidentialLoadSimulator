% Funktion to load the Factors for the Lookup Table of the wind turbine

t=load([pwd, '\Windturbine\Cp_factor_wind.mat']);
Cp_factor_wind = t.Cp_factor_wind;

t=load([pwd, '\Windturbine\rotor_diameter.mat']);
rotor_diameter = t.rotor_diameter;

t=load([pwd, '\Windturbine\el_power.mat']);
el_power = t.el_power;

t=load([pwd, '\Windturbine\hub_height.mat']);
hub_height = t.hub_height;
