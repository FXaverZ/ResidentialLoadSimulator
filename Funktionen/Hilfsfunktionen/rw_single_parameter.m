function arg = rw_single_parameter(mode, obj, fileid, name, value, stddev, ...
	unity, si_un, f_val, f_std, varargin)
%RW_SINGLE_PARAMETER    ermöglicht Zugriff auf Parameter der Klasse "Einzelwert"
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_SINGLE_PARAMETER('Write', OBJ, FILEID, NAME, VALUE, STDDEV, UNITY,...
%                               SI_UN, F_VAL, F_STD) schreibt den Wert VALUE mit                          
%    der Einheit UNITY (als String anzugeben) sowie die Varianz dieses Wertes 
%    STDDEV mit der zugehörigen Einheit SI_UN in das durch FILEID angegebene 
%    txt-File sowie in das durch die XLS_Writer-Instanz OBJ definierte xls-File. 
%    Die Formatstrings (F_...) definieren die jeweilige Wertedarstellung (gem.
%    Matlab-Konvention).
%    Wird für UNITY der String 'bool' übergeben wird der Wert Value als logische
%    Variable behandelt (d.h. Ausgabe in der Form [X] bzw. [ ]).
%    Wird für SI_UN der String 'n.n.' angegeben ('not necessary' - nicht
%    notwendig) wird die Ausgabe der Werte von STDDEV unterdrückt.
%
%    ARG = RW_SINGLE_PARAMETER('Read', LINE) liest die Werte aus dem
%    [1,n]-Cell-Array DATA ein. Dieses muss bereits so aufbereitet sein, dass
%    sich in der ersten Zeile nur der Parametername und die Werte befinden.
%    Weitere Zeilen werden ignoriert! Zurückgegeben wird die 1x3-Cell ARG mit
%    der notwendigen Reihung von {'Parameter Name', 'Werte', 'Verteilung'}.

%    Franz Zeilinger - 07.09.2010

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	% Falls Einheit '%' für die fprintf-Funktion diese in '%%' umwandeln, damit
	% diese dargestellt werden kann:
	if strcmp(unity,'%')
		unity_txt = '%%';
	else
		unity_txt = unity;
	end
	if strcmp(si_un,'%')
		si_un_txt = '%%';
	else
		si_un_txt = unity;
	end
	% Name des Parameters schreiben:
	dist = blanks(24-length(name));
	fprintf(fileid,['%s',dist], name);
	obj.write_values(name);
	% Überprüfen, ob Wert ein logischer Wert sein sollte:
	if strcmpi(unity,'bool')
		if value
			fprintf(fileid, ['[X]','\n']);
			value = 1;
		else
			fprintf(fileid, ['[ ]','\n']);
			value = 0;
		end
		obj.write_values(value);
		obj.next_row;
		return;
	end
	% Werte schreiben
	fprintf(fileid,[f_val,' ',unity_txt,'\t\t\t'], value);
	obj.write_values({value,unity});
	% Falls Angabe von STDDEV nicht notwendig ist:
	if ~strcmpi(si_un,'n.n.') 
		if ischar(stddev)
			fprintf(fileid,stddev);
			obj.write_values({stddev});
		else
			fprintf(fileid,[f_std,' ',si_un_txt], stddev);
			obj.write_values({stddev,si_un});
		end
	end
	fprintf(fileid,'\n');
	obj.next_row;

% Lesemodus:
elseif strcmpi(mode,'read')
	line = obj;
	% Einlesen der Parameter aus der ersten Zeile ohne Einheiten und Rückgabe der 
	% Werte (1.Spalte: Name, 2.Spalte Wert, 4.Spalte Varianz): 
	arg = {line{1,1},line{1,2},line{1,4}};
	if isnan(line{1,4})
		% Falls kein Wert angegeben wurden, Varianz auf Null, da für die
		% Dreier-Gruppierung der Parameter ein Dummy-Wert eingefügt werden muss:
		arg{3} = 0;
	end
	if isnan(line{1,2})
		% Falls kein Wert angegeben wurde NaN durch leere Zelle ersetzten, da
		% dies bei einer eventuellen Geräteinstanzerzeugung zu einem Fehler
		% führt!
		arg{2} = [];
	end
	%Zurückgeben des Parameter-Trippels.
end