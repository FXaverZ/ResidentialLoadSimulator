function Summary = update_summary_for_device_profiles(Model, Devices, Households, ...
				Summary, Season, Weekday)
%UPDATE_SUMMARY_DEVICE_PROFILES Summary of this function goes here
%   Detailed explanation goes here

% Erstellt von:            Franz Zeilinger - 03.12.2012
% Letzte Änderung durch:   Franz Zeilinger - 05.12.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

% Extrahieren des aktuellen Ergebnisses:
resu = Households.Result.(typ);

% Gruppenzusammenhang auslesen und für spätere Auswertung zusammenstellen:
groups = {...
	Model.Device_Groups.gr_avd.Name{1,1}, Model.Device_Groups.gr_avd.Members(:,1);...
	Model.Device_Groups.gr_off.Name{1,1}, Model.Device_Groups.gr_off.Members(:,1);...
	Model.Device_Groups.gr_kit.Name{1,1}, ...
	    {Model.Device_Groups.gr_kit.Members{:,1},'ki_mic'}';...
	Model.Device_Groups.gr_hwa.Name{1,1}, Model.Device_Groups.gr_hwa.Members(:,1);...
	Model.Device_Groups.gr_ill.Name{1,1}, ...
	    {Model.Device_Groups.gr_ill.Members{:,1},'illumi'}';...
	Model.Device_Groups.gr_mis.Name{1,1}, ...
	    {Model.Device_Groups.gr_mis.Members{:,1},'dev_de'}';...
	};
grp_allocation = {};
for i=1:size(groups,1)
	grpname = groups{i,1};
	grpmemb = groups{i,2};
	for j=1:numel(grpmemb)
		grp_allocation(end+1,:) = {grpmemb{j}, grpname}; %#ok<AGROW>
	end
end

% Erstmalige Indizierung:
if isempty(Summary)
	Summary.Devices.Power = [];
end

% Summenprofile der einzelnen Geräte bilden:
for i=1:size(resu,1)
	dev_name = resu{i,1};
	% Anzahl der Benutzer aktualisieren:
	num_user_add = Households.Statistics.(typ).Number_Persons(i);
	if isfield(Summary.Devices.Power, Season) && ...
			isfield(Summary.Devices.Power.(Season), Weekday) && ...
			isfield(Summary.Devices.Power.(Season).(Weekday), 'Number_User')
		num_user = Summary.Devices.Power.(Season).(Weekday).Number_User;
	else
		num_user = 0;
	end
	num_user = num_user + num_user_add;
	Summary.Devices.Power.(Season).(Weekday).Number_User = num_user;
	% Summenprofile der Gerätetypen bilden:
	for j=1:numel(dev_name)
		idx = find(strcmp(dev_name{j},grp_allocation(:,1)));
		if isempty(idx)
			grpname = dev_name{j};
		else
			grpname = grp_allocation{idx,2};
		end
		pow_add = resu{i,3}(j,:);
		if isfield(Summary.Devices.Power, Season) && ...
				isfield(Summary.Devices.Power.(Season), Weekday) && ...
				isfield(Summary.Devices.Power.(Season).(Weekday),grpname)
			pow = Summary.Devices.Power.(Season).(Weekday).(grpname);
		else
			pow = zeros(size(pow_add));
		end
		pow = pow + pow_add;
		Summary.Devices.Power.(Season).(Weekday).(grpname) = pow;
	end
end
end

