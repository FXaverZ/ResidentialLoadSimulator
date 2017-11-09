function handles = get_data_households (handles)
%GET_DATA_HOUSEHOLDS    extrahiert die Daten der Haushalte 

% Franz Zeilinger - 14.02.2012

system = handles.System;   % Systemvariablen
settin = handles.Current_Settings; % aktuelle Einstellungen
db_fil = settin.Database;  % Datenbankstruktur
if isfield (handles, 'Result')
	Result = handles.Result; % Ergebnisstruktur
end
max_num_data_set = db_fil.setti.max_num_data_set; % Anzahl an Datens�tzen in einer
                                                  % Teildatei
sep = db_fil.files.sep;    % Trenner im Dateinamen (' - ')

% die aktuellen Zeitdaten (Jahreszeit, Wochentag) auslesen:
season = system.seasons{settin.Season,1};
weekda = system.weekdays{settin.Weekday,1};
% Auslesen der zeitlichen Aufl�sung in Sekunden:
time_resolution = system.time_resolutions{settin.Time_Resolution,2};

% die einzelnen Haushaltsklassen durchgehen:
Result.Households.Data = [];
for i=1:size(system.housholds,1)
	% Anzahl der Haushalte gem�� Einstellungen auslesen:
	number_hh = settin.Households.(system.housholds{i,1}).Number;
	if number_hh < 1
		% Falls f�r diesen Haushalt keine Daten extrahiert werden sollen 
		% (Anzahl = 0), �berspringen:
		continue;
	end
	% Info Datei laden:
	path = [db_fil.Path,filesep,db_fil.Name,filesep,season,filesep,weekda];
	name = ['Load',sep,season,sep,weekda,sep,system.housholds{i,1},sep,'Info'];
	% Daten laden (Variable "data_info")
	load([path,filesep,name,'.mat']);
	% wieviele Datens�tze gibt es insgesamt?
	num_data_sets = size(data_info,2)/6;
	
	% Je nach Einstellung Datens�tze ausw�hlen:
	switch settin.Worstcase_Housholds
		case 1 % Einstellung: Zuf�llige Auswahl
			% eine Indexliste erstellen, mit zuf�llig ausgew�hlten Datens�tzen:
			pool = 1:num_data_sets;   % Liste mit Indizes der m�glichen Datens�tze
			idx = zeros(number_hh,1); % Liste mit Indizes der ausgew�hlten Datens�tze
			                          % (mit 0 intialisieren)
			for j = 1:number_hh
				% Erzeugen einer Zufallszahl im Bereich [1, Anz._verf._Datens�tze]
				fortu = round(rand()*(numel(pool)-1))+1;
				idx(j) = pool(fortu); % diesen Index in Indexliste aufnehmen
				% gezogenen Datensatz aus der Auswahlm�glickeit entfernen (damit er
				% nicht mehr gezogen werden kann):
				pool(fortu) = [];
			end
		case 2 % Worst Case: H�chster Energieverbrauch
			% aus den Phasenenergieaufnahmen die Gesamtenergieaufnahme ermitteln
			% (Summe aus L1, L2 und L3):
			data_e = sum([...
				data_info(3,1:6:end);...
				data_info(3,3:6:end);...
				data_info(3,5:6:end)],1); %#ok<COLND>
			% die Energiebetr�ge sortieren, die Indexliste I �bernehmen:
			[~, I] = sort(data_e,'descend');
			% die geforderten Inidizes mit dem h�chsten Energieverbrauch �bernehmen
			% (sind die ersten "number_hh"-Inzies der Sortierliste I):
			idx = I(1:number_hh)';
		case 3 % Worst Case: Niedrigster Energieverbrauch
			% Gleicher Ablauf wie bei "H�chster Energieverbrauch", nur umgekehrte
			% Sortierung:
			data_e = sum([...
				data_info(3,1:6:end);...
				data_info(3,3:6:end);...
				data_info(3,5:6:end)],1); %#ok<COLND>
			[~, I] = sort(data_e); 
			idx = I(1:number_hh)';
		case 4 % Worst Case: H�chste Leistungsaufnahme
			% Summen-Leistungsaufnahme aus max. Phasenleistungsaufnahme ermitteln:
			data_max = sum([...
				data_info(1,1:6:end);...
				data_info(1,3:6:end);...
				data_info(1,5:6:end)],1); %#ok<COLND>
			[~, I] = sort(data_max,'descend');
			% die geforderten Inidizes mit dem h�chsten Energieverbrauch �bernehmen:
			idx = I(1:number_hh)';
	end
	% die ermittelten Indizes sortieren (f�r effektiveres Abarbeiten):
	idx = sort(idx);
	% nun die einzelnen Datens�tze aus den jeweiligen Teildateien laden:
	for j=1:ceil(num_data_sets/max_num_data_set)
		% jene Indizes ermitteln, die in aktueller Teil-Datei enthalten sind
		idx_part = idx(idx > (j-1)*max_num_data_set & idx <= j*max_num_data_set);
		if isempty(idx_part)
			% sind keine Daten in dieser Datei, die ausgelesen werden m�ssen, diese
			% �berspringen:
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
		% die relevanten Daten auslesen:
		data_sel = data_phase(1:time_resolution:end,idx_part_real);   %#ok<COLND>
		% eingelesenen Daten wieder l�schen (Speicher freigeben!)
		clear data_phase;
		% die ausgelesenen Daten zum bisherigen Ergebnis hinzuf�gen:
		Result.Households.Data = [Result.Households.Data, data_sel];
	end
end

% abschlie�end Summenleistungen ermitteln:
Result.Households = calculate_additional_data(Result.Households);
% Ergebnis zur�ckschreiben:
handles.Result = Result;
end

