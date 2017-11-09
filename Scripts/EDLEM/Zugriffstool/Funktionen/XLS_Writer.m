classdef XLS_Writer < handle
	%XLS_WRITER    Klasse zur Erstellung von und Navigation in .xls - Files
	%    Mit Hilfe der verschiedenen Funktionen kann ein Output-Cell-Array
	%    bearbeitet werden, welches die fertige .xls-Datei repräsentiert. Es 
	%    werden auch mehrere Arbeitsblätter unterstützt.
	%    Mit Hilfe des Befehls WRITE_OUTPUT(XLSN) wird dann das
	%    Output-Cell-Array als .xls-Datei abgespeichert.
	%
	%    Franz Zeilinger - 14.06.2011
	
	properties
		row_count  %Aktuelle Zeile
		col_count  %Aktuelle Spalte
		layer      %Aktuelle Datenebene (d.h. Startspalte für neue Zelle)
		wsheets    %Namen der definierten Worksheets
		wsh_count  %Aktuelles Worksheet (Arbeitsblatt)
	end
	properties (Hidden)
		output     %Cell-Array das der .xls-Datei entspricht
	end
	
	methods
		function obj = XLS_Writer()
			%XLS_WRITER     Konstruktor der Klasse XLS-Writer
			%    Setzen verschiedner Parameter und des Default-Worksheets (in das 
			%    die ersten Daten geschrieben werden).
			
			obj.wsheets = {};
			obj.wsh_count = 1;
			obj.row_count.(['WSH',num2str(obj.wsh_count)]) = 1;
			obj.col_count.(['WSH',num2str(obj.wsh_count)]) = 1;
			obj.layer.(['WSH',num2str(obj.wsh_count)])  = 1;
			obj.output.(['WSH',num2str(obj.wsh_count)]) = {};
		end
		
		function write_output(obj, xlsn, varargin)
			%WRITE_OUTPUT    Erzeugt ein .XLS-File aus den bisherigen Daten
			%    WRITE_OUTPUT(XLSN) erzeugt das .xls-File mit dem Namen xlsn mit
			%    den vorher definierten Arbeitsblättern. Wurde kein Arbeitsblatt
			%    definiert,werden die Daten in das erste Arbeitsblatt eingefügt
			%
			%    WRITE_OUTPUT(XLSN, WSHN) schreibt die Daten in das neue 
			%    Arbeitsblatt 'WSHN' sofern kein anderes definiert wurde.
			%
			%    WRITE_OUTPUT(XLSN, WSHN, START_CELL) schreibt die Daten 
			%    beginnend mit der Zelle, die in START_CELL definiert wurde 
			%    (gem. MS Excel Anforderungnen)
			
			% Warnungen für neue Tabelle ignorieren (uninteressant):
			warning off MATLAB:xlswrite:AddSheet
			if numel(obj.wsheets) == 0
				% Es wurden von vornherein keine Arbeitsblattnamen angegeben:
				out = obj.output.(['WSH',num2str(obj.wsh_count)]);
				if nargin == 2
					xlswrite(xlsn, out, 1, 'A1');
				elseif nargin == 3
					xlswrite(xlsn, out, varargin{1}, 'A1');
				elseif nargin == 4
					xlswrite(xlsn, out, varargin{1}, varargin{2});
				end
			else
				for i=1:numel(obj.wsheets)
					outp = obj.output.(['WSH',num2str(i)]);
					wshn = obj.wsheets{i};
					xlswrite(xlsn, outp, wshn, 'A1');
				end
			end
		end
		
		function write_lines(obj, input)
			%WRITE_LINES    schreibt eine komplette Zeile
			%    WRITE_LINES(INPUT) schreibt komplette Zeilen mit Inhalt INPUT,
			%    welcher ein Cell-Array, ein String oder auch ein 2D-Array sein
			%    kann. Nach Ende von INPUT, wird in die nächste freie Zeile
			%    gesprungen.
			
			obj.write_values(input);
			obj.next_row;
		end
		
		function write_values(obj, input)
			%WRITE_VALUES    schreibt beliebige Daten in Output Cell-Array
			%    WRITE_VALUES(INPUT) schreibt den Inhalt von INPUT, welcher
			%    ein Cell-Array, ein String oder auch ein 2D-Array sein kann, in
			%    das Output-Cell-Array.
			
			% Ermitteln der jeweiligen Zeilen und Spalten sowie aktuelle
			% Position:
			[rows, cols] = size(input);
			row_c = obj.row_count.(['WSH',num2str(obj.wsh_count)]);
			col_c = obj.col_count.(['WSH',num2str(obj.wsh_count)]);
			% verschiedene Behandlung der INPUT-Daten je nach vorliegender
			% Struktur:
			if ischar(input)
				% Bei Übergabe eines Strings, diesen in eine Zelle schreiben und
				% zur nächsten Spalte springen.
				obj.output.(['WSH',num2str(obj.wsh_count)])...
					(row_c,col_c)={input};
				obj.col_count.(['WSH',num2str(obj.wsh_count)]) = ...
					col_c + 1;
			else
				if isnumeric(input)
					% Numerisches Array in ein Cell-Array umwandeln
					input_cell = num2cell(input);
				elseif iscell(input)
					% ist INPUT bereits ein Cell-Array, dieses übernehmen
					input_cell = input;
				end
				% Daten in OUTPUT schreiben:
                obj.output.(['WSH',num2str(obj.wsh_count)])...
					(row_c:row_c+rows-1, col_c:col_c+cols-1)= input_cell;
				% Aktuelle Position ermitteln (nach Eintrag der Daten):
				obj.row_count.(['WSH',num2str(obj.wsh_count)]) = ...
					row_c + rows - 1;
				obj.col_count.(['WSH',num2str(obj.wsh_count)]) = ...
					col_c + cols;
			end
		end
		
		function write_list_col(obj, list)
			%WRITE_LIST_COL    erzeugt eine Liste in einer Zeile
			%    WRITE_LIST_COL(LIST) nimmt die Einträge von LIST und schreibt
			%    diese in eine Zeile des Output-Arrays
			
			for i=1:size(list,1)
				obj.write_values({list(i,:)});
			end
		end
		
		function next_row(obj, varargin)
			%NEXT_ROW    springen in die nächste Zeile
			%    NEXT_ROW() sorgt für den Beginn einer neuen Zeile. Die
			%    Beginn-Spalte zurückgesetzt (auf die aktuelle Ebene)
			%    
			%    NEXT_ROW(NUM_ROWS) fügt NUM_ROWS leere Zeilen ein. NUM_ROWS 
			%    kann auch negativ sein, so kann um NUM_ROWS zurückgesprungen 
			%    werden.
			
			row = obj.row_count.(['WSH',num2str(obj.wsh_count)]);
			if nargin == 1
				row = row + 1;
			elseif nargin == 2
				row = row + varargin{1};
				if row < 0
					row = 1;
				end
			end
			obj.col_count.(['WSH',num2str(obj.wsh_count)]) = ...
				obj.layer.(['WSH',num2str(obj.wsh_count)]);
			obj.row_count.(['WSH',num2str(obj.wsh_count)]) = row;
		end
		
		function next_col(obj, varargin)
			%NEXT_COL    springen in die nächste Spalte
			%    NEXT_COL() sorgt für den Beginn einer neuen Spalte in der 
			%    aktuellen Zeile.
			%    
			%    NEXT_COL(NUM_COLS) fügt NUM_COLS leere Spalten in der aktuellen
			%    Zeilen ein. NUM_COLS kann auch negativ sein, so kann um  
			%    NUM_COLS zurückgesprungen werden.
			
			col = obj.col_count.(['WSH',num2str(obj.wsh_count)]);
			if nargin == 1
				col = col + 1;
			elseif nargin == 2
				col = col + varargin{1};
				if col < 0
					col = 1;
				end
			end
			obj.col_count.(['WSH',num2str(obj.wsh_count)]) = col;
		end
		
		function next_layer(obj, varargin)
			%NEXT_LAYER    erhöhen der aktuellen Datenebene
			%    NEXT_LAYER() sorgt für das Springen in die nächste Datenebene,
			%    d.h. dass die Beginnspalte für eine neue Zeile von nun an eine
			%    weiter rechts ist. Entspricht einem Einrücken der kommenden
			%    Daten für eine bessere Unterscheidung
			%
			%    NEXT_LAYER(NUM_LAYER) fügt NUM_LAYER Datenebenen ein. NUM_LAYER
			%    wird als positive Zahl interpretiert.
			
			lay = obj.layer.(['WSH',num2str(obj.wsh_count)]);
			if nargin == 1
				lay = lay + 1;
			elseif nargin == 2
				lay = lay + abs(varargin{1});
			end
			obj.col_count.(['WSH',num2str(obj.wsh_count)]) = lay;
			obj.layer.(['WSH',num2str(obj.wsh_count)]) = lay;
		end
		
		function prev_layer(obj, varargin)
			%PREV_LAYER    erniedrigen der aktuellen Datenebene
			%    PREV_LAYER() reduziert die aktuelle Datenebene um eins, d.h.
			%    die Beginnspalte für eine neue Zeile ist eine Spalter weiter
			%    links.
			%
			%    PREV_LAYER(NUM_LAYER) reduziert die aktuelle Datenebene um
			%    NUM_LAYER Ebenen. NUM_LAYER wird dabei als positve Zahl
			%    interpretiert.
			
			lay = obj.layer.(['WSH',num2str(obj.wsh_count)]);
			if nargin == 1
				if lay > 1
					lay = lay - 1;
				else
					lay = 1;
				end
			elseif nargin == 2
				if lay > abs(varargin{1})
					lay = lay - abs(varargin{1});
				else
					lay = 1;
				end
			end
			obj.col_count.(['WSH',num2str(obj.wsh_count)]) = lay;
			obj.layer.(['WSH',num2str(obj.wsh_count)]) = lay;
		end
		
		function reset_layer(obj)
			%RESET_LAYER setzt die aktuelle Datenebene auf die erste Ebene.
			
			obj.layer.(['WSH',num2str(obj.wsh_count)]) = 1;
		end
		
		function set_worksheet(obj, wshn)
			%SET_WORKSHEET wechselt zu einem anderen Arbeitsblatt
			%    SET_WORKSHEET(WSHN) wechselt zum Arbeitsblatt mit dem Namen
			%    WSHN. Ist dieses nicht vorhanden, wird ein neues Arbeitsblatt
			%    mit diesem Namen erzeugt. Wird SET_WORKSHEET zum ersten mal
			%    aufgerufen, werden alle bisherigen Daten dem Arbeitsblatt WSHN
			%    zugeordnet!
			
			ind = find(strcmpi(wshn, obj.wsheets));
			if isempty(ind)
				obj.wsheets(end+1) = {wshn};
				obj.wsh_count = numel(obj.wsheets);
				obj.row_count.(['WSH',num2str(obj.wsh_count)]) = 1;
				obj.col_count.(['WSH',num2str(obj.wsh_count)]) = 1;
				obj.layer.(['WSH',num2str(obj.wsh_count)])  = 1;
			else
				obj.wsh_count = ind;
			end
		end
	end
end

