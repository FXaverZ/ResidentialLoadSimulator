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

%--------------------------------------------------------------------------
addpath([pwd,filesep,'01_Hilfsfunktionen']);
addpath([pwd,filesep,'02_Geraeteklassen']);
% Dateinamen einlesen:
content = dir([output.dest_path,filesep]);
content = struct2cell(content);
content = content(1,3:end);

% Nach der Einstellungsdatei suchen:
eval_id = [];
for a=1:numel(content)
	filename = content{a};
	name_parts = regexp(filename, sep, 'split');
	if strcmp(name_parts{2},'Settings.mat')
		eval_id = name_parts{1};
		%laden der Modelldaten:
		load([output.dest_path,filesep,filename])
		break;
	end
end

allo_sim_folders = Allocation_resolved(2,:);
allo_sim_folders = unique_cells (allo_sim_folders);
diary([output.dest_path,filesep,eval_id,sep,'Step 2 - log.txt']);

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
		
		Output = [];
		
		for c=1:numel(Time.Days_Year)
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
					Output.(nam) = load([output.dest_path,filesep,eval_id,sep,nam,'.mat']);
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
% 					save([output.dest_path,filesep,eval_id,sep,nam,'.mat'],'-v7.3','Device_Names','Time_Data','Operation_Data');
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
			Time_Data = Output.(nams{c}).Time_Data(:,:,time_idx_new);
			Device_Names = Output.(nams{c}).Device_Names;
			Operation_Data = Output.(nams{c}).Operation_Data(:,time_idx_new);
			Output.(nams{c}) = [];
			save([output.dest_path,filesep,eval_id,sep,nams{c},'.mat'],'-v7.3','Device_Names','Time_Data','Operation_Data');
			fprintf(['\t\t\t',nams{c},' saved.\n']);
		end
		fprintf('---------------------------------\n');
	end
end
diary('off');






