function get_energy_yearly(source_path, sep, timebase_output)
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
    Energy.(households{i,1}) = zeros(1,households{i,3}*Model.Number_Runs);
    % Tagesenergiewerte pro Haushaltstyp
    Energy_Day.(households{i,1}) = zeros (numel(Time.Days_Year),households{i,3}*Model.Number_Runs);
    % Alle Leistungsverläufe (dreiphasig) für alle Haushalte
    % (Summenleistungen in Auflösung definiert durch TIMEBASE_OUTPUT
    Powers.(households{i,1}) = zeros(num_timepoints,3*households{i,3}*Model.Number_Runs);
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
hh_counter = 0;
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
            '\t\tAnzahl der Haushaltsklassen (pro Durchlauf, "Ges.:" = Gesamtanzahl in Ordner): \n',...
            '\t\t..............................................................................\n',...
            ]);
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
            if i == 1 && j == 1
                hh_counter = hh_counter + (act_hh_num * Model.Number_Runs);
                fprintf([...
                    '\t\t\t',act_hh_typ,': ',num2str(act_hh_num),', Ges.: ',num2str(act_hh_num * Model.Number_Runs),' (',households{k,2},')\n',...
                    ]);
            end
            ene = cell2mat(Result.(act_hh_typ)(:,7))';
            Energy_Day.(act_hh_typ)(j,(i-1)*act_hh_num+1:i*act_hh_num) = ene;
            ene = Energy.(act_hh_typ)((i-1)*act_hh_num+1:i*act_hh_num) + ene;
            Energy.(act_hh_typ)((i-1)*act_hh_num+1:i*act_hh_num) = ene;
            for l=1:act_hh_num
                pow = cell2mat(Result.(act_hh_typ)(l,6))';
                pow = pow(1:end-1,:);
                for m=0:2
                    powp = pow(:,m+1);
                    powp = reshape(powp,6,[]);
                    powp = squeeze(mean(powp))';
                    Powers.(act_hh_typ)((j-1)*num_tp_p_day+1:j*num_tp_p_day,...
                        (i-1)*(act_hh_num*3)+(l-1)*3+1+m) = powp;
                end
            end
        end
        total_counter = total_counter + 1;
        if i == 1 && j == 1
            fprintf([...
                '\t\t\t            Ges.: ',num2str(hh_counter),'\n',...
                ]);
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
diary('off');

save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,'Energy_Year.mat'],...
	'Timebase_Output','Energy','Energy_Day','-v7.3');
for k=1:size(households,1)
	act_hh_typ = households{k,1};
	Power = Powers.(act_hh_typ); %#ok<NASGU>
	Powers = rmfield(Powers, act_hh_typ);
	save([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,...
		'Powers_Year',sep,act_hh_typ,'.mat'],'Power','Timebase_Output','-v7.3');
end

% %% Erzeuge Zusammenfassung:
% xls = XLS_Writer;
% for i=1:size(households,1)
% 	act_hh_typ = households{i,1};
% 	ener = Energy.(act_hh_typ);
% 	[ener,~] = sort(ener);
% 	xls.write_lines({'Datenauszug für Haushalte des Typs:','','',households{i,2},'',['(',act_hh_typ,')']});
% 	xls.write_values('Energiewerte [kWh] -->');
% 	xls.write_values(ener);
% 	xls.next_row;
% end
% xls.write_output([source_path,filesep,'Summary',sep,datestr(simtime,'yyyy-mm-dd_HH.MM.SS'),sep,'Energy_Summary.xlsx']);
end
