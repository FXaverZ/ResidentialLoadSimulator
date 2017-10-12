function [season, weekd] = day2sim_parameter(Sim_Year, act_day)
%DAY2SIM_PARAMETER Summary of this function goes here
%   Detailed explanation goes here

% Wie werden die Tage auf die Jahreszeiten aufgeteilt (nach VDEW):
% Summer: 15.5. - 14.9.   --> 123 Tage
% Winter: 1.11. - 20.3.   --> 140 Tage
% Transi: sonst           --> 102 Tage
sum_start = datenum(['15.05.',num2str(Sim_Year)],'dd.mm.yyyy'); % Sommer-Beginn
sum_end = datenum(['14.09.',num2str(Sim_Year)],'dd.mm.yyyy');   % Sommer-Ende
win_start = datenum(['01.11.',num2str(Sim_Year)],'dd.mm.yyyy'); % Winter-Beginn
win_end = datenum(['20.03.',num2str(Sim_Year)],'dd.mm.yyyy');   % Winter-Ende

Seasons =   {'Summer'; 'Winter'; 'Transi'};  % Typen der Jahreszeiten
Weekdays =  {'Workda'; 'Saturd'; 'Sunday'};  % Typen der Wochentage

% Tage erstellen, die simuliert werden sollen:
Act_Year = datenum(num2str(Sim_Year), 'yyyy');
Next_Year = datenum(num2str(Sim_Year+1), 'yyyy');

if act_day >= sum_start && act_day < sum_end + 1
	season = Seasons{1};
elseif (act_day >= Act_Year && act_day < win_end + 1) || ...
		(act_day >= win_start && act_day < Next_Year)
	season = Seasons{2};
else
	season = Seasons{3};
end

day_type = weekday(act_day);
if day_type > 1 && day_type < 7
	weekd = Weekdays{1};
elseif day_type == 7
	weekd = Weekdays{2};
else
	weekd = Weekdays{3};
end
end

