function arg = rw_loadcurve_parts(mode, obj, fileid, name, loadc_parts, varargin)
%RW_LOADCURVE_PARTS    ermöglicht Zugriff auf Parameter der Klasse "Lastgangteilung"
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    BESCHREIBUNG FEHLT!

%    Franz Zeilinger - 27.07.2011

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	% Wieviele Lastkurven kommen vor:
	num_loadc = floor(size(loadc_parts,2)/2);
	% Titelzeile Schreiben (Spaltenüberschrift):
	header ='  Start   End  ';
	header = repmat(header,[1,num_loadc]);
	fprintf(fileid,['%s ',header,'   (Indexes)\n'], name);
	header = {'Start_idx','End_idx '};
	header = repmat(header,[1,num_loadc]);
	obj.write_lines([{name},header]);
	% Schreiben der ununterbrechbaren Lastkurveteile:
	for i=1:size(loadc_parts,1)
		% Erste Zeile Anfang:
		if i == 1
			fprintf(fileid,'\t\t\t\t[ ');
			% dazwischenliegende Zeilen:
		elseif (i >1)
			fprintf(fileid,'\t\t\t\t  ');
		end
		for j=1:num_loadc
			start_idx = loadc_parts(i,2*j-1);
			end_idx = loadc_parts(i,2*j);
			% Überpfrüfen, ob NaNs vorliegen, diese dann nicht ausgeben:
			if isnan(start_idx)
				fprintf(fileid,blanks(7));
			else
				fprintf(fileid,'%5.0f, ',start_idx);
			end
			if isnan(end_idx)
				fprintf(fileid,blanks(6));
				if j < num_loadc
					fprintf(fileid,'  ');
				end
			else
				fprintf(fileid,'%6.0f',end_idx);
				% Bei dazwischenliegenden Werten Folgebeistrich einfügen:
				if j < num_loadc
					if isnan(loadc_parts(i,2*j+1))
						fprintf(fileid,'  ');
					else
						fprintf(fileid,', ');
					end
				end
			end
			% Ende der Zeile Semikolon einfügen:
			if j == num_loadc && (i < size(loadc_parts,1))
				fprintf(fileid,';\n');
			end
		end
		% Letzter Eintrag:
		if i == size(loadc_parts,1)
			fprintf(fileid,' ]\n');
		end
		obj.write_values([{''},num2cell(loadc_parts(i,:))]);
		obj.next_row;
	end

	
% Lesemodus:
elseif strcmpi(mode,'read')
	data = obj;
	% Überprüfen, wie viele non-stop-Punkte angegeben sind:
	end_row_idx = 0;
	for j=2:size(data,2)
		if isnan(data{2,j})
			end_col_idx = j-1;
			break;
		end
		% Suchen nach dem letzten Eintrag in der Liste, merken der Länge der 
		% längsten Liste:
		for i=1:size(data,1)
			if isnan(data{i,j})
				if (i-1) > end_row_idx
					end_row_idx = i-1;
				end
				break;
			end
			if i == size(data,1)
				end_row_idx = i;
			end
		end
		if j == size(data,2)
			end_col_idx = j;
		end
	end
	if end_row_idx > 1
		loadc_parts = cell2mat(data(2:end_row_idx,2:end_col_idx));
	else
		% keine Werte gefunden:
		loadc_parts = [];
	end
	% Dummy-Variable einfügen:
	sig = 0;
	%Zurückgeben des Parameter-Trippels:
	arg = {data{1,1}, loadc_parts, sig};
end
end