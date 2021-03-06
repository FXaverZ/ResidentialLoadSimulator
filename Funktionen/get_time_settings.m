function Time = get_time_settings(Model)
%GET_TIME_SETTINGS    ermittelt die notwendigen Zeitdaten f�r die Simulation
%    TIME = get_time_settings(MODEL) ermittelt die notwendigen Zeitdaten f�r die
%    Simulation (definiert durch die Simulationsparameter in MODEL) und
%    speichert diese in der TIME-Struktur.

% Erstellt von:            Franz Zeilinger - 08.04.2008
% Letzte �nderung durch:   Franz Zeilinger - 28.06.2017

% Ermitteln der Zeitbasis
switch Model.Sim_Resolution
	case 'min'
		Time.Base = 60;	
	case '2.5m'
		Time.Base = 150;
	case '10s'
		Time.Base = 10;
	case '5se'
		Time.Base = 5;
	case 'sec'
		Time.Base = 1;
	case 'hou'
		Time.Base = 3600;
	case 'quh'
		Time.Base = 900;
	case '5mi'
		Time.Base = 300;
	otherwise
		Time.Base = 3600;
		warning('Time resolution was not recognized! Setting to Default ("hou")!');
end

% Berechnen der einzelnen Zeitschritte:
Time.day_to_sec = 86400; % Umrechnungsfaktor von Tag auf Sekunden
% Umrechnen der Zeitstrings in Linearzeit:
Time.Date_Start = datenum(Model.Date_Start);
Time.Date_End = datenum(Model.Date_End);
if isfield(Model,'Series_Date_Start')
	Time.Series_Date_Start = datenum(Model.Series_Date_Start, 'dd.mm.yyyy');
else
	Time.Series_Date_Start = Time.Date_Start;
end
if isfield(Model,'Series_Date_End')
	Time.Series_Date_End = datenum(Model.Series_Date_End, 'dd.mm.yyyy');
else
	Time.Series_Date_End = Time.Date_End;
end
% Berechnen der Simulationsschritte:
Time.Dur = Time.Date_End - Time.Date_Start;
Time.Number_Steps = round(Time.Dur * Time.day_to_sec / Time.Base+1);

% Tage erstellen, die simuliert werden sollen:
Time.Days_Year =Time.Series_Date_Start:1:Time.Series_Date_End;
end
