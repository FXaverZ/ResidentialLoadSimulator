function arg = rw_dsm_modus(mode, obj, fileid, name, list, proba, varargin)
%RW_DSM_MODUS    ermöglicht Zugriff auf Parameter der Klasse "DSM Modus"
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_DSM_MODUS('Write', OBJ, FILEID, NAME, LIST, PROBA) schreibt die DSM
%    Moden für NAME (entweder DSM-Input oder DSM-Output) in das durch FILEID
%    angegebene txt-File und das durch die XLS_Writer-Instanz OBJ definierte
%    xls-File. LIST enthält alle DSM-Moden, PROBA deren Verteilung (in %).
%
%    ARG = RW_DSM_MODUS('Read', DATA) liest die DSM-Moden aus dem Cell-Array
%    DATA ein. Dieses muss bereits so aufbereitet sein, dass sich darin nur die
%    DSM-Moden befinden (inkl. Titelzeile). Zurückgegeben wird die 1x3-Cell ARG
%    mit der notwendigen Reihung von {'Parameter Name', 'Werte', 'Verteilung'}.
%
%    Franz Zeilinger - 10.08.2010

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	% Ausgabe der DSM-Moden: Zuerst schreiben des Namen des Parameters
	fprintf(fileid,'\n');
	obj.next_row;
	fprintf(fileid,'%s\t\t', name);
	obj.write_values(name);
	if ischar(list)
		% Falls nur ein Parameter vorhanden, eine einfache Zeile mit
		% 'Name','DSM-Modus' schreiben:
		fprintf(fileid,'%s\n', list);
		obj.write_lines({list});
	elseif iscell(list)
		% Bei mehreren angegegbenen Parametern (in einem Cell-Array) wird eine
		% Auflistung mit Verteilungspfeilen ausgegeben, in der Form:
		% NAME
		%   +---> PARAMETER 1   -->  XX%
		%   +---> PARAMETER 2   -->  XX%
		%   '---> PARAMETER 3   -->  XX%
		fprintf(fileid,'\n');
		obj.next_row;
		% Für alle Einträge:
		for i=1:numel(list)
			% Schreiben der Verteilungspfeile:
			if i<=(numel(list)-1)
				fprintf(fileid,    '\t+---> ');
				obj.write_values('    +---> ');
			else
				fprintf(fileid,    '\t''---> ');
				obj.write_values('    ''---> ');
			end
			% DSM-Modus schreiben:
			fprintf(fileid,'%s', list{i});
			obj.write_values({list{i}});
			% Folgepfeil und Verteilung schreiben:
			dist = blanks(30-length(list{i}));
			fprintf(fileid,[dist,'-->  %5.1f %%\n'], proba(i));
			% um mehrere Spaltern rüberspringen (für Lesbarkeit im xls-File).
			% Verteilung der Moden damit nun in der 6. Spalte vom NAME
			% weggezählt:
			obj.next_col(2);
			obj.write_values({'-->', proba(i),'%'});
			obj.next_row;
		end
	else
		% Falls keine passende Behandlung möglich, dies in die Ausgabe
		% schreiben:
		fprintf(fileid,'%s\t\tFEHLER! Keine passende Parameterbehandlung!', name);
		xls.write_lines({name,'FEHLER! Keine passenden Parameterbehandlung!'});
	end
	fprintf(fileid,'\n');

% Lesemodus:
elseif strcmpi(mode,'read')
	data = obj;
	end_indx = 0;
	% Nachsehen, ob Zelle neben Parameternamen nicht befüllt ist (NaN):
	if isnan(data{1,2})
		% Wenn ja, wurden mehrere DSM-Moden angegeben. Ermitteln wie lange diese
		% Liste ist (in 2. Spalte stehen die Moden, suchen des ersten NaN in
		% dieser Spalte --> hier ist Liste zu Ende):
		for i=2:size(data,1)
			if isnan(data{i,2})
				end_indx = i-1;
				break;
			end
			if i == size(data,1)
				end_indx = i;
			end
		end
		if end_indx > 0
			% Die Modennamen sind in der 2. Spalte
			mods = data(2:end_indx,2)';
			% Die Verteilung in der 6. Spalte (siehe Schreib-Modus dieser Funktion)
			sig = cell2mat(data(2:end_indx,6));
		else
			% Falls keine Werte angegeben wurden, NaN durch leere Zelle ersetzten, dass
			% dies bei einer eventuellen Geräteinstanzerzeugung zu einem Fehler
			% führt!
			mods = [];
			sig = [];
		end
	else
		% nur ein DSM-Modus wurde angegeben (befindet sich neben Namen):
		mods = data{1,2};
		% Verteilung auf Null, da Wert ohne Bedeutung (für Dreier-Gruppierung der
		% Parameter muss ein Dummy-Wert eingefügt werden):
		sig = 0;
	end
	%Zurückgeben des Parameter-Trippels:
	arg = {data{1,1}, mods, sig};
end
end