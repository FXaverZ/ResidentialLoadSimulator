clear;

source_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data\16.09.10 - Jahreslastprofile_TU';
sep = ' - ';
Timebase_Output = 60;

source_path = [source_path, filesep];
simtime = now;

Dev_4Flex_Output = {...
% 	'wa_boi',...
% 	'hea_ra',...
	'hea_wp',...
% 	'cir_pu',...
	}; %#ok<*COMNL>

% Daten laden und zusammensetzen:
% Dateinamen einlesen:
content = dir(source_path);
content = struct2cell(content);
content = content(1,3:end);

% Nach einer Modelldatei suchen:
simtimeid_all = [];
simtimeid_HPs = [];
for i=1:numel(content)
	filename = content{i};
	name_parts = regexp(filename, sep, 'split');
	if isempty(simtimeid_all) && numel(name_parts) > 2 ...
			&& strcmp(name_parts{1},'Summary') ...
			&& strcmp(name_parts{3},'Energy_Year.mat')
		simtimeid_all = name_parts{2};
	end
	if isempty(simtimeid_HPs) && numel(name_parts) > 2 ...
			&& strcmp(name_parts{1},'Summary') ...
			&& strcmp(name_parts{3},'Energy_Year_HPs.mat')
		simtimeid_HPs = name_parts{2};
	end
	if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat')
		%laden der Modelldaten:
		load([source_path,filename])
	end
end

households = Households.Types(:,[1,4,5]);

%Energy, %Energy_Day
load([source_path,'Summary',sep,simtimeid_all,sep,'Energy_Year.mat']);
%Energy_HPs, Energy_Day_HPs
load([source_path,'Summary',sep,simtimeid_HPs,sep,'Energy_Year_HPs.mat']);

Energy_Flex = [];
Energy_Day_Flex = [];
Energy_InFlex = [];
Energy_Day_InFlex = [];
for k=1:size(households,1)
	act_hh_typ = households{k,1};
	Energy_Flex.(act_hh_typ) = Energy_HPs.(act_hh_typ);
	Energy_InFlex.(act_hh_typ) = Energy.(act_hh_typ) - Energy_HPs.(act_hh_typ);
	Energy_Day_Flex.(act_hh_typ) = Energy_Day_HPs.(act_hh_typ);
	Energy_Day_InFlex.(act_hh_typ) = Energy_Day.(act_hh_typ) - Energy_Day_HPs.(act_hh_typ);
end

save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,'Energy_Year_FlexSep.mat'],...
	'Timebase_Output','Energy_Flex','Energy_Day_Flex','Energy_InFlex','Energy_Day_InFlex','-v7.3');

for k=1:size(households,1)
	act_hh_typ = households{k,1};
	%Power
	load([source_path,filesep,'Summary',sep,simtimeid_all,sep,'Powers_Year',sep,act_hh_typ,'.mat']);
	%Power_HePs --> in future Power_HPs!
	load([source_path,filesep,'Summary',sep,simtimeid_HPs,sep,'Powers_Year_HPs',sep,act_hh_typ,'.mat']);
	
	Power_Flex = Power_HePs;
	Power_InFlex = Power - Power_HePs;
	
	save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,...
		'Powers_Year_FlexSep',sep,act_hh_typ,'.mat'],'Power_Flex','Power_InFlex','Timebase_Output','Dev_4Flex_Output','-v7.3');
end


