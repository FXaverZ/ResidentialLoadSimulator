function loadprofile = flexload_allocation_powerandpower (energy, runtimelist_pow1, ...
	runtimelist_pow2, timepoints, timebase, power)
%FLEXLOAD_ALLOCATION_POWERANDTEMPERATURE Summary of this function goes here
%   Detailed explanation goes here

ontime_power1 = flexload_runtimelist2ontime(runtimelist_pow1, timepoints);
ontime_power2 = flexload_runtimelist2ontime(runtimelist_pow2, timepoints);

ontime_day_power1 = reshape(ontime_power1,1440,[]);
ontime_day_power1 = sum(ontime_day_power1)'*timebase; % On-Time each day of year in seconds
ontime_year_power1 = sum(ontime_day_power1); % %overall on-time of the whole year in seconds 

ontime_day_power2 = reshape(ontime_power2,1440,[]);
ontime_day_power2 = sum(ontime_day_power2)'*timebase; % On-Time each day of year in seconds
ontime_year_power2 = sum(ontime_day_power2); % %overall on-time of the whole year in seconds 

share_power_temperature = ontime_year_power1 / (ontime_year_power2 + ontime_year_power1);

energy_power1 = energy * share_power_temperature;
energy_power2 = energy * (1 - share_power_temperature);
fprintf(['1st powerbased part (',num2str(energy_power1),'kWh): ']);
loadprofile_power1 = flexload_allocation_power(energy_power1,...
	runtimelist_pow1, timepoints, timebase, power);
fprintf(['2nd powerpased part (',num2str(energy_power2),'kWh): ']);
loadprofile_power2 = flexload_allocation_power(energy_power2,...
	runtimelist_pow2, timepoints, timebase, power);
loadprofile = loadprofile_power1 + loadprofile_power2;
end

