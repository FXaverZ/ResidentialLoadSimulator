function handles = get_data_solar (handles)
%GET_DATA_SOLAR    extrahiert und simuliert die Einspeise-Daten der Solaranlagen

% Franz Zeilinger - 22.12.2011

system = handles.System;   % Systemvariablen
settin = handles.Current_Settings; % aktuelle Einstellungen
db_fil = settin.Database;  % Datenbankstruktur
if isfield (handles, 'Result')
	Result = handles.Result; % Ergebnisstruktur
end
max_num_data_set = db_fil.setti.max_num_data_set*6; % Anzahl an Datens�tzen in einer
                                                    % Teildatei --> da im Fall von
                                                    % Wetterdaten nur eine Spalte pro
                                                    % Zeitreihe (im Gegensatz zu
                                                    % sechs bei den Haushalten)
                                                    % ben�tigt wird, die Anzahl
                                                    % entsprechend erh�hen...
sep = db_fil.files.sep;    % Trenner im Dateinamen (' - ')

% die aktuellen Zeitdaten (Jahreszeit, Wochentag) auslesen:
season = system.seasons{settin.Season,1};
% Auslesen der zeitlichen Aufl�sung in Sekunden:
time_resolution = system.time_resolutions{settin.Time_Resolution,2};

% Ergebnis-Arrays initialisieren:
Result.Solar.Data = [];

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

% �berpr�fen, ob �berhaupt PV-Erzeugungsanlagen verarbeitet werden sollen:
if number_plants == 0
	% (leeres) Ergebnis zur�ckschreiben:
	handles.Result = Result;
	% Funktion beenden:
	return;
end

% Die Info-Datei laden:
path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,'Genera'];
name = ['Gene',sep,season,sep,'Solar',sep,'Cloud_Factor',sep,'Info'];
% Daten laden (Variable "data_info")
load([path,filesep,name,'.mat']);
% wieviele Datens�tze gibt es insgesamt?
num_data_sets = size(data_info,2);

% Aus den allgemeinen Strahlungsdaten und den Analgenparametern die aktuellen
% Einstrahlungswerte interpolieren, dazu erst die entsprechenden Daten laden:
name = ['Gene',sep,season,sep,'Solar',sep,'Radiation'];
% Daten laden (Variable 'radiation_data_fix','radiation_data_tra' und 'Content'):
load([path,filesep,name,'.mat']);

% Aufbau des Arrays f�r geneigte Fl�chen (fix montiert, 'radiation_data_fix'):
% 1. Dimension: Monat innerhalb einer Jahreszeit (je 4 Monate)
% 2. Dimension: Orientierung z.B. [-15�, 0�, 15�] (0� = S�d; -90� = Ost)
% 3. Dimension: Neigung [15�, 30�, 45�, 60�, 90�] (0�  = waagrecht, 
%                                                        90� = senkrecht, 
%                                                        trac = Tracker)
% 4. Dimension: Datenart [Zeit, Temperatur, Direkt, Diffus]
% 5. Dimension: Werte in W/m^2
%
% Beim Array f�r die nachgef�hrten Anlagen (Tracker, 'radiation_data_tra') entfallen
% die Dimensionen f�r "Orientierung" und "Neigung"!
%
% Die Struktur "Content" enth�lt die korrekten Bezeichnungen/Werte der einzelnen
% Dimensionen f�r die sp�tere Weiterverarbeitung (f�r Indexsuche bzw.
% Interpolationen). Aufbau siehe: 'create_radiation_array.m'

% je nach Einstellungen die Wetterdaten des aktuellen Tages einlesen:
switch settin.Worstcase_Generation
	case 1 % zuf�llige Auswahl
		% einen beliebigen Monat ausw�hlen:
		month_fix = vary_parameter((1:4)', 25*ones(1,4)', 'List');
		month_tra = month_fix;
		% Zuf�llig einen Wolkendatensatz ausw�hlen:
		pool = 1:num_data_sets; % Liste mit Indizes der m�glichen Datens�tze
		% Erzeugen einer Zufallszahl im Bereich [1, Anz._verf._Datens�tze]
		fortu = round(rand()*(numel(pool)-1))+1;
		idx = pool(fortu); % Dieser Index bezeichnet den ausgew�hlten Datensatz!
	case 2 % h�chste Tagesenergieeinspeisung
		% Monat ausw�hlen mit den h�chsten durchnschnittlichen Einstrahlungswerten
		% bei der direkten Einstrahlung. Exemplarisch wird die geringste Neigung und
		% S�dausrichtung herangezogen:
		idx_orient = Content.orienta == 0; % Index der S�dausrichtung
		idx_inclin = Content.inclina == min(Content.inclina); % Index der geringsten
		                                                      % Neigung
		% Anzahl der Datenpunkte jedes Monats ermitteln (d.h. Zeitwert > 0)
		num_datapoi = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,1,:)) > 0,2); %#ok<NODEF>
		% Durchschnittliche Einstrahlung ermitteln:
		e_avg_fix = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,3,:)),2)./num_datapoi;
		e_avg_tra = sum(squeeze(radiation_data_tra(:,3,:)),2)./num_datapoi; %#ok<NODEF>
		% Monat ausw�hlen, in dem die durchschnittliche Einstrahlung Maximal wird:
		month_fix = find(e_avg_fix == max(e_avg_fix),1); % Monat f�r fixe Anlagen
		month_tra = find(e_avg_tra == max(e_avg_tra),1); % Monat f�r Tracker
		
		% Datensatz mit der geringsten durchschnittlichen Bew�lkung finden:
		[~, I] = sort(data_info); 
		idx = I(1);
	case 3 % niedrigste Tagesenergieeinspeisung
		% Monat ausw�hlen mit den geringsten durchnschnittlichen Einstrahlungswerten
		% bei der direkten Einstrahlung. Exemplarisch wird die geringste Neigung und
		% S�dausrichtung herangezogen:
		idx_orient = Content.orienta == 0; % Index der S�dausrichtung
		idx_inclin = Content.inclina == min(Content.inclina); % Index der geringsten
		                                                      % Neigung
		% Anzahl der Datenpunkte jedes Monats ermitteln (d.h. Zeitwert > 0)
		num_datapoi = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,1,:)) > 0,2); %#ok<NODEF>
		% Durchschnittliche Einstrahlung ermitteln:
		e_avg_fix = sum(squeeze(...
			radiation_data_fix(:,idx_orient, idx_inclin,3,:)),2)./num_datapoi;
		e_avg_tra = sum(squeeze(radiation_data_tra(:,3,:)),2)./num_datapoi; %#ok<NODEF>
		% Monat ausw�hlen, in dem die durchschnittliche Einstrahlung Maximal wird:
		month_fix = find(e_avg_fix == min(e_avg_fix),1); % Monat f�r fixe Anlagen
		month_tra = find(e_avg_tra == min(e_avg_tra),1); % Monat f�r Tracker
		
		% Datensatz mit der h�chsten durchschnittlichen Bew�lkung finden:
		[~, I] = sort(data_info,'descend'); 
		idx = I(1);
% 	case 4
end

% nun den ausgew�hlten Datensatz aus der richtigen Teildateie laden:
for j=1:ceil(num_data_sets/max_num_data_set)
	% jene Indizes ermitteln, die in aktueller Teil-Datei enthalten sind
	idx_part = idx(idx > (j-1)*max_num_data_set & idx <= j*max_num_data_set);
	if isempty(idx_part)
		% sind keine Daten in dieser Datei, die ausgelesen werden m�ssen, diese
		% �berspringen:
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
	data_cloud_factor = data_cloud_factor(1:time_resolution:end,idx_part); 
end

% nun stehen f�r die Anlagen jeweils Einstrahlungsdaten sowie Wolkeneinflussdate zur
% Verf�gung. Mit diesen Daten sowie den definierten Anlagenparametern werden nun die
% Anlagen simuliert:
for i=1:numel(plants)
	plant = handles.Current_Settings.Sola.(plants{i});
	% Falls keine Anlage ausgew�hlt, diesen Eintrag �berspringen:
	if plant.Typ == 1
		continue;
	end
	switch plant.Typ
		case 2 % Fix installierte Anlage
			data_phase = model_pv_fix(plant, Content, data_cloud_factor,...
				radiation_data_fix, month_fix, time_resolution);
		case 3 % Tracker
			data_phase = model_pv_tra(plant, Content, data_cloud_factor,...
				radiation_data_tra, month_tra, time_resolution);
	end
	Result.Solar.Data = [Result.Solar.Data, data_phase];
end

% abschlie�end Summenleistungen ermitteln:
Result.Solar = calculate_additional_data(Result.Solar);
% Ergebnis zur�ckschreiben:
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

