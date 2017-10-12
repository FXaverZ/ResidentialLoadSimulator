function loadprofile = flexload_allocation_heatpumps(energy, runtimelist, ...
	timepoints, timebase, temperature, delta_time_max_energy, ontime_min_per_day,...
	mean_vary_power, sigma_vary_power)
%FLEXLOAD_ALLOCATION_TEMPERATUR Summary of this function goes here
%   energy in kWh, timebase in Seconds, delta_time_max_energy and
%   ontime_min_per_day in hours
%   Detailed explanation goes here

temp_cut_off = 10;
delta_time_max_energy = delta_time_max_energy * 60 * 60; %how much time should be left in off state in seconds, also at the most cold day
ontime_min_per_day = ontime_min_per_day * 60 * 60; %how long should the heatpump be running at minimum each day
min_power = 1300; %minimal power value in W
% max_power_single_phase = 1200; %max power for single phase operation in W
power_factor = 1;
power_stepsize = 250; %stepsize of the used power values

for b=1:size(runtimelist,1)
	if strcmp(runtimelist(b,1),'GRT')
		continue;
	end
	if b == 1
		ontime = flexload_runtimelist2ontime(runtimelist(b,3:end),timepoints);
	else
		ontime = ontime & flexload_runtimelist2ontime(runtimelist(b,3:end),timepoints);
	end
end

ontime_day = reshape(ontime,365*24*60*60/(365*timebase),[]);

ontime_day = sum(ontime_day)'*timebase; % On-Time each day of year in seconds
ontime_day(ontime_day<(ontime_min_per_day/timebase)) = ontime_min_per_day/timebase;

energy = energy * 1000 * 60 * 60;  % energy in Ws;
energy_fix = energy * (ontime_min_per_day/(24*60*60));
energy_var = energy - energy_fix;

temperature(temperature>temp_cut_off) = temp_cut_off;
temperature = -temperature + temp_cut_off;
factor_day = temperature/sum(temperature);
energy_var_day = energy_var * factor_day; % daily energy in Ws
energy_fix_day = energy_fix * (1/365);
max_factor = max(factor_day);
idx_max_factor = find(factor_day == max_factor);
ontime_max = ontime_day(idx_max_factor) - delta_time_max_energy - ontime_min_per_day;

power = energy_var_day(idx_max_factor)/ontime_max;

% Power in "power_stepsize" steps and a possible reduction factor:
if power > power_stepsize
	power = ceil(power*power_factor/power_stepsize)*power_stepsize;
end
power = power + vary_parameter(mean_vary_power, sigma_vary_power);
if power < min_power
	power = min_power;
end

runtime_day = ((energy_var_day + energy_fix_day) / power);
delta_ontime = ontime - [ontime(end);ontime(1:end-1)];
delta_ontime = reshape(delta_ontime,1440,[]);
ontime_new = zeros(size(ontime));
for a=1:numel(runtime_day)
	runtime = runtime_day(a)/timebase;
	
	delta_day = delta_ontime(:,a);
	idxs_on = find(delta_day > 0);
	idxs_off = find(delta_day < 0);
	
	% fill up the first runperiod:
	ion = idxs_on(1);
	ioff = idxs_off(find(ion<idxs_off,1));
	if isempty(ioff)
		ioff = 1440+idxs_off(1);
	end
	rt = ioff - ion;
	if rt > runtime
		ioff = ion + runtime;
		rt = runtime;
	end
	rt = round(rt);
	if rt == 0
		continue;
	end
	if (a-1)*1440 + ioff > numel(ontime_new)
		ontime_new(((a-1)*1440+ion):end) = 1;
		rt1 = round((a-1)*1440 + ioff - numel(ontime_new));
		ontime_new(1:rt1) = 1;
	else
		ontime_new((a-1)*1440+(ion:ioff)) = 1;
	end
	runtime = runtime - rt;
	ont = ontime_day(a)/timebase;
	fac = runtime / ont;
	
	for b=2:numel(idxs_on)
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
%
% % if power < max_power_single_phase
% % 	idx = vary_parameter([1;2;3],ones(3,1)*100/3,'List');
% % 	loadprofile = zeros(numel(ontime_new),3);
% % 	loadprofile(:,idx)=ontime_new * power;
% % else
% % 	loadprofile = repmat(ontime_new,[1,3]);
% % 	loadprofile = loadprofile * power / 3;
% % end
if ~isempty(find(strcmp(runtimelist(:,1),'GRT'), 1))
	for b=1:size(runtimelist,1)
		if b == 1
			ontime_alt = flexload_runtimelist2ontime(runtimelist(b,3:end),timepoints);
		else
			ontime_alt = ontime_alt & flexload_runtimelist2ontime(runtimelist(b,3:end),timepoints);
		end
	end
	delta_ontime = ontime_alt - [ontime_alt(end);ontime_alt(1:end-1)];
	delta_ontime = reshape(delta_ontime,1440,[]);
	for a=1:numel(runtime_day)
		rt_old = sum(ontime_new(1440*(a-1)+(1:1440)));
		rt_new = sum(ontime_alt(1440*(a-1)+(1:1440)));
		if rt_old <= rt_new
			ontime_new(1440*(a-1)+(1:1440)) = 0;
			delta_day = delta_ontime(:,a);
			idxs_on = find(delta_day > 0);
			idxs_off = find(delta_day < 0);
			fac = rt_old / rt_new;
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
	end
end

loadprofile = ontime_new * power;

% % Create figure
% figure1 = figure;
% % Create axes
% axes1 = axes('Parent',figure1);
% hold(axes1,'on');
% % Create plot
% plot([ontime,0.8*ontime_new,1.2*ontime_alt]);
% % Uncomment the following line to preserve the X-limits of the axes
% xlim(axes1,[0 4*1440]);
% box(axes1,'on');
% % Set the remaining axes properties
% set(axes1,'XGrid','on','XTick',...
% 	0:60:4*1440,...
% 	'YGrid','on');

fprintf(['(Power=',num2str(power/1000),'kW)']);