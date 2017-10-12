%% Settings
clear;
% input_simdata_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input_simdata_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% output_dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';
output_dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';
output_xls_filename_corename = 'LEAFS_AP3_INPUT_data_';

sheet_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
sheet_selector = 4;
sep = ' - ';

eval_time = now;
eval_id = datestr(now,'yyyy-mm-dd_HH.MM.SS');
addpath([pwd,filesep,'01_Hilfsfunktionen']);

%% load the allocatio an perform a preprocessing for fast computation:
load (['Allocated_Household_Profiles',sep,sheet_names{sheet_selector},'.mat']);

% which simulation folder have to be screened?
sim_folders = Allocation(2,:);
sim_folders = unique(sim_folders);

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
	to_do.(sfsnam).hh_typs = unique(hh_typs_sf);
	
	idxs_sf = cell2mat(Allocation(4:5,strcmp(Allocation(2,:),simfname)));
	id_sf = Allocation(1,strcmp(Allocation(2,:),simfname));
	for b = 1:numel(to_do.(sfsnam).hh_typs)
		act_hh = to_do.(sfsnam).hh_typs{b};
		to_do.(sfsnam).(act_hh).idxs = idxs_sf(:,strcmp(hh_typs_sf,act_hh));
		to_do.(sfsnam).(act_hh).ids = id_sf(:,strcmp(hh_typs_sf,act_hh));
		to_do.(sfsnam).(act_hh).allo = allo_sf(:,strcmp(hh_typs_sf,act_hh));
	end
end

clear a b sfsnam simfname hh_typs_sf idx_sf id_sf act_hh sim_folders idxs_sf

%% operate over all power-outputs and get the profiles
disp('-------------------');
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
		if strcmp(name_parts{1},'Summary')...
				&& strcmp(name_parts{3},'Powers_Year')...
				&& isempty(simtimeid)
			simtimeid = name_parts{2};
		end
		if strcmp(name_parts{3},'Modeldaten.mat')...
				&& ~modelload
			load([input_simdata_path,filesep,simfname,filesep,filename]);
			modelload = 1;
		end
	end
	
	for b = 1:numel(to_do.(sfsnam).hh_typs)
		act_hh = to_do.(sfsnam).hh_typs{b};
		act_hh_num = Model.Households{strcmp(Model.Households(:,1),act_hh),5};
		idxs = to_do.(sfsnam).(act_hh).idxs;
		ids = to_do.(sfsnam).(act_hh).ids;
		load([input_simdata_path,filesep,simfname,filesep,'Summary',...
			sep,simtimeid,sep,'Powers_Year',sep,act_hh,'.mat']);
		for c = 1:numel(ids)
			i = idxs(1,c);
			l = idxs(2,c);
			Loadprofile = Power(:,(i-1)*(act_hh_num*3)+(l-1)*3+(1:3)); %#ok<NASGU>
			Load_ID = cell2mat(ids{c});
			Source.Sim_Filename = simfname;
			Source.Sim_TimeID = simtimeid;
			Source.HH_Typ = Model.Households(strcmp(Model.Households(:,1),act_hh),[1,4,5]);
			Source.IDXs = idxs(:,c);
			Source.Allocation_Information = to_do.(sfsnam).(act_hh).allo{:,1};
			save([output_dest_path,filesep,eval_id,sep,Load_ID,sep,'Overall_Power.mat'],...
				'Loadprofile', 'Load_ID','Source');
			disp(['Saved ',Load_ID, ' (Typ ',act_hh,' from Folder "',simfname,'").']);
		end
	end
end
save([output_dest_path,filesep,eval_id,sep,sheet_names{sheet_selector},sep,'Modeldaten.mat'],...
	'Model','Time','Configuration','Households','Allocation','Settings','Evaluation');
disp('-------------------');
clear a b c act_hh act_hh_num idxs ids Power i l Loadprofile Load_ID allo_sf
clear Source modelload filename content name_parts sfsnam simfname simtimeid
clear to_do

%% Create a matlab output

content = dir([output_dest_path,filesep]);
content = struct2cell(content);
content = content(1,3:end);

cur_grid = sheet_names{sheet_selector};

modelload = 0;
simtimeid = [];
for a = 1:numel(content)
	filename = content{a};
	name_parts = regexp(filename, sep, 'split');
	if numel(name_parts) > 1 && isempty(simtimeid) && strncmp(name_parts{2},cur_grid,length(cur_grid))
		simtimeid = name_parts{1};
	end
	if ~isempty(simtimeid) && ~modelload && numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat')
		load([output_dest_path,filesep,simtimeid,sep,cur_grid,sep,'Modeldaten.mat']);
		modelload = 0;
	end
end
ids = [Allocation{1,:}];
[~, IX] = sort(ids);

Allocation_Sort = Allocation(:,IX);

output_xls_filename = [output_dest_path,filesep,eval_id,sep,output_xls_filename_corename,cur_grid];
% output_xls_filename = [eval_id,sep,output_xls_filename,cur_grid,'.xlsx'];
output_col_headers = {...
	'p_pv_max [0-1]',...
	'p_inflexible_load [kW]',...
	'p_pv [kW]',...
	'p_flexible_load [kW]',...
	'p_ev [kW]',...
	};
%--------------------------------------------------------------------------
time = Time.Series_Date_Start:60/Time.day_to_sec:Time.Series_Date_End+1;
time = time(1:end-1)';

Loadprofiles_Data = zeros(numel(time),(size(Allocation_Sort,2)*12+2));
Loadprofiles_Data(:,1) = time;
clear time;

Loadprofiles_Header = cell(3,size(Loadprofiles_Data,2));

Loadprofiles_Header{1,1} = '';
Loadprofiles_Header{1,2} = 'general input signal (AIT)';
Loadprofiles_Header{2,1} = '';
Loadprofiles_Header{2,2} = output_col_headers{1};
Loadprofiles_Header{3,1} = 'time';
Loadprofiles_Header{3,2} = '';

for a = 1:size(Allocation_Sort,2)
	ID = cell2mat(Allocation_Sort{1,a});
	load([output_dest_path,filesep,simtimeid,sep,ID,sep,'Overall_Power.mat']);
	for b = 1:size(Allocation_Sort,1)
		if iscell(Allocation_Sort{b,a})
			Loadprofiles_Header{1,2+(a-1)*12+b} = cell2mat(Allocation_Sort{b,a});
		else
			Loadprofiles_Header{1,2+(a-1)*12+b} = Allocation_Sort{b,a};
		end
	end
	Loadprofiles_Header{2,2+(a-1)*12+1}=output_col_headers{2};
	Loadprofiles_Header{2,2+(a-1)*12+4}=output_col_headers{3};
	Loadprofiles_Header{2,2+(a-1)*12+7}=output_col_headers{4};
	Loadprofiles_Header{2,2+(a-1)*12+10}=output_col_headers{5};
	for b = 1:4
		Loadprofiles_Header{3,2+(a-1)*12+(b-1)*3+1}='L1';
		Loadprofiles_Header{3,2+(a-1)*12+(b-1)*3+2}='L2';
		Loadprofiles_Header{3,2+(a-1)*12+(b-1)*3+3}='L3';
	end
	Loadprofiles_Data(:,(a-1)*12+(3:5))=Loadprofile/1000;
	clear Loadprofile;
end

save([output_xls_filename,'.mat'],'-v7.3',...
	'Loadprofiles_Header', 'Loadprofiles_Data');


%% create Excel-Output
yts = unique(year(Time.Days_Year));
mts = unique(month(Time.Days_Year));
dts = unique(day(Time.Days_Year));

% Adjust Datebase:
Loadprofiles_Data(:,1) = m2xdate(Loadprofiles_Data(:,1));

time = Time.Series_Date_Start:60/Time.day_to_sec:Time.Series_Date_End+1;
time = time(1:end-1)';

for a = 1:numel(yts)
	for b = 1:numel(mts)
		for c = 1:numel(dts)
			sel = (day(time) == dts(c) & month(time) == mts(b) & year(time) == yts(a));
			if sum(sel) == 0
				continue;
			end
			output_xls = XLS_Writer();
			output_xls.set_worksheet('legend');
			output_xls.write_lines({...
				'','';...
				'','';...
				'Number of Households',size(Allocation_Sort,2);...
				'Number of EV','';...
				'Number of battery storage systems','';...
				'Number of PV systems','';...
				'','';...
				'','';...
				'','';...
				output_col_headers{1}, 'PV feed-in power limitation (day ahead signal provided by the DSO for all PV-systems in the branch)';...
				'','';...
				output_col_headers{2}, 'consumption of inflexible loads of customer';...
				output_col_headers{3}, 'PV generation of customer';...
				output_col_headers{4}, 'consumption of flexible loads of customer ';...
				output_col_headers{5}, 'consumption of electric vehicle of customer';...
				});
			output_xls.set_worksheet('time series');
			
			output_xls.write_lines(Loadprofiles_Header);
			output_xls.write_values(Loadprofiles_Data(sel,:));
			disp(['Write "',[output_xls_filename,sep,num2str(yts(a),'%04.0f'),'-',num2str(mts(b),'%02.0f'),'-',num2str(dts(c),'%02.0f'),'.xlsx'],'"']);
			try
				output_xls.write_output([output_xls_filename,sep,num2str(yts(a),'%04.0f'),'-',num2str(mts(b),'%02.0f'),'-',num2str(dts(c),'%02.0f'),'.xlsx']);
				% 		xlswrite([output_xls_filename(1:end-5),sep,num2str(yts(a),'%04.0f'),'-',num2str(mts(a),'%02.0f'),'.xlsx'],...
				% 			Loadprofiles_Data(:,1:14),'time series','A1');
			catch
				disp('Error, Try again...');
				disp(['Write "',[output_xls_filename,sep,num2str(yts(a),'%04.0f'),'-',num2str(mts(b),'%02.0f'),'-',num2str(dts(c),'%02.0f'),'.xlsx'],'"']);
				output_xls.write_output([output_xls_filename,sep,num2str(yts(a),'%04.0f'),'-',num2str(mts(b),'%02.0f'),'-',num2str(dts(c),'%02.0f'),'.xlsx']);
			end
			output_xls = [];
		end
	end
end

% clear a modelload simtimeid cur_grid ids IX filename name_parts

