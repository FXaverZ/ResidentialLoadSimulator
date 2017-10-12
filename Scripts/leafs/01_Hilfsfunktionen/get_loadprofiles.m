function get_loadprofiles(Allocation, write_output, sep, eval_id, input_simdata_path, ...
	output_dest_path, output_dest_powers, Settings, Evaluation)
%GET_LOADPROFILES Summary of this function goes here
%   Detailed explanation goes here

input_selector = Settings.Input_Selector;

% Adopt the allocation: resolve mulitple entries:
Allocation_resolved = cell(9,0);
for a=1:size(Allocation,2)
	if iscell(Allocation{2,a})
		for b=1:numel(Allocation{2,a})
			Allocation_resolved{1,end+1} = Allocation{1,a};  %#ok<*AGROW>
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

% which simulation folder have to be screened?
sim_folders = Allocation(2,:);
% For some reasons, this does not work for all Inputs?!?!
% sim_folders = unique(sim_folders);
% Here the workaround:
sim_folders = unique_cells (sim_folders);

if isempty(sim_folders)
	fprintf('No Allocation found for specified grid!');
	return;
end

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

%--------------------------------------------------------------------------
% operate over all power-outputs and get the profiles
%--------------------------------------------------------------------------
if write_output
disp('-------------------');
end
for a = 1:to_do.num_sf
	sfsnam = ['Sim_folder_',num2str(a)];
	simfname = to_do.(sfsnam).name;
	content = dir([input_simdata_path,filesep,simfname]);
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
			load([input_simdata_path,filesep,simfname,filesep,filename]);
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
					load([input_simdata_path,filesep,simfname,filesep,'Summary',...
						sep,simtimeid,sep,'Powers_Year',sep,act_hh,'.mat']);
				case 'without flexible loads'
					load([input_simdata_path,filesep,simfname,filesep,'Summary',...
						sep,simtimeid,sep,'Powers_Year_FlexSep',sep,act_hh,'.mat']);
					Power = Power_InFlex;
					clear Power_InFlex Power_Flex Dev_4Flex_Output
				case 'only heatpumps'
					load([input_simdata_path,filesep,simfname,filesep,'Summary',...
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
		
		Power = Power(time_idx_new,:);
		
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
			Load_ID = cell2mat(ids{c});
			filename = [output_dest_path,filesep,output_dest_powers,filesep,eval_id,sep,Load_ID,sep,'Overall_Power.mat'];
			if exist(filename, 'file') == 2
				Loadprofile_add = Loadprofile;
				load(filename);
				Loadprofile = Loadprofile + Loadprofile_add; %#ok<NASGU>
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
			if write_output
			if unique
				disp(['Saved   ',Load_ID, ' (Typ "',act_hh,'" from Folder "',simfname,'").']);
			else
				disp(['Updated ',Load_ID, ' (Typ "',act_hh,'" from Folder "',simfname,'").']);
			end
			end
		end
	end
end
if write_output
	Allocation = Allocation_base; %#ok<NASGU>
	Time.Series_Date_Start = datenum('01.01.2014','dd.mm.yyyy');
	Time.Series_Date_End = datenum('31.12.2014','dd.mm.yyyy');
	save([output_dest_path,filesep,output_dest_powers,filesep,eval_id,sep,...
		Settings.Grid_Names{Settings.Grid_Selector},sep,'Modeldaten.mat'],...
		'Model','Time','Configuration','Households','Allocation',...
		'Allocation_resolved','Settings','Evaluation');
	disp('-------------------');
end
end

