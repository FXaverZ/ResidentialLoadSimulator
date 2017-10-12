function loadprofile = flexload_allocation_power (energy, runtimelist, ...
	timepoints, timebase, power)
%FLEXLOAD_ALLOCATION_POWER Summary of this function goes here
%   energy in kWh, timebase in Seconds, power in kW
%   Detailed explanation goes here

% temp_cut_off = 5;
delta_time_max_energy = 60 * 60; %how much time should be left in off state in seconds, also at the most cold day
max_power_single_phase = 4000; %max power for single phase operation in W
factor_power_input_to_reality = 0.8; %how much power should be used of the given value in the input file?

power = factor_power_input_to_reality * power * 1000; % real used power in W
energy = energy * 1000 * 60 * 60;  % energy in Ws;

ontime = flexload_runtimelist2ontime(runtimelist, timepoints);
ontime_day = reshape(ontime,1440,[]);
ontime_day = sum(ontime_day)'*timebase; % On-Time each day of year in seconds
ontime_year = sum(ontime_day); % %overall on-time of the whole year in seconds 

ontime_energy = energy / power; % overall on-time which is result of the given energy and power value

%check, if the input conditions (power, energy) can be met by the ontimes
%given by the load profile (runtimelist):
if ontime_year < ontime_energy
	loadprofile = [];
	fprintf(['Error! With the given power of ',...
		num2str(power/(factor_power_input_to_reality*1000)),...
		'kW the given energy can not be achieved!']);
	return;
end

fac = ontime_energy / ontime_year;
delta_ontime = ontime - [ontime(end);ontime(1:end-1)];
delta_ontime = reshape(delta_ontime,1440,[]);
ontime_new = zeros(size(ontime));
for a=1:numel(ontime_day)
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

fprintf(['(Power=',num2str(power/1000),'kW; Runtime factor = ',num2str(fac*100),'%%) ']);

end

