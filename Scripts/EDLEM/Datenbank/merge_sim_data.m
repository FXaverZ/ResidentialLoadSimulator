%Script, um Einzelsimulationsdaten zusammenzuführen (zu einer Datenbank):

% Franz Zeilinger - 09.04.2011

clear;
%------------------------------------------------------------------------------------
% Definitionsteil
%------------------------------------------------------------------------------------
% Wieviele Datensätze pro Einzelfile? (um bei Laden nicht allzusehr den
% Arbeitsspeicher zu belasten...)
setti.max_num_data_set = 50;
% Wieviele Datensätze maximal in Datenbank?
setti.max_num_data_set_hh_total = Inf;
setti.max_num_data_set_gena_total = Inf;

% Ordner, in dem die Quelldaten abgelegt wurden:
files.source.path = [pwd,filesep,'Quelldaten'];
files.source.path_load = [files.source.path,filesep,'Lastprofile (sec)'];
files.source.path_sola = [files.source.path,filesep,'Wetterdaten PV'];
files.source.path_wind = [files.source.path,filesep,'Wetterdaten Wind'];
files.sep = ' - '; %Seperator im Dateinamen

setti.name_database = 'EDLEM_Datenbank_2.0';

%------------------------------------------------------------------------------------
% Pfad zu den Klassendefinitionsdateien hinzufügen:
addpath(pwd,filesep,'Klassen');

% Ordner, in dem die Datenbank gespeichert werden soll:
files.target.path = [pwd,filesep,setti.name_database];
% Ordner, in dem bereits in die Datenbank eingelesene Quelldateien verschoben werden:
files.source.path_load_processed = [files.source.path_load,' - processed'];
if ~isdir(files.source.path_load_processed)
	mkdir(files.source.path_load_processed);
end
files.source.path_gene_sola_proc = [files.source.path_sola,' - processed'];
if ~isdir(files.source.path_gene_sola_proc)
	mkdir(files.source.path_gene_sola_proc);
end
files.source.path_gene_wind_proc = [files.source.path_wind,' - processed'];
if ~isdir(files.source.path_gene_wind_proc)
	mkdir(files.source.path_gene_wind_proc);
end

% Ist bereits eine Datenbank vorhanden?
setti.add_data_mode = false;
try
	load([files.target.path,filesep,setti.name_database,'.mat']);
	user_response = questdlg(['Sollen die Daten zur vorhandenen Datenbank ',...
		'hinzugefügt werden?'],'Behandlung vorhandener Datenbank',...
		'Ja', 'Nein', 'Abbrechen','Ja');
	switch user_response
		case 'Ja'
			setti.add_data_mode = true;
		case 'Nein'
			setti.add_data_mode = false;
		otherwise
			return;
	end
	drawnow;
catch ME
end

% Definitionen der verschiedenen möglichen Datentypen:
setti.seasons =   {'Summer'; 'Winter'; 'Transi'};  % Typen der Jahreszeiten
setti.weekdays =  {'Workda'; 'Saturd'; 'Sunday'};  % Typen der Wochentage
setti.households = {...     % Definition der Haushaltskategorien:
	'sing_vt';...          %     (aus simulation_single_cycle_for_load_profiles.m)
	'coup_vt';...          % EDLEM-Haushalte (bzw. ADRES)
	'sing_pt';...
	'coup_pt';...
	'sing_rt';...
	'coup_rt';...
	'fami_2v';...
	'fami_1v';...
	'fami_rt';...
	% 	'home_1';...           % aDSM-Haushaltsdefinition
	% 	'home_2';...
	% 	'home_3';...
	% 	'hom_4p';...
	% 	'flat_1';...
	% 	'flat_2';...
	% 	'flat_3';...
	% 	'fla_4p';...
	};

% Leerarrays für Indexinformation speichern & Ordnerstruktur aufbauen:
if ~isdir(files.target.path)
	mkdir(files.target.path);
end
for i = 1:numel(setti.seasons)
	if ~isdir([files.target.path,filesep,setti.seasons{i}])
		mkdir([files.target.path,filesep,setti.seasons{i}]);
	end
	for j = 1:numel(setti.weekdays)
		if ~isdir([files.target.path,filesep,setti.seasons{i},...
				filesep,setti.weekdays{j}])
			mkdir([files.target.path,filesep,setti.seasons{i},...
				filesep,setti.weekdays{j}]);
		end
		if ~isdir([files.target.path,filesep,setti.seasons{i},filesep,'Genera'])
			mkdir([files.target.path,filesep,setti.seasons{i},filesep,'Genera']);
		end
		% 		for k = 1:numel(setti.housholds)
		% 			files.typ_allocation_hh.(setti.seasons{i}).(setti.weekdays{j}).(setti.housholds{k}) = [];
		% 		end
	end
	files.typ_allocation_pv.(setti.seasons{i}) = [];
	files.typ_allocation_wi.(setti.seasons{i}) = [];
end

% Einlesen der Dateinamen im Quellordner:
files.source.names_load = dir(files.source.path_load);
files.source.names_load = struct2cell(files.source.names_load);
files.source.names_load = files.source.names_load(1,3:end);

% Erstellung einer Indexliste der Dateinamen für die jeweilige Jahreszeit, Wochentag,
% und Haushaltstyp:
files.typ_allocation_hh = [];
for i = 1:size(files.source.names_load,2)
	% aktuellen Dateinamen auslesen + Dateiendung entfernen
	data.name = files.source.names_load{1,i}(1:end-4);
	data.name_parts = regexp(data.name, files.sep, 'split');
	% handelt es sich um ein Simulationslog?
	if strcmp(data.name_parts{2},'Simulations-Log')
		% falls ja, diesen Eintrag überspringen:
		continue;
	end
	sim_time = ['t_', data.name_parts{1}];
	sim_time = strrep(sim_time, '.', '_');
	idx = strcmp(setti.households, data.name_parts{3});
	hh = setti.households{idx};
	hh_name = ['Nr_', data.name_parts{4}];
	idx = strcmp(setti.seasons, data.name_parts{5});  % Jahreszeit
	season = setti.seasons{idx};
	idx = strcmp(setti.weekdays, data.name_parts{6}); % Wochentag
	weekday = setti.weekdays{idx};
	
	files.typ_allocation_hh.(sim_time).(hh).(hh_name).(season).(weekday) = i;
end

% Vollständigkeit der einzelnen Datensätze überprüfen:
times = fields(files.typ_allocation_hh);
for i = 1:numel(times)
	sim_time = files.typ_allocation_hh.(times{i});
	households = fields(sim_time);
	for j = 1:numel(households)
		hh = sim_time.(households{j});
		hh_names = fields(hh);
		for k = 1:numel(hh_names)
			hh_data = hh.(hh_names{k});
			% sind alle Datensätze vorhanden für diesen Haushalt?
			count = 0;
			for n=1:numel(setti.seasons)
				if isfield(hh_data, setti.seasons{n})
					for m=1:numel(setti.weekdays)
						if isfield(hh_data.(setti.seasons{n}), setti.weekdays{m})
							count = count + 1;
						end
					end
				end
			end
			if ~(count == 9)
				files.typ_allocation_hh.(times{i}).(households{j}) = ...
					rmfield(files.typ_allocation_hh.(times{i}).(households{j}),hh_names{k});
			end
		end
	end
end

if ~setti.add_data_mode
	% Die Zählerstruktur auf Anfangswerte setzen:
	for i = 1:numel(setti.households)
		setti.counter_hh.datasets_total.(setti.households{i}) = 0;
		setti.counter_hh.datasets.(setti.households{i}) = 0;
		setti.counter_hh.idx_file.(setti.households{i}) = 1;
	end
end

% nun die einzelnen Kategorien durchgehen, und die Dateien zusammenführen:
fprintf('\n-----------');
for i = 1:numel(setti.households)
	hh_typ = setti.households{i};
	
	% Zählerstände einlesen
	counter_datasets_total = ...
		setti.counter_hh.datasets_total.(hh_typ);
	counter_datasets = ...
		setti.counter_hh.datasets.(hh_typ);
	counter_idx_file = ...
		setti.counter_hh.idx_file.(hh_typ);
	counter_datasets_new = 0;
	
	% Die bereits vorhadnen Daten laden oder die Arrays anlegen:
	if setti.add_data_mode
		try
			name = ['Load',files.sep,hh_typ,files.sep,'Info'];
			load([files.target.path,filesep,name,'.mat']); % hh_data_info
		catch ME
			% Falls laden nicht möglich, Startwert setzen:
			hh_data_info = {};
		end
		try
			%laden der letzten Teildateien:
			for l=1:numel(setti.seasons)
				season = setti.seasons{l};
				for m=1:numel(setti.weekdays)
					weekday = setti.weekdays{m};
					name = ['Load',files.sep,season,files.sep,weekday,...
						files.sep,hh_typ,files.sep,...
						num2str(counter_idx_file,'%03.0f')];
					path_db = [files.target.path,filesep,season,filesep,weekday];
					load([path_db,filesep,name,'.mat']);
					data_power.(season).(weekday) = data_phase;
					counter_datasets = size(data_power.(season).(weekday),2)/6;
					name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
						hh_typ,files.sep,'Info'];
					load([path_db,filesep,name,'.mat']);
					data_merged.(season).(weekday) = data_info;
					name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
						hh_typ,files.sep,'Geraeteinstanzen'];
					load([path_db,filesep,name,'.mat']);
					hh_device_instances.(season).(weekday) = hh_devices;
				end
			end
		catch ME
			% Falls laden nicht möglich, Startwerte setzen:
			for j = 1:numel(setti.seasons)
				for k = 1:numel(setti.weekdays)
					data_power.(setti.seasons{j}).(setti.weekdays{k}) = [];
					data_merged.(setti.seasons{j}).(setti.weekdays{k}) = [];
					hh_device_instances.(setti.seasons{j}).(setti.weekdays{k}) = {};
				end
			end
		end
	else
		hh_data_info = {};
		for j = 1:numel(setti.seasons)
			for k = 1:numel(setti.weekdays)
				data_power.(setti.seasons{j}).(setti.weekdays{k}) = [];
				data_merged.(setti.seasons{j}).(setti.weekdays{k}) = [];
				hh_device_instances.(setti.seasons{j}).(setti.weekdays{k}) = {};
			end
		end
	end
	
	for j = 1:numel(times)
		sim_time = files.typ_allocation_hh.(times{j});
		if ~isfield(sim_time, hh_typ)
			continue;
		end
		hh_data_all = sim_time.(hh_typ);
		hh_all_names = fields(hh_data_all);
		for k = 1:numel(hh_all_names)
			hh_data = hh_data_all.(hh_all_names{k});
			% Nun über alle Jahreszeiten und Wochentage iterieren:
			for l=1:numel(setti.seasons)
				season = setti.seasons{l};
				for m=1:numel(setti.weekdays)
					weekday = setti.weekdays{m};
					% Index der aktuellen Datei auslesen:
					idx = hh_data.(season).(weekday);
					% Daten laden:
					load([files.source.path_load,filesep,files.source.names_load{idx}]);
					if l == 1 && m ==1
						% Wieviele Datensätze werden hinzugefügt?
						number_new_datasets = size(data_phase,2)/6;
						% ersten Datenstaz dieser Haushalte wurde geladen, um Geräteausstattung
						% zu erhalten:
						allo = Households.Devices.(hh_typ).Allocation;
						% Array in logisches Array umformen (für Anzahl):
						allo_num = allo > 0;
						de_na = Households.Devices.(hh_typ).Devices.Elements_Names;
						nu_hh = Households.Statistics.(hh_typ).Number;
						nu_pe = Households.Statistics.(hh_typ).Number_Persons;
						for n=1:nu_hh
							Info.Number_Persons = nu_pe(n);
							Info.Devices = [de_na', num2cell(sum(squeeze(allo_num(:,n,:)),2))];
							hh_data_info{end+1} = Info; %#ok<SAGROW>
						end
					end
					% zus. Daten ermitteln:
					% Max. Wert [W]:
					data_max = max(data_phase);
					% Min. Wert [W]:
					data_min = min(data_phase);
					% Energieinhalt [kWh]:
					data_e = sum(data_phase,1)/3.6e6;
					% Geräteinstanzen extrahieren:
					devs = Households.Devices.(hh_typ).Devices;
					allo = Households.Devices.(hh_typ).Allocation;
					nu_hh = Households.Statistics.(hh_typ).Number;
					for n=1:nu_hh
						allo_hh = squeeze(allo(:,n,:));
						instances = cell(size(allo_hh,1),1);
						for o=1:size(allo_hh,1);
							dev_idx = allo_hh(o,:);
							dev_idx(dev_idx == 0) = [];
							dev = devs.(devs.Elements_Varna{o})(dev_idx);
							if isempty(dev)
								instances{o,1} = [];
							else
								instances{o,1} = dev;
							end
						end
						hh_device_instances.(season).(weekday){end+1} = instances;
					end
					% Daten Zusammenführen:
					if counter_datasets_total == 0
						data_merged.(season).(weekday) =  [...
							data_max; ...
							data_min; ...
							data_e; ...
							];
						data_power.(season).(weekday) = data_phase;
					else
						data_merged.(season).(weekday) =  [...
							data_merged.(season).(weekday)(1,:), data_max; ...
							data_merged.(season).(weekday)(2,:), data_min; ...
							data_merged.(season).(weekday)(3,:), data_e; ...
							];
						data_power.(season).(weekday) = [...
							data_power.(season).(weekday), data_phase];
					end
					% diese Datei in den "Erledigt"-Ordner verschieben:
					movefile([files.source.path_load,filesep,...
						files.source.names_load{idx}], ...
						files.source.path_load_processed);
				end
			end
			% Zählerstände anpassen:
			counter_datasets = counter_datasets + number_new_datasets;
			counter_datasets_new = counter_datasets_new + number_new_datasets;
			counter_datasets_total = counter_datasets_total + ...
				number_new_datasets;
			% Wenn maximale Anzahl an Datensätzen gefunden wurde, die
			% bisherigen abspeichern: 
			while counter_datasets >= setti.max_num_data_set
				for l=1:numel(setti.seasons)
					season = setti.seasons{l};
					for m=1:numel(setti.weekdays)
						weekday = setti.weekdays{m};
						data_phase = data_power.(season).(weekday)(:,1:6*setti.max_num_data_set);
						name = ['Load',files.sep,season,files.sep,weekday,...
							files.sep,hh_typ,files.sep,...
							num2str(counter_idx_file,'%03.0f')];
						path_db = [files.target.path,filesep,season,filesep,weekday];
						save([path_db,filesep,name,'.mat'],'data_phase');
						% Die gespeicherten Daten löschen:
						data_power.(season).(weekday)(:,1:6*setti.max_num_data_set) = [];
					end
				end
				% Anzahl gespeicherter Daten aktualisieren:
				counter_datasets = size(data_power.(season).(weekday),2)/6;
				% Dateiindex erweitern:
				counter_idx_file = counter_idx_file + 1;
			end
		end
	end
	% Nun die restlichen Daten speichern:
	if counter_datasets_new == 0
		% Falls keine Daten vorhanden, nächster Haushhaltstyp:
		continue;
	end
	for l=1:numel(setti.seasons)
		season = setti.seasons{l};
		for m=1:numel(setti.weekdays)
			weekday = setti.weekdays{m};
			%zunächst die Zusatzdaten in eigene Datei speichern: 
			data_info = data_merged.(season).(weekday);
			% Zusatzdaten speichern:
			name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
				hh_typ,files.sep,'Info'];
			path_db = [files.target.path,filesep,season,filesep,weekday];
			save([path_db,filesep,name,'.mat'],'data_info');
			hh_devices = hh_device_instances.(season).(weekday);
			name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
				hh_typ,files.sep,'Geraeteinstanzen'];
			save([path_db,filesep,name,'.mat'],'hh_devices');
			% Die restlichen Datendateien:
			data_phase = data_power.(season).(weekday);
			if ~isempty(data_phase)
				name = ['Load',files.sep,season,files.sep,weekday,...
					files.sep,hh_typ,files.sep,...
					num2str(counter_idx_file,'%03.0f')];
				path_db = [files.target.path,filesep,season,filesep,weekday];
				save([path_db,filesep,name,'.mat'],'data_phase');
			end
		end
	end
	% Die Infos der Haushalte speichern:
	name = ['Load',files.sep,hh_typ,files.sep,'Info'];
	path_db = [files.target.path];
	save([path_db,filesep,name,'.mat'],'hh_data_info');
	% Zählerstände aktualisieren
	setti.counter_hh.datasets_total.(hh_typ) = counter_datasets_total;
	setti.counter_hh.datasets.(hh_typ) = counter_datasets;
	setti.counter_hh.idx_file.(hh_typ) = counter_idx_file;
	
	% Info an Konsole:
	if setti.add_data_mode
		if counter_datasets_new == counter_datasets_total
			fprintf(['\nErledigt: ',...
				hh_typ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
		else
			fprintf(['\nErledigt: ',...
				hh_typ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_new,'%5.0f'),' neue Datensätze, ',...
				num2str(counter_datasets_total,'%5.0f'),' Gesamt']);
		end
	else
		fprintf(['\nErledigt: ',...
			hh_typ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
			num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
	end
end
fprintf('\n-----------');

%------------------------------------------------------------------------------------
% Abarbeiten der Erzeugerprofile (Solar)
%------------------------------------------------------------------------------------

% Abarbeiten der Einstrahlungsdaten:
try
	% Laden von 'Content', 'Radiation_Tracker' und 'Radiation_fixed_Plane'
	load([files.source.path_sola,filesep,'Weatherdata_Sola_Radiation.mat']);
	% Inhalt der PV-Daten in Datenbank abspeichern
	setti.content_sola_data = Content;
	for i = 1:size(setti.seasons,1)
		season = setti.seasons{i,1};
		idx = find(strcmp(season,Content.seasons));
		if ~isempty(idx)
			% Teileinstrahlungs-Array erstellen, in dem nur die Daten der aktuellen
			% Jahreszeit gespeichert sind:
			radiation_data_fix = squeeze(Radiation_fixed_Plane(idx,:,:,:,:,:));
			radiation_data_tra = squeeze(Radiation_Tracker(idx,:,:,:));
			name = ['Gene',files.sep,season,files.sep,'Solar',files.sep,...
				'Radiation'];
			save([files.target.path,filesep,season,filesep,'Genera',filesep,...
				name,'.mat'],'radiation_data_fix','radiation_data_tra','Content');
		end
	end
	% Datei in den "Erledigt"-Ordner verschieben:
	movefile([files.source.path_sola,filesep,'Weatherdata_Sola_Radiation.mat'], ...
		files.source.path_gene_sola_proc);
catch ME
end

% Einlesen der restlichen Dateinamen im Quellordner (enthalten die
% Wolkeneinflussdaten):
files.source.names_sola = dir(files.source.path_sola);
files.source.names_sola = struct2cell(files.source.names_sola);
files.source.names_sola = files.source.names_sola(1,3:end);

if ~setti.add_data_mode
	% Die Zählerstruktur auf Anfangswerte setzen:
	for i = 1:numel(setti.seasons)
		setti.counter_pv.datasets_total.(setti.seasons{i}) = 0;
		setti.counter_pv.datasets.(setti.seasons{i}) = 0;
		setti.counter_pv.idx_file.(setti.seasons{i}) = 1;
	end
end

% Dateien ordnen (nach Jahreszeit) d.h. eine Indexliste erstellen:
for i = 1:size(files.source.names_sola,2)
	% aktuellen Dateinamen auslesen + Dateiendung entfernen
	data.name = files.source.names_sola{1,i}(1:end-4);
	data.name_parts = regexp(data.name, files.sep, 'split');
	% Festellung der Zuordnung der Dateien:
	idx = strcmp(setti.seasons, data.name_parts{2});  % Jahreszeit
	season = setti.seasons{idx};
	files.typ_allocation_pv.(season)(end+1) = i;
end

for i = 1:numel(setti.seasons)
	season = setti.seasons{i};
	idx = files.typ_allocation_pv.(season);
	
	% Zählerstände auslesen:
	counter_idx_file = setti.counter_pv.idx_file.(season);
	counter_datasets_total = setti.counter_pv.datasets_total.(season);
	counter_datasets = setti.counter_pv.datasets.(season);
	counter_datasets_new = 0;
	
	% Kontrolle, ob überhaupt Dateien vorhanden sind bzw. maximale Datensatzanzahl
	% überschritten wurde:
	if isempty(idx)  || ...
			counter_datasets_total >= setti.max_num_data_set_gena_total
		% Wenn nicht, aktuelle Jahreszeit überspringen:
		continue;
	end
	
	% die einzelnen Dateien abarbeiten:
	for j = 1:numel(idx)
		% wurde maximale Datensatzanzahl überschritten?:
		if counter_datasets_total >= setti.max_num_data_set_gena_total
			% Wenn ja, Datei überspringen...
			continue;
		end
		% Datei laden (Cloud_Factor):
		load([files.source.path_sola,filesep,...
			files.source.names_sola{idx(j)}]);
		% diese Datei in den "Erledigt"-Ordner verschieben:
		movefile([files.source.path_sola,filesep,...
			files.source.names_sola{idx(j)}], ...
			files.source.path_gene_sola_proc);
		% Durchschnittlichen Bewölkungsgrad ermitteln:
		data_avg_cloud_factor = sum(Cloud_Factor,1)/86401;
		if (~setti.add_data_mode && j == 1) || counter_datasets_total == 0
			data_avg_cloud_factor_merged = data_avg_cloud_factor;
		elseif setti.add_data_mode && j == 1
			% die ermittelten Ergebnisse der bisher existierenden Datenbank laden:
			path_db = [files.target.path,filesep,season,filesep,'Genera'];
			name = ['Gene',files.sep,season,...
				files.sep,'Solar',files.sep,'Cloud_Factor',files.sep,...
				'Info'];
			load([path_db,filesep,name,'.mat']);
			data_avg_cloud_factor_merged = data_info;
			clear data_info;
			data_avg_cloud_factor_merged = [data_avg_cloud_factor_merged,...
				data_avg_cloud_factor]; %#ok<AGROW>
		else
			data_avg_cloud_factor_merged = [data_avg_cloud_factor_merged,...
				data_avg_cloud_factor]; %#ok<AGROW>
		end
		if (~setti.add_data_mode && j == 1) || counter_datasets == 0
			data_cloud_factor_merged = Cloud_Factor;
			number_new_datasets = size(Cloud_Factor,2);
		elseif setti.add_data_mode && j == 1
			data_cloud_factor_merged = Cloud_Factor;
			number_new_datasets = size(Cloud_Factor,2);
			% Die Daten der letzten Datei laden:
			path_db = [files.target.path,filesep,season,filesep,'Genera'];
			name = ['Gene',files.sep,season,...
				files.sep,'Solar',files.sep,'Cloud_Factor',files.sep,...
				num2str(counter_idx_file,'%03.0f')];
			load([path_db,filesep,name,'.mat']); %data_cloud_factor
			% die Daten zusammensetzen (umgekehrte Reihenfolge, weil in
			% data_phase die bereits gespeicherten Daten zu finden sind, in
			% data_phase_merged die neuen Daten!)
			data_cloud_factor_merged = [data_cloud_factor, data_cloud_factor_merged]; %#ok<AGROW>
		else
			data_cloud_factor_merged = [data_cloud_factor_merged, Cloud_Factor]; %#ok<AGROW>
			number_new_datasets = size(Cloud_Factor,2);
		end
		counter_datasets = counter_datasets + number_new_datasets;
		counter_datasets_new = counter_datasets_new + number_new_datasets;
		counter_datasets_total = counter_datasets_total + number_new_datasets;
		% Teildateien erzeugen (es können 6 mal mehr Daten pro File abgespeichert
		% werden als bei den Haushalten, weil ein Datenvketor nur aus einer Spalte
		% besteht im Gegensatz zu 6 bei den Haushalten:
		while counter_datasets >= setti.max_num_data_set*6
			% Wenn maximale Anzahl an Datensätzen gefunden wurde, die
			% bisherigen abspeichern:
			data_cloud_factor = data_cloud_factor_merged(:,1:6*setti.max_num_data_set); %#ok<NASGU>
			name = ['Gene',files.sep,season,...
				files.sep,'Solar',files.sep,'Cloud_Factor',files.sep,...
				num2str(counter_idx_file,'%03.0f')];
			path_db = [files.target.path,filesep,season,filesep,'Genera'];
			save([path_db,filesep,name,'.mat'],'data_cloud_factor');
			% die restlichen Daten wieder zurückschreiben:
			data_cloud_factor = data_cloud_factor_merged(:,6*setti.max_num_data_set+1:end);
			data_cloud_factor_merged = data_cloud_factor;
			counter_datasets = size(data_cloud_factor_merged,2);
			% Dateiindex erweitern:
			counter_idx_file = counter_idx_file + 1;
		end
	end
	% die (restlichen) Daten speichern:
	data_cloud_factor = data_cloud_factor_merged;
	if ~isempty(data_cloud_factor)
		name = ['Gene',files.sep,season,...
			files.sep,'Solar',files.sep,'Cloud_Factor',files.sep,...
			num2str(counter_idx_file,'%03.0f')];
		path_db = [files.target.path,filesep,season,filesep,'Genera'];
		save([path_db,filesep,name,'.mat'],'data_cloud_factor');
	end
	clear data_cloud_factor;
	% Zusatzdaten in eigene Datei speichern:
	data_info = data_avg_cloud_factor_merged;
	name = ['Gene',files.sep,season,...
		files.sep,'Solar',files.sep,'Cloud_Factor',files.sep,...
		'Info'];
	save([path_db,filesep,name,'.mat'],'data_info');
	% Zählerstände speichern:
	setti.counter_pv.datasets_total.(season) = ...
		counter_datasets_total;
	setti.counter_pv.datasets.(season) = counter_datasets;
	setti.counter_pv.idx_file.(season) = counter_idx_file;
	% Ausgabe an Konsole:
	if setti.add_data_mode
		if counter_datasets_new == counter_datasets_total
			fprintf(['\nErledigt: ',season,files.sep,...
				'Solar',files.sep,'Cloud_Factor',files.sep,...
				num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
		else
			fprintf(['\nErledigt: ',season,files.sep,...
				'Solar',files.sep,'Cloud_Factor',files.sep,...
				num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_new,'%5.0f'),' neue Datensätze, ',...
				num2str(counter_datasets_total,'%5.0f'),' Gesamt']);
		end
	else
		fprintf(['\nErledigt: ',season,files.sep,...
			'Solar',files.sep,'Cloud_Factor',files.sep,...
			num2str(counter_idx_file,'%03.0f'),': ',...
			num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
	end
end
fprintf('\n-----------');

%------------------------------------------------------------------------------------
% Abarbeiten der Erzeugerprofile (Wind)
%------------------------------------------------------------------------------------

% Einlesen der Dateinamen im Quellordner (enthalten die
% Wolkeneinflussdaten):
files.source.names_wind = dir(files.source.path_wind);
files.source.names_wind = struct2cell(files.source.names_wind);
files.source.names_wind = files.source.names_wind(1,3:end);

if ~setti.add_data_mode
	% Die Zählerstruktur auf Anfangswerte setzen:
	for i = 1:numel(setti.seasons)
		setti.counter_wi.datasets_total.(setti.seasons{i}) = 0;
		setti.counter_wi.datasets.(setti.seasons{i}) = 0;
		setti.counter_wi.idx_file.(setti.seasons{i}) = 1;
	end
end

% Dateien ordnen (nach Jahreszeit) d.h. eine Indexliste erstellen:
for i = 1:size(files.source.names_wind,2)
	% aktuellen Dateinamen auslesen + Dateiendung entfernen
	data.name = files.source.names_wind{1,i}(1:end-4);
	data.name_parts = regexp(data.name, files.sep, 'split');
	% Festellung der Zuordnung der Dateien:
	idx = strcmp(setti.seasons, data.name_parts{4});  % Jahreszeit
	season = setti.seasons{idx};
	files.typ_allocation_wi.(season)(end+1) = i;
end

for i = 1:numel(setti.seasons)
	season = setti.seasons{i};
	idx = files.typ_allocation_wi.(season);
	
	% Zählerstände auslesen:
	counter_idx_file = setti.counter_wi.idx_file.(season);
	counter_datasets_total = setti.counter_wi.datasets_total.(season);
	counter_datasets = setti.counter_wi.datasets.(season);
	counter_datasets_new = 0;
	
	% Kontrolle, ob überhaupt Dateien vorhanden sind bzw. maximale Datensatzanzahl
	% überschritten wurde:
	if isempty(idx)  || ...
			counter_datasets_total >= setti.max_num_data_set_gena_total
		% Wenn nicht, aktuelle Jahreszeit überspringen:
		continue;
	end
	
	% die einzelnen Dateien abarbeiten:
	for j = 1:numel(idx)
		% wurde maximale Datensatzanzahl überschritten?:
		if counter_datasets_total >= setti.max_num_data_set_gena_total
			% Wenn ja, Datei überspringen...
			continue;
		end
		% Datei laden (data_v_wind):
		load([files.source.path_wind,filesep,...
			files.source.names_wind{idx(j)}]);
		% diese Datei in den "Erledigt"-Ordner verschieben:
		movefile([files.source.path_wind,filesep,...
			files.source.names_wind{idx(j)}], ...
			files.source.path_gene_wind_proc);
		
		% Zusatzinfos aus den vorhandenen Daten ermitteln:
		% Durchschnittliche Windgeschwindigkeit:
		data_avg_v_wind = sum(data_v_wind,1)/86401;
		% maximale und minimale Windgeschwindigkeit (der Stundenwerte, da diese die
		% Stützstellen sind):
		data_min_v_wind = min(data_v_wind(1:3600:end-3600,:));
		data_max_v_wind = max(data_v_wind(1:3600:end-3600,:));
		% Daten zusammensetzen:
		if (~setti.add_data_mode && j == 1) || counter_datasets_total == 0
			data_avg_v_wind_merged = data_avg_v_wind;
			data_min_v_wind_merged = data_min_v_wind;
			data_max_v_wind_merged = data_max_v_wind;
		elseif setti.add_data_mode && j == 1
			% die ermittelten Ergebnisse der bisher existierenden Datenbank laden:
			path_db = [files.target.path,filesep,season,filesep,'Genera'];
			name = ['Gene',files.sep,season,...
				files.sep,'Wind',files.sep,'Speed',files.sep,...
				'Info'];
			load([path_db,filesep,name,'.mat']);
			data_avg_v_wind_merged = data_info(1,:);
			data_min_v_wind_merged = data_info(2,:);
			data_max_v_wind_merged = data_info(3,:);
			clear data_info;
			data_avg_v_wind_merged = [data_avg_v_wind_merged, data_avg_v_wind];  %#ok<AGROW>
			data_min_v_wind_merged = [data_min_v_wind_merged, data_min_v_wind];  %#ok<AGROW>
			data_max_v_wind_merged = [data_max_v_wind_merged, data_max_v_wind];  %#ok<AGROW>
		else
			data_avg_v_wind_merged = [data_avg_v_wind_merged, data_avg_v_wind];  %#ok<AGROW>
			data_min_v_wind_merged = [data_min_v_wind_merged, data_min_v_wind];  %#ok<AGROW>
			data_max_v_wind_merged = [data_max_v_wind_merged, data_max_v_wind];  %#ok<AGROW>
		end
		if (~setti.add_data_mode && j == 1) || counter_datasets == 0
			data_v_wind_merged = data_v_wind;
			number_new_datasets = size(data_v_wind,2);
		elseif setti.add_data_mode && j == 1
			data_v_wind_merged = data_v_wind;
			number_new_datasets = size(data_v_wind,2);
			% Die Daten der letzten Datei laden:
			path_db = [files.target.path,filesep,season,filesep,'Genera'];
			name = ['Gene',files.sep,season,...
				files.sep,'Wind',files.sep,'Speed',files.sep,...
				num2str(counter_idx_file,'%03.0f')];
			load([path_db,filesep,name,'.mat']); %data_v_wind
			% die Daten zusammensetzen (umgekehrte Reihenfolge, weil in
			% "data_v_wind" die bereits gespeicherten Daten zu finden sind, in
			% "data_v_wind_merged" die neuen Daten!)
			data_v_wind_merged = [data_v_wind, data_v_wind_merged]; %#ok<AGROW>
		else
			data_v_wind_merged = [data_v_wind_merged, data_v_wind]; %#ok<AGROW>
			number_new_datasets = size(data_v_wind,2);
		end
		counter_datasets = counter_datasets + number_new_datasets;
		counter_datasets_new = counter_datasets_new + number_new_datasets;
		counter_datasets_total = counter_datasets_total + number_new_datasets;
		% Teildateien erzeugen (es können 6 mal mehr Daten pro File abgespeichert
		% werden als bei den Haushalten, weil ein Datenvketor nur aus einer Spalte
		% besteht im Gegensatz zu 6 bei den Haushalten:
		while counter_datasets >= setti.max_num_data_set*6
			% Wenn maximale Anzahl an Datensätzen gefunden wurde, die
			% bisherigen abspeichern:
			data_v_wind = data_v_wind_merged(:,1:6*setti.max_num_data_set);  %#ok<NASGU>
			name = ['Gene',files.sep,season,...
				files.sep,'Wind',files.sep,'Speed',files.sep,...
				num2str(counter_idx_file,'%03.0f')];
			path_db = [files.target.path,filesep,season,filesep,'Genera'];
			save([path_db,filesep,name,'.mat'],'data_v_wind');
			% die restlichen Daten wieder zurückschreiben:
			data_v_wind = data_v_wind_merged(:,6*setti.max_num_data_set+1:end);
			data_v_wind_merged = data_v_wind;
			counter_datasets = size(data_v_wind_merged,2);
			% Dateiindex erweitern:
			counter_idx_file = counter_idx_file + 1;
		end
	end
	% die (restlichen) Daten speichern:
	data_v_wind = data_v_wind_merged;
	if ~isempty(data_v_wind)
		name = ['Gene',files.sep,season,...
			files.sep,'Wind',files.sep,'Speed',files.sep,...
			num2str(counter_idx_file,'%03.0f')];
		path_db = [files.target.path,filesep,season,filesep,'Genera'];
		save([path_db,filesep,name,'.mat'],'data_v_wind');
	end
	clear data_v_wind;
	% Zusatzdaten in eigene Datei speichern:
	data_info = [...
		data_avg_v_wind_merged;...
		data_min_v_wind_merged;...
		data_max_v_wind_merged;...
		];
	name = ['Gene',files.sep,season,...
		files.sep,'Wind',files.sep,'Speed',files.sep,...
		'Info'];
	save([path_db,filesep,name,'.mat'],'data_info');
	% Zählerstände speichern:
	setti.counter_wi.datasets_total.(season) = ...
		counter_datasets_total;
	setti.counter_wi.datasets.(season) = counter_datasets;
	setti.counter_wi.idx_file.(season) = counter_idx_file;
	% Ausgabe an Konsole:
	if setti.add_data_mode
		if counter_datasets_new == counter_datasets_total
			fprintf(['\nErledigt: ',season,files.sep,...
				'Wind',files.sep,'Speed',files.sep,...
				num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
		else
			fprintf(['\nErledigt: ',season,files.sep,...
				'Wind',files.sep,'Speed',files.sep,...
				num2str(counter_idx_file,'%03.0f'),': ',...
				num2str(counter_datasets_new,'%5.0f'),' neue Datensätze, ',...
				num2str(counter_datasets_total,'%5.0f'),' Gesamt']);
		end
	else
		fprintf(['\nErledigt: ',season,files.sep,...
			'Wind',files.sep,'Speed',files.sep,...
			num2str(counter_idx_file,'%03.0f'),': ',...
			num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
	end
end
fprintf('\n-----------');

% Einstellungen und Dateiaufbau speichern:
save([files.target.path,filesep,setti.name_database,'.mat'],'files','setti');
