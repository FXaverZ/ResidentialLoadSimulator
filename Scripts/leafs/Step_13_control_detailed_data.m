clear;
% Path to the simulated Data:
output.dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\2017-05-28_23.45.23 - Output_detailed';

% Possible Grids and selection of the one to investigate
grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
grid_selector = 1;


% Devicenames to search for
dev2search4_list = {...
	'refrig';...
	'freeze';...
	'hea_wp';...
	'wa_boi';...
	'hea_ra';...
	};

% Dateinamen einlesen:
sep = ' - ';
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

% Get the names of all load-points (sorted):
hh_names = Allocation_all(1,:);
for a=1:numel(hh_names)
	if iscell(hh_names{a})
		hh_names{a} = cell2mat(hh_names{a});
	end
end
hh_names = sort(hh_names);
for grid_selector=1:4
	gridname = grid_names{grid_selector};
	diary([output.dest_path,filesep,eval_id,sep,gridname,sep,'detailde_ana.txt']);
	for device_selector = 1:numel(dev2search4_list)
		dev2search4 = dev2search4_list{device_selector};
		d_powers.(dev2search4) = [];
	end
	% Go through all names
	for a=1:numel(hh_names)
		% Compare name prefix with current grid: if they not match, skip and go
		% to the next name (so only one gird is investigated furhter):
		idx = find(strncmp(hh_names{a},gridname,length(gridname)));
		if isempty(idx)
			continue;
		end
		
		% Load the data:
		hh_filename = strrep(hh_names{a},'-','_');
		hh_data = load([output.dest_path,filesep,eval_id,sep,hh_filename,'.mat']);
		
		% preallocate arrays and counters
		fprintf(['Processing   "',hh_names{a},'": \n']);
		for device_selector = 1:numel(dev2search4_list)
			dev2search4 = dev2search4_list{device_selector};
			if isempty(d_powers.(dev2search4))
				d_powers.(dev2search4) = zeros(1,size(hh_data.Time_Data,3));
				d_workin.(dev2search4) = d_powers.(dev2search4);
				% overall counter
				d_counte.(dev2search4) = 0;
				d_wor_co.(dev2search4) = 0;
				d_pow_co.(dev2search4) = 0;
				hh_counter.(dev2search4) = 0;
			end
			% counter for one household
			d_counte_sd.(dev2search4) = 0;
			d_wor_co_sd.(dev2search4) = 0;
			d_pow_co_sd.(dev2search4) = 0;
			hh_counter.(dev2search4) = hh_counter.(dev2search4) + 1;
			% search for the device
			idx = find(strcmp(hh_data.Device_Names, dev2search4));
			if isempty(idx)
				continue;
			end
			
			% look at the data for each device
			for b=1:numel(idx)
				d_counte.(dev2search4) = d_counte.(dev2search4) + 1;
				d_counte_sd.(dev2search4) = d_counte_sd.(dev2search4) + 1;
				% acitvity of this device
				workin = squeeze(hh_data.Operation_Data(idx(b),:));
				% power consumption (single phase) of this device
				powers = sum(squeeze(hh_data.Time_Data(idx(b),:,:)));
				if sum(workin) > 0
					% when device is at least one minute marked as active, rise
					% the respective counter:
					d_wor_co.(dev2search4) = d_wor_co.(dev2search4) + 1;
					d_wor_co_sd.(dev2search4) = d_wor_co_sd.(dev2search4)+ 1;
				end
				if sum(powers) > 0
					% when powerconsumption of the device is at least one minute
					% higher than zero, rise the respective counter:
					d_pow_co.(dev2search4) = d_pow_co.(dev2search4) + 1;
					d_pow_co_sd.(dev2search4) = d_pow_co_sd.(dev2search4) + 1;
				end
				% Sum up power and activity for all devices
				d_powers.(dev2search4) = d_powers.(dev2search4) + powers;
				d_workin.(dev2search4) = d_workin.(dev2search4) + workin;
			end
			% Print result for this household
			fprintf(['\t Found ',num2str(d_counte_sd.(dev2search4)),' "',dev2search4,'" (',...
				num2str(d_wor_co_sd.(dev2search4)),' working based on activity, ',num2str(d_pow_co_sd.(dev2search4)),...
				' working based on power)\n']);
		end
	end
	for device_selector = 1:numel(dev2search4_list)
		dev2search4 = dev2search4_list{device_selector};
		% Print overall result:
		fprintf(['Total ',num2str(d_counte.(dev2search4)),' "',dev2search4,'"  found (',...
			num2str(d_wor_co.(dev2search4)),' working based on activity, ',num2str(d_pow_co.(dev2search4)),...
			' working based on power) in ',num2str(hh_counter.(dev2search4)),' household.\n']);
	end
	diary('off');
end


load('D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\02_Output_detailed\2017-06-06_13.35.07 - ETZ_001.mat')

