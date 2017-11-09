function handles = save_data(handles)
%SAVE_DATA   speichern eines Datenbankauszugs
%    HANDLES = SAVE_DATA(HANDLES) führt die Speicherung des aktuellen Datebankauszugs
%    gemäß den Einstellungen, die in der HANDLES-Struktur angegeben sind. Je nach
%    geforderten Datentyp bzw. Datenauflösung werden die Daten zusätzlich noch
%    aufbereitet.

% Franz Zeilinger - 16.01.2011

file = handles.Current_Settings.Target;
resu = handles.Result;

data_phase_hh = resu.Households.Data;
data_phase_pv = resu.Solar.Data;
data_phase_wi = resu.Wind.Data;
setting = handles.Current_Settings;
system = handles.System;

% Auslesen der zeitlichen Auflösung in Sekunden:
time_resolution = system.time_resolutions{setting.Time_Resolution,2};
% Auslesen der aktuellen Zeitstempel
time = resu.Time;
% Erzeugen von Zeitstempel mit aktuellen Einstellungen:
time_set = (time(1):time_resolution/86400:time(end))';
% Überprüfen, ob die gleiche zeitliche Auflösung vorliegt, falls nicht, die Daten
% entsprechend anpassen:
if size(time_set,1) < size(time,1)
	% Daten müssen angepasst werden:
	data_phase_hh = data_phase_hh(1:time_resolution:end,:);
	data_phase_pv = data_phase_pv(1:time_resolution:end,:);
	data_phase_wi = data_phase_wi(1:time_resolution:end,:);
	time = time_set;
elseif size(time_set,1) > size(time,1)
	% es wird eine feinere Auflösung verlangt als jene, in der die aktuellen Daten
	% extrahiert wurden! Datenanpassung nicht möglich, User informieren:
	exception = MException('VerifyOutput:OutOfBounds', ...
       ['Zeitliche Auflösung der vorhandenen Daten ist nicht kompatibel mit ',...
		'aktuellen Speichereinstellungen! Bitte diese überprüfen!']);
    throw(exception);
end

% Je nach Einstellung verschiedene Speichermethoden starten:
switch handles.Current_Settings.Output_Datatyp
	case 1 % .mat - MATLAB Binärdatei
		% Daten speichern:
		save([file.Path,filesep,file.Name,file.Exte],'data_phase_hh',...
			'data_phase_pv','data_phase_wi','setting','system');
	case 2 % .csv - Commaseparated Values
		% Erzeugen einer .csv-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		% Es wird immer pro Haushalt bzw. Erzeugungsanlage für jede Phase jeweils
		% Wirk- und Blindleistung angegeben:
		% HH_001_P_L1, HH_001_Q_L1, HH_001_P_L2, HH_001_Q_L2, HH_001_P_L3, HH_001_Q_L3, ...
		% die zu schreibenden Daten zusammensetzen:
		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		num_hh = size(data_phase_hh,2)/6;
		num_pv = size(data_phase_pv,2)/6;
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
	case 3 % .xlsx - EXCEL Spreadsheet
		% Erzeugen einer .xls-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		% Es wird immer pro Haushalt bzw. Erzeugungsanlage für jede Phase jeweils
		% Wirk- und Blindleistung angegeben:
		% HH_001_P_L1, HH_001_Q_L1, HH_001_P_L2, HH_001_Q_L2, HH_001_P_L3, HH_001_Q_L3, ...
		% die zu schreibenden Daten zusammensetzen:
		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		num_hh = size(data_phase_hh,2)/6;
		num_pv = size(data_phase_pv,2)/6;

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
	case 4 %.xls - EXCEL 97-2003 Spreadsheet
		% Erzeugen einer .xls-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		% Es wird immer pro Haushalt bzw. Erzeugungsanlage für jede Phase jeweils
		% Wirk- und Blindleistung angegeben:
		% HH_001_P_L1, HH_001_Q_L1, HH_001_P_L2, HH_001_Q_L2, HH_001_P_L3, HH_001_Q_L3, ...
		% die zu schreibenden Daten zusammensetzen:
		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		num_hh = size(data_phase_hh,2)/6;
		num_pv = size(data_phase_pv,2)/6;
		
		% Überprüfen, ob überhaupt in diesem Format gespeichert werden kann
		% (Zeilenbeschränkung in MS EXCEL 2003):
		if size(data_phase,1) > 65500
			exception = MException('VerifyOutput:OutOfBounds', ...
				['Zeilenzahl der Daten übersteigt max. Anzahl an verarbeitbaren ',...
				'Zeilen in MS EXCEL! Auflösung reduzieren!']);
			throw(exception);
		end
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
		% Wenn Daten nicht in Sekundenauflösung gespeichert werden, aus
		% Kompatibiltätsgründen auf das EXCEL-97-2003-Format zurückgreifen:
		if size(data_phase,2) > 256
			% Falls zuviele Spalten benötigt werden, diese in extra Files
			% schreiben:
			num_files = ceil((size(data_phase,2)-1)/253)+1; % Anzahl Files
			for i=1:num_files
				% Datenspalten auswählen
				idx_col = (i-1)*42*6+1:(i)*42*6;
				idx_col = idx_col(idx_col<=size(data_phase,2)-1);
				if isempty(idx_col)
					% falls keine Daten mehr geschrieben werden müssen: Speichern
					% abgeschlossen...
					continue;
				end
				% Index anpassen (1. Spalte ist Zeitspalte):
				idx_col = idx_col+1;
				% Teildaten und Teiltitel zusammensetzen:
				data_part = [data_phase(:,1),data_phase(:,idx_col)];
				titl_phase_part = [{'Zeit'},titl_phase(idx_col)];
				% Die Daten in ein .xls schreiben:
				xls = XLS_Writer();
				xls.set_worksheet('Phasenleistung');
				xls.write_lines({'Jahreszeit:',...
					system.seasons{setting.Season,2},'',...
					'Wochentag:',system.weekdays{setting.Weekday,2}});
				xls.write_lines(titl_phase_part); % Spaltenüberschriften
				xls.write_lines(data_part); % Daten
				% Dateiname .xls-File:
				xlsn = [file.Path,filesep,file.Name,'_',num2str(i,'%02.0f'),...
					file.Exte];
				xls.write_output(xlsn);
			end
		else
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
end

