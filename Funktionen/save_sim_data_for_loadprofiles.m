function Configuration = save_sim_data_for_loadprofiles (Configuration, Model,...
	Households, Devices, Result, counter) %#ok<INUSL>
%SAV_SIM_DATA_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

%    Franz Zeilinger - 25.08.2011

% Auslesen der Haushaltskategorie, die berechnet wurde:
typ = Households.Act_Type;

file = Configuration.Save.Data;
% Speichern der wichtigen Workspacevariablen:
file.Data_Name = [datestr(Result.Sim_date,'HHhMM.SS'),...
	' - Lastprofile - ',Model.Sim_Resolution];

%Rohdaten speichern:
% try
% 	save([file.Path,file.Data_Name,'.mat'],'Model','Result','Devices',...
% 		'Households', '-v7.3');
% catch ME
% 	% Falls Fehler aufgetreten ist, Meldung in Konsole:
% 	errorstr = strrep(ME.message,'\','\\');
% 	str = ['--> Ein Fehler ist aufgetreten: ',errorstr];
% 	fprintf(['\n\t\t\t',str,'\n']);
% 	% Versuch, einen häufigen Fehler auszuschließen:
% 	str = 'Speichern der Daten ohne DEVICES-Struktur: ';
% 	fprintf(['\n\t\t',str]);
% 	save([file.Path,file.Data_Name,' (ohne DEVICES).mat'],'Model','Result',...
% 		'Households');
% end

% Erzeugen einer .csv und .xls-Datei mit den Lastprofilen inkl. Zeitstempel:
time = Result.Time;
time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
% Rohdaten der Haushalte auslesen:
resu = Result.Raw_Data.Households_Power_Phase;
% das Ergebnis in eine ausgebbare Form bringen (d.h. 3D --> 2D + 
% Gesamtleistungsaufnahme):
xls_resu_phase = zeros(size(resu,3),3*size(resu,2));
xls_resu_phase(:,1:3:end) = squeeze(resu(1,:,:))';
xls_resu_phase(:,2:3:end) = squeeze(resu(2,:,:))';
xls_resu_phase(:,3:3:end) = squeeze(resu(3,:,:))';
% die zu schreibenden Daten zusammensetzen:
data_phase = [time', xls_resu_phase];
data_total = [time', Result.Raw_Data.Households_Power_Total'];
% Titelzeile generieren:
titl_phase_csv = cell(1,3*size(resu,2));
titl_total_csv = cell(1,size(resu,2));
titl_phase = cell(1,3*size(resu,2));
titl_total = cell(1,size(resu,2));
for i=0:size(resu,2)-1
	% Bezeichnung des Haushaltes:
	name = ['HH_',num2str(i+1,'%05.0f')];
	% Gesamtleistung des Haushaltes i
	titl_total_csv{i+1} = ['P_Ge_',name,';'];
	titl_total{i+1} = ['P_Ge_',name];
	% Phasenleistungen:
	titl_phase_csv{i*3+1} = ['P_L1_',name,';'];
	titl_phase_csv{i*3+2} = ['P_L2_',name,';'];
	titl_phase_csv{i*3+3} = ['P_L3_',name,';'];
	titl_phase{i*3+1} = ['P_L1_',name];
	titl_phase{i*3+2} = ['P_L2_',name];
	titl_phase{i*3+3} = ['P_L3_',name];
end
titl_phase_csv = [{'Zeit;'},titl_phase_csv];
titl_total_csv = [{'Zeit;'},titl_total_csv];
titl_phase = [{'Zeit'},titl_phase];
titl_total = [{'Zeit'},titl_total];
simdate_str_csv = {'Simulationsdaten vom Durchlauf am;',';',';',...
	datestr(Result.Sim_date),';'};

% Ergebnismatritzen in .mat-File speichern:
save([file.Path,file.Data_Name,' - Daten - ', typ,' - ',num2str(counter),...
	'.mat'], 'data_phase', 'data_total');

% .csv-Files schreiben:
if Configuration.Options.savas_csv
csvn_total = [file.Path,file.Data_Name,' - Gesamtleistung - ', typ,'.csv'];
csvn_phase = [file.Path,file.Data_Name,' - Phasenleistung - ', typ,'.csv'];
% Überschriften schreiben:
file_total = fopen(csvn_total,'w');
fprintf(file_total,[simdate_str_csv{:},'\n']);
fprintf(file_total,[titl_total_csv{:},'\n']);
fclose(file_total);
file_phase = fopen(csvn_phase,'w');
fprintf(file_phase,[simdate_str_csv{:},'\n']);
fprintf(file_phase,[titl_phase_csv{:},'\n']);
fclose(file_phase);
% Daten schreiben:
dlmwrite(csvn_total,data_total,'-append',...
	'delimiter',';',...
	'precision','%1.2f');
dlmwrite(csvn_phase,data_phase,'-append',...
	'delimiter',';',...
	'precision','%1.2f');
end
% .xls-File schreiben:
if (numel(time) < 1048576-3) && Configuration.Options.savas_xls
	xls = XLS_Writer();
	xls.set_worksheet('Phasenleistung');
	xls.write_lines({'Simulationsdaten vom Durchlauf am','','',...
		datestr(Result.Sim_date)});
	xls.write_lines(titl_phase); % Spaltenüberschriften
	xls.write_lines(data_phase); % Daten
	xls.set_worksheet('Gesamtleistung');
	xls.write_lines({'Simulationsdaten vom Durchlauf am','','',...
		datestr(Result.Sim_date)});
	xls.write_lines(titl_total); % Spaltenüberschriften
	xls.write_lines(data_total); % Daten
	xlsn = [file.Path,file.Data_Name,' - ', typ,'.xlsx']; % Dateiname .xls-File
	xls.write_output(xlsn);
else
	fprintf('(ohne .xls-Daten) ');
end
end