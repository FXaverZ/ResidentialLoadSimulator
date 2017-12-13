function handles = get_data_solar (handles)
%GET_DATA_SOLAR    extrahiert und simuliert die Einspeise-Daten der Solaranlagen

% Erstellt von:            Franz Zeilinger - 04.07.2012
% Letzte Änderung durch:   Franz Zeilinger - 16.08.2012

system = handles.System;   % Systemvariablen
settin = handles.Current_Settings; % aktuelle Einstellungen
db_fil = settin.Database;  % Datenbankstruktur
max_num_data_set = db_fil.setti.max_num_data_set*6; % Anzahl an Datensätzen in einer
%                                                     Teildatei --> da im Fall von
%                                                     Wetterdaten nur eine Spalte pro
%                                                     Zeitreihe (im Gegensatz zu
%                                                     sechs bei den Haushalten)
%                                                     benötigt wird, die Anzahl
%                                                     entsprechend erhöhen...
sep = db_fil.files.sep;    % Trenner im Dateinamen (' - ')

% die aktuellen Zeitdaten (Jahreszeit, Wochentag) auslesen:
season = system.seasons{settin.Season,1};

% zeitliche Auflösung ermitteln:
time_res = system.time_resolutions{settin.Data_Extract.Time_Resolution,2};
% Ergebnis-Arrays initialisieren:
Solar.Data_Sample = [];
Solar.Data_Mean = [];
Solar.Data_Min = [];
Solar.Data_Max = [];

% Gesamtanzahl der zu simulierenden Anlagen ermitteln:
plants = fieldnames(handles.Current_Settings.Sola);
number_plants = 0;
for i=1:numel(plants)
	plant = handles.Current_Settings.Sola.(plants{i});
	if plant.Typ == 1
		continue;
	else
		number_plants = number_plants + plant.Number;
	end
end

% Überprüfen, ob überhaupt PV-Erzeugungsanlagen verarbeitet werden sollen:
if number_plants == 0
	% (leeres) Ergebnis zurückschreiben:
	handles.Result.Solar = Solar;
	% Funktion beenden:
	return;
end

% Die Info-Datei laden:
path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,'Genera'];
name = ['Gene',sep,season,sep,'Solar',sep,'Cloud_Factor',sep,'Info'];
% Daten laden (Variable "data_info")
load([path,filesep,name,'.mat']);
% wieviele Datensätze gibt es insgesamt?
num_data_sets = size(data_info,2);

% Aus den allgemeinen Strahlungsdaten und den Analgenparametern die aktuellen
% Einstrahlungswerte interpolieren, dazu erst die entsprechenden Daten laden:
name = ['Gene',sep,season,sep,'Solar',sep,'Radiation'];
% Daten laden (Variable 'radiation_data_fix','radiation_data_tra' und 'Content'):
load([path,filesep,name,'.mat']);

% Aufbau des Arrays für geneigte Flächen (fix montiert, 'radiation_data_fix'):
% 1. Dimension: Monat innerhalb einer Jahreszeit (je 4 Monate)
% 2. Dimension: Orientierung z.B. [-15°, 0°, 15°] (0° = Süd; -90° = Ost)
% 3. Dimension: Neigung [15°, 30°, 45°, 60°, 90°] (0°  = waagrecht,
%                                                        90° = senkrecht,
%                                                        trac = Tracker)
% 4. Dimension: Datenart [Zeit, Temperatur, Direkt, Diffus]
% 5. Dimension: Werte in W/m^2
%
% Beim Array für die nachgeführten Anlagen (Tracker, 'radiation_data_tra') entfallen
% die Dimensionen für "Orientierung" und "Neigung"!
%
% Die Struktur "Content" enthält die korrekten Bezeichnungen/Werte der einzelnen
% Dimensionen für die spätere Weiterverarbeitung (für Indexsuche bzw.
% Interpolationen). Aufbau siehe: 'create_radiation_array.m'

% je nach Einstellungen die Wetterdaten des aktuellen Tages einlesen:
switch settin.Worstcase_Generation
	case 1 % zufällige Auswahl
		% einen beliebigen Monat auswählen:
		month_fix = vary_parameter((1:4)', 25*ones(1,4)', 'List');
		month_tra = month_fix;
		% Zufällig einen Wolkendatensatz auswählen:
		pool = 1:num_data_sets; % Liste mit Indizes der möglichen Datensätze
		% Erzeugen einer Zufallszahl im Bereich [1, Anz._verf._Datensätze]
		fortu = round(rand()*(numel(pool)-1))+1;
		idx = pool(fortu); % Dieser Index bezeichnet den ausgewählten Datensatz!
% % ---  FOR DEBUG OUTPUTS  ---
% % Use always the same cloud factor index (for debug):
% 		idx = 76;
% % --- --- --- --- --- --- ---
	case 2 % höchste Tagesenergieeinspeisung
		% Monat auswählen mit den höchsten durchnschnittlichen Einstrahlungswerten
		% bei der direkten Einstrahlung. Exemplarisch wird die geringste Neigung und
		% Südausrichtung herangezogen:
		idx_orient = db_fil.setti.content_sola_data.orienta == 0; % Index der Südausrichtung
		idx_inclin = db_fil.setti.content_sola_data.inclina == ...
			min(db_fil.setti.content_sola_data.inclina); % Index der geringsten
		% Neigung
		% Anzahl der Datenpunkte jedes Monats ermitteln (d.h. Zeitwert > 0)
		num_datapoi = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,1,:)) > 0,2); %#ok<NODEF>
		% Durchschnittliche Einstrahlung ermitteln:
		e_avg_fix = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,3,:)),2)./num_datapoi;
		e_avg_tra = sum(squeeze(radiation_data_tra(:,3,:)),2)./num_datapoi; %#ok<NODEF>
		% Monat auswählen, in dem die durchschnittliche Einstrahlung Maximal wird:
		month_fix = find(e_avg_fix == max(e_avg_fix),1); % Monat für fixe Anlagen
		month_tra = find(e_avg_tra == max(e_avg_tra),1); % Monat für Tracker
		
		% Datensatz mit der geringsten durchschnittlichen Bewölkung finden:
		[~, I] = sort(data_info);
		idx = I(1);
	case 3 % niedrigste Tagesenergieeinspeisung
		% Monat auswählen mit den geringsten durchnschnittlichen Einstrahlungswerten
		% bei der direkten Einstrahlung. Exemplarisch wird die geringste Neigung und
		% Südausrichtung herangezogen:
		idx_orient = db_fil.setti.content_sola_data.orienta == 0; % Index der Südausrichtung
		idx_inclin = db_fil.setti.content_sola_data.inclina == ...
			min(db_fil.setti.content_sola_data.inclina); % Index der geringsten
		% Neigung
		% Anzahl der Datenpunkte jedes Monats ermitteln (d.h. Zeitwert > 0)
		num_datapoi = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,1,:)) > 0,2); %#ok<NODEF>
		% Durchschnittliche Einstrahlung ermitteln:
		e_avg_fix = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,3,:)),2)./num_datapoi;
		e_avg_tra = sum(squeeze(radiation_data_tra(:,3,:)),2)./num_datapoi; %#ok<NODEF>
		% Monat auswählen, in dem die durchschnittliche Einstrahlung Maximal wird:
		month_fix = find(e_avg_fix == min(e_avg_fix),1); % Monat für fixe Anlagen
		month_tra = find(e_avg_tra == min(e_avg_tra),1); % Monat für Tracker
		
		% Datensatz mit der höchsten durchschnittlichen Bewölkung finden:
		[~, I] = sort(data_info,'descend');
		idx = I(1);
		% 	case 4
end

% % ---  FOR DEBUG OUTPUTS  ---
% % Use always the same month index (for debug):
% month_fix = 1;
% month_tra = month_fix;
% % --- --- --- --- --- --- ---

% nun den ausgewählten Datensatz aus der richtigen Teildatei laden:
for j=1:ceil(num_data_sets/max_num_data_set)
	% jene Indizes ermitteln, die in aktueller Teil-Datei enthalten sind
	idx_part = idx(idx > (j-1)*max_num_data_set & idx <= j*max_num_data_set);
	if isempty(idx_part)
		% sind keine Daten in dieser Datei, die ausgelesen werden müssen, diese
		% überspringen:
		continue;
	end
	% Indexzahl korrigieren (der Index der geladenen Daten geht nur von
	% 1:max_num_datasets je Datei):
	idx_part = idx_part - (j-1)*max_num_data_set;
	% Name der aktuellen Teil-Datei:
	name = ['Gene',sep,season,sep,'Solar',sep,'Cloud_Factor',sep,...
		num2str(j,'%03.0f')];
	% Daten laden (Variable "data_cloud_factor")
	load([path,filesep,name,'.mat']);
	% die relevanten Daten auslesen:
	data_cloud_factor = data_cloud_factor(:,idx_part);
% % ---  FOR DEBUG OUTPUTS  ---
% 	figure; plot(data_cloud_factor)
% 	xls = XLS_Writer();
% 	xls.set_worksheet('Cloud_Factor');
% 	xls.write_values(data_cloud_factor);
% % --- --- --- --- --- --- ---
end

% nun stehen für die Anlagen jeweils Einstrahlungsdaten sowie Wolkeneinflussdate zur
% Verfügung. Mit diesen Daten sowie den definierten Anlagenparametern werden nun die
% Anlagen simuliert:
for i=1:numel(plants)
	plant = handles.Current_Settings.Sola.(plants{i});
	% Falls keine Anlage ausgewählt, diesen Eintrag überspringen:
	if plant.Typ == 1
		continue;
	end
	switch plant.Typ
		case 2 % Fix installierte Anlage
			data_phase = model_pv_fix(plant, db_fil.setti.content_sola_data, ...
				data_cloud_factor, radiation_data_fix, month_fix);
% % ---  FOR DEBUG OUTPUTS  ---
% 			data_phase = model_pv_fix(plant, db_fil.setti.content_sola_data, ...
% 				data_cloud_factor, radiation_data_fix, month_fix, xls);
% % --- --- --- --- --- --- ---
		case 3 % Tracker
			data_phase = model_pv_tra(plant, db_fil.setti.content_sola_data, ...
				data_cloud_factor, radiation_data_tra, month_tra);
% % ---  FOR DEBUG OUTPUTS  ---
% 			data_phase = model_pv_tra(plant, db_fil.setti.content_sola_data, ...
% 				data_cloud_factor, radiation_data_tra, month_tra, xls);
% % --- --- --- --- --- --- ---
	end
	% je nach Einstellungen, die relevanten Daten auslesen:
	if settin.Data_Extract.get_Sample_Value
		data_sample = data_phase(1:time_res:end,:);
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
		Solar.Data_Sample = [Solar.Data_Sample,...
			data_sample];
	end
	if settin.Data_Extract.get_Mean_Value || ...
			settin.Data_Extract.get_Min_Max_Value
		% Das ursprüngliche Datenarray so umformen, dass ein 3D Array mit allen
		% Werten eines Zeitraumes in der ersten Dimension entsteht. Diese wird
		% dann durch die nachfolgenden Funktionen (mean, min, max) sofort in die
		% entsprechenden Werte umgerechnet. Mit squeeze muss dann nur mehr die
		% Singleton-Dimension entfernt werden...
		data_phase = data_phase(1:end-1,:);
		data_mean = reshape(data_phase,...
			time_res,[],size(data_phase,2));
		% eingelesenen Daten wieder löschen (Speicher freigeben!)
		clear data_phase;
	end
	if settin.Data_Extract.get_Min_Max_Value
		data_min = squeeze(min(data_mean));
		data_max = squeeze(max(data_mean));
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
		Solar.Data_Min = [Solar.Data_Min,...
			data_min];
		Solar.Data_Max = [Solar.Data_Max,...
			data_max];
		% eingelesenen Daten wieder löschen (Speicher freigeben!)
		clear data_min;
		clear data_max;
	end
	if settin.Data_Extract.get_Mean_Value
		data_mean = squeeze(mean(data_mean));
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
		Solar.Data_Mean = [Solar.Data_Mean,...
			data_mean];
		% eingelesenen Daten wieder löschen (Speicher freigeben!)
		clear data_mean
	end
end
% % ---  FOR DEBUG OUTPUTS  ---
% xls.write_output([num2str(idx),'-Input.xlsx']);
% % --- --- --- --- --- --- ---

% Ergebnis zurückschreiben:
handles.Result.Solar = Solar;
end

