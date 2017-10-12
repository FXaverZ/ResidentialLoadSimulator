%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
clear;

% MD1JFTNC - Fujitsu Laptop
% input.simdata_path = 'F:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% input.allocation_hh_path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_H0_ALTENHEIM';
% output.dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\02_Output_detailed';

% MD1EEZ0C - Simulationsrechner
input.simdata_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input.allocation_hh_path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_H0_ALTENHEIM';
output.dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\02_Output_detailed';

sheet_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
sheet_selector = 1;
sep = ' - ';

timebase_output = 60;

eval_time = now;
eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');
addpath([pwd,filesep,'01_Hilfsfunktionen']);
addpath([pwd,filesep,'02_Geraeteklassen']);

%--------------------------------------------------------------------------
% load the allocatio and perform a preprocessing for fast computation:
%--------------------------------------------------------------------------
Allocation_all = cell(9,0);
if ~isdir(output.dest_path)
	mkdir(output.dest_path);
end
diary([output.dest_path,filesep,eval_id,sep,'Step 1 - log.txt']);
for sheet_selector=1:4

	load ([input.allocation_hh_path,filesep,'Allocated_Household_Profiles',...
		sep,sheet_names{sheet_selector},'.mat']);
	
	Allocation_all = [Allocation_all, Allocation];
end
clear Allocation

% Adopt the allocation: resolve mulitple entries:
Allocation_resolved = cell(9,0);
for a=1:size(Allocation_all,2)
	if iscell(Allocation_all{2,a})
		for b=1:numel(Allocation_all{2,a})
			Allocation_resolved{1,end+1} = Allocation_all{1,a};  %#ok<SAGROW,*AGROW>
			for c=2:5
				tmp = Allocation_all{c,a};
				Allocation_resolved{c,end} = tmp{b};
			end
			for c=6:9
				Allocation_resolved{c,end} = Allocation_all{c,a};
			end
		end
	else
		Allocation_resolved{1,end+1} = Allocation_all{1,a}; %#ok<SAGROW>
		for c=2:9
			Allocation_resolved{c,end} = Allocation_all{c,a};
		end
	end
end

% which simulation folder have to be screened?
allo_sim_folders = Allocation_resolved(2,:);
% For some reasons, this does not work for all Inputs?!?!
% sim_folders = unique(sim_folders);
% Here the workaround:
allo_sim_folders = unique_cells (allo_sim_folders);

if isempty(allo_sim_folders)
	fprintf('No Allocation found for specified grid!');
	return;
end

%Workaround when cells in first row of allocation is also containing
%cells...
for a=1:size(Allocation_resolved,2)
	Allocation_resolved{1,a} = cell2mat(Allocation_resolved{1,a});
end

% go through the sim folders the first time, set up a todo structure and 
% preallocate the arrays:
Allocation_remainig = Allocation_resolved;
idx_Allocation_rema = 1:size(Allocation_resolved,2);
To_Do_List = [];
fprintf('=================================\n');
fprintf('Start with data extraction...\n');
fprintf('---------------------------------\n');
fprintf('1st Step: Array allocation...\n');
fprintf('---------------------------------\n');
for a=1:numel(allo_sim_folders)
	act_sim_folder = allo_sim_folders{a};
	fprintf(['\tSimfolder ',act_sim_folder,'":\n'])
	fprintf('---------------------------------\n');
	% get the subset of the allocation within this folder
	idx = strcmp(act_sim_folder, Allocation_resolved(2,:));
	act_allocation = Allocation_resolved(:,idx);
	idx_act_allocation = idx_Allocation_rema(idx);
	
	% Dateinamen einlesen:
	source_path = [input.simdata_path,filesep,act_sim_folder];
	content = dir(source_path);
	content = struct2cell(content);
	content = content(1,3:end);
	
	% Nach einer Modelldatei suchen:
	sim_date = [];
	for b=1:numel(content)
		filename = content{b};
		name_parts = regexp(filename, sep, 'split');
		if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat');
			sim_date = name_parts{1};
			%laden der Modelldaten:
			load([source_path,filesep,filename])
			break;
		end
	end
	
	if isempty(sim_date)
		error('No Model available!');
	end
	
	% Number of length of output datapoints:
	num_timepoints = numel(Time.Days_Year) * Time.day_to_sec / timebase_output;
	
	for b=1:Model.Number_Runs
		fprintf(['\t\tModel run No. ',num2str(b),' of ',num2str(Model.Number_Runs),':\n'])
		idx = (cell2mat(act_allocation(4,:)) == b);
		act_allocation_numb = act_allocation(:,idx);
		idx_act_allocation_numb = idx_act_allocation(idx);
		% Ersten Jahresdatensatz laden (um die Arrays zu indizieren);
		[season, weekd] = day2sim_parameter(Model, Time.Days_Year(1));
		name_result = [sim_date,sep,num2str(b),sep,datestr(Time.Days_Year(1),'yyyy-mm-dd'),...
			sep,season,sep,weekd,sep,Model.Sim_Resolution];
		% Variable "Result" laden:
		load([source_path,filesep,name_result,'.mat']);
		
		for c=1:size(act_allocation_numb,2)
			% Daten aufbereiten:
			res = Result.(act_allocation_numb{3,c});
			ids = act_allocation_numb{5,c};
			nam = strrep(act_allocation_numb{1,c},'-','_');
			res = res(ids,:);
			allo_id = idx_act_allocation_numb(c);
			if ~isfield(To_Do_List, nam)
				% No data was found for this connetntion point till now
				fprintf(['\t\t\tAdd Household "',act_allocation_numb{1,c},'".\n'])
				% Allocate Arrays:
				Device_Names = res{1,1};
				Time_Data = zeros(...
					numel(Device_Names),...
					3,...
					num_timepoints);
				Operation_Data = zeros(...
					numel(Device_Names),...
					num_timepoints);
				To_Do_List.(nam).Number_Devices = numel(Device_Names);
				To_Do_List.(nam).Allocation = act_allocation_numb(:,c);
				To_Do_List.(nam).Allocation_id = allo_id;
			else
				% Data is allready available, so add it to the present
				% structures
				fprintf(['\t\t\tUpdate Household "',act_allocation_numb{1,c},'".\n']);
				% if by luck, the current loadpoint is allready loaded,
				% skip the reload
				if ~strcmp(nam, nam_old)
					load([output.dest_path,filesep,eval_id,sep,nam,'.mat']);
				end
				Device_Names = [Device_Names; res{1,1}];
				Time_Data = zeros(...
					numel(Device_Names),...
					3,...
					num_timepoints);
				Operation_Data = zeros(...
					numel(Device_Names),...
					num_timepoints);
				To_Do_List.(nam).Number_Devices = [To_Do_List.(nam).Number_Devices, numel(res{1,1})];
				To_Do_List.(nam).Allocation = [To_Do_List.(nam).Allocation, act_allocation_numb(:,c)];
				To_Do_List.(nam).Allocation_id = [To_Do_List.(nam).Allocation_id, allo_id];
			end
			Time_Data = int16(Time_Data);
			Operation_Data = logical(Operation_Data);
			save([output.dest_path,filesep,eval_id,sep,nam,'.mat'],'-v7.3','Device_Names','Time_Data','Operation_Data');
			nam_old = nam;
		end
	end
end
save([output.dest_path,filesep,eval_id,sep,'Settings.mat'],'-v7.3','Time','Model',...
	'To_Do_List','Configuration','Allocation_all','Allocation_resolved',...
	'Evaluation','Households','Settings');
fprintf('=================================\n');
diary('off');