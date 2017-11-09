clear;
load('D:\Projekte\leafs_4Sync\Inhalte\02_Durchfuehrung\03_WP3\Task3.2_synthetic_Profiles\02_Scripts_for_Output_(Matlab)\03_Zwischenergebnisse\Final_HPs\Allocated_Heat_Pumps_Profiles - ETZ.mat')
path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\01_Output_final\Powers_HP_Loads\';
load([path,'2017-05-15_12.09.32 - ETZ - Power_Summary','.mat'])

max_power = 4000;
pos_power = 3000;

[Powers,IX] = sort (Powers);
Load_IDs = Load_IDs(IX);
% Energies = zeros(size(Powers));
% for i = 1:numel(Load_IDs)
% 	idx = strcmp([Allocation{1,:}],Load_IDs{i});
% 	Energies(i) = Allocation{7,idx};
% end

Powers_ok = zeros(size(Powers));
Powerspok = Powers_ok;
Powersnok = Powers_ok;

idx = Powers<pos_power;
Powers_ok(idx) = Powers(idx)/1000;
Powers_ok(Powers_ok==0) = NaN;

idx = Powers>=pos_power & Powers<max_power;
Powerspok(idx) = Powers(idx)/1000;
Powerspok(Powerspok==0) = NaN;

idx = Powers>=max_power;
Powersnok(idx) = Powers(idx)/1000;
Powersnok(Powersnok==0) = NaN;

xtick = 1:numel(Load_IDs);
% [ax, b, p] = plotyy(xtick,[Powers_ok',Powersnok'],xtick,Energies',@bar,@line);
b = bar([Powers_ok',Powerspok',Powersnok'],1,'stacked');
% set(gca,...
% set(ax,...
set(gca,...
	'XLim',[0.5,numel(Load_IDs)+0.5],...
	'XTick',xtick,...
	'XTickLabel',Load_IDs,...
	'XTickLabelRotation',90);
% b(2).BarLayout = 'stacked';
% b(1).BarLayout = 'stacked';
b(3).FaceColor='red';
b(2).FaceColor='yellow';
b(1).FaceColor='green';

% set(gcf,'units','normalized','outerposition',[0 0 1 1])
suptitle('Heatpumps ETZ');