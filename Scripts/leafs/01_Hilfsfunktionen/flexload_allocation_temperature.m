function loadprofile = flexload_allocation_temperature(energy, runtimelist, ...
	timepoints, timebase, temperature)
%FLEXLOAD_ALLOCATION_TEMPERATUR Summary of this function goes here
%   energy in kWh, timebase in Seconds
%   Detailed explanation goes here

temp_cut_off = 15;
delta_time_max_energy = 2 * 60 * 60; %how much time should be left in off state in seconds, also at the most cold day
max_power_single_phase = 2300; %max power for single phase operation in W
power_factor = 2/3;
power_stepsize = 2500; %stepsize of the used power values

ontime = flexload_runtimelist2ontime(runtimelist, timepoints);
ontime_day = reshape(ontime,1440,[]);
ontime_day = sum(ontime_day)'*timebase; % On-Time each day of year in seconds
energy = energy * 1000 * 60 * 60;  % energy in Ws;

temperature(temperature>temp_cut_off) = temp_cut_off;
temperature = -temperature + temp_cut_off;
factor_day = temperature/sum(temperature);
energy_day = energy * factor_day; % daily energy in Ws
max_factor = max(factor_day);
idx_max_factor = find(factor_day == max_factor);
ontime_max = ontime_day(idx_max_factor) - delta_time_max_energy;

power = energy_day(idx_max_factor)/ontime_max;
% Power in "power_stepsize" steps and a possible reduction factor:
if power > power_stepsize
power = round(power*power_factor/power_stepsize)*power_stepsize;
else
	power = power*power_factor;
end

runtime_day = (energy_day / power) / timebase;
delta_ontime = ontime - [ontime(end);ontime(1:end-1)];
delta_ontime = reshape(delta_ontime,1440,[]);
ontime_new = zeros(size(ontime));
for a=1:numel(runtime_day)
	runtime = runtime_day(a);
	ont = ontime_day(a)/timebase;
	fac = runtime / ont;
	delta_day = delta_ontime(:,a);
	idxs_on = find(delta_day > 0);
	idxs_off = find(delta_day < 0);
	
	for b=1:numel(idxs_on)
		ion = idxs_on(b);
		ioff = idxs_off(find(ion<idxs_off,1));
		if isempty(ioff)
			ioff = 1440+idxs_off(1);
		end
		rt = ioff - ion;
		rt = round(rt * fac);
		if rt == 0
			continue;
		end
		ioff = ion + rt;
		if (a-1)*1440 + ioff > numel(ontime_new)
			ontime_new(((a-1)*1440+ion):end) = 1;
			rt1 = (a-1)*1440 + ioff - numel(ontime_new);
			ontime_new(1:rt1) = 1;
		else
			ontime_new((a-1)*1440+(ion:ioff)) = 1;
		end
	end
end

if power < max_power_single_phase
	idx = vary_parameter([1;2;3],ones(3,1)*100/3,'List');
	loadprofile = zeros(numel(ontime_new),3);
	loadprofile(:,idx)=ontime_new * power;
else
	loadprofile = repmat(ontime_new,[1,3]);
	loadprofile = loadprofile * power / 3;
end

fprintf(['(Power=',num2str(power/1000),'kW) ']);