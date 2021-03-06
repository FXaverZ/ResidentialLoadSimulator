clear;
%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
% input_lpt.path = 'D:\Projekte\Leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-09-20_load_types_anonymised.xls';
input_lpt.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
% input_lpt.path = 'E:\Projekte\leafs\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-11-15_load_types_anonymised_FZ.xlsx';
% input_lpt.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-11-15_load_types_anonymised_FZ.xlsx';

% input_simdata.path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input_simdata.path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% input_simdata.path = 'D:\Verbrauchersimulation mit DSM\Simulationsergebnisse';
% input_simdata.path = 'D:\Projekte_Stuff\leafs\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% input_simdata.path = 'E:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';

% input_lpt_to_use = {'H0','L0','L1','L2'};
% input_lpt_to_use = {'H0'};

%--------------------------------------------------------------------------
% General Information
%--------------------------------------------------------------------------
sep = ' - ';
input_lpt.sheet_name = 'Load Profile Index';

% selection of the grid to be assigned:
grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
grid_selector = 2;

% Which input data should be used?
% input_selector = 'As simulated';
% input_selector = 'Without flexible loads';
input_selector = 'Only Heatpumps';

input_lpt.header_row   = 2; %Row, in which the header information can be found
input_lpt.data_cut_row = 4; %From this row on, the data in the input excel can be found!
input_lpt.header_yec = 'Heat Pump - annual energy consumption';
input_lpt.header_lpt = 'Heat Pump - profile';
input_lpt.header_ids = 'Load Profile ID';

eps_lst = [...
	%eps start, delta eps, eps end, load reduction start, delta, end
	         0,      0.01,       1,                   99,    -1,   1, 101, 1, 200;...
	         1,       0.1,      10,                   99,    -1,   1, 101, 1, 200;...
	        10,       0.5,     100,                   99,    -1,   1, 101, 1, 200;...
	       100,         1,    1000,                   90,    -10,   10, 110, 10, 800;...
	%      1000,        10,   10000,                   99,    -1,  95;...
	% 	  10000,       100,  100000,                   99,    -1,  95;...
	];
%==========================================================================
addpath([pwd,filesep,'01_Hilfsfunktionen']);
for grid_selector = 1:4
	input_lpt_to_use = {'All'};
%--------------------------------------------------------------------------
% Read in Excel-configuration information
%--------------------------------------------------------------------------
	diary(['Allocated_Heat_Pumps_Profiles',sep,grid_names{grid_selector},sep,'LOG.txt']);
	
	[~,~,xls_input] = xlsread(input_lpt.path,input_lpt.sheet_name);
	% First row is header row, isolate this row for identification of Columns:
	xls_input_header = xls_input(input_lpt.header_row,:);
	xls_input = xls_input(input_lpt.data_cut_row:end,:);
	
	% make the selection of the spezified grid to be allocated:
	idx_ids = find(strcmp(xls_input_header,input_lpt.header_ids));
	xls_input_id_to_use = xls_input(:,idx_ids);
	idx_lpt_to_use = strncmp(xls_input_id_to_use,grid_names{grid_selector},numel(grid_names{grid_selector}));
	xls_input = xls_input(idx_lpt_to_use,:);
	xls_input_id_to_use = xls_input_id_to_use(idx_lpt_to_use,:);
	
	% Where are the load-profile typs?
	idx_lpt = strcmp(xls_input_header, input_lpt.header_lpt);
	% get the loadprofile typs
	xls_input_lp = xls_input(:,idx_lpt);
	% Deal with the "EAG" prefixes in some date (Energie AG --> removing this
	% additional information):
	idx_lpt_to_use = true(size(xls_input_lp));
	for i=1:numel(xls_input_lp)
		if strncmp(xls_input_lp{i},'EAG',3)
			xls_input_lp{i} = xls_input_lp{i}(5:end);
		end
		if isnan(xls_input_lp{i})
			idx_lpt_to_use(i) = false;
			xls_input_lp{i} = 'Nicht zugeordnet';
		end
	end
	xls_input_lp = xls_input_lp(idx_lpt_to_use);
	xls_input_id_to_use = xls_input_id_to_use(idx_lpt_to_use);
	xls_input = xls_input(idx_lpt_to_use,:);
	
	% what are the different types?
	xls_lpt = sort(unique(xls_input_lp));
	% Evaluation.Grid_Name = sheet_names{sheet_selector};
	Evaluation.Loadprofile_Typs_present = xls_lpt;
	disp('===========');
	disp(['Following loadprofile typs were found for "',...
		grid_names{grid_selector},'": ']);
	disp(xls_lpt);
	disp('-----------');
	% Identify the rows with the to be used load profiles:
	if strcmpi(input_lpt_to_use{1},'all')
		input_lpt_to_use = xls_lpt;
		use_all_lpt = 1;
	else
		use_all_lpt = 0;
	end
	idx_lpt_to_use = [];
	for i = 1:numel(input_lpt_to_use)
		idx_lpt_to_use = [idx_lpt_to_use;find(strcmp(xls_input_lp,input_lpt_to_use{i}))]; %#ok<AGROW>
	end
	idx_lpt_to_use = sort(idx_lpt_to_use);
	
	%Where is the yearly energy?
	idx_yec = find(strcmp(xls_input_header,input_lpt.header_yec));
	xls_input_ye = cell2mat(xls_input(:,idx_yec));
	ye_total = sum(xls_input_ye);
	ye_to_use = sum(xls_input_ye(idx_lpt_to_use));
	if use_all_lpt == 1
		str = 'For all load profile typs';
	elseif numel(input_lpt_to_use) == 1
		str = ['For load profile typ "',input_lpt_to_use{1},'"'];
	else
		str = 'For load profile typs "';
		for i = 1:numel(input_lpt_to_use)
			if i > 1 && i <= numel(input_lpt_to_use)-1
				str = [str,', "'];  %#ok<AGROW>
			end
			if i == numel(input_lpt_to_use)
				str = [str, ' and "']; %#ok<AGROW>
			end
			str = [str, input_lpt_to_use{i}, '"']; %#ok<AGROW>
		end
	end
	disp([str,...
		' a share of ',num2str(ye_to_use*100/ye_total),...
		'% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.']);
	disp([num2str(numel(idx_lpt_to_use)),' loadpoints of ',num2str(numel(xls_input_ye)),...
		' can be supplied with a loadprofile.']);
	disp('-----------');
	
	Evaluation.Used_Loadprofiles = input_lpt_to_use;
	Evaluation.Total_Yearly_Energy_Consumption = ye_total;
	Evaluation.Total_Yearly_Energy_Consumption_unit = 'kWh';
	Evaluation.Possible_Yearly_Energy_Consumption = ye_to_use;
	Evaluation.Possible_Yearly_Energy_Consumption_share = ye_to_use*100/ye_total;
	Evaluation.Possilbe_Yearly_Energy_Consumption_unit = 'kWh';
	Evaluation.Total_Number_Loadpoints = numel(xls_input_ye);
	Evaluation.Possible_Number_Loadpoints = numel(idx_lpt_to_use);
%--------------------------------------------------------------------------
% Get the yearly energy consumption values for the relevant loads defined by
%loadprofile typ to be considered:
%--------------------------------------------------------------------------
	ye_to_use = xls_input_ye(idx_lpt_to_use);
	xls_input_id_to_use = xls_input_id_to_use(idx_lpt_to_use);
	% Sort the values
	[ye_to_use, IX] = sort (ye_to_use);
	idx_lpt_to_use = idx_lpt_to_use(IX);
	xls_input_id_to_use = xls_input_id_to_use(IX);
	
	% retrieve the information of the simulated profiles:
	content = dir(input_simdata.path);
	content = struct2cell(content);
	content = content(1,3:end);
	
	Energy_information = {};
	Energy_values = [];
	for a = 1:numel(content)
		% actual path
		path = content{a};
		% get the files in this subdirectory:
		files = dir([input_simdata.path,filesep,path]);
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
				load([input_simdata.path,filesep,path,filesep,filename]);
				modelload = 0;
			end
			switch lower(input_selector)
				case 'as simulated'
					if strcmp(name_parts{1},'Summary') && strcmp(name_parts{3},'Energy_Year.mat');
						%loading of energy summary of the simulated data:
						load([input_simdata.path,filesep,path,filesep,filename]);
					end
				case 'without flexible loads'
					if strcmp(name_parts{1},'Summary') && strcmp(name_parts{3},'Energy_Year_FlexSep.mat');
						%loading of energy summary of the simulated data:
						load([input_simdata.path,filesep,path,filesep,filename]);
						Energy = Energy_InFlex;
						clear Energy_Flex Energy_InFlex Energy_Day_Flex Energy_Day_Inflex  
					end
				case 'only heatpumps'
					if strcmp(name_parts{1},'Summary') && strcmp(name_parts{3},'Energy_Year_HPs.mat');
						load([input_simdata.path,filesep,path,filesep,filename]);
						Energy = Energy_HPs;
						clear Energy_Day_HPs Energy_HPs
					end
				otherwise
					error('Not supported!!!');
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
	
	idx = Energy_values ~= 0;
	Energy_information = Energy_information(:,idx);
	Energy_values = Energy_values(idx);
%--------------------------------------------------------------------------
% Check, how many profiles can be directly allocated
% (eleminate vaulues out of the range of the simulated profiles)
%--------------------------------------------------------------------------
	idx_lpt_to_use_zeros = idx_lpt_to_use(ye_to_use <= 0.1);
	idx_lpt_to_use_tosma = idx_lpt_to_use(ye_to_use < min(Energy_values));
	idx_lpt_to_use_tobig = idx_lpt_to_use(ye_to_use > max(Energy_values));
	
	fprintf([...
		str,' in "',grid_names{grid_selector},'" are \n\t',...
		num2str(numel(idx_lpt_to_use_zeros)),' yearly energy values zero, \n\t',...
		num2str(numel(idx_lpt_to_use_tosma)),' values smaller than the minimal simulated energy value, \n\t',...
		num2str(numel(idx_lpt_to_use_tobig)),' values higher than the maximal simulated energy vaulue.\n',...
		]);
	fprintf('-----------\n');
	Evaluation.Number_selected_Profiles_equal_zero = numel(idx_lpt_to_use_zeros);
	Evaluation.Number_selected_Profiles_less_min = numel(idx_lpt_to_use_tosma);
	Evaluation.Number_selected_Profiles_bigger_max = numel(idx_lpt_to_use_tobig);
%--------------------------------------------------------------------------
% Allocate housholds
%--------------------------------------------------------------------------
	fprintf([...
		'Starting of allocation of households.\n',...
		'-------------------------------------\n',...
		]);
	tstr_1 = ['Allocation for "',grid_names{grid_selector},'" and f',str(2:end)];
	tstr = [tstr_1,' (all profiles)'];
	fprintf([tstr_1,' (all profiles)\n']);
	estr = sprintf([str,' a share of ',num2str(sum(xls_input_ye(idx_lpt_to_use))*100/ye_total),...
		'%% of the yearly energy consumption of ',num2str(ye_total/1000),'MWh can be realized.\n',...
		num2str(numel(idx_lpt_to_use)),' loadpoints of ',num2str(numel(xls_input_ye)),...
		' can be supplied with a loadprofile.\n',...
		str,' in "',grid_names{grid_selector},'" are from ',num2str(numel(idx_lpt_to_use)),' profiles\n    ',...
		num2str(numel(idx_lpt_to_use_zeros)),' yearly energy values zero, \n    ',...
		num2str(numel(idx_lpt_to_use_tosma)),' values smaller than the minimal simulated energy value, (',num2str(min(Energy_values)),'kWh)\n    ',...
		num2str(numel(idx_lpt_to_use_tobig)),' values higher than the maximal simulated energy vaulue (',num2str(max(Energy_values)),'kWh).\n',...
		]);
	[allocation, found] = heatpumps_allocation (ye_to_use, xls_input_id_to_use, Energy_information, Energy_values, eps_lst, tstr, estr, 1);

	Evaluation.Selected_Yearly_Energy_Consumption = sum(ye_to_use);
	Evaluation.Selected_Yearly_Energy_Consumption_unit = 'kWh';
	Evaluation.Selected_Yearly_Energy_Consumption_share = sum(ye_to_use)*100/ye_total;
	Evaluation.Selected_Number_Loadpoints = numel(ye_to_use);
	
	Settings.input_lpt_to_use = input_lpt_to_use;
	Settings.Timebase_Output = 60;
	Settings.Grid_Names = grid_names;
	Settings.Grid_Selector = grid_selector;
	Settings.Input_Selector = input_selector;
	Settings.Eps_Lst = eps_lst;
	
	Allocation = allocation;
	save(['Allocated_Heat_Pumps_Profiles',sep,grid_names{grid_selector},'.mat'],'Allocation', 'Settings', 'Evaluation', 'Time', 'Model');
	savefig(['Allocated_Heat_Pumps_Profiles',sep,grid_names{grid_selector},'.fig']);
	close(gcf);
	diary('off');
end
% clear;