function handles = get_data_households (handles)
%GET_DATA_HOUSEHOLDS    extrahiert die Daten der Haushalte 

% Erstellt von:            Franz Zeilinger - 14.02.2012
% Letzte Änderung durch:   Franz Zeilinger - 14.08.2012

system = handles.System;           % Systemvariablen
settin = handles.Current_Settings; % aktuelle Einstellungen
db_fil = settin.Database;          % Datenbankstruktur

% Ergebnis-Arrays initialisieren:
Households.Data_Sample = [];
Households.Data_Mean = [];
Households.Data_Min = [];
Households.Data_Max = [];
Households.Data_05P_Quantil = [];
Households.Data_95P_Quantil = [];

max_num_data_set = db_fil.setti.max_num_data_set; % Anzahl an Datensätzen in einer
                                                  % Teildatei
sep = db_fil.files.sep;    % Trenner im Dateinamen (' - ')

% die aktuellen Zeitdaten (Jahreszeit, Wochentag) auslesen:
season = system.seasons{settin.Season,1};
weekda = system.weekdays{settin.Weekday,1};
% zeitliche Auflösung ermitteln:
time_res = system.time_resolutions{settin.Data_Extract.Time_Resolution,2};

% die einzelnen Haushaltsklassen durchgehen:
for i=1:size(system.housholds,1)
	% Anzahl der Haushalte gemäß Einstellungen auslesen:
	number_hh = settin.Households.(system.housholds{i,1}).Number;
	if number_hh < 1
		% Falls für diesen Haushalt keine Daten extrahiert werden sollen 
		% (Anzahl = 0), überspringen:
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
			pool = 1:num_data_sets;   % Liste mit Indizes der möglichen Datensätze
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
			% aus den Phasenenergieaufnahmen die Gesamtenergieaufnahme ermitteln
			% (Summe aus L1, L2 und L3):
			data_e = sum([...
				data_info(3,1:6:end);...
				data_info(3,3:6:end);...
				data_info(3,5:6:end)],1); %#ok<COLND>
			% die Energiebeträge sortieren, die Indexliste I übernehmen:
			[~, I] = sort(data_e,'descend');
			% die geforderten Inidizes mit dem höchsten Energieverbrauch übernehmen
			% (sind die ersten "number_hh"-Inzies der Sortierliste I):
			idx = I(1:number_hh)';
		case 3 % Worst Case: Niedrigster Energieverbrauch
			% Gleicher Ablauf wie bei "Höchster Energieverbrauch", nur umgekehrte
			% Sortierung:
			data_e = sum([...
				data_info(3,1:6:end);...
				data_info(3,3:6:end);...
				data_info(3,5:6:end)],1); %#ok<COLND>
			[~, I] = sort(data_e); 
			idx = I(1:number_hh)';
		case 4 % Worst Case: Höchste Leistungsaufnahme
			% Summen-Leistungsaufnahme aus max. Phasenleistungsaufnahme ermitteln:
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
		idx_part = idx(idx > (j-1)*max_num_data_set & idx <= j*max_num_data_set);
		if isempty(idx_part)
			% sind keine Daten in dieser Datei, die ausgelesen werden müssen, diese
			% überspringen:
			continue;
		end
		% die Indizes der Datenspalten erstellen: jeder Datensatz besteht aus 6
		% Spalten (3x Wirk-, 3x Blindleistung):
		idx_part_real = repmat((idx_part-1)*6,[1,6])+repmat(1:6,[size(idx_part,1),1]);
		idx_part_real = sort(reshape(idx_part_real,1,[]));
		% Indexzahl korrigieren (der Index der geladenen Daten geht nur von
		% 1:max_num_datasets):
		idx_part_real = idx_part_real - (j-1)*6*max_num_data_set;
		% Name der aktuellen Teil-Datei:
		name = ['Load',sep,season,sep,weekda,sep,system.housholds{i,1},sep,...
			num2str(j,'%03.0f')];
		% Daten laden (Variable "data_phase")
		load([path,filesep,name,'.mat']);
		% je nach Einstellungen, die relevanten Daten auslesen:
		if settin.Data_Extract.get_Sample_Value
			data_sample = data_phase(1:time_res:end,idx_part_real);
			% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
			Households.Data_Sample = [Households.Data_Sample,...
				data_sample];
		end
		if settin.Data_Extract.get_Mean_Value || ...
				settin.Data_Extract.get_Min_Max_Value || ...
				settin.Data_Extract.get_5_95_Quantile_Value
			% Das ursprüngliche Datenarray so umformen, dass ein 3D Array mit allen
			% Werten eines Zeitraumes in der ersten Dimension entsteht. Diese wird
			% dann durch die nachfolgenden Funktionen (mean, min, max) sofort in die
			% entsprechenden Werte umgerechnet. Mit squeeze muss dann nur mehr die
			% Singleton-Dimension entfernt werden...
			data_phase = data_phase(1:end-1,idx_part_real);
			data_mean = reshape(data_phase,...
				time_res,[],size(data_phase,2));
			% eingelesenen Daten wieder löschen (Speicher freigeben!)
			clear data_phase;
		end
		if settin.Data_Extract.get_Min_Max_Value
			data_min = squeeze(min(data_mean));
			data_max = squeeze(max(data_mean));
			% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
			Households.Data_Min = [Households.Data_Min,...
				data_min];
			Households.Data_Max = [Households.Data_Max,...
				data_max];
			% eingelesenen Daten wieder löschen (Speicher freigeben!)
			clear data_min;
			clear data_max;
		end
		if settin.Data_Extract.get_5_95_Quantile_Value
			data_05q = squeeze(quantile(data_mean,0.05));
			data_95q = squeeze(quantile(data_mean,0.95));
			% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
			Households.Data_05P_Quantil = [...
				Households.Data_05P_Quantil,...
				data_05q];
			Households.Data_95P_Quantil = [...
				Households.Data_95P_Quantil,...
				data_95q];
			% eingelesenen Daten wieder löschen (Speicher freigeben!)
			clear data_05q;
			clear data_95q;
		end
		if settin.Data_Extract.get_Mean_Value
			data_mean = squeeze(mean(data_mean));
			% die ausgelesenen Daten zum bisherigen Ergebnis hinzufügen:
			Households.Data_Mean = [Households.Data_Mean,...
				data_mean];
			% eingelesenen Daten wieder löschen (Speicher freigeben!)
			clear data_mean
		end
	end
end

% Ergebnis zurückschreiben:
if settin.Data_Extract.get_Time_Series
	% Die aus diesem Durchlauf ermittelten Daten werden zu den bisherigen hinzugefügt
	% (sofern vorhanden):
	if ~isfield(handles, 'Result') || ~isfield(handles.Result, 'Households')
		% Die ermittelten Daten stellen den Beginn der Resultsstruktur dar:
		handles.Result.Households = Households;
		return;
	end
	% Es sind bereits Daten aus den vorhergehenden Durchläufen vorhanden, diese
	% werden um die jetzt ermittelten Daten erweitert:
	handles.Result.Households.Data_Sample = ...
		[handles.Result.Households.Data_Sample(1:end-1,:);
		Households.Data_Sample];
	handles.Result.Households.Data_Mean = ...
		[handles.Result.Households.Data_Mean;
		Households.Data_Mean];
	handles.Result.Households.Data_Min = ...
		[handles.Result.Households.Data_Min;
		Households.Data_Min];
	handles.Result.Households.Data_Max = ...
		[handles.Result.Households.Data_Max;
		Households.Data_Max];
	handles.Result.Households.Data_05P_Quantil = ...
		[handles.Result.Households.Data_05P_Quantil;
		Households.Data_05P_Quantil];
	handles.Result.Households.Data_95P_Quantil = ...
		[handles.Result.Households.Data_95P_Quantil;
		Households.Data_95P_Quantil];
else
	% Die ermittelten Daten stellen die fertige Results-Struktur dar:
	handles.Result.Households = Households;
end
end

