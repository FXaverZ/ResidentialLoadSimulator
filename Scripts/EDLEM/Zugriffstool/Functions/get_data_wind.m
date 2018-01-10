function handles = get_data_wind (handles)
%GET_DATA_WIND    extrahiert und simuliert die Einspeise-Daten der Windkraftanlagen

% Erstellt von:            Franz Zeilinger - 04.07.2012
% Letzte Änderung durch:   Franz Zeilinger - 10.01.2018

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
Wind.Data_Sample = [];
Wind.Data_Mean = [];
Wind.Data_Min = [];
Wind.Data_Max = [];

% Gesamtanzahl der zu simulierenden Anlagen ermitteln:
plants = fieldnames(handles.Current_Settings.Wind);
number_plants = 0;
for i=1:numel(plants)
	plant = handles.Current_Settings.Wind.(plants{i});
	% Falls keine Anlage ausgewählt, diesen Eintrag überspringen:
	if plant.Typ == 1
		continue;
	else
		number_plants = number_plants + plant.Number;	
	end
end

% Überprüfen, ob überhaupt Windkraft-Erzeugungsanlagen verarbeitet werden sollen:
if number_plants == 0
	% (leeres) Ergebnis zurückschreiben:
	handles.Result.Wind = Wind;
	% Funktion beenden:
	return;
end

% Die Info-Datei laden:
path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,'Genera'];
name = ['Gene',sep,season,sep,'Wind',sep,'Speed',sep,'Info'];
% Daten laden (Variable "data_info")
load([path,filesep,name,'.mat']);
% wieviele Datensätze gibt es insgesamt?
num_data_sets = size(data_info,2); %#ok<NODEF>

% je nach Einstellungen die Windaten des aktuellen Tages einlesen:
switch settin.Worstcase_Generation
	case 1 % zufällige Auswahl
		% Zufällig einen Winddatensatz auswählen durch Erzeugen einer Zufallszahl im
		% Bereich [1, Anz._verf._Datensätze]:
		idx = round(rand()*(num_data_sets-1))+1;
% % ---  FOR DEBUG OUTPUTS  ---
% % Use always the same winddata index (for debug):
% 		idx = 27;
% % --- --- --- --- --- --- ---
	case 2 % höchste Tagesenergieeinspeisung
		% Datensatz mit der höchsten durchschnittlichen Windgeschwindigkeit
		% ermitteln:
		[~, I] = sort(data_info(1,:),'descend'); 
		idx = I(1);
	case 3 % niedrigste Tagesenergieeinspeisung
		% Datensatz mit der niedrigsten durchschnittlichen Windgeschwindigkeit
		% ermitteln:
		[~, I] = sort(data_info(1,:)); 
		idx = I(1);
% 	case 4
end

% nun den ausgewählten Datensatz aus der richtigen Teildateie laden:
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
	name = ['Gene',sep,season,sep,'Wind',sep,'Speed',sep,...
		num2str(j,'%03.0f')];
	% Daten laden (Variable "data_v_wind")
	load([path,filesep,name,'.mat']);
	% die relevanten Daten auslesen:
	data_v_wind = data_v_wind(:,idx_part); 
end
% % ---  FOR DEBUG OUTPUTS  ---
% 	figure; plot(data_v_wind)
% 	xls = XLS_Writer();
% 	xls.set_worksheet('Wind_Data');
% 	xls.write_values(data_v_wind);
% % --- --- --- --- --- --- ---

% nun stehen die Windgeschwindigkeiten zur Verfügung. Mit diesen Daten sowie den
% definierten Anlagenparametern werden nun die Anlagen simuliert:
for i=1:numel(plants)
	plant = handles.Current_Settings.Wind.(plants{i});
	% Falls keine Anlage ausgewählt, diesen Eintrag überspringen:
	if plant.Typ == 1
		continue;
	end
	data_phase = model_wind_turbine(plant, data_v_wind);
	% je nach Einstellungen, die relevanten Daten auslesen:
	if settin.Data_Extract.get_Sample_Value
		data_sample = data_phase(1:time_res:end,:);
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
		Wind.Data_Sample = [Wind.Data_Sample,...
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
		Wind.Data_Min = [Wind.Data_Min,...
			data_min];
		Wind.Data_Max = [Wind.Data_Max,...
			data_max];
		% eingelesenen Daten wieder löschen (Speicher freigeben!)
		clear data_min;
		clear data_max;
	end
	if settin.Data_Extract.get_Mean_Value
		data_mean = squeeze(mean(data_mean));
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
		Wind.Data_Mean = [Wind.Data_Mean,...
			data_mean];
		% eingelesenen Daten wieder löschen (Speicher freigeben!)
		clear data_mean
	end
end

% % ---  FOR DEBUG OUTPUTS  ---
% xls.write_output([num2str(idx),'-Wind-Input.xlsx']);
% % --- --- --- --- --- --- ---

% Ergebnis zurückschreiben:
handles.Result.Wind = Wind;
end