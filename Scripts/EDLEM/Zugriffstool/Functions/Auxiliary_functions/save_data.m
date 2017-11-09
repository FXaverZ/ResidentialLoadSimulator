function handles = save_data(handles)
%SAVE_DATA   speichern eines Datenbankauszugs
%    HANDLES = SAVE_DATA(HANDLES) führt die Speicherung des aktuellen Datenbankauszugs
%    gemäß den Einstellungen, die in der HANDLES-Struktur angegeben sind, durch. Je
%    nach geforderten Datentyp bzw. Datenauflösung werden die Daten zusätzlich noch
%    aufbereitet.

% Erstellt von:            Franz Zeilinger - 04.07.2012
% Letzte Änderung durch:   Franz Zeilinger - 05.07.2012

% Auslesen wichtiger Einstellugen und der Results-Struktur:
file = handles.Current_Settings.Target;
resu = handles.Result;
% Anzahl an Phasen (um diese mit den Daten mitzuspeichern):
number_phases = 3;

% Einstellungen auslesen:
Current_Settings = resu.Current_Settings;
System = resu.System;

% Die aktuellen Einstellungen aus dem GUI übernehmen:
Current_Settings.Data_Output = handles.Current_Settings.Data_Output;
Current_Settings.Target = handles.Current_Settings.Target;

% Nun die vorhandenen Daten und die gewünschten Einstellungen untersuchen, ob die
% Daten überhaupt angepasst werden können:
extract = Current_Settings.Data_Extract;
output = Current_Settings.Data_Output;

% Die zu speichernden Arrays indizieren:
data_hh_sample = [];
data_hh_mean = [];
data_hh_min = [];
data_hh_max = [];
data_pv_sample = [];
data_pv_mean = [];
data_pv_min = [];
data_pv_max = [];
data_wi_sample = [];
data_wi_mean = [];
data_wi_min = [];
data_wi_max = [];

if output.Time_Resolution < extract.Time_Resolution
	% es wird eine feinere Auflösung verlangt als jene, in der die aktuellen Daten
	% extrahiert wurden!
	exception = MException('VerifyOutput:OutOfBounds', ...
		['Zeitliche Auflösung der vorhandenen Daten ist nicht kompatibel mit ',...
		'aktuellen Speichereinstellungen! Bitte diese überprüfen!']);
	throw(exception);
end
if output.get_Mean_Value && output.get_Mean_Value ~= extract.get_Mean_Value && ...
		extract.Time_Resolution ~= 1
	% es sind keine Mittelwerte vorhanden bzw. können keine Mittelwerte ermittelt
	% werden!
	exception = MException('VerifyOutput:NoMeanValuePossible', ...
		['Es sind keine Mittelwerte vorhanden bzw. können aus den vorhandenen ',...
		'Daten keine berechnet werden! Bitte Einstellungen überprüfen!']);
	throw(exception);
end
if output.get_Min_Max_Value && output.get_Min_Max_Value ~= extract.get_Min_Max_Value && ...
		extract.Time_Resolution ~= 1
	% es sind keine Minimal und Maximalwerte vorhanden bzw. können diese nicht
	% ermittelt werden!
	exception = MException('VerifyOutput:NoMin_MaxValuePossible', ...
		['Es sind keine Minimal und Maximal-Werte vorhanden bzw. können diese aus ',...
		'den vorhandenen Daten keine berechnet werden! Bitte Einstellungen überprüfen!']);
	throw(exception);
end
if ~output.get_Min_Max_Value && ~output.get_Mean_Value && ~output.get_Sample_Value
	% es sind keine Daten zur Speicherung ausgewählt!
	exception = MException('VerifyOutput:NoDataSelected', ...
		['Es sind keine Daten zur Speicherung ausgewählt! ',...
		'Bitte Einstellungen überprüfen!']);
	throw(exception);
end

% Falls erforderlich, Daten anpassen:
if output.Time_Resolution > extract.Time_Resolution
	% Auslesen der zeitlichen Auflösung in Sekunden:
	time_resu_sett = System.time_resolutions{...
		Current_Settings.Data_Output.Time_Resolution,2};
	% Zeitliche Auflösung der Ursprungsdaten (in Sekunden):
	time_resu_data = System.time_resolutions{...
		resu.Current_Settings.Data_Extract.Time_Resolution,2};
	% Ermitteln der zeitlichen Schrittweite:
	time_step = round(time_resu_sett/time_resu_data);
	time_sample = resu.Time_Sample(1:time_step:end);
	time_mean = time_sample(2:end);
	
	if output.get_Sample_Value
		% Samplewerte einfach mit den ermittelten Schritten auslesen:
		data_hh_sample = resu.Households.Data_Sample(1:time_step:end,:);
		data_pv_sample = resu.Solar.Data_Sample(1:time_step:end,:);
		data_wi_sample = resu.Wind.Data_Sample(1:time_step:end,:);
	end
	if output.get_Mean_Value 
		if extract.Time_Resolution > 1
			% Die Mittelwerte mit der neuen zeitlichen Auflösung aus den vorhandenen
			% Mittelwerten ermitteln, da bereits eine Mittelwertbildung erfolgt ist.
			data_hh_mean = resu.Households.Data_Mean;
			data_pv_mean = resu.Solar.Data_Mean;
			data_wi_mean = resu.Wind.Data_Mean;
		else 
			% Es liegen nur die Sekunden-Sample-Werte vor, aus diesen muss der
			% Mittelwert neu berechnet werden!
			data_hh_mean = resu.Households.Data_Sample;
			data_pv_mean = resu.Solar.Data_Sample;
			data_wi_mean = resu.Wind.Data_Sample;
			% letzten Zeitpunkt (00:00:00) entfernen, der den Tag um eine Sekunde
			% verlängert:
			data_hh_mean = data_hh_mean(1:end-1,:);
			data_pv_mean = data_pv_mean(1:end-1,:);
			data_wi_mean = data_wi_mean(1:end-1,:);
		end
		% Bilden des neuen Mittelwerts. Dazu wird zunächst das bestehende Array
		% umgeformt, dass alle Zeitpunkte, die zusammengefasst werden, in der 2.
		% Dimension angeordnet sind. mit Hilfe der MEAN-Funktion wird dann aus dieser
		% Dimension der Mittelwert ermittelt (dazu muss noch die Singleton-Dimension
		% mit SQUEEZE werden):
		data_hh_mean = reshape(data_hh_mean,time_step,[],size(data_hh_mean,2));
		data_hh_mean = squeeze(mean(data_hh_mean));
		data_pv_mean = reshape(data_pv_mean,time_step,[],size(data_pv_mean,2));
		data_pv_mean = squeeze(mean(data_pv_mean));
		data_wi_mean = reshape(data_wi_mean,time_step,[],size(data_wi_mean,2));
		data_wi_mean = squeeze(mean(data_wi_mean));
	end
	if output.get_Min_Max_Value
		% Ermittlung der neuen Minimal- und Maximalwerte aus den vorhandenen Daten.
		% Vorgangsweiese ist die gleiche wie beim Mittelwert, nur mit den Funktionen
		% MIN und MAX:
		if extract.Time_Resolution > 1
			data_min = resu.Households.Data_Min;
			data_max = resu.Households.Data_Max;
		else
			data_min = resu.Households.Data_Sample;
			data_max = resu.Households.Data_Sample;
			data_min = data_min(1:end-1,:);
			data_max = data_max(1:end-1,:);
		end
		data_min = reshape(data_min,time_step,[],size(data_min,2));
		data_max = reshape(data_max,time_step,[],size(data_max,2));
		data_min = squeeze(min(data_min));
		data_max = squeeze(max(data_max));
		data_hh_min = data_min;
		data_hh_max = data_max;
		if extract.Time_Resolution > 1
			data_min = resu.Solar.Data_Min;
			data_max = resu.Solar.Data_Max;
		else
			data_min = resu.Solar.Data_Sample;
			data_max = resu.Solar.Data_Sample;
			data_min = data_min(1:end-1,:);
			data_max = data_max(1:end-1,:);
		end
		data_min = reshape(data_min,time_step,[],size(data_min,2));
		data_max = reshape(data_max,time_step,[],size(data_max,2));
		data_min = squeeze(min(data_min));
		data_max = squeeze(max(data_max));
		data_pv_min = data_min;
		data_pv_max = data_max;
		if extract.Time_Resolution > 1
			data_min = resu.Wind.Data_Min;
			data_max = resu.Wind.Data_Max;
		else
			data_min = resu.Wind.Data_Sample;
			data_max = resu.Wind.Data_Sample;
			data_min = data_min(1:end-1,:);
			data_max = data_max(1:end-1,:);
		end
		data_min = reshape(data_min,time_step,[],size(data_min,2));
		data_max = reshape(data_max,time_step,[],size(data_max,2));
		data_min = squeeze(min(data_min));
		data_max = squeeze(max(data_max));
		data_wi_min = data_min;
		data_wi_max = data_max;
		clear('data_min','data_max');
	end
else
	% falls keine Anpassung notwendig, Daten einfach auslesen:
	time_sample = resu.Time_Sample;
	time_mean = resu.Time_Mean;
	
	data_hh_sample = resu.Households.Data_Sample;
	data_pv_sample = resu.Solar.Data_Sample;
	data_wi_sample = resu.Wind.Data_Sample;
	data_hh_mean = resu.Households.Data_Mean;
	data_pv_mean = resu.Solar.Data_Mean;
	data_wi_mean = resu.Wind.Data_Mean;
	data_hh_min = resu.Households.Data_Min;
	data_hh_max = resu.Households.Data_Max;
	data_pv_min = resu.Solar.Data_Min;
	data_pv_max = resu.Solar.Data_Max;
	data_wi_min = resu.Wind.Data_Min;
	data_wi_max = resu.Wind.Data_Max;
end

% Falls Daten einphasig abgespeichert werden sollen, die Rohdaten entsprechend
% anpassen:
if Current_Settings.Data_Output.Single_Phase
	data_hh_sample = calculate_single_phase_data (data_hh_sample);
	data_hh_mean = calculate_single_phase_data (data_hh_mean);
	data_hh_min = calculate_single_phase_data (data_hh_min);
	data_hh_max = calculate_single_phase_data (data_hh_max);
	data_pv_sample = calculate_single_phase_data (data_pv_sample);
	data_pv_mean = calculate_single_phase_data (data_pv_mean);
	data_pv_min = calculate_single_phase_data (data_pv_min);
	data_pv_max = calculate_single_phase_data (data_pv_max);
	data_wi_sample = calculate_single_phase_data (data_wi_sample);
	data_wi_mean = calculate_single_phase_data (data_wi_mean);
	data_wi_min = calculate_single_phase_data (data_wi_min);
	data_wi_max = calculate_single_phase_data (data_wi_max);
	
	% 	Anzahl der Phasen auf eins setzen
	number_phases = 1; %#ok<*NASGU>
end

% Je nach Einstellung verschiedene Speichermethoden starten:
switch handles.Current_Settings.Data_Output.Datatyp
	
	case 1 % .mat - MATLAB Binärdatei
		% Daten speichern:
		save([file.Path,filesep,file.Name,file.Exte],...
			'data_hh_sample',...
			'data_hh_mean',...
			'data_hh_min',...
			'data_hh_max',...
			'data_pv_sample',...
			'data_pv_mean',...
			'data_pv_min',...
			'data_pv_max',...
			'data_wi_sample',...
			'data_wi_mean',...
			'data_wi_min',...
			'data_wi_max', 'number_phases');
		
	case 2 % .csv - Commaseparated Values
		if output.get_Sample_Value
			% die zu schreibenden Daten zusammensetzen:
			data_phase = [data_hh_sample, data_pv_sample, data_wi_sample];
			% .csv erstellen:
			save_as_csvs(time_sample, data_phase, ...
				'Sample-Werte', '_Sample', ...
				System, Current_Settings);
		end
		if output.get_Mean_Value
			% die zu schreibenden Daten zusammensetzen:
			data_phase = [data_hh_mean, data_pv_mean, data_wi_mean];
			% .csv erstellen:
			save_as_csvs(time_mean, data_phase, ...
				'Mittelwerte', '_Mean', ...
				System, Current_Settings);
		end
		if output.get_Min_Max_Value
			% die zu schreibenden Daten zusammensetzen:
			data_phase = [data_hh_min, data_pv_min, data_wi_min];
			save_as_csvs(time_mean, data_phase, ...
				'Minimalwerte', '_Min', ...
				System, Current_Settings);
			data_phase = [data_hh_max, data_pv_max, data_wi_max];
			save_as_csvs(time_mean, data_phase, ...
				'Maximalwerte', '_Max', ...
				System, Current_Settings);
		end
		
	case 3 % .xlsx - EXCEL Spreadsheet
		
		% die zu schreibenden Daten zusammensetzen:
		data_sample = [time_sample, data_hh_sample, data_pv_sample, data_wi_sample];
		data_mean = [time_mean, data_hh_mean, data_pv_mean, data_wi_mean];
		data_min = [time_mean, data_hh_min, data_pv_min, data_wi_min];
		data_max = [time_mean, data_hh_max, data_pv_max, data_wi_max];
		
		% Titelzeilten generieren:
		[titl_phase, titl_infos] = get_header_text(System, Current_Settings);
		
		% Excel-File schreiben:
		save_as_xls (data_sample, data_mean, data_min, data_max, ...
			titl_phase, titl_infos, System, Current_Settings);
		
	case 4 %.xls - EXCEL 97-2003 Spreadsheet
		% die zu schreibenden Daten zusammensetzen:
		data_sample = [time_sample, data_hh_sample, data_pv_sample, data_wi_sample];
		data_mean = [time_mean, data_hh_mean, data_pv_mean, data_wi_mean];
		data_min = [time_mean, data_hh_min, data_pv_min, data_wi_min];
		data_max = [time_mean, data_hh_max, data_pv_max, data_wi_max];
		
		% Überprüfen, ob überhaupt in diesem Format gespeichert werden kann
		% (Zeilenbeschränkung in MS EXCEL 2003):
		if ...
				size(data_sample,1) > 65500 || ...
				size(data_mean,1)   > 65500 || ...
				size(data_min,1)    > 65500 || ...
				size(data_max,1)    > 65500
			exception = MException('VerifyOutput:OutOfBounds', ...
				['Zeilenzahl der Daten übersteigt max. Anzahl an verarbeitbaren ',...
				'Zeilen in MS EXCEL! Auflösung reduzieren!']);
			throw(exception);
		end
			
		% Titelzeilten generieren:
		[titl_phase, titl_infos] = get_header_text(System, Current_Settings);
		
		% Wenn Daten nicht in Sekundenauflösung gespeichert werden, kann aus
		% Kompatibiltätsgründen auf das EXCEL-97-2003-Format zurückgegriffen werden:
		max_col = max([...
			size(data_sample,2),...
			size(data_mean,2),...
			size(data_min,2),...
			size(data_max,2)]);
		if max_col > 256 
			% Falls zuviele Spalten benötigt werden, diese in extra Files
			% schreiben:
			num_files = ceil((max_col-1)/253)+1; % Anzahl Files
			for i=1:num_files
				% Datenspalten auswählen
				idx_col = (i-1)*42*6+1:(i)*42*6;
				idx_col = idx_col(idx_col<=max_col-1);
				if isempty(idx_col)
					% falls keine Daten mehr geschrieben werden müssen: Speichern
					% abgeschlossen...
					continue;
				end
				% Index anpassen (1. Spalte ist Zeitspalte):
				idx_col = idx_col+1;
				% Teildaten und Teiltitel zusammensetzen:
				data_part_sample = [data_sample(:,1),data_sample(:,idx_col)];
				data_part_mean = [data_mean(:,1),data_mean(:,idx_col)];
				data_part_min = [data_min(:,1),data_min(:,idx_col)];
				data_part_max = [data_max(:,1),data_max(:,idx_col)];
				titl_phase_part = [{'Zeit'},titl_phase(idx_col)];
				titl_infos_part = [{''},titl_infos(idx_col)];
				% Namen der Teildateien anpassen:
				Current_Settings.Target.Name = ...
					[handles.Current_Settings.Target.Name,'_',num2str(i,'%02.0f')];
				% Die Daten in ein .xls schreiben:
				save_as_xls (data_part_sample, data_part_mean, data_part_min, ...
					data_part_max, titl_phase_part, titl_infos_part, ...
					System, Current_Settings);
			end
			% Ursprünglich eingestellten Dateinamen wieder zurückschreiben...
			Current_Settings.Target.Name = handles.Current_Settings.Target.Name;
		else
			% Daten in ein .xls schreiben:
			save_as_xls (data_sample, data_mean, data_min, data_max, ...
				titl_phase, titl_infos, System, Current_Settings);
		end
end

% Festhalten, dass die Daten verändert wurden: dazu werden die Ouput mit den
% Extraktionseinstellungen gleichgesetzt!

Current_Settings.Data_Extract = Current_Settings.Data_Output;
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
if Current_Settings.Data_Output.Single_Phase
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
	if Current_Settings.Data_Output.Single_Phase
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

function save_as_csvs (time, data, description_str, typ_str, System, Current_Settings)
% Erzeugen einer .csv-Datei mit den Lastprofilen inkl. Zeitstempel:
time = time - datenum('30-Dec-1899'); % Zeitformat in Excel-Format bringen

% die zu schreibenden Daten zusammensetzen:
data_phase = [time, data];

% Titelzeilen generieren:
[titl_phase, titl_infos] = get_header_text(System, Current_Settings);

% Für .csv müssen nun nach jedem Eintrag der Überschriften noch ";" eingefügt
% werden:
titl_phase_csv = cellfun(@(x) [x,';'],titl_phase,'UniformOutput',false);
titl_infos_csv = cellfun(@(x) [x,';'],titl_infos,'UniformOutput',false);
% Zusätzliche Infos:
simdate_str_csv = {...
	'Jahreszeit:;',System.seasons{Current_Settings.Season,2},';',...
	'Wochentag:;',System.weekdays{Current_Settings.Weekday,2},';',...
	'Datentyp:;',description_str};

% Vollständiger Name des .csv-Files:
file = Current_Settings.Target;
csvn_phase = [file.Path,filesep,file.Name,typ_str,file.Exte];

% Überschriften schreiben:
file_phase = fopen(csvn_phase,'w');
fprintf(file_phase,[simdate_str_csv{:},'\n']);
fprintf(file_phase,[titl_infos_csv{:},'\n']);
fprintf(file_phase,[titl_phase_csv{:},'\n']);
fclose(file_phase);
% Daten schreiben:
dlmwrite(csvn_phase,data_phase,'-append',...
	'delimiter',';',...
	'precision','%1.4f');

end

function save_as_xls (data_sample, data_mean, data_min, data_max, ...
	titl_phase, titl_infos, System, Current_Settings)

% XLS_Writer initialisieren, schreiben in Tabellenblatt "Phasenleistung":
xls = XLS_Writer();
if size(data_sample,2)>1
	% Tabellenblatt erstellen:
	xls.set_worksheet('Sample_Werte');
	% Zustzliche Infos sowie Inhalt schreiben:
	xls.write_lines({...
		'Jahreszeit:',System.seasons{Current_Settings.Season,2},'',...
		'Wochentag:',System.weekdays{Current_Settings.Weekday,2},'',...
		'Datentyp:','Sample-Werte'});
	xls.write_lines(titl_infos); % Infozeile
	xls.write_lines(titl_phase); % Spaltenüberschriften
	xls.write_lines(data_sample); % Daten
end
if size(data_mean,2)>1
	% Tabellenblatt erstellen:
	xls.set_worksheet('Mittelwerte');
	% Zustzliche Infos sowie Inhalt schreiben:
	xls.write_lines({...
		'Jahreszeit:',System.seasons{Current_Settings.Season,2},'',...
		'Wochentag:',System.weekdays{Current_Settings.Weekday,2},'',...
		'Datentyp:','Mittelwerte'});
	xls.write_lines(titl_infos); % Infozeile
	xls.write_lines(titl_phase); % Spaltenüberschriften
	xls.write_lines(data_mean); % Daten
end
if size(data_min,2)>1 && size(data_max,2)>1
	% Tabellenblatt erstellen:
	xls.set_worksheet('Minimalwerte');
	% Zustzliche Infos sowie Inhalt schreiben:
	xls.write_lines({...
		'Jahreszeit:',System.seasons{Current_Settings.Season,2},'',...
		'Wochentag:',System.weekdays{Current_Settings.Weekday,2},'',...
		'Datentyp:','Minimalwerte'});
	xls.write_lines(titl_infos); % Infozeile
	xls.write_lines(titl_phase); % Spaltenüberschriften
	xls.write_lines(data_min); % Daten
	% Tabellenblatt erstellen:
	xls.set_worksheet('Maximalwerte');
	% Zustzliche Infos sowie Inhalt schreiben:
	xls.write_lines({...
		'Jahreszeit:',System.seasons{Current_Settings.Season,2},'',...
		'Wochentag:',System.weekdays{Current_Settings.Weekday,2},'',...
		'Datentyp:','Maximalwerte'});
	xls.write_lines(titl_infos); % Infozeile
	xls.write_lines(titl_phase); % Spaltenüberschriften
	xls.write_lines(data_max); % Daten
end

% Dateiname .xls-File:
file = Current_Settings.Target;
xlsn = [file.Path,filesep,file.Name,file.Exte];

% EXCEL-File erstellen:
xls.write_output(xlsn);
end