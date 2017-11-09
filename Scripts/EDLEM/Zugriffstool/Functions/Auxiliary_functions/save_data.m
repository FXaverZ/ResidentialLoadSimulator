function handles = save_data(handles)
%SAVE_DATA   speichern eines Datenbankauszugs

file = handles.Current_Settings.Target;
resu = handles.Result;

data_phase_hh = resu.Households.Data;
% data_phase_pv = resu.Solar.Data;
% data_phase_wi = resu.Wind.Data;
setting = handles.Current_Settings;
system = handles.System;

switch handles.Current_Settings.Output_Datatyp
	case 1 % .mat - MATLAB Binärdatei
		% Daten speichern:
% 		save([file.Path,filesep,file.Name,file.Exte],'data_phase_hh',...
% 			'data_phase_pv','data_phase_wi','setting','system');
		save([file.Path,filesep,file.Name,file.Exte],'data_phase_hh','setting',...
			'system');
	case 2 % .csv - Commaseparated Values
		% Erzeugen einer .csv-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = resu.Time;
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		% Es wird immer pro Haushalt bzw. Erzeugungsanlage für jede Phase jeweils
		% Wirk- und Blindleistung angegeben:
		% HH_001_P_L1, HH_001_Q_L1, HH_001_P_L2, HH_001_Q_L2, HH_001_P_L3, HH_001_Q_L3, ...
		% die zu schreibenden Daten zusammensetzen:
% 		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		data_phase = [time, data_phase_hh];
		num_hh = size(data_phase_hh,2)/6;
% 		num_pv = size(data_phase_pv,2)/6;
        num_pv = 0;
		% Titelzeile generieren:
		titl_phase_csv = cell(1,size(data_phase,2)-1);
		for i=0:((size(data_phase,2)-1)/6)-1
			if i < num_hh
				% Bezeichnung des Haushaltes:
				name = ['HH_',num2str(i+1,'%05.0f'),'_'];
				% Phasenleistungen:
			end
			if i >= num_hh && i < num_hh+num_pv
				% Bezeichnung der PV-Anlage:
				name = ['PV_',num2str(i+1-num_hh,'%05.0f'),'_'];
			end
			if i >= num_hh+num_pv
				% Bezeichnung der Windkraft-Anlage:
				name = ['WI_',num2str(i+1-num_hh-num_pv,'%05.0f'),'_'];
			end
			titl_phase_csv{i*6+1} = [name,'P_L1',';'];
			titl_phase_csv{i*6+3} = [name,'P_L2',';'];
			titl_phase_csv{i*6+5} = [name,'P_L3',';'];
			titl_phase_csv{i*6+2} = [name,'Q_L1',';'];
			titl_phase_csv{i*6+4} = [name,'Q_L2',';'];
			titl_phase_csv{i*6+6} = [name,'Q_L3',';'];
		end
		titl_phase_csv = [{'Zeit;'},titl_phase_csv];
		simdate_str_csv = {'Jahreszeit:;',system.seasons{setting.Season,2},';',...
			'Wochentag:;',system.weekdays{setting.Weekday,2},';'};
		
		% .csv-Files schreiben:
		csvn_phase = [file.Path,filesep,file.Name,file.Exte];
		% Überschriften schreiben:
		file_phase = fopen(csvn_phase,'w');
		fprintf(file_phase,[simdate_str_csv{:},'\n']);
		fprintf(file_phase,[titl_phase_csv{:},'\n']);
		fclose(file_phase);
		% Daten schreiben:
		dlmwrite(csvn_phase,data_phase,'-append',...
			'delimiter',';',...
			'precision','%1.2f');
	case 3 % .xls - EXCEL Spreadsheet
		% Erzeugen einer .csv-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = resu.Time;
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		% Es wird immer pro Haushalt bzw. Erzeugungsanlage für jede Phase jeweils
		% Wirk- und Blindleistung angegeben:
		% HH_001_P_L1, HH_001_Q_L1, HH_001_P_L2, HH_001_Q_L2, HH_001_P_L3, HH_001_Q_L3, ...
		% die zu schreibenden Daten zusammensetzen:
% 		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
        data_phase = [time, data_phase_hh];
		num_hh = size(data_phase_hh,2)/6;
% 		num_pv = size(data_phase_pv,2)/6;
        num_pv = 0;
		% Titelzeile generieren:
		titl_phase = cell(1,size(data_phase,2)-1);
		for i=0:((size(data_phase,2)-1)/6)-1
			if i < num_hh
				% Bezeichnung des Haushaltes:
				name = ['HH_',num2str(i+1,'%05.0f'),'_'];
				% Phasenleistungen:
			end
			if i >= num_hh && i < num_hh+num_pv
				% Bezeichnung der PV-Anlage:
				name = ['PV_',num2str(i+1-num_hh,'%05.0f'),'_'];
			end
			if i >= num_hh+num_pv
				% Bezeichnung der Windkraft-Anlage:
				name = ['WI_',num2str(i+1-num_hh-num_pv,'%05.0f'),'_'];
			end
			titl_phase{i*6+1} = [name,'P_L1'];
			titl_phase{i*6+3} = [name,'P_L2'];
			titl_phase{i*6+5} = [name,'P_L3'];
			titl_phase{i*6+2} = [name,'Q_L1'];
			titl_phase{i*6+4} = [name,'Q_L2'];
			titl_phase{i*6+6} = [name,'Q_L3'];
		end
		titl_phase = [{'Zeit'},titl_phase];
		xls = XLS_Writer();
		xls.set_worksheet('Phasenleistung');
		xls.write_lines({'Jahreszeit:',system.seasons{setting.Season,2},'',...
			'Wochentag:',system.weekdays{setting.Weekday,2}});
		xls.write_lines(titl_phase); % Spaltenüberschriften
		xls.write_lines(data_phase); % Daten
		% Dateiname .xls-File:
		xlsn = [file.Path,filesep,file.Name,file.Exte];
		xls.write_output(xlsn);
end
end

