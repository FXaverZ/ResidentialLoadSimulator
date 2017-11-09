function handles = get_data(handles)
%GET_DATA    extrahiert die Daten aus der Datenbank gemäß den Einstellungen

system = handles.System;   % Systemvariablen
settin = handles.Settings; % aktuelle Einstellungen
db_fil = settin.Database;  % Datenbankstruktur
max_num_data_set = db_fil.setti.max_num_data_set; % Anzahl an Datensätzen in einer
                                                  % Teildatei
sep = db_fil.files.sep;    % Trenner im Dateinamen (' - ')

% die aktuellen Zeitdaten (Jahreszeit, Wochentag) auslesen:
season = system.seasons{settin.Season,1};
weekda = system.weekdays{settin.Weekday,1};
% Auslesen der zeitlichen Auflösung in Sekunden:
time_resolution = system.time_resolutions{settin.Time_Resolution,2};

% die einzelnen Haushaltsklassen durchgehen:
Result.Households.Data = [];
for i=1:size(system.housholds,1)
	% Anzahl der Haushalte gemäß Einstellungen auslesen:
	number_hh = settin.Households.(system.housholds{i,1}).Number;
	if number_hh < 1
		% Falls für diesen Haushalt keine Daten extrahiert werden sollen (Anzahl =
		% 0), überspringen:
		continue;
	end
	% Info Datei laden:
	path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,weekda];
	name = ['Load',sep,season,sep,weekda,sep,system.housholds{i,1},sep,'Info'];
	% Daten laden (Variable "data_info")
	load([path,filesep,name,'.mat']);
	% wieviele Datensätze gibt es insgesamt?
	num_data_sets = size(data_info,2)/6;
	
	% Je nach Einstellung Datensätze auswählen:
	switch settin.Worstcase_Housholds
		case 1 % Einstellung: Zufällige Auswahl
			% eine Indexliste erstellen, mit zufällig ausgewählten Datensätzen:
			pool = 1:num_data_sets; % Liste mit Indizes der möglichen Datensätze
			idx = zeros(number_hh,1); % Liste mit Indizes der ausgewählten Datensätze
			                          % (mit 0 intialisieren)
			for j = 1:number_hh
				% Erzeugen einer Zufallszahl im Bereich [1, Anz._verf._Datensätze]
				fortu = round(rand()*(numel(pool)-1))+1;
				idx(j) = pool(fortu); % diesen Index in Indexliste aufnehmen
				% gezogenen Datensatz aus der Auswahlmöglickeit entfernen (damit er
				% nicht mehr gezogen werden kann):
				pool(fortu) = [];
			end
		case 2 % Worst Case: Höchster Energieverbrauch
			data_e = sum([...
				data_info(3,1:6:end);...
				data_info(3,3:6:end);...
				data_info(3,5:6:end)],1); %#ok<COLND>
			[~, I] = sort(data_e,'descend');
			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen:
			idx = I(1:number_hh)';
		case 3 % Worst Case: Niedrigster Energieverbrauch
			data_e = sum([...
				data_info(3,1:6:end);...
				data_info(3,3:6:end);...
				data_info(3,5:6:end)],1); %#ok<COLND>
			[~, I] = sort(data_e);
			% die geforderten Inidizes mit dem niedrigsten Energieverbrauch
			% übernehmen: 
			idx = I(1:number_hh)';
		case 4 % Worst Case: Höchste Leistungsaufnahme
			data_max = sum([...
				data_info(1,1:6:end);...
				data_info(1,3:6:end);...
				data_info(1,5:6:end)],1); %#ok<COLND>
			[~, I] = sort(data_max,'descend');
			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen:
			idx = I(1:number_hh)';
	end
	% die ermittelten Indizes sortieren (für effektiveres Abarbeiten):
	idx = sort(idx);
	% nun die einzelnen Datensätze aus den jeweiligen Teildateien laden:
	for j=1:ceil(num_data_sets/max_num_data_set)
		% jene Indizes ermitteln, die in aktueller Teil-Datei enthalten sind
		idx_part = idx(idx > (j-1)*max_num_data_set+1 & idx <= j*max_num_data_set);
		if isempty(idx_part)
			% sind keine Daten in dieser Datei, die ausgelesen werden müssen, diese
			% überspringen:
			continue;
		end
		% die Indizes der Datenspalten erstellen: jeder Datensatz besteht aus 6
		% Spalten (3x Wirk-, 3x Blindleistung):
		idx_part_real = repmat((idx_part-1)*6,[1,6])+repmat(1:6,[size(idx_part,1),1]);
		idx_part_real = sort(reshape(idx_part_real,1,[]));
		% Indexzahl korrigieren (:
		idx_part_real = idx_part_real - (j-1)*6*max_num_data_set;
		% Name der aktuellen Teil-Datei:
		name = ['Load',sep,season,sep,weekda,sep,system.housholds{i,1},sep,...
			num2str(j,'%03.0f')];
		% Daten laden (Variable "data_phase")
		load([path,filesep,name,'.mat']);
		% die relevanten Daten auslesen:
		data_sel = data_phase(1:time_resolution:end,idx_part_real);   %#ok<COLND>
		% eingelesenen Daten wieder löschen (Speicher freigeben!)
		clear data_phase;
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
		Result.Households.Data = [Result.Households.Data, data_sel];
	end
end

% % Solaranlagen behandeln:
% Result.Solar.Data = [];
% todo = {...
% 	'Sola_1', 'typ_sola', 'popup_genera_pv_1_typ', ...
% 	'edit_genera_pv_1_number', 'edit_genera_pv_1_installed_power', ...
% 	'push_genera_pv_1_parameters', 'push_genera_pv_add_system';...
% 	'Sola_2', 'typ_sola', 'popup_genera_pv_2_typ', ...
% 	'edit_genera_pv_2_number', 'edit_genera_pv_2_installed_power', ...
% 	'push_genera_pv_2_parameters', 'push_genera_pv_add_system';...
% 	};
% for i=1:2
% 	number_dev = settin.(todo{i,1}).Number;
% 	power_inst = settin.(todo{i,1}). Power_Installed;
% 	typ = system.typ_sola{settin.(todo{i,1}).Typ,2};
% 	if number_dev < 1
% 		continue;
% 	end
% 	% Info Datei laden:
% 	path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,'Genera'];
% 	name = ['Gene',sep,season,sep,'Solar',sep,typ,sep,'Info'];
% 	% Daten laden (data_info)
% 	load([path,filesep,name,'.mat']);
% 	% wieviele Datensätze gibt es?
% 	num_data_sets = size(data_info,2)/6;
% 	switch settin.Worstcase_Generation
% 		case 1 % Zufällige Auswahl
% 			% eine Indexliste erstellen, mit zufällig ausgewählten Datensätzen:
% 			pool = 1:num_data_sets; % Liste mit Indizes der möglichen Datensätze
% 			idx = zeros(number_dev,1);
% 			for j = 1:number_dev
% 				fortu = round(rand()*(numel(pool)-1))+1;
% 				idx(j) = pool(fortu);
% 				% gezogenen Datensatz aus der Auswahlmöglickeit entfernen:
% 				pool(fortu) = [];
% 			end
% 			case 2 % Höchste Einspeisung
% 			data_e = sum([...
% 				data_info(3,1:6:end);...
% 				data_info(3,3:6:end);...
% 				data_info(3,5:6:end)],1); %#ok<COLND>
% 			[~, I] = sort(data_e,'descend');
% 			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen:
% 			idx = I(1:number_dev)';
% 		case 3 % Niedrigste Tageseinspeisung
% 			data_e = sum([...
% 				data_info(3,1:6:end);...
% 				data_info(3,3:6:end);...
% 				data_info(3,5:6:end)],1); %#ok<COLND>
% 			data_e = data_e(data_e > 0);
% 			[~, I] = sort(data_e);
% 			% die geforderten Inidizes mit dem niedrigsten Energieverbrauch übernehmen:
% 			idx = I(1:number_dev)';
% 		case 4 % Höchste Leistungsspitze beim Einspeisen
% 			data_max = sum([...
% 				data_info(1,1:6:end);...
% 				data_info(1,3:6:end);...
% 				data_info(1,5:6:end)],1); %#ok<COLND>
% 			[~, I] = sort(data_max,'descend');
% 			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen:
% 			idx = I(1:number_dev)';	
% 	end
% 	idx = sort(idx);
% 	% nun die einzelnen Datensätze aus den jeweiligen Teildateien laden:
% 	for j=1:ceil(num_data_sets/max_num_data_set)
% 		idx_part = idx(idx > (j-1)*max_num_data_set+1 & idx <= j*max_num_data_set);
% 		% die Indizes der Datenspalten erstellen: jeder Datensatz besteht ja aus 6
% 		% Spalten:
% 		if isempty(idx_part)
% 			continue;
% 		end
% 		idx_part_real = repmat((idx_part-1)*6,[1,6])+repmat(1:6,[size(idx_part,1),1]);
% 		idx_part_real = sort(reshape(idx_part_real,1,[]))-(j-1)*max_num_data_set*6;
% 		% daten laden:
% 		name = ['Gene',sep,season,sep,'Solar',sep,typ,sep,...
% 			num2str(j,'%03.0f')];
% 		% Daten laden (data_phase)
% 		load([path,filesep,name,'.mat']);
% 		% die relevanten Daten auslesen:
% 		data_sel = data_phase(:,idx_part_real) * power_inst * 1000;
% 		clear data_phase;
% 		Result.Solar.Data = [Result.Solar.Data, data_sel];
% 	end
% end
% 
% % Windkraftanlagen behandeln:
% Result.Wind.Data = [];
% todo = {...
% 	'Wind_1', 'typ_wind', 'popup_genera_wind_1_typ', ...
% 	'edit_genera_wind_1_number', 'edit_genera_wind_1_installed_power', ...
% 	'push_genera_wind_1_parameters', 'push_genera_wind_add_system';...
% 	'Wind_2', 'typ_wind', 'popup_genera_wind_2_typ', ...
% 	'edit_genera_wind_2_number', 'edit_genera_wind_2_installed_power', ...
% 	'push_genera_wind_2_parameters', 'push_genera_wind_add_system';...
% };
% for i=1:2
% 	number_dev = settin.(todo{i,1}).Number;
% 	power_inst = settin.(todo{i,1}).Power_Installed;
% 	typ = system.typ_wind{settin.(todo{i,1}).Typ,2};
% 	if number_dev < 1
% 		continue;
% 	end
% 	% Info Datei laden:
% 	path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,'Genera'];
% 	name = ['Gene',sep,season,sep,'Wind',sep,typ,sep,'Info'];
% 	% Daten laden (data_info)
% 	load([path,filesep,name,'.mat']);
% 	% wieviele Datensätze gibt es?
% 	num_data_sets = size(data_info,2)/6;
% 	switch settin.Worstcase_Generation
% 		case 1 % Zufällige Auswahl
% 			% eine Indexliste erstellen, mit zufällig ausgewählten Datensätzen:
% 			pool = 1:num_data_sets; % Liste mit Indizes der möglichen Datensätze
% 			idx = zeros(number_dev,1);
% 			for j = 1:number_dev
% 				fortu = round(rand()*(numel(pool)-1))+1;
% 				idx(j) = pool(fortu);
% 				% gezogenen Datensatz aus der Auswahlmöglickeit entfernen:
% 				pool(fortu) = [];
% 			end
% 			case 2 % Höchste Einspeisung
% 			data_e = sum([...
% 				data_info(3,1:6:end);...
% 				data_info(3,3:6:end);...
% 				data_info(3,5:6:end)],1); %#ok<COLND>
% 			[~, I] = sort(data_e,'descend');
% 			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen:
% 			idx = I(1:number_dev)';
% 		case 3 % Niedrigste Tageseinspeisung
% 			data_e = sum([...
% 				data_info(3,1:6:end);...
% 				data_info(3,3:6:end);...
% 				data_info(3,5:6:end)],1); %#ok<COLND>
% 			data_e = data_e(data_e > 0);
% 			[~, I] = sort(data_e);
% 			% die geforderten Inidizes mit dem niedrigsten Energieverbrauch übernehmen:
% 			idx = I(1:number_dev)';
% 		case 4 % Höchste Leistungsspitze beim Einspeisen
% 			data_max = sum([...
% 				data_info(1,1:6:end);...
% 				data_info(1,3:6:end);...
% 				data_info(1,5:6:end)],1); %#ok<COLND>
% 			[~, I] = sort(data_max,'descend');
% 			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen:
% 			idx = I(1:number_dev)';	
% 	end
% 	idx = sort(idx);
% 	% nun die einzelnen Datensätze aus den jeweiligen Teildateien laden:
% 	for j=1:ceil(num_data_sets/max_num_data_set)
% 		idx_part = idx(idx > (j-1)*max_num_data_set+1 & idx <= j*max_num_data_set);
% 		if isempty(idx_part)
% 			continue;
% 		end
% 		% die Indizes der Datenspalten erstellen: jeder Datensatz besteht ja aus 6
% 		% Spalten:
% 		idx_part_real = repmat((idx_part-1)*6,[1,6])+repmat(1:6,[size(idx_part,1),1]);
% 		idx_part_real = sort(reshape(idx_part_real,1,[]))-(j-1)*max_num_data_set*6;
% 		% daten laden:
% 		name = ['Gene',sep,season,sep,'Wind',sep,typ,sep,...
% 			num2str(j,'%03.0f')];
% 		% Daten laden (data_phase)
% 		load([path,filesep,name,'.mat']);
% 		% die relevanten Daten auslesen:
% 		data_sel = data_phase(:,idx_part_real) * power_inst * 1000;
% 		clear data_phase;
% 		Result.Wind.Data = [Result.Wind.Data, data_sel];
% 	end
% end

% abschließend Summenleistungen ermitteln:
Result.Households = calculate_additional_data(Result.Households);
% Result.Solar = calculate_additional_data(Result.Solar);
% Result.Wind = calculate_additional_data(Result.Wind);
% Ergebnis zurückschreiben:
handles.Result = Result;
end

function structure = calculate_additional_data(structure)
structure.Acvtive_Power_Total = sum(structure.Data(:,1:2:end),2);
structure.Reactive_Power_Total = sum(structure.Data(:,2:2:end),2);
structure.Active_Power_Phase = [...
	sum(structure.Data(:,1:6:end),2),...
	sum(structure.Data(:,3:6:end),2),...
	sum(structure.Data(:,5:6:end),2)];
structure.Reactive_Power_Phase = [...
	sum(structure.Data(:,2:6:end),2),...
	sum(structure.Data(:,4:6:end),2),...
	sum(structure.Data(:,6:6:end),2)];
end

