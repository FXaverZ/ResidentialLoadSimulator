function Households = postprocess_results_for_annual_profiles_device_level (Households, Devices, Model, Time)
%POSTPROCESS_RESULTS_FOR_SINGLE_DEVICE_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 16.11.2012
% Letzte Änderung durch:   Franz Zeilinger - 18.12.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;

% Inhalt der einzelnen Spalent der Ergebnis-Arrays zusammenfassen:
Households.Result.Content = {...
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
	dev_var_names = Households.Result.(typ){i,1};
	dev_instances = Households.Result.(typ){i,2};
	dev_powers = Households.Result.(typ){i,3};
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
		% Geräteinstanz (für Eigenschaften):
		dev_instance = dev_instances{idx(j)};
		% Schaltzeiten ermitteln:
		dev_p = squeeze(sum(squeeze(dev_powers(idx(j),:,:))));
		% Wann ist Gerät in Betrieb, ersetzen mit Nennleistung:
		dev_p(dev_p >= dev_instance.Power_Nominal) = ...
			dev_instance.Power_Nominal;
		delta = dev_p(2:end) - dev_p(1:end-1);
		t_start = (find(delta>0)' + 1)*Time.Base/60;
		t_end = (find(delta<0)')*Time.Base/60;
		if numel(t_end) == 0 || numel(t_start) == 0
			% für den seltenen Fall, dass ein Kühlgerät 24h durchläuft, ein leeres
			% Array speichern: 
			dev_schedules{idx(j)} = [];
			dev_powers(idx(j),:,:) = zeros(size(dev_powers(idx(j),:,:)));
			dev_energy(idx(j)) = 0;
			% Gerät wurde erledigt:
			idxs_to_do(idxs_to_do == idx(j)) = [];
			continue;
		end
		if dev_p(1) > 0
			% Falls Gerät schon läuft, abschätzen der Startzeit (negative Minuten!)
			t_start = [t_end(1) - (t_end(2) - t_start(1)); t_start]; %#ok<AGROW>
		end
		if dev_p(end) > 0
			% Falls Gerät noch läuft, abschätzen der Endzeit (Minuten > 1440!)
			t_end(end+1) = t_start(end) + (t_end(end) - t_start(end-1)); %#ok<AGROW>
			t_end = reshape(t_end,size(t_start));
		end
		% Einsatzplan zusammenstellen:
		Time_Schedule_Day = [t_start, t_end, ...
			repmat(dev_instance.Power_Nominal, size(t_start))];
		
		% Ergebnisse abspeichern:
		dev_energy(idx(j)) = sum(sum(dev_powers(idx(j),:,:)))*Time.Base/(1000*3600);% Energieaufnahme in 24h
		dev_schedules{idx(j)} = Time_Schedule_Day;  % Einsatzplan
		
		% Gerät wurde erledigt:
		idxs_to_do(idxs_to_do == idx(j)) = [];
	end
	
	% nun die Geräte bearbeiten, die ein Programm abfahren (Geschirrspüler,
	% Wäschetrockner, Waschmaschinen:
	idx = find(strcmp(dev_var_names, 'washer') | strcmp(dev_var_names, 'dishwa') |...
		strcmp(dev_var_names, 'cl_dry'));
	for j = 1:numel(idx)
		dev_instance = dev_instances{idx(j)};
		% entsprechende Daten auslesen:
		t_start = dev_instance.Time_Start_Day;
		t_end = dev_instance.Time_Stop_Day;
		loadcrv_idx = dev_instance.Picked_Loadcurves;
		
		% Einsatzplan abspeichern, entspricht hier Startzeit, Endzeit (also Ablauf
		% komplettes Programm) und Index des aktiven Programms zu dieser Zeit (diese
		% kann über 
		%    dev_instance.Loadcurve_Struct.(['Loadcurve_',num2str(Index Programm)])
		% ausgelesen werden):
		Time_Schedule_Day = [t_start, t_end, loadcrv_idx];
		dev_schedules{idx(j)} = Time_Schedule_Day;
		
		% Leistungsaufnahme über der Zeit:
		dev_energy(idx(j)) = sum(sum(dev_powers(idx(j),:,:)))*Time.Base/(1000*3600); % Energieaufnahme in 24h
		
		% Gerät wurde erledigt:
		idxs_to_do(idxs_to_do == idx(j)) = [];
	end
	
	% Die restliche Geräte abarbeiten:
	for j = 1:numel(idxs_to_do)
		dev_power = dev_powers(idxs_to_do(j),:,:);
		dev_instance = dev_instances{idxs_to_do(j)};
		Time_Schedule_Day = dev_instance.Time_Schedule_Day;
		if ~isempty(Time_Schedule_Day)
			% Blindleistung entfernen (letzte Spalte):
			Time_Schedule_Day = Time_Schedule_Day(:,1:3);
% 			% auf ganze Minuten bringen:
% 			Time_Schedule_Day(:,1) = ceil(Time_Schedule_Day(:,1));
% 			Time_Schedule_Day(:,2) = floor(Time_Schedule_Day(:,2));
		end
		
		% Ergebnisse abspeichern:
		dev_schedules{idxs_to_do(j)} = Time_Schedule_Day;
		dev_energy(idxs_to_do(j)) = sum(sum(dev_power))*Time.Base/(1000*3600);
	end
	
	% Geräteklassen der untenstehenden Liste zusammenführen:
	to_do = {...
		'illum', 'illumi';...
		'div_d', 'dev_de';...
		'stove', 'stove_';...
		'oven_', 'oven__';...
		'micro', 'microw';...
		'ki_mi', 'ki_mic';...
% 		'hea_r', 'hea_ra';...
% 		'hea_w', 'hea_wp';...
% 		'wa_he', 'wa_hea';...
% 		'wa_bo', 'wa_boi';...
		};
	for j=1:size(to_do,1)
		% alle gleichen Geräte finden:
		idx = find(strncmp(dev_var_names, to_do{j,1},5));
		if isempty(idx)
			continue;
		end
		% leeres Gerätearray erstellen:
		dev_instance = dev_instances{idx(1)}.empty(0,0);
		% die zusammengefassten Geräteinstanzen in das Array schreiben:
		try
		for k=1:numel(idx)
			dev_instance(k) = dev_instances{idx(k)};
		end
		catch %#ok<CTCH>
			% Wenn es zu einem Fehler kommt, wurde versucht, unterschiedliche
			% Geräteklassen in ein gemeinsames Array zu stecken --> das funktioniert
			% nicht. In dem Fall ein Cell-Array mit den einzelnen Geräteinstanzen
			% erstellen:
			dev_instance = cell(0,0);
			for k=1:numel(idx)
				dev_instance{k} = dev_instances{idx(k)};
			end
		end
		% Summenleistung der zusammengefassten Geräte ermitteln:
		dev_power = squeeze(sum(dev_powers(idx,:,:),1));
		
		% die alten Einträge im Ergenis-Cell-Array entfernen...
		dev_instances(idx) = [];
		dev_powers(idx,:,:) = [];
		dev_var_names(idx) = [];
		dev_schedules(idx) = [];
		dev_energy(idx) = [];
		% ... und die neu ermittelten Werte eintragen:
		dev_instances{end+1} = dev_instance; %#ok<AGROW>
		dev_powers(end+1,:,:) = dev_power;   %#ok<AGROW>
		dev_var_names{end+1} = to_do{j,2};   %#ok<AGROW>
		dev_schedules{end+1} = [];           %#ok<AGROW>
		dev_energy(end+1) = sum(sum(dev_power))*Time.Base/(1000*3600); %#ok<AGROW>
	end
	
	% In Hauptstruktur wieder abspeichern:
	Households.Result.(typ){i,1} = dev_var_names;
	Households.Result.(typ){i,2} = dev_instances;
	Households.Result.(typ){i,3} = dev_powers;
	Households.Result.(typ){i,4} = dev_schedules;
	Households.Result.(typ){i,5} = dev_energy;
	Households.Result.(typ){i,7} = sum(dev_energy);
end

% Nun noch Arrays mit Statistiken erstellen, um den Modelloutput überprüfen zu
% können: 
% Auslesen der Zuordnung der Geräte zu den Haushalten:
hh_devices = Households.Devices.(typ).Allocation;
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

