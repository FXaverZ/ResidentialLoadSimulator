function Joblist = load_joblist(File_Path, File_Name)
%LOAD_JOBLIST    lädt die Jobliste von einem xls-File
%    JOBLIST = LOAD_JOBLIST(FILE_PATH, FILE_NAME) lädt aus dem durch FILE_PATH
%    und FILE_NAME (ohne Datei-Endung) angegebenen xls-File die JOBLIST, die die
%    für eine Simulationsreihe abzuarbeitenden Parameterdatein spezifiziert. 
%
%    Der Beginn der Liste wird in diesem File durch eine leere Zelle in der ersten
%    Spalte angezeigt. Alle darüberliegenden zusammenhängenden Bereiche werden
%    ignoriert (kann für Kommentare genutzt werden). Die Liste besteht aus einer
%    Titelzeile, 1. Spalte laufende Nummern der Jobs, 2. Spalte Links zu den
%    Parameterdateien. Die Pfade zu den Parameterdateien müssen sich in der
%    3.Spalte befinden.

%    Franz Zeilinger - 19.08.2010 - R2008b lauffähig

% Name der Parameterdatei:
xlsn = [File_Path,File_Name,'.xls'];

% Infos zur zu ladenden Listendatei einholen:
try
	[message, sheets]=xlsfinfo(xlsn);
catch ME
	% Bei Fehler leere Matrix zurückgeben, damit nachfolgende Funktionen den
	% Fehler erkennen können:
	Joblist = [];
	return;
end
% Name des Worksheets, in dem die Job-Liste aufglistet sein müssen:
wshn_param = 'Joblist';
% Überprüfen, ob dieses vorhanden ist:
if ~any(strcmpi(wshn_param, sheets))
	Joblist = [];
	return;
end
% Daten einlesen:
[numeric, text, raw_data] = xlsread(xlsn,wshn_param);

% Suchen nach Beginn der Liste (nach ersten NaN, d.h. leerer Zeile):
for i=1:size(raw_data,1)
	if isnan(raw_data{i,1})
		start_idx = i+1;
		break;
	end
end

% Wurden verschiedene Frequenzdaten in Joblistendatei gespeichert?
if strcmpi(raw_data{start_idx+2,2},'Frequ_Data:')
	Joblist = cell((size(raw_data,1)-start_idx)/2,4);
	step = 2;
else
	Joblist = cell(size(raw_data,1)-start_idx,2);
	step = 1;
end

% Extrahieren der Jobliste (erste Zeile ignorieren, da Titelzeile, Pfade zu
% Parameterdateien befinden sich in der dritten Spalte):
for i=start_idx+1:step:size(raw_data,1)
	entry = raw_data{i,3};
	[path,name] = fileparts(entry);
	if step > 1
		Joblist(ceil((i-start_idx)/2),1:2)={[path,'\'],name};
		entry = raw_data{i+1,3};
		[path,name] = fileparts(entry);
		Joblist(ceil((i-start_idx)/2),3:4)={[path,'\'],name};
	else
		Joblist(i-start_idx,1:2)={[path,'\'],name};
	end
end