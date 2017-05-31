function Households = pick_results_households_for_device_profiles (Households, ...
	Time, Devices, Result)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Erstellt von:            Franz Zeilinger - 03.12.2012
% Letzte Änderung durch:   Franz Zeilinger - 05.12.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

% Auslesen der Zuordnung der Geräte zu den Haushalten:
hh_devices = Households.Devices.(typ).Allocation;
dev_var_names = Devices.Elements_Varna;
% die Einzelgeräte-Lastprofile der einzelnen Haushalte zusammensetzen (mit Hilfe
% der zuvor ermittelten Indizes der einzelnen Geräte):
Households.Result.(typ) = cell(size(hh_devices,2),7);
power_ra = Result.Raw_Data.Households_Power;
for i=1:size(hh_devices,2)
	% Indizes der einzelnen Geräte des aktuellen Haushalts:
	idx = squeeze(hh_devices(:,i,:));
	% wieviele einzelne Geräte hat dieser Haushalt?:
	num_dev = sum(sum(idx>0));
	% Ein Ergebnisarray erstellen:
	dev_hh_power = zeros(num_dev,Time.Number_Steps);
	dev_hh_names =cell(num_dev,1);
	dev_hh_devices =cell(num_dev,1);
	dev_counter = 1;
	for j=1:size(idx,1)
		% die einzelnen Geräte durchgehen:
		dev_idxs = idx(j,:);
		dev_idxs(dev_idxs == 0) = [];
		for k=1:numel(dev_idxs)
			dev_idx = dev_idxs(k);
			dev_hh_power(dev_counter,:) = sum(squeeze(power_ra(:,j,dev_idx,:)));
			dev = Devices.(dev_var_names{j})(dev_idx);
			dev_hh_devices{dev_counter} = dev;
			dev_hh_names{dev_counter} = dev_var_names{j};
			dev_counter = dev_counter + 1;
		end
	end
	Households.Result.(typ){i,1} = dev_hh_names;
	Households.Result.(typ){i,2} = dev_hh_devices;
	Households.Result.(typ){i,3} = dev_hh_power;
	Households.Result.(typ){i,6} = sum(dev_hh_power);
end
end

