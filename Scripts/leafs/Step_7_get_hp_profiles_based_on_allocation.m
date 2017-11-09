%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
clear;

output.year_string = '2014';
Timebase_Number_Days = 365;
Timebase_Output = 60;
max_power_single_phase = 1300; %max power for single phase operation in W
max_power = 4001;
pos_power = 3001; 
phase_composition_quantile = 0.99;

% MD1JFTNC - Fujitsu Laptop
% input_lpt.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
% input_simdata.path = 'F:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% input_allocation.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_HPs';
% input_fll.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-11-23_Zusammenstellung_Flex_Loads.xlsx';
% input_tem.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2014-01-01_Termperaturdaten_2014.xlsx';
% output.dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

% MD1EEZ0C - Simulationsrechner
input_lpt.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
input_simdata.path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input_allocation.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_HPs';
input_fll.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-11-23_Zusammenstellung_Flex_Loads.xlsx';
input_tem.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2014-01-01_Termperaturdaten_2014.xlsx';
output.dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

output.dest_path_powers = 'Powers_HP_Loads';

%--------------------------------------------------------------------------
% General Information
%--------------------------------------------------------------------------
sep = ' - ';

input_lpt.sheet_name = 'Load Profile Index';
input_fll.sheet_name = 'Schaltzeiten';
input_tem.sheet_name = 'Temperaturen';

% selection of the grid to be assigned:
grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
grid_selector = 1;

input_lpt.header_row   = 2; %Row, in which the header information can be found
input_lpt.data_cut_row = 4; %From this row on, the data in the input excel can be found!
input_lpt.header_yec = 'Heat Pump - annual energy consumption';
input_lpt.header_lpt = 'Heat Pump - profile';
input_lpt.header_typ = 'Heat Pump - profile type';
input_lpt.header_pow = 'Heat Pump - contracted / rated power';
input_lpt.header_sec = 'Heat Pump - sector code';
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

%--------------------------------------------------------------------------
eval_time = now;
rng(27,'twister');
eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');
addpath([pwd,filesep,'01_Hilfsfunktionen']);
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

for grid_selector=1:4
Powers = [];
Load_IDs = {};
if ~isdir([output.dest_path,filesep,output.dest_path_powers])
	mkdir([output.dest_path,filesep,output.dest_path_powers]);
	
% 	save_raw_profiles = true;
% else
% 	content = dir([output.dest_path,filesep,output.dest_path_powers]);
% 	content = struct2cell(content);
% 	content = content(1,3:end);
% 	simtimeid = [];
% 	modelload = 0;
% 	for b = 1:numel(content)
% 		filename = content{b};
% 		name_parts = regexp(filename, sep, 'split');
% 		if isempty(simtimeid) && strcmp 
% 			simtimeid = name_parts{1};
% 		end
% 		if strcmp(name_parts{3},'Modeldaten.mat')...
% 				&& ~modelload
% 			try
% 			load([output.dest_path,filesep,output.dest_path_powers,filesep,filename]);
% 			modelload = 1;
% 			catch
% 				fprintf('Not possible to load model!\n');
% 				modelload = 0;
% 			end
% 		end
% 		if modelload && ~isempty(simtimeid)
% 			break;
% 		end
% 	end
% 	if  modelload
% 		eval_id = simtimeid;
% 		save_raw_profiles = false;
% 	else
% 		save_raw_profiles = true;
% 	end
end

diary([output.dest_path,filesep,output.dest_path_powers,filesep,eval_id,sep,grid_names{grid_selector},sep,'log.txt']);

% %--------------------------------------------------------------------------
% % First, save the found profiles (along with shift to year 2014 and
% % adaption according to the reduction factor...
% %--------------------------------------------------------------------------
% % if save_raw_profiles
	load ([input_allocation.path,filesep,'Allocated_Heat_Pumps_Profiles',sep,grid_names{grid_selector},'.mat']);
% 	Settings.max_power_single_phase = max_power_single_phase;
% 	Settings.phase_composition_quantile = phase_composition_quantile;
% 	
% 	get_loadprofiles(Allocation, 1, sep, eval_id, input_simdata.path, ...
% 		output.dest_path, output.dest_path_powers, Settings, Evaluation);
% % end

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

fprintf('Start with loadprofile adoption:\n');

timepoints = output_year_number:1/(24 * 60 * 60 / Timebase_Output):(output_year_number+Timebase_Number_Days);
timepoints = timepoints(1:end-1)';

Settings.Input_LPTs_to_use = xls_lpt.loadprofiles_typs;
Settings.Grid_Selector = grid_selector;

for a = 1:numel(xls_lpt.loadprofiles_typs)
	fprintf(['\t',xls_lpt.id_to_use{a},': '])
	lpts = regexp(xls_lpt.loadprofiles_typs{a},', ','split');
	idx = zeros(size(xls_fll.names));
	Load_ID = xls_lpt.id_to_use{a};
	for b=1:numel(lpts)
		idx = idx | strcmp(xls_fll.names,lpts{b});
	end
	runtimes = xls_fll.data(idx,:);
	idx_uwp = find(strcmp(runtimes(:,1),'UWP'));
	if ~isempty(idx_uwp)
		runtimes{end+1,1} = 'GRT';
		runtimes{end,2} = 'Erzeugte Startzeiten';
		runtimes{end,3} = runtimes{idx_uwp,3};
		runtimes{end,4} = runtimes{idx_uwp,4};
		runtimes{end,5} = (6+normrnd(0,0.75))/24+1;
		runtimes{end,6} = 11/24+1;
		runtimes{end,7} = runtimes{idx_uwp,3};
		runtimes{end,8} = runtimes{idx_uwp,4};
		runtimes{end,9} = (16+normrnd(0,0.75))/24+1;
		runtimes{end,10} = 23.75/24+1;
	end
	
	id_allo = strcmp([Allocation{1,:}],Load_ID);
	energy = Allocation{7,id_allo};
	
	Loadprofile = flexload_allocation_heatpumps(energy, runtimes, ...
	timepoints, Timebase_Output, Temperatures, 2, 0, 250, 20);
		
	filename = [output.dest_path,filesep,output.dest_path_powers,filesep,...
		eval_id,sep,Load_ID,sep,'Overall_Power.mat'];
% 	load(filename);
% 	% sum up all three phases
% 	Loadprofile = sum(Loadprofile,2);
% 	energy_lp = sum(Loadprofile);
% 	energy_lp_rt = sum(Loadprofile(logical(ontime),:));
% 	fac_power = energy_lp / energy_lp_rt;
% 	Loadprofile = Loadprofile * fac_power;
% 	Loadprofile(~logical(ontime)) = 0;
% 	Loadprofile = reshape(Loadprofile,1440,[]);
% 	energy_day = sum(Loadprofile);
% 	[energ_sort, energ_IX] = sort(energy_day);
% 	[temsp_sort, temps_IX] = sort(Temperatures,'descend'); 
% 	Loadprofile(:,temps_IX) = Loadprofile(:,energ_IX);
% 	Loadprofile = reshape(Loadprofile,[],1);
	
	if (max(Loadprofile) > pos_power)  
		fprintf('; P too high! Recalculate: ')
		if ~isempty(find(strcmp(runtimes(:,1),'H4'), 1)) || ...
				~isempty(find(strcmp(runtimes(:,1),'H6'), 1)) || ...
				~isempty(find(strcmp(runtimes(:,1),'H8'), 1))
			Loadprofile = flexload_allocation_heatpumps(energy, runtimes, ...
			timepoints, Timebase_Output, Temperatures, 0, 0, 0, 0);
		else
		Loadprofile = flexload_allocation_heatpumps(energy, runtimes, ...
			timepoints, Timebase_Output, Temperatures, 0, 4, 0, 0);
		end
	end
	
	Powers(end+1) = max(Loadprofile);
	Load_IDs{end+1} = Load_ID;
	
	if max(Loadprofile) < max_power_single_phase
		idx = vary_parameter([1;2;3],ones(3,1)*100/3,'List');
		load_profile = zeros(numel(Loadprofile),3);
		load_profile(:,idx) = Loadprofile;
		Loadprofile = load_profile;
		clear load_profile;
	else
		Loadprofile = repmat(Loadprofile,[1,3]);
		Loadprofile = Loadprofile / 3;
	end
	
	Source.Max_Power_Single_Phase = max_power_single_phase;
	
	Loadprofile = round(Loadprofile);
	Loadprofile = int32(Loadprofile);
	
	save(filename,...
				'Loadprofile','Load_ID','Source');
	fprintf('. Profile Saved.\n');
	
% 	fprintf('\n');
end

[Powers,IX] = sort (Powers);
Load_IDs = Load_IDs(IX);

filename = [output.dest_path,filesep,output.dest_path_powers,filesep,...
		eval_id,sep,grid_names{grid_selector},sep,'Power_Summary'];
save([filename,'.mat'], 'Powers','Load_IDs');

try
Powers_ok = zeros(size(Powers));
Powerspok = Powers_ok;
Powersnok = Powers_ok;

idx = Powers<pos_power;
Powers_ok(idx) = Powers(idx)/1000;
Powers_ok(Powers_ok==0) = NaN;

idx = Powers>=pos_power & Powers<max_power;
Powerspok(idx) = Powers(idx)/1000;
Powerspok(Powerspok==0) = NaN;

idx = Powers>=max_power;
Powersnok(idx) = Powers(idx)/1000;
Powersnok(Powersnok==0) = NaN;

xtick = 1:numel(Load_IDs);
% [ax, b, p] = plotyy(xtick,[Powers_ok',Powersnok'],xtick,Energies',@bar,@line);
b = bar([Powers_ok',Powerspok',Powersnok'],1,'stacked');
% set(gca,...
% set(ax,...
set(gca,...
	'XLim',[0.5,numel(Load_IDs)+0.5],...
	'XTick',xtick,...
	'XTickLabel',Load_IDs,...
	'XTickLabelRotation',90);
% b(2).BarLayout = 'stacked';
% b(1).BarLayout = 'stacked';
b(3).FaceColor='red';
b(2).FaceColor='yellow';
b(1).FaceColor='green';

% set(gcf,'units','normalized','outerposition',[0 0 1 1])
suptitle(['Heatpumps ',grid_names{grid_selector}]);

savefig([filename,'.fig']);
catch ME
	disp(ME.message);
end
% close(gcf);
diary('off');
end
