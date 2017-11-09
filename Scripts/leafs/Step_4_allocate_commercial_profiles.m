clear;
%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
Settings.Timebase_Output = 60;
% MD1EEZ0C - Simulationsrechner
% input_lpt.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
% MD1JFTNC - Fujitsu Laptop
input_lpt.path = 'D:\Projekte\Leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
input_allocation.HH_path = 'D:\Projekte\Leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_H0_ALTENHEIM';
%--------------------------------------------------------------------------
% General Information
%--------------------------------------------------------------------------
sep = ' - ';
input_lpt.sheet_name = 'Load Profile Index';

% selection of the grid to be assigned:
grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
grid_selector = 4;

% Which input data should be used?
% input_selector = 'As simulated';
% input_selector = 'Without flexible loads';
% input_selector = 'Only Heatpumps';

input_lpt.header_row   = 2; %Row, in which the header information can be found
input_lpt.data_cut_row = 4; %From this row on, the data in the input excel can be found!

header_ids = 'Load Profile ID';
input_lpt.header_yec = 'Fixed Load - annual energy consumption';
input_lpt.header_lpt = 'Fixed Load - profile';
input_lpt.header_ids = 'Load Profile ID';
%==========================================================================
addpath([pwd,filesep,'01_Hilfsfunktionen']);
for grid_selector = 1:4
	diary(['Allocated_Commercial_Profiles',sep,grid_names{grid_selector},sep,'LOG.txt']);
	
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
	
	% load the confguration of the last step:
	hh_allocation = load ([input_allocation.HH_path,filesep,'Allocated_Household_Profiles',...
		sep,grid_names{grid_selector},'.mat']);
	Model = hh_allocation.Model;
	Time = hh_allocation.Time;
	
	
	% remove the allready allocated profiles:
	input_lpt_to_use = xls_lpt;
	hh_lpt = hh_allocation.Evaluation.Used_Loadprofiles;
	for i=1:numel(hh_lpt)
		idx = strcmp(xls_lpt,hh_lpt{i});
		input_lpt_to_use(idx) = [];
	end
	
	% get the indexes of the now given load profiles:
	idx_lpt_to_use = true(size(xls_input_lp));
	for i=1:numel(xls_input_lp)
		if isempty(find(strcmp(input_lpt_to_use,xls_input_lp{i}),1))
			idx_lpt_to_use(i) = false;
		end
	end
	
	%Where is the yearly energy?
	idx_yec = find(strcmp(xls_input_header,input_lpt.header_yec));
	xls_input_ye = cell2mat(xls_input(:,idx_yec));
	ye_total = sum(xls_input_ye);
	ye_to_use = sum(xls_input_ye(idx_lpt_to_use));
	if numel(input_lpt_to_use) == 1
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
	disp([num2str(sum(idx_lpt_to_use)),' loadpoints of ',num2str(numel(xls_input_ye)),...
		' can be supplied with a loadprofile.']);
	disp('-----------');
	
	Evaluation.Used_Loadprofiles = input_lpt_to_use;
	Evaluation.Total_Yearly_Energy_Consumption = ye_total;
	Evaluation.Total_Yearly_Energy_Consumption_unit = 'kWh';
	Evaluation.Possible_Yearly_Energy_Consumption = ye_to_use;
	Evaluation.Possible_Yearly_Energy_Consumption_share = ye_to_use*100/ye_total;
	Evaluation.Possilbe_Yearly_Energy_Consumption_unit = 'kWh';
	Evaluation.Total_Number_Loadpoints = numel(xls_input_ye);
	Evaluation.Possible_Number_Loadpoints = sum(idx_lpt_to_use);
	
	Settings.Grid_Names = grid_names;
	Settings.Grid_Selector = grid_selector;
	
	ye_to_use = xls_input_ye(idx_lpt_to_use);
	lp_to_use = xls_input_lp(idx_lpt_to_use);
	xls_input_id_to_use = xls_input_id_to_use(idx_lpt_to_use);
	
	fprintf([...
		'Starting allocation of commercial loads.\n',...
		'----------------------------------------\n',...
		]);
	Allocation = cell(9,numel(ye_to_use));
	for i=1:numel(ye_to_use)
		fprintf(['\t',xls_input_id_to_use{i},': ']);
		Allocation{1,i} = xls_input_id_to_use{i};
		if ye_to_use(i) < 1
			fprintf(['Yearly energy = 0! (',lp_to_use{i},')\n']);
			Allocation{3,i} = 'Zero';
			Allocation{7,i} = 0;
			continue;
		end
		data = BDEWProfileDaten(lp_to_use{i});
		if isempty(data)
			fprintf(['Error! Unknwon profile type! (',lp_to_use{i},')\n']);
			Allocation{3,i} = 'Unknown';
		else
			fprintf([lp_to_use{i},' (',num2str(ye_to_use(i)),' kWh)\n']);
			Allocation{3,i} = lp_to_use{i};
		end
		Allocation{7,i} = ye_to_use(i);
	end
	disp('===========');
	save(['Allocated_Commercial_Profiles',sep,grid_names{grid_selector},'.mat'],'Allocation', 'Settings', 'Evaluation', 'Time', 'Model');
	disp(['Saved "',['Allocated_Commercial_Profiles',sep,grid_names{grid_selector},'.mat'],'"']);
	disp('===========');
	diary('off');
	
end
