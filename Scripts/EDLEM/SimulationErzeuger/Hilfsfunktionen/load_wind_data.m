function v_wind = load_wind_data(path, name)
%LOAD_WIND_DATA Laden und Aufbereiten von Windgeschwindigkeitsmessungen

% Franz Zeilinger - 20.12.2011

% Daten einlesen:
[~, ~, raw_data] = xlsread([path,filesep,name,'.xls'],'Daten');

% Windgeschwindigkeiten auslesen:
v_wind_year = raw_data(18:end,3);
v_wind_year = cell2mat(v_wind_year);

% Zeiten auslesen:
time_year = raw_data(18:end,1);
% Rohdaten löschen, werden nicht mehr benötigt:
clear('raw_data');

% jene Datumseinräge, die nicht vollständig sind, berichtigen:
idx =  find(cellfun(@length, time_year) < 11);
for j = 1:numel(idx)
	time_year{idx(j)} = ...
		datestr(datenum(time_year{idx(j)},'dd.mm.yyyy'), 'dd.mm.yyyy HH:MM:SS');
end
% Datum in serielle Matlabzeit umwandeln:
time_year = datenum(time_year, 'dd.mm.yyyy HH:MM:SS');
% die Winddaten liegen nun als 60min Mittelwerte vor. Der zugehörige Zeitpunkt
% gibt den Startzeitpunkt dieser 60min-Phase an!

% Start- und Endjahre der vorhandenen Daten ermitteln:
start_year = str2double(datestr(time_year(1), 'yyyy'));
end_year = str2double(datestr(time_year(end), 'yyyy'));
% Winddaten auf die Jahreszeiten aufteilen (nach VDEW):
% Summer: 15.5. - 14.9.   --> 123 Tage
% Winter: 1.11. - 20.3.   --> 140 Tage
% Transi: sonst           --> 102 Tage

for i=start_year:end_year
	year = num2str(i);
	act_year = datenum(year, 'yyyy');
	next_year = datenum(num2str(i+1), 'yyyy');
	% Die nachfolgende etwas seltsame Code-Konstruktion war notwendig, da die
	% datenum-Funktion einige Probleme verursacht. Wenn man Sie zwei mal aufruft, ist
	% sichergestellt, dass alle Daten korrekt verarbeitet werden können...
	% Im Prinzip werden für das aktuelle Jahr die Zeiten für Jahreszeitenbeginn und
	% Ende in Matlab-Serialzeit erzeugt:
	try
		sum_start = datenum(['15.05.',year],'dd.mm.yyyy'); % Sommer-Beginn
	catch %#ok<*CTCH>
		sum_start = datenum(['15.05.',year],'dd.mm.yyyy');
	end
	try
		sum_end = datenum(['14.09.',year],'dd.mm.yyyy'); % Sommer-Ende
	catch
		sum_end = datenum(['14.09.',year],'dd.mm.yyyy');
	end
	try
		win_start = datenum(['01.11.',year],'dd.mm.yyyy'); % Winter-Beginn
	catch
		win_start = datenum(['01.11.',year],'dd.mm.yyyy');
	end
	try
		win_end = datenum(['20.03.',year],'dd.mm.yyyy'); % Winter-Ende
	catch
		win_end = datenum(['20.03.',year],'dd.mm.yyyy');
	end
	
	% Indizes der jeweiligen Einträge für Sommer/Winter/Übergangszeit finden:
	idx_wi = find(time_year >= act_year & time_year < win_end + 1);
	idx_wi = [idx_wi; find(time_year >= win_start & time_year < next_year)]; %#ok<AGROW>
	idx_su = find(time_year >= sum_start & time_year < sum_end + 1);
	idx_tr = find(time_year >= win_end + 1 & time_year < sum_start);
	idx_tr = [idx_tr; find(time_year >= sum_end + 1 & time_year < win_start)]; %#ok<AGROW>
	
	% Daten übernehmen und nach Jahreszeit getrennt abspeichern:
	if i == start_year
		v_wind.Winter = v_wind_year(idx_wi);
		v_wind.Summer = v_wind_year(idx_su); 
		v_wind.Transi = v_wind_year(idx_tr);
	else
		v_wind.Winter = [v_wind.Winter; v_wind_year(idx_wi)];
		v_wind.Summer = [v_wind.Summer; v_wind_year(idx_su)];
		v_wind.Transi = [v_wind.Transi; v_wind_year(idx_tr)];
	end
end
end

