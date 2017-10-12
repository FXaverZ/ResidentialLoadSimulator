%% Settings
clear;

% input_lpt = 'D:\Projekte\Leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-09-20_load_types_anonymised.xls';
input_lpt = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-09-20_load_types_anonymised.xls';
% input_simdata_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input_simdata_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';

Input_LPTs_to_use = {'H0','L0','L1','L2'};
% input_lpt_to_use = {'H0'};
% input_lpt_to_use = {'All'};
output_dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';
sep = ' - ';
%% General Information
sheet_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
header_yec = 'JEV [kWh]';
header_lpt = 'Lastprofil';
header_ids = 'ID';

sheet_selector = 4;

%% Read in Excel-configuration information
[~,~,xls_input] = xlsread(input_lpt,sheet_names{sheet_selector});
% First row is header row, isolate this row for identification of Columns:
xls_input_header = xls_input(1,:);
xls_input = xls_input(2:end,:);

% Where are the load-profile typs?
idx_lpt = strcmp(xls_input_header, header_lpt);
% get the loadprofile typs
xls_input_lp = xls_input(:,idx_lpt);
% Deal with the "EAG" prefixes in some date (Energie AG --> removing this
% additional information):
if strncmp(xls_input_lp{1},'EAG',3)
	xls_input_lp = cellfun(@(x) x(5:end), xls_input_lp, 'UniformOutput', false);
end
% Deal with loadprofiletyps of infeed ("E1") --> these have to be removed!
idx_e1 = strcmp(xls_input_lp,'E1');
xls_input = xls_input(~idx_e1,:);
xls_input_lp = xls_input_lp(~idx_e1,:);
clear idx_e1 idx_lpt

% what are the different types?
xls_lpt = sort(unique(xls_input_lp));
Evaluation.Grid_Name = sheet_names{sheet_selector};
Evaluation.Loadprofile_Typs_present = xls_lpt;
disp('===========');
disp(['Following loadprofile typs were found for "',...
	sheet_names{sheet_selector},'": ']);
disp(xls_lpt);
disp('-----------');
% Identify the rows with the to be used load profiles:
if strcmpi(Input_LPTs_to_use{1},'all')
	Input_LPTs_to_use = xls_lpt;
	use_all_lpt = 1;
else
	use_all_lpt = 0;
end
idx_lpt_to_use = [];
for i = 1:numel(Input_LPTs_to_use)
	idx_lpt_to_use = [idx_lpt_to_use;find(strcmp(xls_input_lp,Input_LPTs_to_use{i}))]; %#ok<AGROW>
end
idx_lpt_to_use = sort(idx_lpt_to_use);

%Where is the yearly energy?
idx_yec = find(strcmp(xls_input_header,header_yec));
xls_input_ye = cell2mat(xls_input(:,idx_yec));
idx_ids = find(strcmp(xls_input_header,header_ids));
xls_input_id_to_use = xls_input(:,idx_ids);
ye_total = sum(xls_input_ye);
ye_to_use = sum(xls_input_ye(idx_lpt_to_use));
if use_all_lpt == 1
	str = 'For all load profile typs';
elseif numel(Input_LPTs_to_use) == 1
	str = ['For load profile typ "',Input_LPTs_to_use{1},'"'];
else
	str = 'For load profile typs "';
	for i = 1:numel(Input_LPTs_to_use)
		if i > 1 && i <= numel(Input_LPTs_to_use)-1
			str = [str,', "'];  %#ok<AGROW>
		end
		if i == numel(Input_LPTs_to_use)
			str = [str, ' and "']; %#ok<AGROW>
		end
		str = [str, Input_LPTs_to_use{i}, '"']; %#ok<AGROW>
	end
end
disp([str,...
	' a share of ',num2str(ye_to_use*100/ye_total),...
	'% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.']);
disp([num2str(numel(idx_lpt_to_use)),' loadpoints of ',num2str(numel(xls_input_ye)),...
	' can be supplied with a loadprofile.']);
disp('-----------');

Evaluation.Used_Loadprofiles = Input_LPTs_to_use;
Evaluation.Total_Yearly_Energy_Consumption = ye_total;
Evaluation.Total_Yearly_Energy_Consumption_unit = 'kWh';
Evaluation.Possible_Yearly_Energy_Consumption = ye_to_use;
Evaluation.Possible_Yearly_Energy_Consumption_share = ye_to_use*100/ye_total;
Evaluation.Possilbe_Yearly_Energy_Consumption_unit = 'kWh';
Evaluation.Total_Number_Loadpoints = numel(xls_input_ye);
Evaluation.Possible_Number_Loadpoints = numel(idx_lpt_to_use);

%% Get the yearly energy consumption values for the relevant loads defined by
%loadprofile typ to be considered:
ye_to_use = xls_input_ye(idx_lpt_to_use);
xls_input_id_to_use = xls_input_id_to_use(idx_lpt_to_use);
% Sort the values
[ye_to_use, IX] = sort (ye_to_use);
idx_lpt_to_use = idx_lpt_to_use(IX);
xls_input_id_to_use = xls_input_id_to_use(IX);

% retrieve the information of the simulated profiles:
content = dir(input_simdata_path);
content = struct2cell(content);
content = content(1,3:end);

Energy_information = {};
Energy_values = [];
for a = 1:numel(content)
	% actual path
	path = content{a};
	% get the files in this subdirectory:
	files = dir([input_simdata_path,filesep,path]);
	files = struct2cell(files);
	files = files(1,3:end);
	% search for the summaries:
	simtimeid = [];
	modelload = 1;
	for b=1:numel(files)
		filename = files{b};
		name_parts = regexp(filename, sep, 'split');
		if isempty(simtimeid) && ~strcmp(name_parts{1},'Summary')
			simtimeid = name_parts{1};
		end
		if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat') && modelload == 1
			%loadin of the model settings:
			load([input_simdata_path,filesep,path,filesep,filename]);
			modelload = 0;
		end
		if strcmp(name_parts{1},'Summary') && strcmp(name_parts{3},'Energy_Year.mat');
			%loading of energy summary of the simulated data:
			load([input_simdata_path,filesep,path,filesep,filename]);
		end
	end
	fieldnames = fields(Energy);
	num_runs = Model.Number_Runs;
	for b=1:numel(fieldnames)
		act_hh = fieldnames{b};
		num_hh = Model.Households{strcmp(Model.Households(:,1),act_hh),5};
		for c=1:num_runs
			for d=1:num_hh
				Energy_information{1,end+1} = path; %#ok<SAGROW>
				Energy_information{2,end} = act_hh;
				Energy_information{3,end} = c;
				Energy_information{4,end} = d;
				Energy_information{5,end} = Energy.(act_hh)((c-1)*num_hh+d);
				Energy_values(end+1) = Energy.(act_hh)((c-1)*num_hh+d); %#ok<SAGROW>
			end
		end
	end
end
[Energy_values,IX] = sort(Energy_values);
Energy_information = Energy_information(:,IX);

%% Check, how many profiles can be directly allocated
% (eleminate vaulues out of the range of the simulated profiles)
idx_lpt_to_use_zeros = idx_lpt_to_use(ye_to_use <= 0.1);
idx_lpt_to_use_tosma = idx_lpt_to_use(ye_to_use < min(Energy_values));
idx_lpt_to_use_tobig = idx_lpt_to_use(ye_to_use > max(Energy_values));

fprintf([...
	str,' in "',sheet_names{sheet_selector},'" are \n\t',...
	num2str(numel(idx_lpt_to_use_zeros)),' yearly energy values zero, \n\t',...
	num2str(numel(idx_lpt_to_use_tosma)),' values smaller than the minimal simulated energy value, \n\t',...
	num2str(numel(idx_lpt_to_use_tobig)),' values higher than the maximal simulated energy vaulue.\n',...
	]);
fprintf('-----------\n');
Evaluation.Number_selected_Profiles_equal_zero = numel(idx_lpt_to_use_zeros);
Evaluation.Number_selected_Profiles_less_min = numel(idx_lpt_to_use_tosma);
Evaluation.Number_selected_Profiles_bigger_max = numel(idx_lpt_to_use_tobig);

%% Allocate housholds
eps_lst = [...
	0,    0.01,      1;...
	1,    0.1,      10;...
	10,    0.5,     100;...
	100,    1,      1000;...
	1000,   10,     10000;...
 	10000,  100,    100000;...
	];
fprintf([...
	'Starting of allocation of households.\n',...
	'-------------------------------------\n',...
	]);
tstr_1 = ['Allocation for "',sheet_names{sheet_selector},'" and f',str(2:end)];
tstr = [tstr_1,' (all profiles)'];
estr = sprintf([str,' a share of ',num2str(sum(xls_input_ye(idx_lpt_to_use))*100/ye_total),...
	'%% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.\n',...
	num2str(numel(idx_lpt_to_use)),' loadpoints of ',num2str(numel(xls_input_ye)),...
	' can be supplied with a loadprofile.\n',...
	str,' in "',sheet_names{sheet_selector},'" are from ',num2str(numel(idx_lpt_to_use)),' profiles\n    ',...
	num2str(numel(idx_lpt_to_use_zeros)),' yearly energy values zero, \n    ',...
	num2str(numel(idx_lpt_to_use_tosma)),' values smaller than the minimal simulated energy value, (',num2str(min(Energy_values)),'kWh)\n    ',...
	num2str(numel(idx_lpt_to_use_tobig)),' values higher than the maximal simulated energy vaulue (',num2str(max(Energy_values)),'kWh).\n',...
	]);
% all profiles
% [allocation, found] = household_allocation (ye_to_use, Energy_information, Energy_values, eps_lst, tstr, estr);
household_allocation (ye_to_use, xls_input_id_to_use, Energy_information, Energy_values, eps_lst, tstr, estr);
% % without zeros
% tstr = sprintf([tstr_1,'\n(without zero values)']);
ye_to_use_wo_zeros = ye_to_use(ye_to_use >= 0.1);
xls_input_id_wo_zeros = xls_input_id_to_use(ye_to_use >= 0.1);
% estr = sprintf([...
% 	'Removed were\n    ',...
% 	num2str(numel(idx_lpt_to_use_zeros)),' profiles with yearly energy values zero.\n',...
% 	'Now a share of ',num2str(sum(ye_to_use_wo_zeros)*100/ye_total),...
% 	'%% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.\n',...
% 	num2str(numel(ye_to_use_wo_zeros)),' loadpoints of ',num2str(numel(xls_input_ye)),...
% 	' can be supplied with a loadprofile.',...
% 	]);
% [allocation_wo_zeros, found_wo_zeros] = household_allocation (ye_to_use_wo_zeros, xls_input_id_wo_zeros, Energy_information, Energy_values, eps_lst, tstr, estr);
% without zeros and too small values
% tstr = sprintf([tstr_1,'\n(without zero and too small values)']);
ye_to_use_wo_tosmall = ye_to_use_wo_zeros(ye_to_use_wo_zeros > min(Energy_values));
xls_input_id_wo_tosmall = xls_input_id_wo_zeros (ye_to_use_wo_zeros > min(Energy_values));
% estr = sprintf([...
% 	'Removed were\n    ',...
% 	num2str(numel(idx_lpt_to_use_zeros)),' profiles with yearly energy values zero, \n    ',...
% 	num2str(numel(idx_lpt_to_use_tosma)),' profiles with values smaller than the minimal simulated energy value (',num2str(min(Energy_values)),'kWh).\n',...
% 	'Now a share of ',num2str(sum(ye_to_use_wo_tosmall)*100/ye_total),...
% 	'%% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.\n',...
% 	num2str(numel(ye_to_use_wo_tosmall)),' loadpoints of ',num2str(numel(xls_input_ye)),...
% 	' can be supplied with a loadprofile.',...
% 	]);
% [allocation_wo_tosmall, found_wo_tosmall] = household_allocation (ye_to_use_wo_tosmall, xls_input_id_wo_tosmall, Energy_information, Energy_values, eps_lst, tstr, estr);
% without zeros and too small and too big values
tstr = sprintf([tstr_1,'\n(without zero, too small and too big values)']);
ye_to_use_wo_tobig = ye_to_use_wo_tosmall(ye_to_use_wo_tosmall < max(Energy_values));
xls_input_id_wo_tobig = xls_input_id_wo_tosmall (ye_to_use_wo_tosmall < max(Energy_values));
estr = sprintf([...
	'Removed were\n    ',...
	num2str(numel(idx_lpt_to_use_zeros)),' profiles with yearly energy values zero, \n    ',...
	num2str(numel(idx_lpt_to_use_tosma)),' profiles with values smaller than the minimal simulated energy value, (',num2str(min(Energy_values)),'kWh)\n    ',...
	num2str(numel(idx_lpt_to_use_tobig)),' profiles with values higher than the maximal simulated energy vaulue (',num2str(max(Energy_values)),'kWh).\n',...
	'Now a share of ',num2str(sum(ye_to_use_wo_tobig)*100/ye_total),...
	'%% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.\n',...
	num2str(numel(ye_to_use_wo_tobig)),' loadpoints of ',num2str(numel(xls_input_ye)),...
	' can be supplied with a loadprofile.',...
	]);
[allocation_wo_tobig, found_wo_tobig] = household_allocation (ye_to_use_wo_tobig, xls_input_id_wo_tobig, Energy_information, Energy_values, eps_lst, tstr, estr);

Evaluation.Selected_Yearly_Energy_Consumption = sum(ye_to_use_wo_tobig);
Evaluation.Selected_Yearly_Energy_Consumption_unit = 'kWh';
Evaluation.Selected_Yearly_Energy_Consumption_share = sum(ye_to_use_wo_tobig)*100/ye_total;
Evaluation.Selected_Number_Loadpoints = numel(ye_to_use_wo_tobig);

Settings.Input_LPTs_to_use = Input_LPTs_to_use;
Settings.Timebase_Output = 60;
Settings.Grid_Names = sheet_names;
Settings.Grid_Selector = sheet_selector;
Settings.Mode_removed_Loadprofiles = 'profiles with values smaller than the minimal simulated energy value AND profiles with values higher than the maximal simulated energy vaulue';

Allocation = allocation_wo_tobig;
save(['Allocated_Household_Profiles',sep,sheet_names{sheet_selector},'.mat'],'Allocation', 'Settings', 'Evaluation');
clear;