function [season_overlap, season_1, season_2] = day2season_overlap(Model, act_day)
%DAY2SEASON_OVERLAP Summary of this function goes here
%   Detailed explanation goes here

season_overlap = false;
season_1 = [];
season_2 = [];

[season, ~, parafilemname] = day2sim_parameter(Model, act_day);

% Get the seasons which are present in the past and the future by the given period by
% the user:
[season_fut, ~, parafilemname_fut] = day2sim_parameter(Model, act_day + Model.Seasons_Overlap - 1);
[season_pas, ~, parafilemname_pas] = day2sim_parameter(Model, act_day - Model.Seasons_Overlap);

% are different season present? If not, no overlapping oparation has to be perfomed!
if strcmp(season, season_fut) && strcmp(season, season_pas)
	return;
end

season_overlap = true;

if ~strcmp(season, season_fut)
	% Season changes in future
	season_1.season = season;
	season_1.parafilemname = parafilemname;
	season_1.factor = 0;
	season_2.season = season_fut;
	season_2.parafilemname = parafilemname_fut;
	season_2.factor = 0;
	
	% determine how many days of each season are currently
	% in the given period present:
	for i=-Model.Seasons_Overlap:Model.Seasons_Overlap-1
		season_cur = day2sim_parameter(Model, act_day + i);
		if strcmp(season, season_cur)
			season_1.factor = season_1.factor + 1;
		else
			season_2.factor = season_2.factor + 1;
		end
	end
	season_1.factor = season_1.factor / (2* Model.Seasons_Overlap);
	season_2.factor = season_2.factor / (2* Model.Seasons_Overlap);
else
	% Season changed in past
	season_1.season = season_pas;
	season_1.parafilemname = parafilemname_pas;
	season_1.factor = 0;
	season_2.season = season;
	season_2.parafilemname = parafilemname;
	season_2.factor = 0;
	
	% determine how many days of each season are currently
	% in the given period present:
	for i=-Model.Seasons_Overlap:Model.Seasons_Overlap-1
		season_cur = day2sim_parameter(Model, act_day + i);
		if strcmp(season_pas, season_cur)
			season_1.factor = season_1.factor + 1;
		else
			season_2.factor = season_2.factor + 1;
		end
	end
	season_1.factor = season_1.factor / (2* Model.Seasons_Overlap);
	season_2.factor = season_2.factor / (2* Model.Seasons_Overlap);
end


end

