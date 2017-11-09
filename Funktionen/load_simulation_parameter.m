function Model = load_simulation_parameter(File_Path, File_Name, Model)
%LOAD_SIMULATION_PARAMETER    lädt die Simulationseinstellungen aus Datei
%    MODLE = LOAD_SIMULATION_PARAMETER(FILE_PATH, FILE_NAME, MODEL) lädt aus der
%    durch FILE_PATH und FILE_NAME (ohne Datei-Endung) angegebenen
%    xls-Parameterdatei die Simulationseinstellungen, sofern diese vorhanden
%    sind. 
%
%    Die Simulationparameter müssen sich im angegebenen xls-File in einem
%    Worksheet mit dem Namen 'Parameters' und oberhalb der Geräteparameter
%    befinden. Sie werden mit der Überschrift 'Simulation Settings:'
%    eingeleitet.
%    Die verarbeitbaren Parameternamen sind in der Struktur MODEL unter
%    MODEL.SIM_PARAM_POOL angeführt (siehe LOAD_DEFAULT_VALUES).

%    Franz Zeilinger - 17.08.2010

% Einleitungstext bei Fehler:
error_text = {...
	'Fehler sind beim Laden der Simualtionseinstellungen aufgetreten:';...
		' ';...
		};
error_titl = 'Fehler beim Laden der Simualtionseinstellungen';

% Name der Parameterdatei:
xlsn = [File_Path,File_Name,'.xls'];

% Infos zur zu ladenden Konfigurationsdatei einholen:
try
	[~, sheets]=xlsfinfo(xlsn);
catch ME
	error_text(end+1) = {[' - ',ME.message]};
	errordlg(error_text, error_titl);
	Model = [];
	return;
end
% Name des Worksheets, in dem die Parameter aufglistet sein müssen:
wshn_param = 'Parameters';
% Überprüfen, ob dieses vorhanden ist:
if ~any(strcmpi(wshn_param, sheets))
	error_text(end+1) = {[' - notwendige Daten konnten in Datei nicht',...
		' gefunden werden!']};
	errordlg(error_text, error_titl);
	Model = [];
	return;
end

% Daten einlesen:
[~,~,raw_data] = xlsread(xlsn,wshn_param);
% Finden der einzelnen Haupt-Bereiche für Einstellungen (müssen in der 
% richtigen Reihenfolge vorliegen!):
ind = find(strcmpi('Simulation Settings:',raw_data));
[set_row,set_col] = ind2sub(size(raw_data),ind);
ind = find(strcmpi('Device Settings:',raw_data));
dev_row = ind2sub(size(raw_data),ind);
% Teilen des eingelesenen Arrays in die Hauptbereiche:
data = raw_data(set_row+1:dev_row-2,set_col+1:end);

% Falls keine Daten gefunden wurden, zurück (keine Simulationseinstellungen in
% der Datei vorhanden!):
if isempty(data)
	return;
end

% Durchlaufen aller Zeilen und finden der Parameter:
result = zeros(size(data,1),1);
for i=1:size(data,1)
	%in der ersten Spalte müssen die Parametername stehen:
	idx = find(strcmp(data{i,1},Model.Sim_Param_Pool(:,1)),1);
	if ~isempty(idx)
		result(i) = idx;
	end
end
% Aufteilen des Bereiches auf die einzelnen Parameter und zuführen dieser
% Teilbereich der notwendigen Einlesefunktionen:
idx = 0;
idx_start = zeros(1,sum(logical(result)));
idx_count = 1;
idx_end = zeros(1,sum(logical(result)));
for i=1:size(data,1)
	if (result(i) ~= 0) && (idx ~= 0)
		idx_start(idx_count) = idx;
		idx_end(idx_count) = i-1;
		idx_count = idx_count + 1;
		idx = 0;
	end
	if (result(i) ~= 0) && (idx == 0)
		idx = i;
	end
	if i == size(data,1)
		if idx ~= 0
			idx_start(idx_count) = idx;
		else
			idx_start(idx_count) = 1;
		end
		idx_end(idx_count) = i;
		idx_count = idx_count + 1;
	end
end
for i=1:numel(idx_start)
	name = data{idx_start(i),1};
	fun = Model.Sim_Param_Pool{result(idx_start(i)),2};
	Model.(name) = fun('Read',data(idx_start(i):idx_end(i),:),Model);
end

% Konvertieren der logischen Parameter:
Model.Use_DSM = logical(Model.Use_DSM);
Model.Use_Same_DSM = logical(Model.Use_Same_DSM);
end