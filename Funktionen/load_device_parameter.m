function Model = load_device_parameter(File_Path, File_Name, Model)
%LOAD_DEVICE_PARAMETER    l�dt die Ger�teparameter aus Parameterfile
%    MODEL = LOAD_DEVICE_PARAMETER(MODEL) erg�nzt die MODEL-Struktur um die
%    Ger�tedaten f�r die jeweiligen Ger�teklassen. Diese sind im angegebenen
%    xls-Parameterfile (FILE_PATH und FILE_NAME ohne Endung) angef�hrt. Diese
%    Funktion findet im xls-File die Positionen der einzelnen Ger�teklassen
%    sowie deren Parameter, liest diese ein und erzeugt eine korrekte
%    Argumenten-Liste.
%
%    Um die Parameter finden zu k�nnen m�ssen sich die Ger�teparameter im
%    angegebenen xls-File in einem Worksheet mit dem Namen 'Parameters' und
%    unterhalb eventueller Simulationseinstellungen befinden. Der Bereich wird
%    duch die �berschrift 'Device Settings:' markiert. 
%    Eine Ger�teklasse muss mit ihrem Namen als �berschrift markiert werden
%    (siehe hierzu Funktion GET_DEFAULT_VALUES).
%    Unter den Ger�teparametern m�ssen sich dann (sofern �berhaupt angegeben)
%    die DSM-Einstellungen befinden, eingeleitet durch die �berschrift 'DSM -
%    Settings:'.
%
%    Parameter Mitglieder einer Ger�tegruppe:
%
%    Franz Zeilinger - 26.07.2011

% Einleitungstext bei Fehler (wird im Fehlerfall erg�nzt):
error_text = {...
	'Fehler sind beim Laden der Parameterdatei aufgetreten:';...
		' ';...
		};
error_titl = 'Fehler beim Laden der Parameterdatei';

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
% Name des Worksheets, in dem die Parameter aufglistet sein m�ssen:
wshn_param = 'Parameters';
% �berpr�fen, ob dieses vorhanden ist:
if ~any(strcmpi(wshn_param, sheets))
	error_text(end+1) = {[' - notwendige Daten konnten in Datei nicht',...
		' gefunden werden!']};
	errordlg(error_text, error_titl);
	Model = [];
	return;
end

% eventuell vorhandene alte Argumentenliste l�schen:
Model.Args = {};

% Daten einlesen:
[~, ~, raw_data] = xlsread(xlsn,wshn_param);
% Finden der einzelnen Haupt-Bereiche f�r Einstellungen (m�ssen in der 
% richtigen Reihenfolge vorliegen!):
ind = find(strcmpi('Device Settings:',raw_data));
[dev_row,dev_col] = ind2sub(size(raw_data),ind);
% Teilen des eingelesenen Arrays in die Hauptbereiche:
dev_data = raw_data(dev_row+1:end,dev_col+1:end);

% Finden der einzelnen Ger�teparameter:
ind = zeros(size(Model.Elements_Pool,1),1);
for i=1:size(Model.Elements_Pool,1)
	name = Model.Elements_Pool{i,2};
	result = find(strcmpi(name,dev_data));
	if ~isempty(result)
		ind(i) = result;
	else
		ind(i) = 0;
	end
end
% Suchen nach den DSM-Einstellungen:
dsm_ind = find(strcmpi('DSM - Settings:',dev_data));
if isempty(dsm_ind) && Model.Use_DSM
	errordlg({...
		error_text;...
		' ';...
		['Datei enth�lt keine Parameter f�r DSM (werden aber f�r ',...
		'aktuelle Simulationseinstellung ben�tigt!']},...
		error_titl);
	return;
end
	
% Sortieren der Eintr�ge:
[dev_row,dev_col] = ind2sub(size(dev_data),ind);
[dev_row,IX] = sort(dev_row);
dev_col = dev_col(IX);
% vorhandene Parameternamen:
content = Model.Elements_Pool(IX(logical(dev_row)),1:2);
% Indizes der jew. Parameter
dev_col = dev_col(logical(dev_row)); 
dev_row = dev_row(logical(dev_row));
% das gleiche f�r die DSM-Parameter-Indizes:
if ~isempty(dsm_ind)
	[dsm_row,dsm_col] = ind2sub(size(dev_data),dsm_ind);
	[dsm_row,IX] = sort(dsm_row);
	dsm_col = dsm_col(IX);
	% Alle Indizes, die kleiner sind als die Ger�tepositionen, verwerfen (das
	% sind ev. vor den Ger�teparametern definiert DSM-Einstellungen, die zu
	% keinem Ger�t geh�ren):
	ok_dsm = dsm_row > dev_row(1);
	dsm_row = dsm_row(ok_dsm);
	dsm_col = dsm_col(ok_dsm);
end
	
% Aufteilen des Parameterbereichs in die einzelnen Ger�te:
for i=1:numel(dev_row)
	name = content{i,1};
	dev_sing_data = dev_data(dev_row(i)+1:dsm_row(i)-1,dev_col(i)+1:end);
	if i<numel(dev_row)
		dev_sing_dsmD = dev_data(dsm_row(i)+1:dev_row(i+1)-1,dsm_col(i)+1:end);
	else
		dev_sing_dsmD = dev_data(dsm_row(i)+1:end,dsm_col(i)+1:end);
	end
	% Einlesen der Ger�teparameter:
	Model = read_parameter(Model, name, Model.Parameter_Pool, dev_sing_data);
	% Einlesen der DSM-Parameter:
	Model = read_parameter(Model, [name,'_dsm'], Model.DSM_Param_Pool, dev_sing_dsmD);
end
end

% HILFSFUNKTIONEN:
function Model = read_parameter(Model, name, Pool, data)
%READ_PARAMETER    einlesen Parameter aus vorbereiteten Daten-Array
%    MODEL = READ_PARAMETER(MODEL, NAME, POOL, DATA)

Model.Args.(name)={};
% Durchlaufen aller Zeilen und finden der Parameter:
result = zeros(size(data,1),1);
for i=1:size(data,1)
	%in der ersten Spalte m�ssen die Parametername stehen:
	idx = find(strcmp(data{i,1},Pool(:,1)),1);
	if ~isempty(idx)
		result(i) = idx;
	end
end
% Aufteilen des Bereiches auf die einzelnen Parameter und zuf�hren dieser
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
	fun = Pool{result(idx_start(i)),2};
	arg = fun('Read',data(idx_start(i):idx_end(i),:));
	Model.Args.(name) = [Model.Args.(name), arg];
end
end