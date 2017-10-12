clear;
%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
output.year_string = '2014';
Timebase_Output = 60;
Timebase_Number_Days = 365;
% Which input data should be used?
% input_selector = 'As simulated';
input_selector = 'Without flexible loads';
max_power_single_phase = 2300; %max power for single phase operation
% between the phases in W
phase_composition_quantile = 0.999;% Given quantile, in which the power of
% the single phases are obsorved an it it is tryed to ensure, that the
% single phase power is not too high. 1 = max

% MD1JFTNC - Fujitsu Laptop
% input_lpt.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
% input_fll.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-11-23_Zusammenstellung_Flex_Loads.xlsx';
% input_tem.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2014-01-01_Termperaturdaten_2014.xlsx';
% input_simdata.path = 'F:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% output.dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

% MD1EEZ0C - Simulationsrechner
input_lpt.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
input_fll.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-11-23_Zusammenstellung_Flex_Loads.xlsx';
input_tem.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2014-01-01_Termperaturdaten_2014.xlsx';
input_simdata.path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
output.dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

output.dest_path_powers = 'Powers_Flexible_Loads';
%--------------------------------------------------------------------------
% General Information
%--------------------------------------------------------------------------
sep = ' - ';

input_lpt.sheet_name = 'Load Profile Index';
input_fll.sheet_name = 'Schaltzeiten';
input_tem.sheet_name = 'Temperaturen';

% selection of the grid to be assigned:
grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
grid_selector = 3;

input_lpt.header_row   = 2; %Row, in which the header information can be found
input_lpt.data_cut_row = 4; %From this row on, the data in the input excel can be found!
input_lpt.header_yec = 'Flexible Load - annual energy consumption';
input_lpt.header_lpt = 'Flexible Load - profile';
input_lpt.header_typ = 'Flexible Load - profile type';
input_lpt.header_pow = 'Flexible Load - contracted / rated power';
input_lpt.header_sec = 'Flexible Load - sector code';
input_lpt.header_ids = 'Load Profile ID';

input_tem.header_row   = 1;
input_tem.data_cut_row = 2;
input_tem.header_name = 'Stationname';
input_tem.header_temp = 'air temperature at the ground';
input_tem.header_date = 'Date';

input_fll.header_row   = 1;
input_fll.data_cut_row = 2;
input_fll.header_name = 'Name';
input_fll.header_date_from = 'von';
input_fll.header_date_to   = 'bis';

eps_lst = [...
	%eps start, delta eps, eps end, load reduction start, delta, end
	         0,      0.01,       1,                   99,    -1,   0;...
	         1,       0.1,      10,                   99,    -1,   0;...
	        10,       0.5,     100,                   99,    -1,   0;...
	       100,         1,    1000,                   99,    -1,   0;...
	%      1000,        10,   10000,                   99,    -1,  95;...
	% 	  10000,       100,  100000,                   99,    -1,  95;...
	];
%==========================================================================

Settings.Timebase_Output = 60;
Settings.Grid_Names = grid_names;
Settings.Input_Selector = input_selector;
Settings.Eps_Lst = eps_lst;

addpath([pwd,filesep,'01_Hilfsfunktionen']);
eval_time = now;
% eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');
eval_id = '2017-01-12_13.48.34';
output_year_number = datenum('2014','yyyy');

% Prepare a temperature profile:
xls_tem = [];
[~,~,xls_tem.data] = xlsread(input_tem.path,input_tem.sheet_name);
xls_tem.header = xls_tem.data(input_tem.header_row, :);
xls_tem.data = xls_tem.data(input_tem.data_cut_row:end,:);
idx_name = strcmp(xls_tem.header,input_tem.header_name);
names = unique(xls_tem.data(:,idx_name));
idx_date = strcmp(xls_tem.header,input_tem.header_date);
dates = xls_tem.data(:,idx_date);
dates = datenum(dates,'dd.mm.yyyy');
dates = unique(dates);

idx_temp = strcmp(xls_tem.header,input_tem.header_temp);
temps = zeros(numel(dates),numel(names));
for a = 1:numel(names)
	name = names{a};
	idx = strcmp(xls_tem.data(:,idx_name),name);
	temps(:,a) = cell2mat(xls_tem.data(idx,idx_temp));
end
Temperatures = mean(temps,2);
Evaluation.Temperatures = Temperatures;
Evaluation.Dates_Temperatures = dates;
fprintf(['Temperatures from ',datestr(dates(1),'dd.mm.yyyy'),' to ',...
	datestr(dates(end),'dd.mm.yyyy'),' were loaded (Output year should be ',output.year_string,')!\n']);

clear names idx_name idx_dates dates a name temps idx xls_tem
fprintf('===========\n');

%Prepare runtimes of load profile typs:
xls_fll = [];
[~,~,xls_fll.data] = xlsread(input_fll.path,input_fll.sheet_name);
xls_fll.header = xls_fll.data(input_fll.header_row, :);
xls_fll.data = xls_fll.data(input_fll.data_cut_row:end,:);
idx = strcmp(xls_fll.header,input_fll.header_date_from) | strcmp(xls_fll.header,input_fll.header_date_to);
dates = xls_fll.data(:,idx);
for a=1:size(dates,1)
	for b=1:size(dates,2)
		if isnan(dates{a,b})
			continue;
		end
		dates{a,b} = datenum([dates{a,b},output.year_string],'dd.mm.yyyy');
	end
end
xls_fll.data(:,idx) = dates;
idx = strcmp(xls_fll.header,input_fll.header_name);
xls_fll.names = xls_fll.data(:,idx);
clear a b idx

for grid_selector=1:numel(grid_names)
if ~isdir([output.dest_path,filesep,output.dest_path_powers])
	mkdir([output.dest_path,filesep,output.dest_path_powers]);
end
diary([output.dest_path,filesep,output.dest_path_powers,filesep,eval_id,sep,grid_names{grid_selector},sep,'log.txt']);
[~,~,xls_lpt.data] = xlsread(input_lpt.path,input_lpt.sheet_name);
% First row is header row, isolate this row for identification of Columns:
xls_lpt.header = xls_lpt.data(input_lpt.header_row,:);
xls_lpt.data = xls_lpt.data(input_lpt.data_cut_row:end,:);

% make the selection of the spezified grid to be allocated:
idx_ids = strcmp(xls_lpt.header,input_lpt.header_ids);
xls_lpt.id_to_use = xls_lpt.data(:,idx_ids);
idx_lpt_to_use = strncmp(xls_lpt.id_to_use,grid_names{grid_selector},numel(grid_names{grid_selector}));
xls_lpt.data = xls_lpt.data(idx_lpt_to_use,:);
xls_lpt.id_to_use = xls_lpt.id_to_use(idx_lpt_to_use,:);

% Where are the load-profiles?
idx_lp = strcmp(xls_lpt.header, input_lpt.header_lpt);
% get the loadprofile typs
xls_lpt.loadprofiles = xls_lpt.data(:,idx_lp);
idx_lpt_to_use = true(size(xls_lpt.loadprofiles));
% Deal with the "EAG" prefixes in some date (Energie AG --> removing this
% additional information):
for i=1:numel(xls_lpt.loadprofiles)
	if strncmp(xls_lpt.loadprofiles{i},'EAG',3)
		xls_lpt.loadprofiles{i} = xls_lpt.loadprofiles{i}(5:end);
	end
	if isnan(xls_lpt.loadprofiles{i})
		idx_lpt_to_use(i) = false;
		xls_lpt.loadprofiles{i} = 'Nicht zugeordnet';
	end
end

xls_lpt.loadprofiles = xls_lpt.loadprofiles(idx_lpt_to_use);
xls_lpt.id_to_use = xls_lpt.id_to_use(idx_lpt_to_use);
xls_lpt.data = xls_lpt.data(idx_lpt_to_use,:);

clear idx_lp idx_ids i idx_lpt_to_use

% what are the different load profiles?
xls_lp = sort(unique(xls_lpt.loadprofiles));
% Evaluation.Grid_Name = sheet_names{sheet_selector};
Evaluation.Loadprofiles_present = xls_lp;
fprintf('===========\n');
disp(['Following loadprofiles were found for "',...
	grid_names{grid_selector},'": ']);
disp(xls_lp);

% Where are the load-profiles typs?
idx_lp_typs = strcmp(xls_lpt.header, input_lpt.header_typ);
% get the loadprofile typs
xls_lpt.loadprofiles_typs = xls_lpt.data(:,idx_lp_typs);
% Deal with the "EAG" prefixes in some date (Energie AG --> removing this
% additional information):
input_lp_typs = cell(0,2);
for i=1:numel(xls_lpt.loadprofiles_typs)
	parts = regexp(xls_lpt.loadprofiles_typs{i},', ','split');
	for j=1:numel(parts)
		subparts = regexp(parts{j},'-','split');
		idx = find(strcmp(input_lp_typs(:,1),subparts{1}));
		if isempty(idx)
			input_lp_typs{end+1,1} = subparts{1}; %#ok<SAGROW>
			input_lp_typs{end,2} = 1;
		else
			input_lp_typs{idx,2} = input_lp_typs{idx,2} + 1;
		end
	end
end

% what are the different types?
xls_lpt_typs = sort(unique(input_lp_typs(:,1)));
% Evaluation.Grid_Name = sheet_names{sheet_selector};
Evaluation.Loadprofile_Typs_present = xls_lpt_typs;
fprintf('===========\n');
disp(['Following loadprofile typs were found for "',...
	grid_names{grid_selector},'" [number of occuring]: ']);
disp(input_lp_typs);
fprintf('-----------\n');

idx = strcmp(xls_lpt.header,input_lpt.header_pow);
xls_lpt.powers = xls_lpt.data(:,idx);
idx = strcmp(xls_lpt.header,input_lpt.header_sec);
xls_lpt.how_to_deal_with_loadprofile = xls_lpt.data(:,idx);
idx = strcmp(xls_lpt.header,input_lpt.header_yec);
xls_lpt.annual_energy = xls_lpt.data(:,idx);

clear i j idx idx_lp_typs parts subparts input_lpt_typs
clear xls_lpt_typs xls_lp

fprintf('Start with loadprofile allocation:\n');

timepoints = output_year_number:1/(24 * 60 * 60 / Timebase_Output):(output_year_number+Timebase_Number_Days);
timepoints = timepoints(1:end-1)';

Settings.Input_LPTs_to_use = xls_lpt.loadprofiles_typs;
Settings.Grid_Selector = grid_selector;

for a = 1:numel(xls_lpt.loadprofiles_typs)
	fprintf(['\t',xls_lpt.id_to_use{a},': '])
	
	deal_typ = xls_lpt.how_to_deal_with_loadprofile{a};
	idx = strcmp(xls_fll.names,xls_lpt.loadprofiles_typs{a});
	runtimes = xls_fll.data(idx,:);
	switch lower(deal_typ)
		case 'laufzeit'
			str='Allocate profile based on runtime: ';
			fprintf([str,blanks(50-numel(str))]);
			Loadprofile = flexload_allocation_runtime(xls_lpt.annual_energy{a}, runtimes(:,3:end), timepoints, Timebase_Output);
			Source.Runtime_Info = runtimes;
			fprintf('OK! ');
		case 'temperatur'
			str='Allocate profile based on temperature: ';
			fprintf([str,blanks(50-numel(str))]);
			Loadprofile = flexload_allocation_temperature(xls_lpt.annual_energy{a},...
				runtimes(:,3:end), timepoints, Timebase_Output, Temperatures);
			Source.Runtime_Info = runtimes;
			fprintf('OK! ');
		case 'leistung'
			str='Allocate profile based on power: ';
			fprintf([str,blanks(50-numel(str))]);
			Loadprofile = flexload_allocation_power(xls_lpt.annual_energy{a},...
				runtimes(:,3:end), timepoints, Timebase_Output, xls_lpt.powers{a});
			Source.Runtime_Info = runtimes;
			fprintf('OK! ');
		case 'leistung, temperatur'
			str = 'Allocate profile based on power and temperature: ';
			fprintf([str,blanks(50-numel(str))]);
			lpts = regexp(xls_lpt.loadprofiles_typs{a},', ','split');
			idx = strcmp(xls_fll.names,lpts{1});
			runtimes_power = xls_fll.data(idx,:);
			idx = strcmp(xls_fll.names,lpts{2});
			runtimes_temperature = xls_fll.data(idx,:);
			Loadprofile = flexload_allocation_powerandtemperature(xls_lpt.annual_energy{a},...
				runtimes_power(:,3:end), runtimes_temperature(:,3:end), timepoints, Timebase_Output, ...
				Temperatures, xls_lpt.powers{a});
			Source.Runtime_Info = [runtimes_power; runtimes_temperature];
			fprintf('OK! ');
		case 'profil'
			str = 'Allocate profile based on a power profile: ';
			fprintf([str,blanks(50-numel(str))]);
			filename = [pwd,filesep,'Energy_Values_Profile_Saved',sep,runtimes{1},'.mat'];
			% get the engery inforamation of the profiles with ontimes
			% corresponding with the given loadprofile.
			if exist(filename, 'file') == 2
				load(filename);
			else
				ontime = flexload_runtimelist2ontime(runtimes(3:end),timepoints);
				[Energy_information, Energy_values] = ...
					flexload_allocatoin_get_profile_energy(input_simdata, sep, ...
					input_selector, Timebase_Output, ontime);
				save(filename,'-v7.3',...
					'input_selector','Energy_information','Energy_values',...
					'ontime','Timebase_Output');
			end
			tstr = ['Allocation for "',xls_lpt.id_to_use{a},'"'];
			estr = [];
			Allocation = household_allocation (xls_lpt.annual_energy{a}, ...
				xls_lpt.id_to_use(a), Energy_information, Energy_values, eps_lst, tstr, estr, 0);
			fprintf(['Profile with ',num2str(Allocation{8,1}),...
				'%% error found (',num2str(Allocation{6,1}),'kW for ',num2str(xls_lpt.annual_energy{a}),'kW) ']);
			Settings.max_power_single_phase = max_power_single_phase;
			Settings.phase_composition_quantile = phase_composition_quantile;
			
			get_loadprofiles(Allocation, 0, sep, eval_id, input_simdata.path, ...
				output.dest_path, output.dest_path_powers, Settings, []);
			filename = [output.dest_path,filesep,output.dest_path_powers,filesep,eval_id,sep,xls_lpt.id_to_use{a},sep,'Overall_Power.mat'];
			load(filename);
			Loadprofile(~logical(ontime),:) = 0;
			Source.Runtime_Info = runtimes;
			fprintf('OK! ');
		case 'leistung, leistung'
			str = 'Allocate profile based on two powers: ';
			fprintf([str,blanks(50-numel(str))]);
			lpts = regexp(xls_lpt.loadprofiles_typs{a},', ','split');
			idx = strcmp(xls_fll.names,lpts{1});
			runtimes_power1 = xls_fll.data(idx,:);
			idx = strcmp(xls_fll.names,lpts{2});
			runtimes_power2 = xls_fll.data(idx,:);
			Loadprofile = flexload_allocation_powerandpower(xls_lpt.annual_energy{a},...
				runtimes_power1(:,3:end), runtimes_power2(:,3:end), timepoints, Timebase_Output, ...
				xls_lpt.powers{a});
			Source.Runtime_Info = [runtimes_power1; runtimes_power2];
			fprintf('OK! ');
		otherwise
			Loadprofile = [];
			Source = [];
			fprintf('No procedure present! ')
	end
	if ~isempty(Loadprofile)
		Load_ID = xls_lpt.id_to_use{a};
		
		Loadprofile = round(Loadprofile);
		Loadprofile = int32(Loadprofile);
		
		filename = [output.dest_path,filesep,output.dest_path_powers,filesep,eval_id,sep,Load_ID,sep,'Overall_Power.mat'];
		save(filename,'Loadprofile','Load_ID','Source');
		fprintf('File saved! ');
	end
	fprintf('\n');
end
fprintf('===========\n');
diary ('off');
end
