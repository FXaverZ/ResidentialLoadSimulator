function handles = get_data_wind (handles)
%GET_DATA_WIND    extrahiert und simuliert die Einspeise-Daten der Windkraftanlagen

% Franz Zeilinger - 02.01.2012

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
Result.Wind.Data = [];

% Gesamtanzahl der zu simulierenden Anlagen ermitteln:
plants = fieldnames(handles.Current_Settings.Wind);
number_plants = 0;
for i=1:numel(plants)
	plant = handles.Current_Settings.Wind.(plants{i});
	if plant.Typ == 1
		continue;
	else
		number_plants = number_plants + plant.Number;	
	end
end

% �berpr�fen, ob �berhaupt Windkraft-Erzeugungsanlagen verarbeitet werden sollen:
if number_plants == 0
	% (leeres) Ergebnis zur�ckschreiben:
	handles.Result = Result;
	% Funktion beenden:
	return;
end

% Die Info-Datei laden:
path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,'Genera'];
name = ['Gene',sep,season,sep,'Wind',sep,'Speed',sep,'Info'];
% Daten laden (Variable "data_info")
load([path,filesep,name,'.mat']);
% wieviele Datens�tze gibt es insgesamt?
num_data_sets = size(data_info,2); %#ok<NODEF>

% je nach Einstellungen die Windaten des aktuellen Tages einlesen:
switch settin.Worstcase_Generation
	case 1 % zuf�llige Auswahl
		% Zuf�llig einen Winddatensatz ausw�hlen durch Erzeugen einer Zufallszahl im
		% Bereich [1, Anz._verf._Datens�tze]:
		idx = round(rand()*(num_data_sets-1))+1;
	case 2 % h�chste Tagesenergieeinspeisung
		% Datensatz mit der h�chsten durchschnittlichen Windgeschwindigkeit
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
	name = ['Gene',sep,season,sep,'Wind',sep,'Speed',sep,...
		num2str(j,'%03.0f')];
	% Daten laden (Variable "data_v_wind")
	load([path,filesep,name,'.mat']);
	% die relevanten Daten auslesen:
	data_v_wind = data_v_wind(:,idx_part); 
end

% nun stehen die Windgeschwindigkeiten zur Verf�gung. Mit diesen Daten sowie den
% definierten Anlagenparametern werden nun die Anlagen simuliert:
for i=1:numel(plants)
	plant = handles.Current_Settings.Wind.(plants{i});
	% Falls keine Anlage ausgew�hlt, diesen Eintrag �berspringen:
	if plant.Typ == 1
		continue;
	end
	data_phase = model_wind_turbine(plant, data_v_wind);
	% Daten an zeitliche Aufl�sung anpassen:
	data_phase = data_phase(1:time_resolution:end,:);
	Result.Wind.Data = [Result.Wind.Data, data_phase];
end

% abschlie�end Summenleistungen ermitteln:
Result.Wind = calculate_additional_data(Result.Wind);
% Ergebnis zur�ckschreiben:
handles.Result = Result;
end

function structure = calculate_additional_data(structure)
structure.Active_Power_Total = sum(structure.Data(:,1:2:end),2);
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