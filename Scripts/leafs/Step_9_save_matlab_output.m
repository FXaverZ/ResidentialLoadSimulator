clear;

% MD1JFTNC - Fujitsu Laptop
% input_lpt.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
% output.dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';


% MD1EEZ0C - Simulationsrechner
input_lpt.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
output.dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

output.dest_path_powers.fixed = 'Powers_Fixed_Loads';
output.dest_path_powers.inflex = 'Powers_Flexible_Loads';
output.dest_path_powers.hps = 'Powers_HP_Loads';
output.dest_path_powers.pv_ev = 'Powers_PV_EV';

output.filename_corename = 'LEAFS_AP3_INPUT_data_';

input_lpt.sheet_name = 'Load Profile Index';

input_lpt.header_row   = 1; %Row, in which the header information can be found
input_lpt.data_cut_row = 4; %From this row on, the data in the input excel can be found!
input_lpt.header_ids = 'Load Profile ID';

sep = ' - ';

%--------------------------------------------------------------------------
% Create a matlab output
%--------------------------------------------------------------------------

addpath([pwd,filesep,'01_Hilfsfunktionen']);
eval_time = now;
eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');

data_typs = fields(output.dest_path_powers);

% selection of the grid to be assigned:
grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
% grid_selector = 3;
for grid_selector = 1:4
	cur_grid = grid_names{grid_selector};
	modelload = false;
	PV_EV = [];
	output_filename = [output.dest_path,filesep,eval_id,sep,output.filename_corename,cur_grid];
	diary([output_filename,sep,'LOG.txt']);
	fprintf('===============\n');
	fprintf(['Processing "',cur_grid,'": \n']);
	for b = 1:numel(data_typs)
		
		content.(data_typs{b}) = dir([output.dest_path,filesep,output.dest_path_powers.(data_typs{b}),filesep]);
		content.(data_typs{b}) = struct2cell(content.(data_typs{b}));
		content.(data_typs{b}) = content.(data_typs{b})(1,3:end);
			
		simtimeid.(data_typs{b}) = [];
		
		for a = 1:numel(content.(data_typs{b}))
			filename = content.(data_typs{b}){a};
			name_parts = regexp(filename, sep, 'split');
			if numel(name_parts) > 1 && isempty(simtimeid.(data_typs{b})) ...
					&& strncmp(name_parts{2},cur_grid,length(cur_grid))
				simtimeid.(data_typs{b}) = name_parts{1};
			end
			if ~isempty(simtimeid.(data_typs{b})) && ~modelload && numel(name_parts) > 2 ...
					&& strcmp(name_parts{3},'Modeldaten.mat')
				load([output.dest_path,filesep,...
					output.dest_path_powers.(data_typs{b}),filesep,...
					simtimeid.(data_typs{b}),sep,cur_grid,sep,'Modeldaten.mat']);
				modelload = true;
			end
		end
	end
	% load ([input_allocation_path,filesep,'Allocated_Household_Profiles',sep,sheet_names{sheet_selector},'.mat']);
	Allocation = [Allocation, Allocation_Commercial];
	ids = [Allocation{1,:}];
	[~, IX] = sort(ids);
	Allocation_Sort = Allocation(:,IX);
	
	[~,~,xls_lpt.data] = xlsread(input_lpt.path,input_lpt.sheet_name);
	% First row is header row, isolate this row for identification of Columns:
	xls_lpt.header = xls_lpt.data(input_lpt.header_row,:);
	xls_lpt.data = xls_lpt.data(input_lpt.data_cut_row:end,:);
	output_col_headers = {};
	output_col_headers{1} = 'P_PV_max_[0-1]';
	for a=1:numel(xls_lpt.header)
		if isnan(xls_lpt.header{a})
			continue;
		end
		entry = xls_lpt.header{a};
		entry = strrep(entry,' ','_');
		output_col_headers{end+1} = [entry,'_[kW]']; %#ok<SAGROW>
	end
	
	time = Time.Series_Date_Start:Settings.Timebase_Output/Time.day_to_sec:Time.Series_Date_End+1;
	time = time(1:end-1)';
	
	number_categories  = numel(output_col_headers)-1;
	
	Loadprofiles_Data = int32(zeros(...
		numel(time),...
		size(Allocation_Sort,2)*number_categories*3+2));
	
	Loadprofiles_Data(:,1) = int32(time);
	clear time;
	
	Loadprofiles_Header = cell(3,size(Loadprofiles_Data,2));
	Loadprofiles_Header{1,1} = '';
	Loadprofiles_Header{1,2} = 'General input signal (AIT)';
	Loadprofiles_Header{2,1} = '';
	Loadprofiles_Header{2,2} = output_col_headers{1};
	Loadprofiles_Header{3,1} = 'Time';
	Loadprofiles_Header{3,2} = '';
	
	for a = 1:size(Allocation_Sort,2)
		try
			ID = cell2mat(Allocation_Sort(1,a));
		catch
			ID = cell2mat(Allocation_Sort{1,a});
		end
		
		sumload = int32(zeros(size(Loadprofiles_Data,1),3));
		
		fprintf(['\t',ID,': \n']);
		load([output.dest_path,filesep,output.dest_path_powers.fixed,...
			filesep,simtimeid.fixed,sep,ID,sep,'Overall_Power.mat']);
		for b = 1:size(Allocation_Sort,1)
			if iscell(Allocation_Sort{b,a})
				if numel(Allocation_Sort{b,a}) == 1
					Loadprofiles_Header{1,2+(a-1)*number_categories*3+b} = cell2mat(Allocation_Sort{b,a});
				else
					Loadprofiles_Header{1,2+(a-1)*number_categories*3+b} = Allocation_Sort{b,a};
				end
			else
				Loadprofiles_Header{1,2+(a-1)*number_categories*3+b} = Allocation_Sort{b,a};
			end
		end
		for b=1:number_categories
			Loadprofiles_Header{2,2+(a-1)*number_categories*3+1+(b-1)*3}=output_col_headers{b+1};
			Loadprofiles_Header{3,2+(a-1)*number_categories*3+(b-1)*3+1}='L1';
			Loadprofiles_Header{3,2+(a-1)*number_categories*3+(b-1)*3+2}='L2';
			Loadprofiles_Header{3,2+(a-1)*number_categories*3+(b-1)*3+3}='L3';
		end
		Loadprofiles_Data(:,(a-1)*number_categories*3+(3:5))=Loadprofile;
		sumload = sumload + Loadprofile;
		pr_energy = sum(sum(double(Loadprofile)*Settings.Timebase_Output/(60*60*1000)));
		fprintf(['\t\tFixed Load (',num2str(pr_energy/1000),' MWh); ']);
		filename = [output.dest_path,filesep,output.dest_path_powers.inflex,...
			filesep,simtimeid.inflex,sep,ID,sep,'Overall_Power.mat'];
		if exist(filename, 'file') == 2
			load(filename);
			Loadprofiles_Data(:,(a-1)*number_categories*3+(6:8))=Loadprofile;
			sumload = sumload + Loadprofile;
			pr_energy = sum(sum(double(Loadprofile)*Settings.Timebase_Output/(60*60*1000)));
			fprintf(['Flexible Load (',num2str(pr_energy/1000),' MWh); ']);
		end
		filename = [output.dest_path,filesep,output.dest_path_powers.hps,...
			filesep,simtimeid.hps,sep,ID,sep,'Overall_Power.mat'];
		if exist(filename, 'file') == 2
			load(filename);
			Loadprofiles_Data(:,(a-1)*number_categories*3+(9:11))=Loadprofile;
			sumload = sumload + Loadprofile;
			pr_energy = sum(sum(double(Loadprofile)*Settings.Timebase_Output/(60*60*1000)));
			fprintf(['Heat Pumps (',num2str(pr_energy/1000),' MWh); ']);
		end
		if isempty(PV_EV)
			filename = [output.dest_path,filesep,output.dest_path_powers.pv_ev,...
				filesep,simtimeid.pv_ev,sep,cur_grid,sep,'PV_EV.mat'];
			PV_EV = load(filename);
			% get rid of NANs
			ocur_nan = isnan(PV_EV.Loadprofiles_Data);
			PV_EV.Loadprofiles_Data(ocur_nan) = 0;
		end
		idx = find(strcmp(PV_EV.Loadprofiles_Header(1,:),ID));
		% EVs:
		ev_energy = sum(sum(PV_EV.Loadprofiles_Data(:,idx+(3:5))))*Settings.Timebase_Output/(60*60);
		pv_energy = sum(sum(PV_EV.Loadprofiles_Data(:,idx+(0:2))))*Settings.Timebase_Output/(60*60);
		if ev_energy > 0
			Loadprofiles_Data(:,(a-1)*number_categories*3+(12:14)) = int32(round(PV_EV.Loadprofiles_Data(:,idx+(3:5))*1000));
			sumload = sumload + Loadprofiles_Data(:,(a-1)*number_categories*3+(12:14));
			fprintf(['EV (',num2str(ev_energy/1000),' MWh); ']);
		end
		if pv_energy < 0
			Loadprofiles_Data(:,(a-1)*number_categories*3+(15:17)) = int32(round(PV_EV.Loadprofiles_Data(:,idx+(0:2))*1000));
			fprintf(['PV Infeed (',num2str(pv_energy/1000),' MWh); ']);
		end 
		fprintf(['\n\t\tOverall load energy: ',num2str(sum(sum(double(sumload)*Settings.Timebase_Output/(60*60*1000*1000)))),'MWh; ']);
		fprintf(['max. power: ',num2str(max(max(sumload))),'W; ']);
		max_diff_phase = max(max(sumload,[],2) - min(sumload,[],2));
		fprintf([' max. phase difference: ',num2str(max_diff_phase),'W; ']);
		max_diff_phase = quantile(max(sumload,[],2) - min(sumload,[],2),0.99);
		fprintf([' max. phase difference (99%%-quantile): ',num2str(max_diff_phase),'W']);
		fprintf('\n');
	end
	fprintf('--------------\n');
	clear Loadprofile;
	save([output_filename,'.mat'],'-v7.3',...
		'Loadprofiles_Header', 'Loadprofiles_Data');
	fprintf(['Data saved! (',strrep(output_filename,'\','\\'),'.mat)\n']);
	fprintf('===============\n');
	fprintf('\n');
	diary off;
end

