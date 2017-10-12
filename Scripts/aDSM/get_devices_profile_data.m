% ----------------------------------------------------------------------------------------
% EINSTELLUNGEN:
% ----------------------------------------------------------------------------------------

% Excel-Datei mit den Zuordnungen der Haushalten:
path_xls = pwd;
name_xls = '1_Haushaltsdefinition 126 aus 1260_neue_Ausstattung.xlsx';
% In welcher Spalte ist die Haushaltszuordnungs-ID?
name_col_HH_ids = 'ID_HH_f_neue_Ausstattung';%'ID - HH (Liste 1260)';

% Ort der Profile:
path = ['D:\Projekte\aDSM\5_Synthetische_HH_Lasten\03_Synthetische_Profile_(Rohdaten)',...
	'\13.10.18 - Geräteprofile (Neue Austattung, f. Siedlung x 10)'];

% Output wird wohingespeichert?
save_path = [pwd,filesep,'aDSM_HH_Daten_aufbereitet_4'];
if ~isdir(save_path)
	mkdir(save_path)
end
	
% Einstellungen aus der Simulation:
sim_year = 2013;
sim_date = '11_07.20';
sim_numb = 1;
sim_reso = 'min';
sep = ' - ';

% ----------------------------------------------------------------------------------------
% Excel-Daten laden:
% ----------------------------------------------------------------------------------------
[~,~,raw] = xlsread([path_xls,filesep,name_xls]);
% erste Spalte und erste zwei Zeilen löschen:
raw(:,1) = [];
raw(1:2,:)=[];
% ev nachfolgende NANs löschen:
while isnan(raw{end,1})
	raw(end,:) = [];
end

% Namen der Haushalte auslesen:
idx = strcmp('aDSM ID Haushalt', raw(1,:));
hh_aDSM_names = raw(2:end,idx);

% Haushaltstypen laden und anpassen:
idx = strcmp('Wohntyp', raw(1,:));
hh_aDSM_types = raw(2:end,idx);
todo = {...
	'H1', 'home_1';...
	'H2', 'home_2';...
	'H3', 'home_3';...
	'H4+','hom_4p';...
% 	'W1', 'flat_1';...
% 	'W2', 'flat_2';...
% 	'W3', 'flat_3';...
% 	'W4+','fla_4p';...
	};
for i=1:size(todo,1)
	idx = find(strcmp(todo{i,1}, hh_aDSM_types));
	for j=1:numel(idx)
		hh_aDSM_types{idx(j)} = todo{i,2};
	end
end

% Die IDs der Haushalte in der großen Simulation laden:
idx = strcmp(name_col_HH_ids, raw(1,:));
hh_aDSM_ids = cell2mat(raw(2:end,idx));

% ----------------------------------------------------------------------------------------
% Daten auslesen und zusammenführen:
% ----------------------------------------------------------------------------------------

diary([pwd,filesep,datestr(now,'yyyy-mm-dd_HH-MM-SS'),' - Log.txt']);

% Vektor mit allen Tagen erstellen (Neuer Beginn: 31.12.2012!):
days = datenum(sim_year,1,1)-1:1:datenum(sim_year+1,1,1)-1;
% Geräteklassen und Hilfsfunktionen in den Matlab-Suchpfad aufnehmen:
addpath([pwd,filesep,'Klassen']);
addpath([pwd,filesep,'Hilfsfunktionen']);

fprintf('\n============================');
fprintf('\nBeginne mit Datenextraktion:');
fprintf('\n============================\n');
% Nun die Daten durchgehen und Arrays erstellen:
for i=1:size(todo,1)
	% Ersten Jahresdatensatz laden (um die Arrays zu indizieren);
	[season, weekd] = day2sim_parameter(datestr(days(1),'yyyy'), days(1));
	name_result = [sim_date,sep,num2str(sim_numb),sep,datestr(days(1),'yyyy-mm-dd'),...
		sep,season,sep,weekd,sep,sim_reso];
	% Variable "Result" laden:
	load([path,filesep,name_result,'.mat']);
	
	% Daten aufbereiten:
	res = Result.(todo{i,2});
	idx = strcmp(todo{i,2},hh_aDSM_types);
	ids = hh_aDSM_ids(idx);
	nam = hh_aDSM_names(idx);
	res = res(ids,:);
	% Anzahl an Zeitpunkten eines Tages:
	tp_num = (numel(res{1,6})-1);
	
	% Arrays indidzieren:
	Output = [];
	Summary.(todo{i,2}) =[];
	Summary.(todo{i,2}).HH_Number = 0;
	for j=1:numel(nam)
		Output.(nam{j}).Time_Data = zeros(...
			numel(res{j,1}),...
			2,...
			tp_num*numel(days));
		Output.(nam{j}).Device_Names = res{j,1};
		Summary.(todo{i,2}).HH_Number = Summary.(todo{i,2}).HH_Number + 1;
		for k=1:numel(res{j,1})
			if isfield(Summary.(todo{i,2}), res{j,1}{k})
				Summary.(todo{i,2}).(res{j,1}{k}) = Summary.(todo{i,2}).(res{j,1}{k}) + 1;
			else
				Summary.(todo{i,2}).(res{j,1}{k}) = 1;
			end
		end
	end
	
	fprintf(['\tBearbeite Typ "',todo{i,2},'" ...\n']);
	
	% Nun sind alle Arrays eines Haushaltstyps indiziert! Zusammenführen der Daten:
	% Druchgehen der einzelnen Tage:
	tic;
	for j=1:numel(days)
		fprintf(['\t\tTag ',num2str(j),' von ',num2str(numel(days)),': ']);
		act_day = days(j);
		[season, weekd] = day2sim_parameter(datestr(act_day,'yyyy'), act_day);
		name_result = [sim_date,sep,num2str(sim_numb),sep,datestr(act_day,'yyyy-mm-dd'),...
			sep,season,sep,weekd,sep,sim_reso];
		% Variable "Result" laden, relevante Daten rausziehen und den Rest löschen:
		load([path,filesep,name_result,'.mat']);
		res = Result.(todo{i,2})(ids,:);
		Result = [];
		fprintf([datestr(act_day,'yyyy-mm-dd'),...
			sep,season,sep,weekd,': ']); 
		
		% Nun die einzelnen Haushalte durchgehen:
		for k=1:numel(nam)
			% Zusammenführen der Zeitreihen:
			Output.(nam{k}).Time_Data(:,1,(j-1)*tp_num+1:j*tp_num) = ...
				res{k,3}(:,2:end);
			
			% Operationsmatrix erstellen, dazu die verschiedenen Gerätearten seperat
			% behandeln:
			% Linearer Tageszeitvektor (z.B. 1 - 1440 bei Minutenauflösung)
			vec = 1:tp_num;
			% Indexliste mit den zu 
			dev_idxs_to_do = 1:numel(Output.(nam{k}).Device_Names);
			
			% Kühlgeräte:
			id_dev = find(...
				strcmp(Output.(nam{k}).Device_Names, 'refrig') | ...
				strcmp(Output.(nam{k}).Device_Names, 'freeze'));
			for l=1:numel(id_dev)
				% Einsatzplan auslesen:
				oplan = res{k,4}{id_dev(l)};
				% Geräteinstanz:
				dev_i = res{k,2}{id_dev(l)};
				% Gerät als erledigt markieren:
				dev_idxs_to_do(dev_idxs_to_do == id_dev(l)) = [];
				% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
				idx = find(squeeze(Output.(nam{k}).Time_Data(id_dev(l),1,(j-1)*tp_num+1:j*tp_num)) == dev_i.Power_Nominal);
				% Aktivitätsmatrix entsprechend anpassen:
				Output.(nam{k}).Time_Data(id_dev(l),2,(j-1)*tp_num+idx) = 1;
			end
			
			% nun die Geräte berarbeiten, die ein Programm abfahren (Geschirrspüler,
			% Wäschetrockner, Waschmaschinen:
			id_dev = find(...
				strcmp(Output.(nam{k}).Device_Names, 'washer') | ...
				strcmp(Output.(nam{k}).Device_Names, 'dishwa') |...
				strcmp(Output.(nam{k}).Device_Names, 'cl_dry'));
			for l=1:numel(id_dev)
				% Geräteinstanz:
				dev_i = res{k,2}{id_dev(l)};
				% Gerät als erledigt markieren:
				dev_idxs_to_do(dev_idxs_to_do == id_dev(l)) = [];
				% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
				idx = find(squeeze(Output.(nam{k}).Time_Data(id_dev(l),1,(j-1)*tp_num+1:j*tp_num)) > 0);
				% Aktivitätsmatrix entsprechend anpassen:
				Output.(nam{k}).Time_Data(id_dev(l),2,(j-1)*tp_num+idx) = 1;
			end
			
			% Geräte für die kein Einsatzplan extrahiert wurde (z.B. weil Gerätegruppen
			% zusammengefasst wurden:			
			id_dev = find(...
				strcmp(Output.(nam{k}).Device_Names, 'illumi') | ...
				strcmp(Output.(nam{k}).Device_Names, 'dev_de') | ...
				strcmp(Output.(nam{k}).Device_Names, 'stove_') | ...
				strcmp(Output.(nam{k}).Device_Names, 'oven__') | ...
				strcmp(Output.(nam{k}).Device_Names, 'microw') | ...
				strcmp(Output.(nam{k}).Device_Names, 'ki_mic'));
			for l=1:numel(id_dev)
				stby = 0;
				% Geräteinstanzen laden
				devs = res{k,2}{id_dev(l)};
				% Gerät(e) als erledigt markieren:
				dev_idxs_to_do(dev_idxs_to_do == id_dev(l)) = [];
				for m=1:numel(devs)
					% Einzelgerätinstanz auslesen:
					dev = devs(m);
					% Check, ob noch ein Cell-Array vorliegt
					if ~iscell(dev)
						% Wenn nicht, Einzelgerät vorhanden, Stand-by aufaddieren:
						stby = stby + dev.Power_Stand_by;
					else
						% Falls noch ein Cell-Aray vorliegt, liegen unterschiedliche
						% Geräteklassen vor, diese "aufdröseln":
						d = devs{m};
						for n=1:numel(d)
							dev = d(n);
							% Stand-by aufaddieren:
							stby = stby + dev.Power_Stand_by;
						end
					end
				end
				% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
				idx = find(squeeze(Output.(nam{k}).Time_Data(id_dev(l),1,(j-1)*tp_num+1:j*tp_num)) > stby);
				% Aktivitätsmatrix entsprechend anpassen:
				Output.(nam{k}).Time_Data(id_dev(l),2,(j-1)*tp_num+idx) = 1;
			end
			
			% Nun noch die restlichen Geräte abarbeiten, für diese wurde bereits ein
			% Einsatzplan extrahiert:
			for l=1:numel(dev_idxs_to_do)
				% Geräteinstanz:
				dev_i = res{k,2}{dev_idxs_to_do(l)};
				% Zeitpunkte ermitteln, zu denen das Gerät aktiv ist:
				idx = find(squeeze(Output.(nam{k}).Time_Data(dev_idxs_to_do(l),1,(j-1)*tp_num+1:j*tp_num)) > dev_i.Power_Stand_by);
				% Aktivitätsmatrix entsprechend anpassen:
				Output.(nam{k}).Time_Data(dev_idxs_to_do(l),2,(j-1)*tp_num+idx) = 1;
			end
		end
		% Statusinfo zum Gesamtfortschritt an User:
		t = toc;
		progress = j/numel(days);
		time_elapsed = t/progress - t;
		fprintf(['Laufzeit: ',...
			sec2str(t),...
			'. Verbleibende Zeit: ',...
			sec2str(time_elapsed),'\n']);
	end
	fprintf('\t--> erledigt! Speichern der Daten...\n');
	% Daten abspeichern:
	for k=1:numel(nam)
		fprintf(['\t\tDatensatz ',nam{k},' ']);
		eval([nam{k},'= Output.(nam{k});']);
		save([save_path,filesep,nam{k},'.mat'],nam{k});
		eval(['clear ',nam{k}]);
		fprintf(['(ID = ',num2str(ids(k)),')\n']);
	end
	fprintf('\t--> erledigt!\n - - - - - - \n');
end

fprintf('Informationen zur Geräteausstattung:\n');
for i=1:size(todo,1)
	fprintf(['\t',todo{i,2},':\n']);
	devs = fieldnames(Summary.(todo{i,2}));
	devs(strcmp(devs,'HH_Number'))=[];
	for j=1:numel(devs)
		fprintf(['\t\t',devs{j},': ',num2str(Summary.(todo{i,2}).(devs{j})),' Geräte, '...
			num2str(Summary.(todo{i,2}).(devs{j})*100/Summary.(todo{i,2}).HH_Number),'%%\n']);
	end
end

diary('off');







