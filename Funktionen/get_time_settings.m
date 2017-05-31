function Time = get_time_settings(Model)
%GET_TIME_SETTINGS    ermittelt die notwendigen Zeitdaten f�r die Simulation
%    TIME = get_time_settings(MODEL) ermittelt die notwendigen Zeitdaten f�r die
%    Simulation (definiert durch die Simulationsparameter in MODEL) und
%    speichert diese in der TIME-Struktur.

% Erstellt von:            Franz Zeilinger - 08.04.2008
% Letzte �nderung durch:   Franz Zeilinger - 19.12.2012

if ~isfield(Model,'Sim_Year')
	Model.Sim_Year = str2double(datestr(datenum(Model.Date_Start),'yyyy'));
end

% Ermitteln der Zeitbasis
switch Model.Sim_Resolution
	case 'min'
		Time.Base = 60;	
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
end

% Berechnen der einzelnen Zeitschritte:
Time.day_to_sec = 86400; % Umrechnungsfaktor von Tag auf Sekunden
% Umrechnen der Zeitstrings in Linearzeit:
Time.Date_Start = datenum(Model.Date_Start);
Time.Date_End = datenum(Model.Date_End);
% Berechnen der Simulationsschritte:
Time.Dur = Time.Date_End - Time.Date_Start;
Time.Number_Steps = round(Time.Dur * Time.day_to_sec / Time.Base+1);

% Tage erstellen, die simuliert werden sollen:
Time.Act_Year = datenum(num2str(Model.Sim_Year), 'yyyy');
Time.Next_Year = datenum(num2str(Model.Sim_Year+1), 'yyyy');

% 1.1.act_year bis 1.1.next_year
Time.Days_Year = Time.Act_Year:1:Time.Next_Year;
end
