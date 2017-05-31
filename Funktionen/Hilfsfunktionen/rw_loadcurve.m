function arg = rw_loadcurve(mode, obj, fileid, name, loadcurve, sigma, varargin)
%RW_LOADCURVE    ermöglicht Zugriff auf Parameter der Klasse "Lastgang"
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_LOADCURVE('Write', OBJ, FILEID, NAME, LOADCURVE, SIGMA) schreibt den
%    Lastgang LOADCURVE in das durch FILEID angegebene txt-File sowie in das
%    durch die XLS_Writer-Instanz OBJ definierte xls-File. SIGMA enthält die zu
%    erzielende Standardverteilung der Lastkurve bei einer Parametervariierung.
%    Die Lastkurve eines Geräts ist eine [m,2]-Matrix der Form:
%    LOADCURCE [m,2]:    [Dauer (in min),       Leistung (in W)]
%    SIGMA     [1,2]:    [Varianz Dauer (in %), Varianz Leistung (in %)]
%    Es können aber ebenso mehrere Lastkurven nebeneinander definiert werden,
%    die Anzahl ist beliebig. Die Wahrscheinlichkeit für eine Lastkurve wird in
%    einem eigenen Parameter definiert (siehe Klasse LOADCURVE_OPERATION). SIGMA
%    ist dann entweder für alle Lastkurven gleich ([1,2]-Vektor) oder wird für
%    jede Laskurve extra definiert ([1,2n]-Vektor für n Lastkurven)!
%
%    ARG = RW_LOADCURVE('Read', DATA) liest die Lastkurve aus dem Cell-Array
%    DATA ein. Dieses muss bereits so aufbereitet sein, dass sich darin nur die
%    Lastkurve befinden (inkl. Titelzeile). Zurückgegeben wird die 1x3-Cell ARG
%    mit der notwendigen Reihung von {'Parameter Name', 'Werte', 'Verteilung'}.

%    Franz Zeilinger - 24.08.2010

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	% Wieviele Lastkurven kommen vor:
	num_loadc = floor(size(loadcurve,2)/2);
	% Titelzeile Schreiben (Spaltenüberschrift):
	header =' min     W     ';
	header = repmat(header,[1,num_loadc]);
	fprintf(fileid,['%s\t\t   ',header,'\n'], name);
	header = {'min','W'};
	header = repmat(header,[1,num_loadc]);
	obj.write_lines([{name},header]);
	% Schreiben der Lastkurve in der Form:
	% Loadcurve             min     W
	%      |              [  1     100
	%      |                10      50
	%      |                 1     100 ]
	%      '-> STDABW.:   [ 10      20 ] %
	for i=1:size(loadcurve,1)
		% Erste Zeile Anfang:
		if i == 1
			fprintf(fileid,'\t|\t\t\t[ ');
			% dazwischenliegende Zeilen:
		elseif (i >1)
			fprintf(fileid,'\t|\t\t\t  ');
		end
		for j=1:num_loadc
			time = loadcurve(i,2*j-1);
			powe = loadcurve(i,2*j);
			% Überpfrüfen, ob NaNs vorliegen, diese dann nicht ausgeben:
			if isnan(time)
				fprintf(fileid,blanks(7));
			else
				fprintf(fileid,'%5.1f, ',time);
			end
			if isnan(powe)
				fprintf(fileid,blanks(6));
				if j < num_loadc
					fprintf(fileid,'  ');
				end
			else
				fprintf(fileid,'%6.1f',powe);
				% Bei dazwischenliegenden Werten Folgebeistrich einfügen:
				if j < num_loadc
					if isnan(loadcurve(i,2*j+1))
						fprintf(fileid,'  ');
					else
						fprintf(fileid,', ');
					end
				end
			end
			% Ende der Zeile Semikolon einfügen:
			if j == num_loadc && (i < size(loadcurve,1))
				fprintf(fileid,';\n');
			end
		end
		% Letzter Eintrag:
		if i == size(loadcurve,1)
			fprintf(fileid,' ]\n');
		end
		obj.write_values([{'    |'},num2cell(loadcurve(i,:))]);
		obj.next_row;
	end
	% Formatstring einer Zeile definieren:
	sigma_fstr = '%5.1f, %6.1f, ';
	sigma_fstr = repmat (sigma_fstr,[1,floor(size(sigma,2)/2)]);
	sigma_fstr = sigma_fstr(1:end-2); %letzten Beistrich entfernen
	% Streuungen schreiben:
	fprintf(fileid,['\t''-> STDABW.:\t[',sigma_fstr,' ] %%\n'],...
		sigma);
	obj.write_lines([{'    ''-> Std.Dev.:'},...
		num2cell(sigma),{'%'}]);
	obj.next_row;
	
% Lesemodus:
elseif strcmpi(mode,'read')
	data = obj;
	% Überprüfen, wie viele Lastkurven angegeben sind:
	end_row_idx = 0;
	for j=1:size(data,2)
		if isnan(data{2,j})
			end_col_idx = j-1;
			break;
		end
		% Suchen nach dem letzten Eintrag in der Liste, merken der längsten
		% Liste:
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
		% Entnehmen der Lastkurve aus DATA (letzte Zeile enthält Varianzen):
		loadc = cell2mat(data(2:end_row_idx-1,2:end_col_idx));
		% Entnehmen der Varianzen (zuerst suchen nach letzten Eintrag):
		for j=1:size(data,2)
			if isnan(data{end_row_idx,j})
				end_col_idx = j-1;
				break;
			end
			if j == size(data,2)
				end_col_idx = j;
			end
	end
		sig = cell2mat(data(end_row_idx,2:end_col_idx-1));
	else
		% Falls keine Werte angegeben wurden, NaN durch leere Zelle ersetzten, dass
		% dies bei einer eventuellen Geräteinstanzerzeugung zu einem Fehler
		% führt!
		loadc = [];
		sig = [];
	end
	%Zurückgeben des Parameter-Trippels:
	arg = {data{1,1}, loadc, sig};
end
end