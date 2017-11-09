function loadprofile = flexload_allocation_powerandtemperature (energy, runtimelist_pow, ...
	runtimelist_temp, timepoints, timebase, temperature, power)
%FLEXLOAD_ALLOCATION_POWERANDTEMPERATURE Summary of this function goes here
%   energy in kWh, timebase in Seconds, power in kW
%   Detailed explanation goes here

ontime_power = flexload_runtimelist2ontime(runtimelist_pow, timepoints);
ontime_temperature = flexload_runtimelist2ontime(runtimelist_temp, timepoints);

ontime_day_power = reshape(ontime_power,1440,[]);
ontime_day_power = sum(ontime_day_power)'*timebase; % On-Time each day of year in seconds
ontime_year_power = sum(ontime_day_power); % %overall on-time of the whole year in seconds 

ontime_day_temperature = reshape(ontime_temperature,1440,[]);
ontime_day_temperature = sum(ontime_day_temperature)'*timebase; % On-Time each day of year in seconds
ontime_year_temperature = sum(ontime_day_temperature); % %overall on-time of the whole year in seconds 

share_power_temperature = ontime_year_power / (ontime_year_temperature + ontime_year_power);

energy_power = energy * share_power_temperature;
energy_temperature = energy * (1 - share_power_temperature);
fprintf(['powerbased part (',num2str(energy_power),'kWh): ']);
loadprofile_power = flexload_allocation_power(energy_power,...
	runtimelist_pow, timepoints, timebase, power);
fprintf(['temperaturebased part (',num2str(energy_temperature),'kWh): ']);
loadprofile_temperature = flexload_allocation_temperature(energy_temperature,...
	runtimelist_temp, timepoints, timebase, temperature);
loadprofile = loadprofile_power + loadprofile_temperature;
end

