%% Prelaod hughe data
load(['D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation',...
	'\01_Output_final\2017-06-12_08.55.28 - LEAFS_AP3_INPUT_data_ETZ.mat']);
addpath([pwd,filesep,'01_Hilfsfunktionen']);
addpath([pwd,filesep,'02_Geraeteklassen']);
%% Compare Data:
%S-e-t-t-i-n-g-s-----------------------------------------------------------
hh_name = 'ETZ-004';
d_sta = 3;
d_end = 7;
timebase_output = 60;

input.simdata_path = ...
	'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
sep = ' - ';
output_dest_path = ...
	'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\03_Test';
%--------------------------------------------------------------------------

load(['D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation',...
	'\02_Output_detailed\2017-06-06_13.35.07 - ',strrep(hh_name,'-','_'),'.mat']);

idx_hh = find(strcmp(hh_name,Loadprofiles_Header(1,:)));
powers_single = squeeze(sum(squeeze(sum(Time_Data))));
powers_all = sum(Loadprofiles_Data(:,idx_hh:(idx_hh+2)),2)';
% figure; 
% plot(powers_single((d_sta-1)*1440+1:d_end*1440)); 
% hold; 
% plot(powers_all((d_sta-1)*1440+1:d_end*1440));

%% remove flexible Parts:
Dev_4Flex_Output = {...
	'wa_boi',...
	'hea_ra',...
	'hea_wp',...
	'cir_pu',...
    'wa_hea',...
	}; 

idx_devs = true(numel(Device_Names),1);
for a=1:numel(Dev_4Flex_Output)
	dev_2_rem = Dev_4Flex_Output{a};
	idx = ~strcmp(Device_Names,dev_2_rem);
	idx_devs = idx_devs & idx;
end
powers_single2 = squeeze(sum(squeeze(sum(Time_Data(idx_devs,:,:)))));
% figure; 
% plot(powers_single2((d_sta-1)*1440+1:d_end*1440)); 
% hold; 
% plot(powers_all((d_sta-1)*1440+1:d_end*1440));

%% Make some timeshifts:
% time_idx_new = workaround_shift_timeidx(size(Time_Data,3),60);
% powers_single3 = squeeze(sum(squeeze(sum(Time_Data(:,:,time_idx_new)))));
% 
% % figure;
% % plot(powers_single3((d_sta-1)*1440+1:d_end*1440));
% % hold;
% % plot(powers_all((d_sta-1)*1440+1:d_end*1440));
% 
powers_all2 = sum(Loadprofiles_Data(time_idx_new,idx_hh:(idx_hh+2)),2)';
% figure;
% plot(powers_single2((d_sta-1)*1440+1:d_end*1440));
% hold;
% plot(powers_all2((d_sta-1)*1440+1:d_end*1440));

%% Try to manully set up a household
load('D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_H0_ALTENHEIM\Allocated_Household_Profiles - ETZ.mat')
for a=1:size(Allocation,2)
	if iscell(Allocation{1,a})
		Allocation{1,a} = cell2mat(Allocation{1,a}); %#ok<SAGROW>
	end
end

idx_allo = find(strcmp(Allocation(1,:),hh_name));
hh_alloc = Allocation(:,idx_allo);
Allocation = hh_alloc;

hh_simfi = hh_alloc{2};
hh_htyps = hh_alloc{3};
hh_mruns = hh_alloc{4};
hh_siidx = hh_alloc{5};

sim_folders = unique_cells (hh_simfi);

%% First powers_all
Allocation = hh_alloc;
% Adopt the allocation: resolve mulitple entries:
powers_all2_struct = [];
eval_time = now;
eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');

Allocation_resolved = cell(9,0);
for a=1:size(Allocation,2)
	if iscell(Allocation{2,a})
		for b=1:numel(Allocation{2,a})
			Allocation_resolved{1,end+1} = Allocation{1,a};  
			for c=2:5
				tmp = Allocation{c,a};
				Allocation_resolved{c,end} = tmp{b};
			end
			for c=6:9
				Allocation_resolved{c,end} = Allocation{c,a};
			end
		end
	else
		Allocation_resolved{1,end+1} = Allocation{1,a}; 
		for c=2:9
			Allocation_resolved{c,end} = Allocation{c,a};
		end
	end
end
Allocation_base = Allocation;
Allocation = Allocation_resolved;
to_do = [];
to_do.num_sf = numel(sim_folders);
for a = 1:numel(sim_folders)
	sfsnam = ['Sim_folder_',num2str(a)];
	simfname = sim_folders{a};
	to_do.(sfsnam).name = simfname;
	% 	num_run_fs = cell2mat(Allocation(4,strcmp(Allocation(2,:),simfname)));
	% 	to_do.(sfsnam).runs = unique(num_run_fs);
	allo_sf = Allocation(:,strcmp(Allocation(2,:),simfname));
	
	hh_typs_sf = Allocation(3,strcmp(Allocation(2,:),simfname));
	to_do.(sfsnam).hh_typs = unique_cells(hh_typs_sf);
	
	idxs_sf = cell2mat(Allocation(4:5,strcmp(Allocation(2,:),simfname)));
	id_sf = Allocation(1,strcmp(Allocation(2,:),simfname));
	for b = 1:numel(to_do.(sfsnam).hh_typs)
		act_hh = to_do.(sfsnam).hh_typs{b};
		to_do.(sfsnam).(act_hh).idxs = idxs_sf(:,strcmp(hh_typs_sf,act_hh));
		to_do.(sfsnam).(act_hh).ids = id_sf(:,strcmp(hh_typs_sf,act_hh));
		to_do.(sfsnam).(act_hh).allo = allo_sf(:,strcmp(hh_typs_sf,act_hh));
	end
end

% get sure, that the zero Loadprofiles are proceeded after a normal profile
% was loaded (so Time and Model exist!)
if strcmpi(to_do.Sim_folder_1.name,'none')
	to_do_2 = to_do;
	to_do_2.Sim_folder_1 = to_do.(['Sim_folder_',num2str(to_do.num_sf)]);
	to_do_2.(['Sim_folder_',num2str(to_do.num_sf)]) = to_do.Sim_folder_1;
	to_do = to_do_2;
	clear to_do_2
end

input_selector = Settings.Input_Selector;
phase_composition_quantile = 0.999;
max_power_single_phase = 2300; 
max_difference_power_phase = max_power_single_phase; 

for a = 1:to_do.num_sf
	sfsnam = ['Sim_folder_',num2str(a)];
	simfname = to_do.(sfsnam).name;
	content = dir([input.simdata_path,filesep,simfname]);
	content = struct2cell(content);
	content = content(1,3:end);
	simtimeid = [];
	modelload = 0;
	for b = 1:numel(content)
		filename = content{b};
		name_parts = regexp(filename, sep, 'split');
		if strcmp(name_parts{2},'Simulations-Log.txt')
			% Skip the log files
			continue;
		end
		switch lower(input_selector)
			case 'as simulated'
				if strcmp(name_parts{1},'Summary')...
						&& strcmp(name_parts{3},'Powers_Year')...
						&& isempty(simtimeid)
					simtimeid = name_parts{2};
				end
			case 'without flexible loads'
				if strcmp(name_parts{1},'Summary')...
						&& strcmp(name_parts{3},'Powers_Year_FlexSep')...
						&& isempty(simtimeid)
					simtimeid = name_parts{2};
				end
			case 'only heatpumps'
				if strcmp(name_parts{1},'Summary')...
						&& strcmp(name_parts{3},'Powers_Year_HPs')...
						&& isempty(simtimeid)
					simtimeid = name_parts{2};
				end
			otherwise
				error('Not supported!!!');
		end
		if strcmp(name_parts{3},'Modeldaten.mat')...
				&& ~modelload
			load([input.simdata_path,filesep,simfname,filesep,filename]);
			modelload = 1;
		end
	end
	time_idx_new = [];
	for b = 1:numel(to_do.(sfsnam).hh_typs)
		act_hh = to_do.(sfsnam).hh_typs{b};
		if strcmpi(act_hh,'none')
			act_hh_num = 1;
			Power = zeros(numel(Time.Series_Date_Start:Settings.Timebase_Output/Time.day_to_sec:Time.Series_Date_End+1)-1,3);
		else
			act_hh_num = Model.Households{strcmp(Model.Households(:,1),act_hh),5};
			switch lower(input_selector)
				case 'as simulated'
					load([input.simdata_path,filesep,simfname,filesep,'Summary',...
						sep,simtimeid,sep,'Powers_Year',sep,act_hh,'.mat']);
				case 'without flexible loads'
					load([input.simdata_path,filesep,simfname,filesep,'Summary',...
						sep,simtimeid,sep,'Powers_Year_FlexSep',sep,act_hh,'.mat']);
					Power = Power_InFlex;
					clear Power_InFlex Power_Flex Dev_4Flex_Output
				case 'only heatpumps'
					load([input.simdata_path,filesep,simfname,filesep,'Summary',...
						sep,simtimeid,sep,'Powers_Year_HPs',sep,act_hh,'.mat']);
					Power = Power_HePs;
					clear Power_HePs
				otherwise
					error('Not supported!!!');
			end
		end
		
		if isempty(time_idx_new)
			time_idx_new = workaround_shift_timeidx(size(Power,1),Settings.Timebase_Output);
		end
		
% 		Power = Power(time_idx_new,:);
		idxs = to_do.(sfsnam).(act_hh).idxs;
		ids = to_do.(sfsnam).(act_hh).ids;
		
		for c = 1:numel(ids)
			i = idxs(1,c);
			l = idxs(2,c);
			Source = [];
			Scale_Factor = to_do.(sfsnam).(act_hh).allo{9,c};
			if sum(sum(idxs)) == 0
				Loadprofile = Power;
			else
				Loadprofile = Power(:,(i-1)*(act_hh_num*3)+(l-1)*3+(1:3)) * Scale_Factor;
			end
			if iscell(ids{c})
				Load_ID = cell2mat(ids{c});
			else
				Load_ID = ids{c};
			end
			filename = [output_dest_path,filesep,eval_id,sep,Load_ID,sep,'Overall_Power.mat'];
			Loadprofile = round(Loadprofile);
			Loadprofile = int32(Loadprofile);
			powers_all2_struct = [powers_all2_struct;sum(Loadprofile,2)'];
			if exist(filename, 'file') == 2
				permute = 0;
				permute_success = 0;
				Loadprofile_add = Loadprofile;
				load(filename);
				% Check, if a single phase power is exceeded:
				permutes = [...
					1,2,3;...
					2,3,1;...
					3,1,2;...
					2,1,3;...
					2,3,1;...
					3,2,1;...
					];
				max_powers_per_permutation = zeros(size(permutes,1),1);
				for d = 1:size(permutes,1)
					Loadprofile_temp = Loadprofile + Loadprofile_add(:,permutes(d,:));
					max_diff_phase = quantile(max(Loadprofile_temp,[],2) - min(Loadprofile_temp,[],2),phase_composition_quantile);
					max_powers_per_permutation(d) = max_diff_phase;
					if max_diff_phase > max_difference_power_phase
						permute = 1;
					else
						permute_success = 1;
						break;
					end
				end
				% if no suitable permutation was found, use at least the
				% one, with the smallest power difference between the
				% phases:
				if ~permute_success
					idx = find(max_powers_per_permutation == min(max_powers_per_permutation),1);
					Loadprofile_temp = Loadprofile + Loadprofile_add(:,permutes(idx,:));
					max_diff_phase = quantile(max(Loadprofile_temp,[],2) - min(Loadprofile_temp,[],2),phase_composition_quantile);
				end
				Loadprofile = Loadprofile_temp; 
			end
			if isempty(Source)
				unique = true;
				Source.Num_Sources = 1;
				Source.Sim_Filename{1} = simfname;
				Source.Sim_TimeID{1} = simtimeid;
				Source.HH_Typ{1} = Model.Households(strcmp(Model.Households(:,1),act_hh),[1,4,5]);
				Source.IDXs{1} = idxs(:,c);
				Source.Allocation_Information{1} = to_do.(sfsnam).(act_hh).allo(:,c);
			else
				unique = false;
				Source.Num_Sources = Source.Num_Sources + 1;
				Source.Sim_Filename{end+1} = simfname;
				Source.Sim_TimeID{end+1} = simtimeid;
				Source.HH_Typ{end+1} = Model.Households(strcmp(Model.Households(:,1),act_hh),[1,4,5]);
				Source.IDXs{end+1} = idxs(:,c);
				Source.Allocation_Information{end+1} = to_do.(sfsnam).(act_hh).allo(:,c);
			end
			save(filename,...
				'Loadprofile','Load_ID','Source');
				if unique
					fprintf(['Saved   ',Load_ID, ' (Typ "',act_hh,'" from Folder "',simfname,'").\n']);
				else
					fprintf(['Updated ',Load_ID, ' (Typ "',act_hh,'" from Folder "',simfname,'")']);
					if permute
						fprintf(': Phase Power Violation!');
						if permute_success
							fprintf([' Solved via permutation [',num2str(permutes(d,:)),']']);
						else
							fprintf([' Used minimal phase difference [',num2str(permutes(idx,:)),']']);
						end
						fprintf([' (max. Phase difference: ',num2str(max_diff_phase),'W).\n']);
					else
						fprintf('.\n');
					end
				end
		end
	end
end

powers_all3 = sum(Loadprofile,2)';
figure; 
plot(powers_all3((d_sta-1)*1440+1:d_end*1440)); 
hold; 
plot(powers_all((d_sta-1)*1440+1:d_end*1440));

figure;
for a=1:size(powers_all2_struct,1)
	plot(powers_all2_struct(a,(d_sta-1)*1440+1:d_end*1440)); 
	if a ==1 
		hold;
	end
end


%% Now powers_single
% go through the sim folders the first time, set up a todo structure and 
% preallocate the arrays:
Allocation = hh_alloc;
eval_time = now;
eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');

Allocation_resolved = cell(9,0);
for a=1:size(Allocation,2)
	if iscell(Allocation{2,a})
		for b=1:numel(Allocation{2,a})
			Allocation_resolved{1,end+1} = Allocation{1,a};  
			for c=2:5
				tmp = Allocation{c,a};
				Allocation_resolved{c,end} = tmp{b};
			end
			for c=6:9
				Allocation_resolved{c,end} = Allocation{c,a};
			end
		end
	else
		Allocation_resolved{1,end+1} = Allocation{1,a}; 
		for c=2:9
			Allocation_resolved{c,end} = Allocation{c,a};
		end
	end
end
Allocation_base = Allocation;
Allocation = Allocation_resolved;

idx_Allocation_rema = 1:size(Allocation,2);
To_Do_List = [];
fprintf('=================================\n');
fprintf('Start with data extraction...\n');
fprintf('---------------------------------\n');
fprintf('1st Step: Array allocation...\n');
fprintf('---------------------------------\n');
for a=1:numel(sim_folders)
	act_sim_folder = sim_folders{a};
	fprintf(['\tSimfolder ',act_sim_folder,'":\n'])
	fprintf('---------------------------------\n');
	% get the subset of the allocation within this folder
	idx = strcmp(act_sim_folder, Allocation(2,:));
	act_allocation = Allocation(:,idx);
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
		if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat')
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
		if isempty(act_allocation_numb)
			continue;
		end
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
					load([output_dest_path,filesep,eval_id,sep,nam,'.mat']);
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
			Time_Data = int32(Time_Data);
			Operation_Data = logical(Operation_Data);
			save([output_dest_path,filesep,eval_id,sep,nam,'.mat'],'-v7.3','Device_Names','Time_Data','Operation_Data');
			nam_old = nam;
		end
	end
end
save([output_dest_path,filesep,eval_id,sep,'Settings.mat'],'-v7.3','Time','Model',...
	'To_Do_List','Configuration','Allocation_resolved',...
	'Evaluation','Households','Settings');
fprintf('=================================\n');
diary('off');


%% Second Step
% Dateinamen einlesen:
content = dir([output_dest_path,filesep]);
content = struct2cell(content);
content = content(1,3:end);
powers_single2_struct = [];


% Nach der Einstellungsdatei suchen:
eval_id = [];
for a=1:numel(content)
	filename = content{a};
	name_parts = regexp(filename, sep, 'split');
	if strcmp(name_parts{2},'Settings.mat')
		eval_id = name_parts{1};
		%laden der Modelldaten:
		load([output_dest_path,filesep,filename])
		break;
	end
end

allo_sim_folders = Allocation_resolved(2,:);
allo_sim_folders = unique_cells (allo_sim_folders);
diary([output_dest_path,filesep,eval_id,sep,'Step 2 - log.txt']);

fprintf('=================================\n');
fprintf('Start with data extraction...\n');
fprintf('---------------------------------\n');
fprintf('2nd Step: Data Extraction...\n');
fprintf('---------------------------------\n');

Allocation_remainig = Allocation_resolved;
idx_Allocation_rema = 1:size(Allocation_resolved,2);
nam_old = 'no_name';

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
		if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat')
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
	num_tp_day = Time.day_to_sec / timebase_output;
	
	for b=1:Model.Number_Runs
		fprintf(['\t\tModel run No. ',num2str(b),' of ',num2str(Model.Number_Runs),':\n'])
		idx = (cell2mat(act_allocation(4,:)) == b);
		act_allocation_numb = act_allocation(:,idx);
		idx_act_allocation_numb = idx_act_allocation(idx);
		
		if isempty(act_allocation_numb)
			continue;
		end
		
		Output = [];
		
		for c=d_sta:d_end
			fprintf(['\t\t\tDay No. ',num2str(c),' of ',num2str(numel(Time.Days_Year)),' (',datestr(Time.Days_Year(c),'dd.mm.yyyy'),'):\n'])
			[season, weekd] = day2sim_parameter(Model, Time.Days_Year(c));
			name_result = [sim_date,sep,num2str(b),sep,datestr(Time.Days_Year(c),'yyyy-mm-dd'),...
				sep,season,sep,weekd,sep,Model.Sim_Resolution];
			% Variable "Result" laden:
			load([source_path,filesep,name_result,'.mat']);
			
			for d=1:size(act_allocation_numb,2)
				% Daten aufbereiten:
				res = Result.(act_allocation_numb{3,d});
				ids = act_allocation_numb{5,d};
				nam = strrep(act_allocation_numb{1,d},'-','_');
				res = res(ids,:);
				allo_id = idx_act_allocation_numb(d);
				
				fprintf([...
					'\tSF ',num2str(a),'/',num2str(numel(allo_sim_folders)),...
					'\tMR ',num2str(b),'/',num2str(Model.Number_Runs),...
					'\tDY ',num2str(c,'%03d'),'/',num2str(numel(Time.Days_Year)),...
					'\tHH ',num2str(d,'%02d'),'/',num2str(size(act_allocation_numb,2)),...
					'\tUpdate Household "',act_allocation_numb{1,d},'"']);
				
				% Zusammenführen der Zeitreihen:
				tdata = res{1,3}(:,:,2:end);
				tdata = reshape(tdata,size(tdata,1),size(tdata,2),timebase_output/Time.Base,[]);
				tdata = squeeze(sum(tdata,3))*Time.Base/timebase_output;
				% Adjust the power values according to the given
				% scale-Factor and convert to a int32 array:
				scalefactor =  act_allocation_numb{9,d};
				tdata = tdata * scalefactor;
				tdata = int32(round(tdata));
				
				% Operationsmatrix erstellen, dazu die verschiedenen Gerätearten seperat
				% behandeln:
				oparr = zeros(numel(res{1,1}),num_tp_day);
				% Linearer Tageszeitvektor (z.B. 1 - 1440 bei Minutenauflösung)
				vec = 1:(Time.day_to_sec / timebase_output);
				% Indexliste mit den zu
				dev_idxs_to_do = 1:numel(res{1,1});
				
				% Kühlgeräte:
				id_dev = find(...
					strcmp(res{1,1}, 'refrig') | ...
					strcmp(res{1,1}, 'freeze'));
				for e=1:numel(id_dev)
					% Einsatzplan auslesen:
					oplan = res{1,4}{id_dev(e)};
					% Geräteinstanz:
					dev_i = res{1,2}{id_dev(e)};
					% Gerät als erledigt markieren:
					dev_idxs_to_do(dev_idxs_to_do == id_dev(e)) = [];
					% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist
					% (wenn in einem Zeitpunkt die Nominalleistung um 50%
					% überschritten wird, wird der Zeitpunkt als aktiv
					% gezählt (--> notwendig wegen Mittelwertbildung!))
					idx = squeeze(sum(tdata(id_dev(e),:,:),2)) >= dev_i.Power_Nominal * scalefactor *0.5;
					% Aktivitätsmatrix entsprechend anpassen:
					oparr(id_dev(e),idx) = 1;
				end
				
				% nun die Geräte berarbeiten, die ein Programm abfahren (Geschirrspüler,
				% Wäschetrockner, Waschmaschinen:
				id_dev = find(...
					strcmp(res{1,1}, 'washer') | ...
					strcmp(res{1,1}, 'dishwa') | ...
					strcmp(res{1,1}, 'cl_dry'));
				for e=1:numel(id_dev)
					% Geräteinstanz:
					dev_i = res{1,2}{id_dev(e)};
					% Gerät als erledigt markieren:
					dev_idxs_to_do(dev_idxs_to_do == id_dev(e)) = [];
					% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
					idx = squeeze(sum(tdata(id_dev(e),:,:),2)) > 0;
					% Aktivitätsmatrix entsprechend anpassen:
					oparr(id_dev(e),idx) = 1;
				end
				
				% Geräte für die kein Einsatzplan extrahiert wurde (z.B. weil Gerätegruppen
				% zusammengefasst wurden:
				id_dev = find(...
					strcmp(res{1,1}, 'illumi') | ...
					strcmp(res{1,1}, 'dev_de') | ...
					strcmp(res{1,1}, 'stove_') | ...
					strcmp(res{1,1}, 'oven__') | ...
					strcmp(res{1,1}, 'microw') | ...
					strcmp(res{1,1}, 'ki_mic'));
				for e=1:numel(id_dev)
					stby = 0;
					% Geräteinstanzen laden
					devs = res{1,2}{id_dev(e)};
					% Gerät(e) als erledigt markieren:
					dev_idxs_to_do(dev_idxs_to_do == id_dev(e)) = [];
					for f=1:numel(devs)
						% Einzelgerätinstanz auslesen:
						dev = devs(f);
						% Check, ob noch ein Cell-Array vorliegt
						if ~iscell(dev)
							% Wenn nicht, Einzelgerät vorhanden, Stand-by aufaddieren:
							stby = stby + dev.Power_Stand_by * scalefactor;
						else
							% Falls noch ein Cell-Aray vorliegt, liegen unterschiedliche
							% Geräteklassen vor, diese "aufdröseln":
							de = devs{f};
							for g=1:numel(de)
								dev = de(g);
								% Stand-by aufaddieren:
								stby = stby + dev.Power_Stand_by * scalefactor;
							end
						end
					end
					% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
					idx = squeeze(sum(tdata(id_dev(e),:,:),2)) > stby;
					% Aktivitätsmatrix entsprechend anpassen:
					oparr(id_dev(e),idx) = 1;
				end
				
				% Nun noch die restlichen Geräte abarbeiten, für diese wurde bereits ein
				% Einsatzplan extrahiert:
				for e=1:numel(dev_idxs_to_do)
					% Geräteinstanz:
					dev_i = res{1,2}{dev_idxs_to_do(e)};
					% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
					idx = squeeze(sum(tdata(dev_idxs_to_do(e),:,:),2)) > dev_i.Power_Stand_by * scalefactor;
					% Aktivitätsmatrix entsprechend anpassen:
					oparr(dev_idxs_to_do(e),idx) = 1;
				end
				oparr = logical(oparr);
				
				% Now the Data is available, update the output arrays with
				% the values at the correct places
				if ~isfield(Output, nam)
					Output.(nam) = load([output_dest_path,filesep,eval_id,sep,nam,'.mat']);
				end
				%convert the Operation array to a logical (bit) array
				if ~islogical(Output.(nam).Operation_Data)
					Output.(nam).Operation_Data = logical(Output.(nam).Operation_Data);
				end
				allo_id_lst = To_Do_List.(nam).Allocation_id;
				if numel(allo_id_lst) == 1
					fprintf('... calculations done! Update data (single HH-pofile).\n');
					% The current loadpoint is only composed out of one
					% household array, add this to the overall ouput
					Output.(nam).Time_Data(:,:,(c-1)*num_tp_day+1:c*num_tp_day) = tdata;
					Output.(nam).Operation_Data(:,(c-1)*num_tp_day+1:c*num_tp_day) = oparr;
				else
					fprintf('... calculations done! Update data (multiple HH-pofile).\n');
					% when the allocation id list is longer than one entry, the
					% correct spot for data update has to be found:
					numb_devices = To_Do_List.(nam).Number_Devices;
					pos = find(allo_id_lst == allo_id);
					if pos == 1
						%begin of array
						Output.(nam).Time_Data(1:numb_devices(1),:,(c-1)*num_tp_day+1:c*num_tp_day) = tdata;
						Output.(nam).Operation_Data(1:numb_devices(1),(c-1)*num_tp_day+1:c*num_tp_day) = oparr;
					else
						%Middle or end postion
						prev_dev = sum(numb_devices(1:pos-1));
						Output.(nam).Time_Data(prev_dev+1:prev_dev+numb_devices(pos),:,(c-1)*num_tp_day+1:c*num_tp_day) = tdata;
						Output.(nam).Operation_Data(prev_dev+1:prev_dev+numb_devices(pos),(c-1)*num_tp_day+1:c*num_tp_day) = oparr;
					end
				end
				
% 				% Save Output:
% 				if d == size(act_allocation_numb,2) || ~strcmp(nam, strrep(act_allocation_numb{1,d+1},'-','_'))
% 					save([output_dest_path,filesep,eval_id,sep,nam,'.mat'],'-v7.3','Device_Names','Time_Data','Operation_Data');
% 					fprinf('. Data saved.\n');
% 				else
% 					fprinf('. Continue...\n');
% 				end
% 				nam_old = nam;
			end
		end
		fprintf('---------------------------------\n');
		fprintf('Saving data...\n');
		fprintf('---------------------------------\n');
		nams = fieldnames(Output);
		time_idx_new = [];
		for c=1:numel(nams)
			if isempty(time_idx_new)
				time_idx_new = workaround_shift_timeidx(size(Output.(nams{c}).Time_Data,3),Settings.Timebase_Output);
			end
% 			Time_Data = Output.(nams{c}).Time_Data(:,:,time_idx_new);
			Time_Data = Output.(nams{c}).Time_Data;
% 			powers_single2_struct = [powers_single2_struct;squeeze(sum(squeeze(sum(Time_Data))))];
			Device_Names = Output.(nams{c}).Device_Names;
% 			Operation_Data = Output.(nams{c}).Operation_Data(:,time_idx_new);
			Operation_Data = Output.(nams{c}).Operation_Data;
			Output.(nams{c}) = [];
			save([output_dest_path,filesep,eval_id,sep,nams{c},'.mat'],'-v7.3','Device_Names','Time_Data','Operation_Data');
			fprintf(['\t\t\t',nams{c},' saved.\n']);
		end
		fprintf('---------------------------------\n');
	end
end
diary('off');

figure; 
powers_single4 = squeeze(sum(squeeze(sum(Time_Data))));
plot(powers_single4((d_sta-1)*1440+1:d_end*1440)); 
hold; 
plot(powers_all3((d_sta-1)*1440+1:d_end*1440));
