function ontime = flexload_runtimelist2ontime(runtimelist, timepoints)
%FLEXLOAD_RUNTIMELIST2ONTIME Summary of this function goes here
%   Detailed explanation goes here

ontime = zeros(size(timepoints));
for a=1:4:numel(runtimelist)
	if isempty(runtimelist{a}) || isnan(runtimelist{a})
		return;
	end
	daylist = (runtimelist{a}:1:runtimelist{a+1});
	on_timelist = daylist+runtimelist{a+2} - 1;
	off_timelist = daylist+runtimelist{a+3} - 1;
	
	for b=1:numel(daylist)
		idx = ((timepoints < off_timelist(b) - 1) ...
			& (timepoints >= daylist(b)) & (timepoints < (daylist(b)+1))) ...
			| ((timepoints >= on_timelist(b)) & (timepoints <= off_timelist(b)) ...
			& (timepoints >= daylist(b)) & (timepoints < (daylist(b)+1)));
		ontime(idx) = 1;
	end
end

