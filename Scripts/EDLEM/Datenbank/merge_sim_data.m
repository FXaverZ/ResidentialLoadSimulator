%Script, um Einzelsimulationsdaten zusammenzuführen (zu einer Datenbank):

% Franz Zeilinger - 15.09.2011

clear;
%------------------------------------------------------------------------------------
% Definitionsteil
%------------------------------------------------------------------------------------
% Wieviele Datensätze pro Einzelfile? (um bei Laden nicht allzusehr den
% Arbeitsspeicher zu belasten...
setti.max_num_data_set = 50;

% Ordner, in dem die Quelldaten abgelegt wurden:
files.source.path = [pwd,filesep,'Quelldaten'];
files.source.path_load = [files.source.path,filesep,'Lastprofile (sec)'];
files.source.path_sola = [files.source.path,filesep,'Wetterdaten PV'];
files.source.path_wind = [files.source.path,filesep,'Wetterdaten Wind'];
files.sep = ' - '; %Seperator im Dateinamen

setti.name_database = 'EDLEM_Datenbank_Test';

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
setti.housholds = {...     % Definition der Haushaltskategorien:
	'sing_vt';...          %     (aus simulation_single_cycle_for_load_profiles.m)
	'coup_vt';...
	'sing_pt';...
	'coup_pt';...
	'sing_rt';...
	'coup_rt';...
	'fami_2v';...
	'fami_1v';...
	'fami_rt'};

% Erstellung einer Indexliste der Dateinamen für die jeweilige Jahreszeit, Wochentag,
% und Haushaltstyp:
% Aufbau des Dateinamens: 
%    07h54.59 - Summer - Sunday -  coup_r -  1.mat
%    Uhrzeit - Jahreszeit - Wochentag - Typ - Index .mat
% Im Fall des Simulationslogs:
%    07h54.59 - Simulations-Log - sec.txt

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
		for k = 1:numel(setti.housholds)
			files.typ_allocation_hh.(setti.seasons{i}).(setti.weekdays{j}).(setti.housholds{k}) = [];
		end
	end
end

% Einlesen der Dateinamen im Quellordner:
files.source.names_load = dir(files.source.path_load);
files.source.names_load = struct2cell(files.source.names_load);
files.source.names_load = files.source.names_load(1,3:end);

for i = 1:size(files.source.names_load,2) 
	% aktuellen Dateinamen auslesen + Dateiendung entfernen
	data.name = files.source.names_load{1,i}(1:end-4);
	data.name_parts = regexp(data.name, files.sep, 'split');
	% handelt es sich um ein Simulationslog?
	if strcmp(data.name_parts{2},'Simulations-Log')
		% falls ja, diesen Eintrag überspringen:
		continue;
	end
	% Festellung der Zurodnung der Dateien:
	idx = strcmp(setti.seasons, data.name_parts{2});  % Jahreszeit
	season = setti.seasons{idx};
	idx = strcmp(setti.weekdays, data.name_parts{3}); % Wochentag
	weekday = setti.weekdays{idx};
	idx = strcmp(setti.housholds, data.name_parts{4});
	househ = setti.housholds{idx};
	files.typ_allocation_hh.(season).(weekday).(househ)(end+1) = i;
end

if ~setti.add_data_mode
	% Die Zählerstruktur auf Anfangswerte setzen:
	for i = 1:numel(setti.seasons)
		for j = 1:numel(setti.weekdays)
			for k = 1:numel(setti.housholds)
				setti.counter.datasets_total.(setti.seasons{i...
					}).(setti.weekdays{j}).(setti.housholds{k}) = 0;
				setti.counter.datasets.(setti.seasons{i...
					}).(setti.weekdays{j}).(setti.housholds{k}) = 0;
				setti.counter.idx_file.(setti.seasons{i...
					}).(setti.weekdays{j}).(setti.housholds{k}) = 1;
			end
		end
	end
end

% nun die einzelnen Kategorien durchgehen, und die Dateien zusammenführen:
fprintf('\n-----------');
for i = 1:numel(setti.seasons)
	season = setti.seasons{i};
	for j = 1:numel(setti.weekdays)
		weekday = setti.weekdays{j};
		for k = 1:numel(setti.housholds)
			househ = setti.housholds{k};
			% Zählerstände einlesen
			counter_datasets_total = ...
				setti.counter.datasets_total.(season).(weekday).(househ);
			counter_datasets = ...
				setti.counter.datasets.(season).(weekday).(househ);
			counter_idx_file = ...
				setti.counter.idx_file.(season).(weekday).(househ);
			counter_datasets_new = 0;
			% Indizes für Dateinamen einlesen:
			idx = files.typ_allocation_hh.(season).(weekday).(househ);
			if isempty(idx)
				continue;
			end
			for l = 1:numel(idx)
				% Datei laden (data_phase):
				load([files.source.path_load,filesep,...
					files.source.names_load{idx(l)}]);
				% diese Datei in den "Erledigt"-Ordner verschieben:
				movefile([files.source.path_load,filesep,...
					files.source.names_load{idx(l)}], ...
					files.source.path_load_processed);
				% zus. Daten ermitteln:
				% Max. Wert [W]:
				data_max = max(data_phase);
				% Min. Wert [W]:
				data_min = min(data_phase);
				% Energieinhalt [kWh/kW_inst]:
				data_e = sum(data_phase,1)/3.6e6;
				if (~setti.add_data_mode && l == 1) || counter_datasets_total == 0
					data_merged_max = data_max;
					data_merged_min = data_min;
					data_merged_e = data_e;
				elseif setti.add_data_mode && l == 1
					% die ermittelten Ergebnisse der bisher existierenden Datenbank
					% laden:
					path_db = [files.target.path,filesep,season,filesep,weekday];
					name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
						househ,files.sep,'Info'];
					load([path_db,filesep,name,'.mat']); % data_info
					data_merged_max = data_info(1,:);
					data_merged_min = data_info(2,:);
					data_merged_e = data_info(3,:);
					% die neu ermittlenten Daten den bisher ermittelten hinzufügen:
					data_merged_max = [data_merged_max, data_max]; %#ok<AGROW>
					data_merged_min = [data_merged_min,data_min]; %#ok<AGROW>
					data_merged_e = [data_merged_e,data_e]; %#ok<AGROW>
				else
					data_merged_max = [data_merged_max, data_max]; %#ok<AGROW>
					data_merged_min = [data_merged_min,data_min]; %#ok<AGROW>
					data_merged_e = [data_merged_e,data_e]; %#ok<AGROW>
				end
				
				if (~setti.add_data_mode && l == 1) || counter_datasets == 0
					data_phase_merged = data_phase;
					number_new_datasets = size(data_phase,2)/6;
				elseif setti.add_data_mode && l == 1
					data_phase_merged = data_phase;
					number_new_datasets = size(data_phase,2)/6;
					% Die Daten der letzten Datei laden:
					path_db = [files.target.path,filesep,season,filesep,weekday];
					name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
						househ,files.sep,num2str(counter_idx_file,'%03.0f')];
					load([path_db,filesep,name,'.mat']); %data_phase
					% die Daten zusammensetzen (umgekehrte Reihenfolg, weil in
					% data_phase die bereits gespeicherten Daten zu finden sind, in
					% data_phase_merged die neuen Daten!)
					data_phase_merged = [data_phase, data_phase_merged]; %#ok<AGROW>
				else
					data_phase_merged = [data_phase_merged, data_phase]; %#ok<AGROW>
					number_new_datasets = size(data_phase,2)/6;
				end
				
				% Zähler erhöhen (um Anzahl von Datensätzen)
				counter_datasets = counter_datasets + number_new_datasets;
				counter_datasets_new = counter_datasets_new + number_new_datasets;
				counter_datasets_total = counter_datasets_total + ...
					number_new_datasets;
				
				while counter_datasets >= setti.max_num_data_set
					% Wenn maximale Anzahl an Datensätzen gefunden wurde, die
					% bisherigen abspeichern:
					data_phase = data_phase_merged(:,1:6*setti.max_num_data_set); %#ok<NASGU>
					name = ['Load',files.sep,season,files.sep,weekday,...
						files.sep,househ,files.sep,...
						num2str(counter_idx_file,'%03.0f')];
					path_db = [files.target.path,filesep,season,filesep,weekday];
					save([path_db,filesep,name,'.mat'],'data_phase');
					% die restlichen Daten wieder zurückschreiben:
					data_phase = data_phase_merged(:,6*setti.max_num_data_set+1:end);
					data_phase_merged = data_phase;
					% Anzahl gespeicherter Daten aktualisieren:
					counter_datasets = size(data_phase_merged,2)/6;
					% Dateiindex erweitern:
					counter_idx_file = counter_idx_file + 1;
				end
			end
			% die (restlichen) Daten speichern:
			data_phase = data_phase_merged;
			if ~isempty(data_phase)
				name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
					househ,files.sep,num2str(counter_idx_file,'%03.0f')];
				path_db = [files.target.path,filesep,season,filesep,weekday];
				save([path_db,filesep,name,'.mat'],'data_phase');
			end
			clear data_phase;
			% Zusatzdaten in eigene Datei speichern:
			data_info = [...
				data_merged_max; ...
				data_merged_min; ...
				data_merged_e; ...
				];
			% Zusatzdaten speichern:
			name = ['Load',files.sep,season,files.sep,weekday,files.sep,...
				househ,files.sep,'Info'];
			save([path_db,filesep,name,'.mat'],'data_info');
			% Ausgabe an Konsole:
			if setti.add_data_mode
				if counter_datasets_new == counter_datasets_total
				fprintf(['\nErledigt: ',season,files.sep,weekday,files.sep,...
					househ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
					num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
				else
				fprintf(['\nErledigt: ',season,files.sep,weekday,files.sep,...
					househ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
					num2str(counter_datasets_new,'%5.0f'),' neue Datensätze, ',...
					num2str(counter_datasets_total,'%5.0f'),' Gesamt']);
				end
			else
				fprintf(['\nErledigt: ',season,files.sep,weekday,files.sep,...
					househ,files.sep,num2str(counter_idx_file,'%03.0f'),': ',...
					num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
			end
			% Zählerstände speichern:
			setti.counter.datasets_total.(season).(weekday).(househ) = ...
				counter_datasets_total;
			setti.counter.datasets.(season).(weekday).(househ) = counter_datasets;
			setti.counter.idx_file.(season).(weekday).(househ) = counter_idx_file;
		end
	end
end
fprintf('\n-----------');

%------------------------------------------------------------------------------------
% Abarbeiten der Erzeugerprofile (Solar)
%------------------------------------------------------------------------------------
 
% % Einlesen der Dateinamen im Quellordner:
files.source.names_sola = dir(files.source.path_sola);
files.source.names_sola = struct2cell(files.source.names_sola);
files.source.names_sola = files.source.names_sola(1,3:end);
% 
% setti.typs_sola = cell(0,0); 
% 
% % Die Simulationsparameter auslesen:
% for i = 1:size(files.source.names_sola,2)
% 	% aktuellen Dateinamen auslesen + Dateiendung entfernen
% 	data.name = files.source.names_sola{1,i}(1:end-4);
% 	data.name_parts = regexp(data.name, files.sep, 'split');
% 	% handelt es sich um ein Simulationslog?
% 	if strcmp(data.name_parts{2},'Simulations-Log')
% 		% falls ja, diesen Eintrag überspringen:
% 		continue;
% 	end
% 	typ = data.name_parts{5};
% 	typ = regexprep(typ, '°', 'Deg'); %° bei PV-Typ-Namen ersetzen
% 	typ = regexprep(typ, '-', '_'); %° bei PV-Typ-Namen ersetzen
% 	idx = find(strcmp(setti.typs_sola, typ), 1);
% 	if isempty(idx) 
% 		% Neuer Anlagentyp gefunden, speichern und Leerarray anlegen:
% 		setti.typs_sola{end+1} = typ;
% 		for j = 1:numel(setti.seasons)
% 			files.typ_allocation_pv.(setti.seasons{j}).Genera.(typ) = [];
% 		end
% 	end
% 	% Festellung der Zurodnung der Dateien:
% 	idx = strcmp(setti.seasons, data.name_parts{4});  % Jahreszeit
% 	season = setti.seasons{idx};
% 	files.typ_allocation_pv.(season).Genera.(typ)(end+1) = i;
% end
% 
% for i = 1:numel(setti.seasons)
% 	season = setti.seasons{i};
% 	counter_datasets_total = 0;
% 	for j = 1:numel(setti.typs_sola)
% 		counter_datasets_total = 0;
% 		typ = setti.typs_sola{j};
% 		idx = files.typ_allocation_pv.(season).Genera.(typ);
% 		if isempty(idx)
% 			continue;
% 		end
% 		counter_datasets = 0;
% 		counter_idx_file = 1;
% 		for l = 1:numel(idx)
% 			% Datei laden (data_phase):
% 			load([files.source.path_sola,filesep,...
% 				files.source.names_sola{idx(l)}]);
% 			% zus. Daten ermitteln:
% 			% Max. Wert [W]:
% 			data_max = max(data_phase);
% 			% Min. Wert [W]:
% 			data_min = min(data_phase);
% 			% Energieinhalt [kWh/kW_inst]:
% 			data_e = sum(data_phase,1)/3.6e6;
% 			if l == 1
% 				data_merged_max = data_max;
% 				data_merged_min = data_min;
% 				data_merged_e = data_e;
% 			else
% 				data_merged_max = [data_merged_max, data_max]; %#ok<AGROW>
% 				data_merged_min = [data_merged_min,data_min]; %#ok<AGROW>
% 				data_merged_e = [data_merged_e,data_e]; %#ok<AGROW>
% 			end
% 			if l == 1 ||counter_datasets == 0
% 				data_phase_merged = data_phase;
% 			else
% 				data_phase_merged = [data_phase_merged, data_phase]; %#ok<AGROW>
% 			end
% 			counter_datasets = counter_datasets + size(data_phase,2)/6;
% 			while counter_datasets >= setti.max_num_data_set
% 				% Wenn maximale Anzahl an Datensätzen gefunden wurde, die
% 				% bisherigen abspeichern:
% 				data_phase = data_phase_merged(:,1:6*setti.max_num_data_set); %#ok<NASGU>
% 				typ = regexprep(typ, 'Deg', '°');
% 				name = ['Gene',files.sep,season,...
% 					files.sep,'Solar',files.sep,typ,files.sep,...
% 					num2str(counter_idx_file,'%03.0f')];
% 				path_db = [files.target.path,filesep,season,filesep,'Genera'];
% 				save([path_db,filesep,name,'.mat'],'data_phase');
% 				% die restlichen Daten wieder zurückschreiben:
% 				data_phase = data_phase_merged(:,6*setti.max_num_data_set+1:end);
% 				data_phase_merged = data_phase;
% 				% Anzahl gespeicherter Daten aktualisieren:
% 				counter_datasets = size(data_phase,2)/6;
% 				counter_datasets_total = counter_datasets_total + ...
% 					setti.max_num_data_set;
% 				% Dateiindex erweitern:
% 				counter_idx_file = counter_idx_file + 1;
% 			end
% 		end
% 		% die (restlichen) Daten speichern:
% 		data_phase = data_phase_merged;
% 		if ~isempty(data_phase)
% 			typ = regexprep(typ, 'Deg', '°');
% 			name = ['Gene',files.sep,season,...
% 				files.sep,'Solar',files.sep,typ,files.sep,...
% 				num2str(counter_idx_file,'%03.0f')];
% 			path_db = [files.target.path,filesep,season,filesep,'Genera'];
% 			save([path_db,filesep,name,'.mat'],'data_phase');
% 			counter_datasets_total = counter_datasets_total + ...
% 				size(data_phase,2)/6;
% 		end
% 		clear data_phase;
% 		% Zusatzdaten in eigene Datei speichern:
% 		data_info = [...
% 			data_merged_max; ...
% 			data_merged_min; ...
% 			data_merged_e; ...
% 			];
% 		% Zusatzdaten speichern:
% 		name = ['Gene',files.sep,season,...
% 			files.sep,'Solar',files.sep,typ,files.sep,...
% 			'Info'];
% 		save([path_db,filesep,name,'.mat'],'data_info');
% 		fprintf(['\nErledigt: ',season,files.sep,...
% 			'Solar',files.sep,typ,files.sep,...
% 			num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
% 	end
% end
% 
% %------------------------------------------------------------------------------------
% % Abarbeiten der Erzeugerprofile (Wind)
% %------------------------------------------------------------------------------------
% 
% % Einlesen der Dateinamen im Quellordner:
% files.source.names_wind = dir(files.source.path_wind);
% files.source.names_wind = struct2cell(files.source.names_wind);
% files.source.names_wind = files.source.names_wind(1,3:end);
% 
% setti.typs_wind = cell(0,0); 
% 
% % Die Simulationsparameter auslesen:
% for i = 1:size(files.source.names_wind,2)
% 	% aktuellen Dateinamen auslesen + Dateiendung entfernen
% 	data.name = files.source.names_wind{1,i}(1:end-4);
% 	data.name_parts = regexp(data.name, files.sep, 'split');
% 	% handelt es sich um ein Simulationslog?
% 	if strcmp(data.name_parts{2},'Simulations-Log')
% 		% falls ja, diesen Eintrag überspringen:
% 		continue;
% 	end
% 	typ = data.name_parts{5};
% 	idx = find(strcmp(setti.typs_wind, typ), 1);
% 	if isempty(idx) 
% 		% Neuer Anlagentyp gefunden, speichern und Leerarray anlegen:
% 		setti.typs_wind{end+1} = typ;
% 		for j = 1:numel(setti.seasons)
% 			files.typ_allocation_wi.(setti.seasons{j}).Genera.(typ) = [];
% 		end
% 	end
% 	% Festellung der Zurodnung der Dateien:
% 	idx = strcmp(setti.seasons, data.name_parts{4});  % Jahreszeit
% 	season = setti.seasons{idx};
% 	files.typ_allocation_wi.(season).Genera.(typ)(end+1) = i;
% end
% 
% for i = 1:numel(setti.seasons)
% 	season = setti.seasons{i};
% 	for j = 1:numel(setti.typs_wind)
% 		counter_datasets_total = 0;
% 		typ = setti.typs_wind{j};
% 		idx = files.typ_allocation_wi.(season).Genera.(typ);
% 		if isempty(idx)
% 			continue;
% 		end
% 		counter_datasets = 0;
% 		counter_idx_file = 1;
% 		for l = 1:numel(idx)
% 			% Datei laden (data_phase):
% 			load([files.source.path_wind,filesep,...
% 				files.source.names_wind{idx(l)}]);
% 			% zus. Daten ermitteln:
% 			% Max. Wert [W]:
% 			data_max = max(data_phase);
% 			% Min. Wert [W]:
% 			data_min = min(data_phase);
% 			% Energieinhalt [kWh/kW_inst]:
% 			data_e = sum(data_phase,1)/3.6e6;
% 			if l == 1
% 				data_merged_max = data_max;
% 				data_merged_min = data_min;
% 				data_merged_e = data_e;
% 			else
% 				data_merged_max = [data_merged_max, data_max]; %#ok<AGROW>
% 				data_merged_min = [data_merged_min,data_min]; %#ok<AGROW>
% 				data_merged_e = [data_merged_e,data_e]; %#ok<AGROW>
% 			end
% 			if l == 1 ||counter_datasets == 0
% 				data_phase_merged = data_phase;
% 			else
% 				data_phase_merged = [data_phase_merged, data_phase]; %#ok<AGROW>
% 			end
% 			counter_datasets = counter_datasets + size(data_phase,2)/6;
% 			while counter_datasets >= setti.max_num_data_set
% 				% Wenn maximale Anzahl an Datensätzen gefunden wurde, die
% 				% bisherigen abspeichern:
% 				data_phase = data_phase_merged(:,1:6*setti.max_num_data_set); %#ok<NASGU>
% 				name = ['Gene',files.sep,season,...
% 					files.sep,'Wind',files.sep,typ,files.sep,...
% 					num2str(counter_idx_file,'%03.0f')];
% 				path_db = [files.target.path,filesep,season,filesep,'Genera'];
% 				save([path_db,filesep,name,'.mat'],'data_phase');
% 				% die restlichen Daten wieder zurückschreiben:
% 				data_phase = data_phase_merged(:,6*setti.max_num_data_set+1:end);
% 				data_phase_merged = data_phase;
% 				% Anzahl gespeicherter Daten aktualisieren:
% 				counter_datasets = size(data_phase,2)/6;
% 				counter_datasets_total = counter_datasets_total + ...
% 					setti.max_num_data_set;
% 				% Dateiindex erweitern:
% 				counter_idx_file = counter_idx_file + 1;
% 			end
% 		end
% 		% die (restlichen) Daten speichern:
% 		data_phase = data_phase_merged;
% 		if ~isempty(data_phase)
% 			name = ['Gene',files.sep,season,...
% 				files.sep,'Wind',files.sep,typ,files.sep,...
% 				num2str(counter_idx_file,'%03.0f')];
% 			path_db = [files.target.path,filesep,season,filesep,'Genera'];
% 			save([path_db,filesep,name,'.mat'],'data_phase');
% 			counter_datasets_total = counter_datasets_total + ...
% 				size(data_phase,2)/6;
% 		end
% 		clear data_phase;
% 		% Zusatzdaten in eigene Datei speichern:
% 		data_info = [...
% 			data_merged_max; ...
% 			data_merged_min; ...
% 			data_merged_e; ...
% 			];
% 		% Zusatzdaten speichern:
% 		name = ['Gene',files.sep,season,...
% 			files.sep,'Wind',files.sep,typ,files.sep,...
% 			'Info'];
% 		save([path_db,filesep,name,'.mat'],'data_info');
% 		% Arbeitsfortschritt in Konsole ausgeben:
% 		fprintf(['\nErledigt: ',season,files.sep,...
% 			'Wind',files.sep,typ,files.sep,...
% 			num2str(counter_datasets_total,'%5.0f'),' Datensätze']);
% 	end
% end
 
% % Einstellungen und Dateiaufbau speichern:
% save([files.target.path,filesep,setti.name_database,'.mat'],'files','setti');
