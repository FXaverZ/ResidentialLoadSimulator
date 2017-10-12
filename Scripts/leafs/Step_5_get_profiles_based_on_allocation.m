%--------------------------------------------------------------------------
% Settings
%--------------------------------------------------------------------------
clear;

input_simdata_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% input_simdata_path = 'E:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
input_allocation_path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\04_Zwischenergebnisse\Final_wo_HPs_99_-1_0';
% input_allocation_path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\04_Zwischenergebnisse\Final_wo_HPs_99_-1_0';
% output_dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';
output_dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';
% output_dest_path = 'E:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';
output_dest_powers = 'Powers_Fixed_Loads';

sheet_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
sheet_selector = 2;
sep = ' - ';

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
load ([input_allocation_path,filesep,'Allocated_Household_Profiles',...
	sep,sheet_names{sheet_selector},'.mat']);

input_selector = Settings.Input_Selector;

get_loadprofiles(Allocation, 1, sep, eval_id, input_simdata_path, ...
	output_dest_path, output_dest_powers, Settings, Evaluation);

diary('off');
end
