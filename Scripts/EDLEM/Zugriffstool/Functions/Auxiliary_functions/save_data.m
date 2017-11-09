function handles = save_data(handles)
%SAVE_DATA   speichern eines Datenbankauszugs
%    HANDLES = SAVE_DATA(HANDLES) führt die Speicherung des aktuellen Datebankauszugs
%    gemäß den Einstellungen, die in der HANDLES-Struktur angegeben sind. Je nach
%    geforderten Datentyp bzw. Datenauflösung werden die Daten zusätzlich noch
%    aufbereitet.

% Franz Zeilinger - 23.01.2011

% Auslesen wichtiger Einstellugen und der Results-Strukutr:
file = handles.Current_Settings.Target;
resu = handles.Result;

% Einstellungen der Daten auslesen:
Current_Settings = resu.Current_Settings;
System = resu.System;
% Aktualisieren der Einstellungen aus GUI (restlichen Einstellungen werden nicht
% davon betroffen, sie stellen die Ausleseeinstellungen dar, diese sind mit dem
% aktuellen Datensatz verknüpft!):
Current_Settings.Output_Single_Phase = handles.Current_Settings.Output_Single_Phase;
Current_Settings.Target = handles.Current_Settings.Target;
Current_Settings.Time_Resolution_Output = ...
	handles.Current_Settings.Time_Resolution_Output;

% die zu verarbeitenden Daten auslesen:
data_phase_hh = resu.Households.Data;
data_phase_pv = resu.Solar.Data;
data_phase_wi = resu.Wind.Data;

% Auslesen der zeitlichen Auflösung in Sekunden:
time_resolution = System.time_resolutions{Current_Settings.Time_Resolution_Output,2};
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

% Falls Daten einphasig abgespeichert werden sollen, die Rohdaten entsprechend
% anpassen:
if Current_Settings.Output_Single_Phase
	% die einzelnen Phasenleistungen eines Haushaltes aufaddieren:
	data_phase = zeros(size(data_phase_hh,1),size(data_phase_hh,2)/3);
	% Wirkleistung
	data_phase(:,1:2:end) = ...
		data_phase_hh(:,1:6:end) + ...
		data_phase_hh(:,3:6:end) + ...
		data_phase_hh(:,5:6:end);
	% Blindleistung:
	data_phase(:,2:2:end) = ...
		data_phase_hh(:,2:6:end) + ...
		data_phase_hh(:,4:6:end) + ...
		data_phase_hh(:,6:6:end);
	% Ergebnis übernehmen (statt eines [t,n*6]-Arrays liegt nun ein [t,n*2]-Array
	% vor):
	data_phase_hh = data_phase;
	
	% die einzelnen Phasenleistungen der PV aufaddieren:
	data_phase = zeros(size(data_phase_pv,1),size(data_phase_pv,2)/3);
	% Wirkleistung
	data_phase(:,1:2:end) = ...
		data_phase_pv(:,1:6:end) + ...
		data_phase_pv(:,3:6:end) + ...
		data_phase_pv(:,5:6:end);
	% Blindleistung:
	data_phase(:,2:2:end) = ...
		data_phase_pv(:,2:6:end) + ...
		data_phase_pv(:,4:6:end) + ...
		data_phase_pv(:,6:6:end);
	% Ergebnis übernehmen (statt eines [t,n*6]-Arrays liegt nun ein [t,n*2]-Array
	% vor):
	data_phase_pv = data_phase;
	
	% die einzelnen Phasenleistungen eines Haushaltes aufaddieren:
	data_phase = zeros(size(data_phase_wi,1),size(data_phase_wi,2)/3);
	% Wirkleistung
	data_phase(:,1:2:end) = ...
		data_phase_wi(:,1:6:end) + ...
		data_phase_wi(:,3:6:end) + ...
		data_phase_wi(:,5:6:end);
	% Blindleistung:
	data_phase(:,2:2:end) = ...
		data_phase_wi(:,2:6:end) + ...
		data_phase_wi(:,4:6:end) + ...
		data_phase_wi(:,6:6:end);
	% Ergebnis übernehmen (statt eines [t,n*6]-Arrays liegt nun ein [t,n*2]-Array
	% vor):
	data_phase_wi = data_phase;
	clear('data_phase');
end

% Je nach Einstellung verschiedene Speichermethoden starten:
switch handles.Current_Settings.Output_Datatyp
	
	case 1 % .mat - MATLAB Binärdatei
		% Daten speichern:
		save([file.Path,filesep,file.Name,file.Exte],'data_phase_hh',...
			'data_phase_pv','data_phase_wi');
	
	case 2 % .csv - Commaseparated Values
		% Erzeugen einer .csv-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		
		% die zu schreibenden Daten zusammensetzen:
		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		
		% Titelzeilen generieren:
		[titl_phase, titl_infos] = get_header_text(System, Current_Settings);
		
		% Für .csv müssen nun nach jedem Eintrag der Überschriften noch ";" eingefügt
		% werden:
		titl_phase_csv = cellfun(@(x) [x,';'],titl_phase,'UniformOutput',false);
		titl_infos_csv = cellfun(@(x) [x,';'],titl_infos,'UniformOutput',false);
		% Zusätzliche Infos:
		simdate_str_csv = {'Jahreszeit:;',...
			System.seasons{Current_Settings.Season,2},';',...
			'Wochentag:;',System.weekdays{Current_Settings.Weekday,2},';'};
		
		% Vollständiger Name des .csv-Files:
		csvn_phase = [file.Path,filesep,file.Name,file.Exte];
		
		% Überschriften schreiben:
		file_phase = fopen(csvn_phase,'w');
		fprintf(file_phase,[simdate_str_csv{:},'\n']);
		fprintf(file_phase,[titl_infos_csv{:},'\n']);
		fprintf(file_phase,[titl_phase_csv{:},'\n']);
		fclose(file_phase);
		% Daten schreiben:
		dlmwrite(csvn_phase,data_phase,'-append',...
			'delimiter',';',...
			'precision','%1.2f');
		
	case 3 % .xlsx - EXCEL Spreadsheet
		% Erzeugen einer .xls-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen
		
		% die zu schreibenden Daten zusammensetzen:
		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		
		% Titelzeilten generieren:
		[titl_phase, titl_infos] = get_header_text(System, Current_Settings);
		
		% XLS_Writer initialisieren, schreiben in Tabellenblatt "Phasenleistung":
		xls = XLS_Writer();
		xls.set_worksheet('Phasenleistung');
		
		% Zustzliche Infos sowie Inhalt schreiben:
		xls.write_lines({'Jahreszeit:',...
			System.seasons{Current_Settings.Season,2},'',...
			'Wochentag:',System.weekdays{Current_Settings.Weekday,2}});
		xls.write_lines(titl_infos); % Infozeile
		xls.write_lines(titl_phase); % Spaltenüberschriften
		xls.write_lines(data_phase); % Daten
		
		% Dateiname .xls-File:
		xlsn = [file.Path,filesep,file.Name,file.Exte];
		
		% EXCEL-File erstellen:
		xls.write_output(xlsn);
		
	case 4 %.xls - EXCEL 97-2003 Spreadsheet
		% Erzeugen einer .xls-Datei mit den Lastprofilen inkl. Zeitstempel:
		time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen

		% die zu schreibenden Daten zusammensetzen:
		data_phase = [time, data_phase_hh, data_phase_pv, data_phase_wi];
		
		% Überprüfen, ob überhaupt in diesem Format gespeichert werden kann
		% (Zeilenbeschränkung in MS EXCEL 2003):
		if size(data_phase,1) > 65500
			exception = MException('VerifyOutput:OutOfBounds', ...
				['Zeilenzahl der Daten übersteigt max. Anzahl an verarbeitbaren ',...
				'Zeilen in MS EXCEL! Auflösung reduzieren!']);
			throw(exception);
		end
		
		% Titelzeilen generieren:
		[titl_phase, titl_infos] = get_header_text(System, Current_Settings);
		
		% Wenn Daten nicht in Sekundenauflösung gespeichert werden, kann aus
		% Kompatibiltätsgründen auf das EXCEL-97-2003-Format zurückgegriffen werden:
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
				titl_infos_part = [{''},titl_infos(idx_col)];
				% Die Daten in ein .xls schreiben:
				xls = XLS_Writer();
				xls.set_worksheet('Phasenleistung');
				xls.write_lines({'Jahreszeit:',...
					System.seasons{Current_Settings.Season,2},'',...
					'Wochentag:',System.weekdays{Current_Settings.Weekday,2}});
				xls.write_lines(titl_infos_part); % Infozeile
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
			xls.write_lines({'Jahreszeit:',...
				System.seasons{Current_Settings.Season,2},'',...
				'Wochentag:',System.weekdays{Current_Settings.Weekday,2}});
			xls.write_lines(titl_infos); % Infozeile
			xls.write_lines(titl_phase); % Spaltenüberschriften
			xls.write_lines(data_phase); % Daten
			
			% Dateiname .xls-File:
			xlsn = [file.Path,filesep,file.Name,file.Exte];
			xls.write_output(xlsn);
		end
end

% zugehörige Konfiguration speichern (aus handles.Result):
save([file.Path,filesep,file.Name,Current_Settings.Config.Exte],...
	'Current_Settings','System');
end

function [titl_phase, titl_infos] = get_header_text(System, Current_Settings)
% Diese Funktion generiert die Titeleinträge für die Ausgabefiletypen, die diese
% benötigen. Im Fall von .csv muss nach jedem Eintrag noch ein ';' eingefügt werden!

% Liste mit den Hauhaltstypen der jeweiligen Daten erstellen (für die
% Infozeile):
hh_info = {};
% Für alle Haushaltstypen
for i=1:size(System.housholds,1)
	% Für die jeweilige Anzahl der aktuellen Haushalte
	for j=1:Current_Settings.Households.(System.housholds{i,1}).Number
		hh_info(end+1)=System.housholds(i,2); %#ok<AGROW>
	end
end

% Liste mit groben Anlageninfos für alle Anlagen erstellen:
pv_info = {};
plants = Current_Settings.Sola;
for i=1:size(fieldnames(plants),1)
	plant = plants.(['Plant_',num2str(i)]);
	for j=1:plant.Number
		typ = System.Sola.Typs{plant.Typ};
		pow = [num2str(plant.Power_Installed),' kW'];
		ori = [num2str(plant.Orientation),'°'];
		inc = [num2str(plant.Inclination),'°'];
		sep = ' - ';
		pv_info(end+1) = {[typ,sep,pow,sep,ori,sep,inc]}; %#ok<AGROW>
	end
end
wi_info = {};
plants = Current_Settings.Wind;
for i=1:size(fieldnames(plants),1)
	plant = plants.(['Plant_',num2str(i)]);
	for j=1:plant.Number
		typ = System.Wind.Typs{plant.Typ};
		pow = [num2str(plant.Power_Installed/1000),' kW'];
		rot = [num2str(plant.Size_Rotor),' m'];
		sep = ' - ';
		wi_info(end+1) = {[typ,sep,pow,sep,rot]}; %#ok<AGROW>
	end
end

% Anzahl der einzelnen Datensätze:
num_hh = size(hh_info,2);
num_pv = size(pv_info,2);
num_wi = size(wi_info,2);
num_ge = num_hh + num_pv + num_wi;

% Titelzeile & Infozeile initialisieren:
if Current_Settings.Output_Single_Phase
	% Bei einphasigen Daten nur 2 Datenspalten pro Einheit
	titl_phase = cell(1,num_ge*2);
	titl_infos = cell(1,num_ge*2);
else
	% Ansonsten 6 Datenspalten pro Einheit:
	titl_phase = cell(1,num_ge*6);
	titl_infos = cell(1,num_ge*6);
end

% Die Zeilen mit dem Inhalt befüllen:
for i=0:num_ge - 1
	if i < num_hh
		% Bezeichnung des Haushaltes:
		name = ['HH_',num2str(i+1,'%05.0f'),'_'];
		info = hh_info{i+1};
		% Phasenleistungen:
	end
	if i >= num_hh && i < num_hh+num_pv
		% Bezeichnung der PV-Anlage:
		name = ['PV_',num2str(i+1-num_hh,'%05.0f'),'_'];
		info = pv_info{i+1-num_hh};
	end
	if i >= num_hh+num_pv
		% Bezeichnung der Windkraft-Anlage:
		name = ['WI_',num2str(i+1-num_hh-num_pv,'%05.0f'),'_'];
		info = wi_info{i+1-num_hh-num_pv};
	end
	if Current_Settings.Output_Single_Phase
		titl_phase{i*2+1} = [name,'P'];
		titl_phase{i*2+2} = [name,'Q'];
		titl_infos{i*2+1} = info;
	else
		titl_phase{i*6+1} = [name,'P_L1'];
		titl_phase{i*6+3} = [name,'P_L2'];
		titl_phase{i*6+5} = [name,'P_L3'];
		titl_phase{i*6+2} = [name,'Q_L1'];
		titl_phase{i*6+4} = [name,'Q_L2'];
		titl_phase{i*6+6} = [name,'Q_L3'];
		titl_infos{i*6+1} = info;
	end
end
titl_phase = [{'Zeit'},titl_phase];
titl_infos = [{''},titl_infos];
end