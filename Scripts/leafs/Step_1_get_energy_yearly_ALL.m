clear;
% source_path = 'E:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
% source_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
source_path = 'D:\Verbrauchersimulation mit DSM\Simulationsergebnisse';

content = dir(source_path);
content = struct2cell(content);
content = content(1,3:end);

for a = 1:numel(content)
    path = content{a};
    get_energy_yearly([source_path, filesep, path], ' - ', 60);
end