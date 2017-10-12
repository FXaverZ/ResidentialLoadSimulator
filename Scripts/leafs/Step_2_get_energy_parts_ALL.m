clear;
% source_path = 'E:\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';
source_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data';

% Devices, for which a energy-evaluation is needed:
Dev_4Energy_Output = {...
	'hea_wp',...
	};
% Devices, which are seen to be "flexible", therfore build a power group
% with them (Power_Flex) and the Others (Power_InFlex):
Dev_4Flex_Output = {...
	'wa_boi',...
	'hea_ra',...
	'hea_wp',...
% 	'cir_pu',...
	}; %#ok<*COMNL>

content = dir(source_path);
content = struct2cell(content);
content = content(1,3:end);

for a = 1:numel(content)
    path = content{a};
    get_energy_parts([source_path, filesep, path], ' - ', 60, Dev_4Energy_Output, Dev_4Flex_Output);
end