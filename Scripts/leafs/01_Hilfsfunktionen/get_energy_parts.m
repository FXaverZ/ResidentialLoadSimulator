function get_energy_parts(source_path, sep, timebase_output, Dev_4Energy_Output, Dev_4Flex_Output)
%% Add folder with needed funktions to the matlab search path
addpath(...
    [pwd,filesep,'01_Hilfsfunktionen'],...
    [pwd,filesep,'02_Geraeteklassen']);
% Einstellungen laden:
% sep = ' - '; %Seperator im Dateinamen

% Wo sind die Geräteprofile zu finden?
% source_path = 'D:\Projekte\leafs_only_Data_not4Sync\01_Simulation_Data\Household_Simulation\00_RAW_Data\16.08.24 - Jahreslastprofile\';
source_path = [source_path, filesep];

% Gewünschte Ausgabezeitbasis in Sekunden:
% timebase_output = 60;
Timebase_Output = timebase_output;

if numel(Dev_4Energy_Output) > 1
	error('More than one device specified in "Dev_4Energy_Output" is not implemented yet!');
end
%% Daten laden und zusammensetzen:
% Dateinamen einlesen:
content = dir(source_path);
content = struct2cell(content);
content = content(1,3:end);

% Nach einer Modelldatei suchen:
simtimeid = [];
for i=1:numel(content)
    filename = content{i};
    name_parts = regexp(filename, sep, 'split');
    if isempty(simtimeid)
        simtimeid = name_parts{1};
    end
    if numel(name_parts) > 2 && strcmp(name_parts{3},'Modeldaten.mat');
        %laden der Modelldaten:
        load([source_path,filename])
        break;
    end
end

% Übernehmen und vorberechnen wichtiger Daten:
households = Households.Types(:,[1,4,5]);
num_tp_p_day = Time.day_to_sec / timebase_output;
num_timepoints = numel(Time.Days_Year) * num_tp_p_day;

% Ausgabe vorinitialisieren:
for i=1:size(households,1)
    % Energiewerte pro Haushaltstyp, für alle Durchläufe in einem Array
    % kombiniert:
    Energy_HPs.(households{i,1}) = zeros(1,households{i,3}*Model.Number_Runs);
	Energy_Flex.(households{i,1}) = zeros(1,households{i,3}*Model.Number_Runs);
	Energy_InFlex.(households{i,1}) = zeros(1,households{i,3}*Model.Number_Runs);
    % Tagesenergiewerte pro Haushaltstyp
    Energy_Day_HPs.(households{i,1}) = zeros (numel(Time.Days_Year),households{i,3}*Model.Number_Runs);
	Energy_Day_Flex.(households{i,1}) = zeros (numel(Time.Days_Year),households{i,3}*Model.Number_Runs);
	Energy_Day_InFlex.(households{i,1}) = zeros (numel(Time.Days_Year),households{i,3}*Model.Number_Runs);
    % Alle Leistungsverläufe (dreiphasig) für alle Haushalte
    % (Summenleistungen in Auflösung definiert durch TIMEBASE_OUTPUT
    Powers_Flex.(households{i,1}) = zeros(num_timepoints,3*households{i,3}*Model.Number_Runs);
	Powers_InFlex.(households{i,1}) = zeros(num_timepoints,3*households{i,3}*Model.Number_Runs);	
	Powers_HPs.(households{i,1}) = zeros(num_timepoints,3*households{i,3}*Model.Number_Runs);	
end

% Dateinamen der Simulationsergebnisse sind überlicherweise folgendermaßen aufgebaut:
%    16_26.14 - 1 - 2013-01-08 - Winter - Workda - min.mat
%    Simzeit - lfd. Nr. - Datum - Jahreszeit - Tagestyp - Sim.-Auflösung
% Dann gibt es noch
%    16_26.14 - Modeldaten.mat          % gesichertes Modell
%    16_26.14 - Simulations-Log.txt     % Simulationsaufzeichnungen (Konsole)
%    16_26.14 - Summary.mat             % Zusammenfassung der Daten (Pro Kopf)
%    16_26.14 - Summary.xlsx            % w.o. nur in Excel-Format

fprintf(['\n\nBeginne mit Datenverarbeitung für ',strrep(source_path,'\','\\'),'...\n']);
simtime = now;
diary([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,'Log.txt']);
tic; %Zeitmessung start
total_counter = 0;
fprintf([...
    '\tEckdaten der untersuchten Simulation:\n',...
    '\t-------------------------------------\n',...
    '\t\tAnzahl Durchläufe: ',num2str(Model.Number_Runs),'\n']);
% Iteration über alle Durchläufe
for i=1:Model.Number_Runs
    % Iteration über alle Tage
    if i == 1
        fprintf([...
            '\t\tAnzahl Tage: ',num2str(numel(Time.Days_Year)),'\n'...
            '\t\tStartdatum: ',datestr(Time.Days_Year(1),'dd.mm.yyyy'),'\n',...
            '\t\tEnddatum:   ',datestr(Time.Days_Year(end),'dd.mm.yyyy'),'\n',...
            ['\t\tAnzahl der gefundenen Geräte des Typs "',Dev_4Energy_Output{1},'": \n'],...
            '\t\t..............................................................................\n',...
            ]);
	else
		fprintf('\t\t..............................................................................\n');
    end
    for j=1:numel(Time.Days_Year)
        % über den aktuellen Tag den zugehörigen Dateinamen zusammensetzen
        % und die Ergebnis-Daten:
        act_day = Time.Days_Year(j);
        [season, weekd] = day2sim_parameter(Model, act_day);
        act_filename = [simtimeid,sep,num2str(i),sep,datestr(act_day,...
            'yyyy-mm-dd'),sep,season,sep,weekd,sep,Model.Sim_Resolution,'.mat'];
        load([source_path,act_filename]); % Results
		
		% Iteration über alle Haushaltstypen
        for k=1:size(households,1)
            act_hh_typ = households{k,1};
            act_hh_num = households{k,3};
			
			hh_typ_counter = 0;
			for l=1:act_hh_num
				devs = Result.(act_hh_typ){l,1};
				idx_devs_energy = strcmp(devs,Dev_4Energy_Output{1});
				hh_typ_counter = hh_typ_counter + sum(idx_devs_energy);
				idx_devs_flex = zeros(size(idx_devs_energy));
				for m=1:numel(Dev_4Flex_Output)
					idx_devs_flex = idx_devs_flex | strcmp(devs, Dev_4Flex_Output{m});
				end
								
				ene = cell2mat(Result.(act_hh_typ)(l,5));
				ene_hps = sum(ene(idx_devs_energy));
				ene_ifl = sum(ene(idx_devs_flex));
				ene_fle = sum(ene(~idx_devs_flex));
				Energy_Day_HPs.(act_hh_typ)(j,(i-1)*act_hh_num+l) = ene_hps;
				Energy_Day_Flex.(act_hh_typ)(j,(i-1)*act_hh_num+l) = ene_fle;
				Energy_Day_InFlex.(act_hh_typ)(j,(i-1)*act_hh_num+l) = ene_ifl;
				ene_hps = sum(ene(idx_devs_energy))+ Energy_HPs.(act_hh_typ)((i-1)*act_hh_num+l);
				ene_fle = sum(ene(~idx_devs_flex))+ Energy_InFlex.(act_hh_typ)((i-1)*act_hh_num+l);
				ene_ifl = sum(ene(idx_devs_flex))+ Energy_InFlex.(act_hh_typ)((i-1)*act_hh_num+l);
				Energy_HPs.(act_hh_typ)((i-1)*act_hh_num+l) = ene_hps;
				Energy_InFlex.(act_hh_typ)((i-1)*act_hh_num+l) = ene_ifl;
				Energy_Flex.(act_hh_typ)((i-1)*act_hh_num+l) = ene_fle;
				
				pow = cell2mat(Result.(act_hh_typ)(l,3));
				pow = pow(:,:,1:end-1);
				for m=1:size(pow,1)
					for n=0:2
						powp = squeeze(pow(m,n+1,:));
						powp = reshape(powp,Timebase_Output/Time.Base,[]);
						powp = squeeze(mean(powp))';
						if idx_devs_flex(m)
							powpfl = powp + Powers_Flex.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
								(i-1)*(act_hh_num*3)+(l-1)*3+1+n);
							Powers_Flex.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
								(i-1)*(act_hh_num*3)+(l-1)*3+1+n) = powpfl;
						else
							powpif = powp + Powers_InFlex.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
								(i-1)*(act_hh_num*3)+(l-1)*3+1+n);
							Powers_InFlex.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
								(i-1)*(act_hh_num*3)+(l-1)*3+1+n) = powpif;
						end
						if idx_devs_energy(m)
							powphp = powp + Powers_HPs.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
								(i-1)*(act_hh_num*3)+(l-1)*3+1+n);
							Powers_HPs.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
								(i-1)*(act_hh_num*3)+(l-1)*3+1+n) = powphp;
						end
						clear powpfl powpif powphp
					end
				end
			end
			if j == 1
				fprintf([...
					'\t\t\t',act_hh_typ,' at run No. ',num2str(i),': ',num2str(hh_typ_counter),'\n',...
					]);
			end
        end
        total_counter = total_counter + 1;
        if j == 1
            fprintf('\t\t..............................................................................\n');
        end
        % Statusinfo zum Gesamtfortschritt an User:
        t = toc;
        num_steps = Model.Number_Runs*numel(Time.Days_Year);
        progress = total_counter/num_steps;
        time_elapsed = t/progress - t;
        fprintf(['\tErgebnisfile Nr. ',num2str(total_counter),' von ',...
            num2str(num_steps),' abgeschlossen. Laufzeit: ',...
            sec2str(t),...
            '. Verbleibende Zeit: ',...
            sec2str(time_elapsed),'\n']);
    end
end

t = toc;
fprintf('\t--> erledigt!\n');
fprintf(['\tBerechnungen beendet nach ',sec2str(t)]);
fprintf('\nSaving results...\n');
save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,'Energy_Year_HPs.mat'],...
	'Timebase_Output','Energy_HPs','Energy_Day_HPs','-v7.3');
save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,'Energy_Year_FlexSep.mat'],...
	'Timebase_Output','Energy_Flex','Energy_Day_Flex','Energy_InFlex','Energy_Day_InFlex','-v7.3');
for k=1:size(households,1)
	act_hh_typ = households{k,1};
	Power_HPs = Powers_HPs.(act_hh_typ); %#ok<NASGU>
	Powers_HPs = rmfield(Powers_HPs, act_hh_typ);
	save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,...
		'Powers_Year_HPs',sep,act_hh_typ,'.mat'],'Power_HPs','Timebase_Output','Dev_4Energy_Output','-v7.3');
	clear Power_HePs;
	Power_Flex = Powers_Flex.(act_hh_typ); %#ok<NASGU>
	Powers_Flex = rmfield(Powers_Flex, act_hh_typ);
	Power_InFlex = Powers_InFlex.(act_hh_typ); %#ok<NASGU>
	Powers_InFlex = rmfield(Powers_InFlex, act_hh_typ);
	save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,...
		'Powers_Year_FlexSep',sep,act_hh_typ,'.mat'],'Power_Flex','Power_InFlex','Timebase_Output','Dev_4Flex_Output','-v7.3');
	clear Power_Flex Power_InFlex;
end
fprintf('\t--> erledigt!\n');
diary('off');
