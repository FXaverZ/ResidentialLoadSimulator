function Households = postprocess_results_for_device_profiles (Households, ...
	Time, Devices, Result)
%POSTPROCESS_RESULTS_FOR_SINGLE_DEVICE_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 16.11.2012
% Letzte Änderung durch:   Franz Zeilinger - 28.11.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

% Falls noch keine Zuordnung getroffen wurde (parallele Simulation!) diese nun
% vornehmen:
if ~isfield(Households, 'Devices_Power') || ~isfield(Households.Devices_Power, typ)
	% Auslesen der Zuordnung der Geräte zu den Haushalten:
	hh_devices = Households.Devices.(typ);
	dev_var_names = Devices.Elements_Varna;
	% die Einzelgeräte-Lastprofile der einzelnen Haushalte zusammensetzen (mit Hilfe
	% der zuvor ermittelten Indizes der einzelnen Geräte):
	Households.Devices_Power.(typ) = cell(size(hh_devices,2),7);
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
		Households.Devices_Power.(typ){i,1} = dev_hh_names;
		Households.Devices_Power.(typ){i,2} = dev_hh_devices;
		Households.Devices_Power.(typ){i,3} = dev_hh_power;
		Households.Devices_Power.(typ){i,6} = sum(dev_hh_power);
		Households.Devices_Power.(typ){i,7} = sum(sum(dev_hh_power))/60000;
	end
end

% Inhalt der einzelnen Spalent der Ergebnis-Arrays zusammenfassen:
Households.Devices_Power.Content = {...
	'Variablennamen für Geräte',...
	'Instanz des jeweiligen Geräts',...
	'Array mit Leistungsaufnahme der einzelnen Geräte [W]',...
	'Einsatzpläne der Geräte [Start  Ende  W]',...
	'Tagesenergieaufnahme der einzelnen Geräte [kWh]',...
	'Gesamlastgang des Haushalts [W]',...
	'Tagesenergieaufnahme des Haushalts [kWh]',...
	};

% Weiter Aufbereiten der Daten:
% Zunächst die Listen mit Einschalt- und Ausschaltzeiten anpassen bzw. erstellen: 
for i=1:Households.Statistics.(typ).Number;
	% wieder auslesen der wichtigen Datenlisten:
	dev_var_names = Households.Devices_Power.(typ){i,1};
	dev_instances = Households.Devices_Power.(typ){i,2};
	dev_powers = Households.Devices_Power.(typ){i,3};
	% anlegen einer neuen mit den Zeitplänen:
	dev_schedules = cell(numel(dev_var_names),1);
	dev_energy = zeros(numel(dev_var_names),1);
	
	% Liste mit den noch zu behandlenden Geräten (wenn abgearbeitet, wird der
	% entsprechende Eintrag gelöscht, also zuerst die Sonderfälle und dann die
	% Allgemeinen):
	idxs_to_do = 1:numel(dev_var_names);
	
	% jetzt die Kühlgeräte bearbeiten, da diese keinen Einstatzplan bei der
	% Simulation erstellen: dazu zunächst nach Kühlgeräten suchen:
	idx = find(strcmp(dev_var_names, 'refrig') | strcmp(dev_var_names, 'freeze'));
	% Für die einzelnen Kühlgeräte eine Liste mit Startzeiten erstellen (ähnlich wie
	% für alle anderen Geräte):
	for j = 1:numel(idx)
		% Leistungsaufnahme über der Zeit:
		dev_power = dev_powers(idx(j),:);
		% Geräteinstanz (für Eigenschaften):
		dev_instance = dev_instances{idx(j)};
		% Wann ist Gerät in Betrieb, ersetzen mit Nennleistung:
		dev_power(dev_power >= dev_instance.Power_Nominal) = ...
			dev_instance.Power_Nominal;
		% Schaltzeiten ermitteln:
		delta = dev_power(2:end) - dev_power(1:end-1);
		t_start = find(delta>0)' + 1;
		t_end = find(delta<0)';
		if numel(t_end) == 0 || numel(t_start) == 0
			% für den seltenen Fall, dass ein Kühlgerät 24h durchläuft, ein leeres
			% Array speichern: 
			dev_schedules{idx(j)} = [];
			dev_powers(idx(j),:) = zeros(size(dev_power));
			dev_energy(idx(j)) = 0;
			% Gerät wurde erledigt:
			idxs_to_do(idxs_to_do == idx(j)) = [];
			continue;
		end
		if dev_power(1) > 0
			% Falls Gerät schon läuft, abschätzen der Startzeit (negative Minuten!)
			t_start = [t_end(1) - (t_end(2) - t_start(1)); t_start]; %#ok<AGROW>
		end
		if dev_power(end) > 0
			% Falls Gerät noch läuft, abschätzen der Endzeit (Minuten > 1440!)
			t_end(end+1) = t_start(end) + (t_end(end) - t_start(end-1)); %#ok<AGROW>
		end
		% Einsatzplan zusammenstellen:
		Time_Schedule_Day = [t_start, t_end, ...
			repmat(dev_instance.Power_Nominal, size(t_start))];
		
		% Ergebnisse abspeichern:
		dev_powers(idx(j),:) = dev_power;           % angepasste Leistung
		dev_energy(idx(j)) = sum(dev_power)*1/60000;% Energieaufnahme in 24h
		dev_schedules{idx(j)} = Time_Schedule_Day;  % Einsatzplan
		
		% Gerät wurde erledigt:
		idxs_to_do(idxs_to_do == idx(j)) = [];
	end
	
	% nun die Geräte berarbeiten, die ein Programm abfahren (Geschirrspüler,
	% Wäschetrockner, Waschmaschinen:
	idx = find(strcmp(dev_var_names, 'washer') | strcmp(dev_var_names, 'dishwa') |...
		strcmp(dev_var_names, 'cl_dry'));
	
	% Die restliche Geräte abarbeiten:
	for j = 1:numel(idxs_to_do)
		dev_power = dev_powers(idxs_to_do(j),:);
		dev_instance = dev_instances{idxs_to_do(j)};
		Time_Schedule_Day = dev_instance.Time_Schedule_Day;
		% Blindleistung entfernen (letzte Spalte):
		Time_Schedule_Day = Time_Schedule_Day(:,1:3);
		% auf Ganz Minuten bringen:
		Time_Schedule_Day(:,1) = ceil(Time_Schedule_Day(:,1));
		Time_Schedule_Day(:,2) = floor(Time_Schedule_Day(:,2));
		
		% Ergebnisse abspeichern:
		dev_schedules{idxs_to_do(j)} = Time_Schedule_Day;
		dev_energy(idxs_to_do(j)) = sum(dev_power)*1/60000;
	end
	% In Hauptstruktur wieder abspeichern:
	Households.Devices_Power.(typ){i,3} = dev_powers;
	Households.Devices_Power.(typ){i,4} = dev_schedules;
	Households.Devices_Power.(typ){i,5} = dev_energy;
end

% Nun noch Arrays mit Statistiken erstellen, um den Modelloutput überprüfen zu
% können: 
% Auslesen der Zuordnung der Geräte zu den Haushalten:
hh_devices = Households.Devices.(typ);
dev_var_names = Devices.Elements_Varna;

% Anzahl der einzlenen Geräte je Haushalt ermitteln:
hh_devices(hh_devices>0) = 1;
hh_devices = sum(hh_devices,3);

% Nun verschiedene Gruppen zusammfassen:
to_do = {...
	'illum', 'illumi';...
	'div_d', 'dev_de';...
	'ki_mi', 'ki_mic';...
	};
for i=1:size(to_do,1)
	idx = strncmp(dev_var_names,to_do{i,1},5);
	sum_dev = sum(hh_devices(idx,:));
	hh_devices(idx,:) = [];
	hh_devices(end+1,:)=sum_dev; %#ok<AGROW>
	dev_var_names(idx) = [];
	dev_var_names{end+1} = to_do{i,2}; %#ok<AGROW>
end
Households.Statistics.(typ).Number_Devices = hh_devices;
Households.Statistics.(typ).Var_Names_Devices = dev_var_names;
end

