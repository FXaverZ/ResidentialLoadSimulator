function [season, weekd, parafilemname] = day2sim_parameter(Model, Time, act_day)
%DAY2SIM_PARAMETER Summary of this function goes here
%   Detailed explanation goes here

% Wie werden die Tage auf die Jahreszeiten aufgeteilt (nach VDEW):
% Summer: 15.5. - 14.9.   --> 123 Tage
% Winter: 1.11. - 20.3.   --> 140 Tage
% Transi: sonst           --> 102 Tage
sum_start = datenum(['15.05.',num2str(Model.Sim_Year)],'dd.mm.yyyy'); % Sommer-Beginn
sum_end = datenum(['14.09.',num2str(Model.Sim_Year)],'dd.mm.yyyy');   % Sommer-Ende
win_start = datenum(['01.11.',num2str(Model.Sim_Year)],'dd.mm.yyyy'); % Winter-Beginn
win_end = datenum(['20.03.',num2str(Model.Sim_Year)],'dd.mm.yyyy');   % Winter-Ende

if act_day >= sum_start && act_day < sum_end + 1
	season = Model.Seasons{1};
elseif (act_day >= Time.Act_Year && act_day < win_end + 1) || ...
		(act_day >= win_start && act_day < Time.Next_Year)
	season = Model.Seasons{2};
else
	season = Model.Seasons{3};
end

day_type = weekday(act_day);
if day_type > 1 && day_type < 7
	weekd = Model.Weekdays{1};
elseif day_type == 7
	weekd = Model.Weekdays{2};
else
	weekd = Model.Weekdays{3};
end
sep = Model.Seperator;
parafilemname = ['Param',sep,season,sep,weekd];
end

