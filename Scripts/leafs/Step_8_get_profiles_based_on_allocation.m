%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
clear;

% MD1JFTNC - Fujitsu Laptop
% input_simdata_path = 'F:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% input_allocation_hh_path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_H0_ALTENHEIM';
% input_allocation_co_path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_Commercial';
% output_dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

% MD1EEZ0C - Simulationsrechner
input_simdata_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input_allocation_co_path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_Commercial';
input_allocation_hh_path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_H0_ALTENHEIM';
output_dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

output_dest_powers = 'Powers_Fixed_Loads';

sheet_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
sheet_selector = 1;
sep = ' - ';
max_power_single_phase = 2300; %max power for single phase operation
% between the phases in W
phase_composition_quantile = 0.999;% Given quantile, in which the power of
% the single phases are obsorved an it it is tryed to ensure, that the
% single phase power is not too high. 1 = max

eval_time = now;
eval_id = datestr(eval_time,'yyyy-mm-dd_HH.MM.SS');
addpath([pwd,filesep,'01_Hilfsfunktionen']);

for sheet_selector=1:4
	if ~isdir([output_dest_path,filesep,output_dest_powers])
		mkdir([output_dest_path,filesep,output_dest_powers]);
	end
	diary([output_dest_path,filesep,output_dest_powers,filesep,eval_id,sep,sheet_names{sheet_selector},sep,'log.txt']);
	
	%--------------------------------------------------------------------------
	% load the allocatio and perform a preprocessing for fast computation:
	%--------------------------------------------------------------------------
	load ([input_allocation_hh_path,filesep,'Allocated_Household_Profiles',...
		sep,sheet_names{sheet_selector},'.mat']);
	Settings.max_power_single_phase = max_power_single_phase;
	Settings.phase_composition_quantile = phase_composition_quantile;
	
	input_selector = Settings.Input_Selector;
	fprintf('Households:\n');
	get_loadprofiles(Allocation, 1, sep, eval_id, input_simdata_path, ...
		output_dest_path, output_dest_powers, Settings, Evaluation);
	
	fprintf('Commercial Loads:\n');
	load ([input_allocation_co_path,filesep,'Allocated_Commercial_Profiles',...
		sep,sheet_names{sheet_selector},'.mat']);
	Settings.max_power_single_phase = max_power_single_phase;
	Settings.phase_composition_quantile = phase_composition_quantile;
	
	disp('-------------------');
	for a = 1:size(Allocation,2)
		Load_ID = Allocation{1,a};
		Profile_Typ = Allocation{3,a};
		JEC = Allocation{7,a};
		
		if strcmp(Profile_Typ, 'Zero') || strcmp(Profile_Typ, 'Unknown')
			Loadprofile = zeros(525600,3);
		else
			profil = BDEWProfileDaten(Profile_Typ);
			% Aufloesunge im neuen Profil
			k = floor(365 * 24 * 60 / (Settings.Timebase_Output/60));
			timeSteps = zeros(k,1);
			for i=1:k
				timeSteps(i,1) = i * (Settings.Timebase_Output/60);
			end
			% Aufloesunge im BDEW Profil
			deltaTime = round((profil(2,1)-profil(1,1))*24*60);
			% Anzahl der Aufloesunge im Jahr
			n = floor(365 * 24 * 60 / deltaTime);
			% Aufloesunge im Jahr nach altem Profil
			baseTime = zeros(n,1);
			% Aufloesunge im BDEW Profil
			for i=1:n
				baseTime(i,1) = i*deltaTime;
			end
			
			Standardlastprofil = Jahresprofil(baseTime, zeros(n,1), timeSteps);
			dyn = DynamisierungsfaktorenDaten;
			[~, P] = BDEWProfil_2014(profil, dyn(:,2), Profile_Typ);
			Standardlastprofil = addLast(Standardlastprofil, P, JEC);
			[~, power] = Standardlastprofil.getProfilNeu;
			
			if max(power) < Settings.max_power_single_phase
				idx = vary_parameter([1;2;3],ones(3,1)*100/3,'List');
				Loadprofile = zeros(numel(power),3);
				Loadprofile(:,idx)= power;
			else
				Loadprofile = repmat((power/3),[1,3]);
			end
		end
		
		Loadprofile = round(Loadprofile);
		Loadprofile = int32(Loadprofile);
		
		Source.Allocation = Allocation{:,a};
		Source.Settings = Settings;
		
		filename = [output_dest_path,filesep,output_dest_powers,filesep,eval_id,sep,Load_ID,sep,'Overall_Power.mat'];
		save(filename,...
			'Loadprofile','Load_ID','Source');
		fprintf(['Saved   ',Load_ID, ' (Typ "',Profile_Typ,'" with JEC of ',num2str(JEC),'kWh).\n']);
		
	end
	
	Allocation_Commercial = Allocation;
	load([output_dest_path,filesep,output_dest_powers,filesep,eval_id,sep,...
		Settings.Grid_Names{Settings.Grid_Selector},sep,'Modeldaten.mat']);
	save([output_dest_path,filesep,output_dest_powers,filesep,eval_id,sep,...
		Settings.Grid_Names{Settings.Grid_Selector},sep,'Modeldaten.mat'],...
		'Model','Time','Configuration','Households','Allocation',...
		'Allocation_resolved','Settings','Evaluation','Allocation_Commercial');
	disp('-------------------');
	diary('off');
end
