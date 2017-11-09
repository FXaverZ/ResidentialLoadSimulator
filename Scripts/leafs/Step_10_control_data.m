clear;

% MD1JFTNC - Fujitsu Laptop
input_lpt.path = 'D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
output.dest_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

% MD1EEZ0C - Simulationsrechner
% input_lpt.path = 'D:\leafs\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\2016-12-06_load_types_anonymised_FZ.xlsx';
% output.dest_path = 'D:\leafs\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final';

sep = ' - ';

input_lpt.sheet_name = 'Load Profile Index';

input_lpt.header_row   = 2; %Row, in which the header information can be found
input_lpt.data_cut_row = 4; %From this row on, the data in the input excel can be found!
input_lpt.header_yec = 'Flexible Load - annual energy consumption';
input_lpt.header_lpt = 'Flexible Load - profile';
input_lpt.header_typ = 'Flexible Load - profile type';
input_lpt.header_pow = 'Flexible Load - contracted / rated power';
input_lpt.header_sec = 'Flexible Load - sector code';
input_lpt.header_ids = 'Load Profile ID';

grid_names = {'ETZ', 'LIT', 'KOE', 'HSH'};
grid_selector = 3;

% load('D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final\2016-12-19_15.39.29 - LEAFS_AP3_INPUT_data_KOE.mat');
% load('D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final\2017-01-12_14.24.50 - LEAFS_AP3_INPUT_data_KOE.mat');
load('D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final\2017-01-12_14.33.46 - LEAFS_AP3_INPUT_data_KOE.mat');

idx = find(strcmp(Loadprofiles_Header(2,:),'Flexible_Load_[kW]'));
% idx = sort([idx, idx + 1, idx + 2]);
ids = Loadprofiles_Header(1,idx-3);

flex_loads = Loadprofiles_Data(:,idx) + Loadprofiles_Data(:,idx+1) + Loadprofiles_Data(:,idx+2);
idx = find(sum(flex_loads)~=0);
flex_loads = flex_loads(:,idx);
ids = ids(idx);

trafo_loading = sum(Loadprofiles_Data(:,3:end),2);

flex_loads_sum = sum(flex_loads,2);

time = datenum('01.01.2014','dd.mm.yyyy'):1/1440:datenum('01.01.2015','dd.mm.yyyy')-1/1440;

day = 98;
dur = 10;
plot_idxs = (day)*1440+1:day*1440+dur*1440;

% figure;
% plot(time(plot_idxs),flex_loads_sum(plot_idxs,:))
% datetick('x','keeplimits')
% 
% figure;
% plot(time(plot_idxs),flex_loads(plot_idxs,:));
% legend(ids);
% datetick('x','keeplimits');

figure;
plot(time(plot_idxs),trafo_loading(plot_idxs,:));
datetick('x','keeplimits');

