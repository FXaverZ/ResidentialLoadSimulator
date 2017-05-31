function arg = rw_sim_parameter(mode, obj, fileid, name, value, varargin)
%RW_SIM_PARAMETER    ermöglicht Zugriff auf die Simulationseinstellungen
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_SIM_PARAMETER ('Write', OBJ, FILEID, NAME, VALUE) schreibt den Wert
%    VALUE in das durch FILEID angegebene txt-File sowie in das durch die
%    XLS_Writer-Instanz OBJ definierte xls-File. Je nach Art des Datentyps von
%    VALUE (String, Numeric oder Logical) erfolgt eine dem Datentyp entsprechende 
%    Form der Ausgabe.    
%
%    ARG = RW_SIM_PARAMETER('Read', LINE) liest aus dem [1,m]-Cell-Array die
%    jeweilige Simulationseinstellung heraus. In der ersten Zelle darf sich nur
%    der Name des Parameters befinden, irgendwo danach in der Zeile der Wert.
%    Alle weiteren Einträge werden ignoriert.
%    Falls im Parametername der Teilstring 'Date' vorkommt, wird der Parameter
%    als Datum erkannt und gesondert behandelt, damit als Rückgabewert der für
%    das Simulationsprogramm notwendige Datums-String zur Verfügung steht.

%    Franz Zeilinger - 27.07.2011

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	dist = blanks(20-length(name));
	fprintf(fileid, ['\t',name,dist]);
	obj.write_values(name);
	if length(name) > 10
		obj.next_col;
	end
	
	if ~isempty(findstr('Date',name))
		% Besondere Behandlung, falls ein Datum mit Zeit vorliegt:
		if length(arg) > 10
			arg = datestr(datenum(arg,'dd.mm.yyyy HH:MM:SS'));
		elseif length(arg) == 10
			arg = datestr(datenum(arg,'dd.mm.yyyy'));
		end
	end
	
	if ischar(value)
		fprintf(fileid, ['''',value,'''\n']);
	elseif isnumeric(value)
		fprintf(fileid, [num2str(value),'\n']);
	elseif islogical(value)
		if value
			fprintf(fileid, ['[X]','\n']);
			value = 1;
		else
			fprintf(fileid, ['[ ]','\n']);
			value = 0;
		end
	end
	
	obj.write_values(value)
	obj.next_row;

% Lesemodus
elseif strcmpi(mode,'read')
	line = obj;
	for i=2:size(line,2)
		arg = line{1,i};
		if ~isnan(arg)
			break;
		end
	end
	if ~isempty(findstr('Date',line{1,1}))
		% Besondere Behandlung, falls ein Datum mit Zeit vorliegt:
		if length(arg) > 10
			arg = datestr(datenum(arg,'dd.mm.yyyy HH:MM:SS'));
		elseif length(arg) == 10
			arg = datestr(datenum(arg,'dd.mm.yyyy'));
		end
	end
end
end