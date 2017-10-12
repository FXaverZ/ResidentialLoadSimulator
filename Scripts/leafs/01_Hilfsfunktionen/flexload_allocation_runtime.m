function loadprofile = flexload_allocation_runtime(energy, runtimelist, timepoints, timebase)
% energy in kWh
% FLEXLOAD_ALLOCATION_RUNTIME Summary of this function goes here
%   Detailed explanation goes here

max_power_single_phase = 4000; %max power for single phase operation in W

ontime = flexload_runtimelist2ontime(runtimelist, timepoints);

sumtime = sum(ontime)*timebase; %time on in seconds
energy_ws = energy * 60 * 60 * 1000; %energy in Ws
power = energy_ws / sumtime; %Power in W during ontime

if power < max_power_single_phase
	idx = vary_parameter([1;2;3],ones(3,1)*100/3,'List');
	loadprofile = zeros(numel(ontime),3);
	loadprofile(:,idx)=ontime * power;
else
	loadprofile = repmat(ontime,[1,3]);
	loadprofile = loadprofile * power / 3;
end

fprintf(['(Power=',num2str(power/1000),'kW) ']);

