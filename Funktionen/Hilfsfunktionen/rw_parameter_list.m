function arg = rw_parameter_list(mode, obj, fileid, name, values, stddev, unity,...
	si_un, f_val, f_sig, f_val_list, f_sig_list, varargin)
%RW_PARAMETER_LIST    ermöglicht Zugriff auf Parameter der Klasse "Liste"
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_PARAMETER_LIST('Write', OBJ, FILEID, NAME, VALUES, STDDEV, UNITY, SI_UN,...
%                               F_VAL, F_SIG, F_VAL_LIST, F_SIG_LIST) schreibt
%    die Parameterliste angegeben in VALUES in das durch FILEID angegebene
%    txt-File sowie in das durch die XLS_Writer-Instanz OBJ definierte xls-File.
%    UNITY gibt die Einheit von VALUES (als String), STDEV die zu erzielende
%    Standardabweichung bei einer Parametervariation und SI_UN die Einheit von
%    STDDEV an. Die Formatstrings (F_...) definieren die jeweilige
%    Wertedarstellung (gem. Matlab-Konvention).
%    Beim Schreiben der Liste wird zwischen einem Einzeleintrag (Liste der Länge
%    1) sowie einer echten Liste (Liste der Länge größer 1) unterschieden:
%    Länge = 1: die Format-Strings F_VAL und F_SIG werden verwendet. Die beiden
%               Werte werden mit ihrer Einheit gemeinsam in eine Zeile
%               geschrieben (ähnlich bei RW_SINGLE_PARAMETER).
%    Länge > 1: die Format-Strings F_VAL_LISR und F_SIG_LISR werden verwendet.
%               In der ersten Zeile werden die Werte von VALUES geschrieben, in
%               der zweiten Zeile jene von STDDEV.
%    Wird für SI_UN der String 'n.n.' angegeben ('not necessary' - nicht
%    notwendig) wird die Ausgabe der Werte von STDDEV unterdrückt.
%    Sowohl VALUES als auch SIGMA sind [m,1] bzw. [1,1]-Spaltenvektoren.
%
%    ARG = RW_PARAMETER_LIST('Read', DATA) liest die Werte der Parameterliste
%    aus dem Cell-Array DATA ein. Dieses muss bereits so aufbereitet sein, dass
%    sich darin nur die notwendigen Daten befinden (inkl. Titelzeile). Wurde bei
%    den Werten als Einheit 'Uhr' angegeben, werden die eingelesenen Werte in
%    einen Uhrzeitstring der Form 'HH:MM' umgewandelt.
%    Zurückgegeben wird die 1x3-Cell ARG mit der notwendigen Reihung von
%    {'Parameter Name', 'Werte', 'Verteilung'}.
%
%    Franz Zeilinger - 10.08.2010

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	% Name des Parameters schreiben:
	dist = blanks(24-length(name));
	fprintf(fileid,['%s',dist], name);
	obj.write_values(name);
	
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
	
	if (numel(values) == 1) && (numel(stddev) == 1)
		% Liste der Länge 1:
		fprintf(fileid,[f_val,' ',unity_txt,'\t\t\t'], values);
		obj.write_values({values,unity});
		% Falls Angabe von STDDEV nicht notwendig ist:
		if ~strcmpi(si_un,'n.n.')
			fprintf(fileid,[f_sig,' ',si_un_txt], stddev);
			obj.write_values({stddev,si_un});
		end
		fprintf(fileid,'\n');
		obj.next_row;
	else
		% Liste der Länge > 1: Zuerst schreiben der Werte in eine Zeile:
		fprintf(fileid,'[');
		for i=1:size(values,1)-1
			fprintf(fileid,[f_val_list,'; '],values(i,:));
		end
		fprintf(fileid,[f_val_list,']'],values(i+1,:));
		fprintf(fileid, [' ', unity_txt,'\n']);
		obj.write_list_col(values);
		obj.write_values(unity);
		obj.next_row;
		if ~strcmpi(si_un,'n.n.')
			% Beschriftung für die Zeile mit den Varianzen einfügen:
			fprintf(fileid,'\t''-> STDABW.:\t');
			obj.write_values('    ''-> Std.Dev.:');
			if numel(stddev) == 1
				% Nur ein Wert angegeben:
				fprintf(fileid,['  ',f_sig,' ',si_un_txt,'\n'], stddev);
			else
				% Mehrere Werte wurden angegeben, diese nebeneinander in die
				% Zeile schreiben:
				fprintf(fileid,'[');
				for i=1:size(stddev,1)-1
					fprintf(fileid,[f_sig_list,'; '],stddev(i,:));
				end
				fprintf(fileid,[f_sig_list,']'],stddev(i+1,:));
				fprintf(fileid, [' ', si_un_txt,'\n']);
			end
			% Das selbe für das xls-File:
			obj.write_list_col(stddev);
			obj.write_values(si_un);
			obj.next_row;
		end
	end
	
% Lesemodus:
elseif strcmpi(mode,'read')
	data = obj;
	% Finden des Endes der Liste (bei ersten auftretenden NaN):
	for i=1:size(data,2)
		if isnan(data{1,i})
			end_indx = i-1;
			break;
		end
		if i == size(data,2)
			end_indx = i;
		end
	end
	if end_indx > 1
		% Werte auslesen (letzter Wert ist Einheit):
		values = cell2mat(data(1,2:end_indx-1));
	else
		% Falls kein Wert angegeben wurde NaN durch leere Zelle ersetzten, dass
		% dies bei einer eventuellen Geräteinstanzerzeugung zu einem Fehler
		% führt!
		values = [];
	end
	if strcmpi(data{1,end_indx},'uhr')
		% Falls als Einheit 'Uhr' angegeben wurde, Werte in Uhrzeitstring
		% umwandeln (erzeugt automatisch einen Spaltenvektor):
		values = datestr(values,'HH:MM');
	else
		% Umwandeln des Zeilen- in einen Spaltenvektor:
		values = values';
	end

	if size(data,1) > 1
		% Falls eine zweite Zeile vorhanden ist, sind dort die Werte für die
		% Standardabweichung zu finden. Ermitteln der Länge der Liste (bis zum
		% ersten NaN):
		for i=1:size(data,2)
			if isnan(data{2,i})
				end_indx = i-1;
				break;
			end
			if i == size(data,2)
				end_indx = i;
			end
		end
		% Auslesen der Werte, letzer Eintrag ist die Einheit. Umwandeln des
		% Zeilenvektors in einen Spaltenvektor:
		if end_indx > 1
			% Werte wurden gefunden:
			sig = cell2mat(data(2,2:end_indx-1))';
		else
			% Falls keine Werte angegeben wurden, Varianz auf Null, da für die
			% Dreier-Gruppierung der Parameter ein Dummy-Wert eingefügt werden muss:
			sig = 0;
		end
	else
		% Falls keine Werte angegeben wurden, Varianz auf Null, da für die
		% Dreier-Gruppierung der Parameter ein Dummy-Wert eingefügt werden muss:
		sig = 0;
	end
	%Zurückgeben des Parameter-Trippels:
	arg = {data{1,1}, values, sig};
end
end