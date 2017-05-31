function save_model_parameters(Configuration, Model)
%SAVE_MODEL_PARAMETERS    speichert die Model-Parameter als .txt und .xls-File
%    SAVE_MODEL_PARAMETERS(CONFIGURATION, MODEL, DEVICES) erzeugt ein .txt-File
%    und ein .xls-File im Simulationspfad (definiert in der CONFIGURATION-Struktur),
%    in dem alle wichtigen Einstellungen und Parameter (MODEL-Struktur) für den
%    jeweiligen Simulationsdurchlauf gespeichert werden.

%    Franz Zeilinger - 15.08.2010

% try
	file = Configuration.Save.Data;
	sour = Configuration.Save.Source;
	
	% Konvertieren der logischen Parameter:
	Model.Use_DSM = logical(Model.Use_DSM);
	Model.Use_Same_DSM = logical(Model.Use_Same_DSM);
	% Definieren der max. Zeilenlänge im .txt Dokument:
	Line_lenght = 80;
	% Öffnen der entsprechenden Dateien:
	fileid = fopen([file.Path,file.Parameter_Name,'.txt'],'w');
	xls = XLS_Writer(); 
	
	% Speichern des Pfades zur Quelldatei der Parameter (für Nachvollziebarkeit
	% zusätzlich als Hyperlink im .xls-File)
	filestr = [sour.Path, sour.Parameter_Name,'.xls'];
	filestr = strrep(filestr,'\','\\');
	fprintf(fileid,['Daten-Quelle: ',filestr,'\n\n']);
	xls.write_lines({'Daten-Quelle:','',['=HYPERLINK("',sour.Path,'"&"',...
		sour.Parameter_Name,'"&".xls";"',sour.Parameter_Name,'"&".xls")'],...
		[sour.Path, sour.Parameter_Name,'.xls']});
	xls.next_row;
	% Überschriften für Simulationseinstellungen:
	write_txt_header(fileid,'SIMULATIONSEINSTELLUNGEN',Line_lenght,'=')
	xls.write_lines('Simulation Settings:');
	xls.next_layer;
	
	% Eintragen der Simulationsenstellungen:
	for i=1:size(Model.Sim_Param_Pool,1)
		name = Model.Sim_Param_Pool{i,1};
		idx = find(strcmp(name,Model.Sim_Param_Pool(:,1)));
		if ~isempty(idx)
			fun = Model.Sim_Param_Pool{idx,2};
			fun('Write',xls, fileid, name, Model.(name), Model);
		else
			fprintf(fileid,['%s\t\tFEHLER! Keine passende'...
				'Parameterbehandlung!'], name);
			xls.write_lines({name,['FEHLER! Keine passende'...
				'Parameterbehandlung!']});
		end
	end
	
	% Überschriften für Geräteparameter:
	write_txt_header(fileid,'GERÄTEPARAMETER',Line_lenght,'=')
	fprintf(fileid, 'PARAMETERNAME\t\t   WERT(e)\t\tSTANDARDABWEICHUNG\n\n');
	xls.write_lines('Device Settings:');
	xls.next_layer;
	
	% Eintragen der Geräteparameter: möglich sind die Parameter von Geräten und von
	% Gerätegruppen
	elements = [Model.Device_Groups_Pool; Model.Devices_Pool(:,1:2)];
	for i=1:size(elements,1)
		name = elements{i,1};
		% Ist die Gerätegruppe oder das Gerät aktiv, dann speichern der Parameter:
		if (isfield(Model.Device_Assembly, name) && ...
				Model.Device_Assembly.(name)) || ...
				(isfield(Model.Device_Assembly_Simulation, name) && ...
				Model.Device_Assembly_Simulation.(name))
			write_txt_header(fileid, elements{i,2},Line_lenght,'-')
			xls.write_lines(elements{i,2});
			args = Model.Args.(name);
			xls.next_layer;
			% Schreiben aller angegebenen Geräteparameterwerte:
			for j=1:3:numel(args)
				parameter = args{j};
				idx = find(strcmp(parameter,Model.Parameter_Pool(:,1)));
				if ~isempty(idx)
					fun = Model.Parameter_Pool{idx,2};
					fun('Write',xls, fileid, args{j}, args{j+1}, args{j+2},...
						Model.Parameter_Pool{idx,3:end});
				else
					fprintf(fileid,['%s\t\tFEHLER! Keine passende'...
						'Parameterbehandlung!'], args{i});
					xls.write_lines({args{i},['FEHLER! Keine passende'...
						'Parameterbehandlung!']});
				end
			end
			xls.prev_layer;
			if Model.Use_DSM
				fprintf(fileid, '\n');
				write_txt_header(fileid,'DSM - Einstellungen',Line_lenght,'Inline');
				xls.write_lines('DSM - Settings:');
				xls.next_layer;
				args = Model.Args.([name,'_dsm']);
				% Schreiben aller angegebenen DSM-Geräteparameterwerte:
				for j=1:3:numel(args)
					parameter = args{j};
					idx = find(strcmp(parameter,Model.DSM_Param_Pool(:,1)));
					if ~isempty(idx)
						fun = Model.DSM_Param_Pool{idx,2};
						fun('Write',xls, fileid, args{j}, args{j+1}, args{j+2},...
							Model.DSM_Param_Pool{idx,3:end});
					else
						fprintf(fileid,['%s\t\tFEHLER! Keine passende'...
							'Parameterbehandlung!'], args{i});
						xls.write_lines({args{i},['FEHLER! Keine passende'...
							'Parameterbehandlung!']});
					end
				end
				xls.prev_layer;
				xls.next_row;
			end
		end
	end
	
	% Abschließen der Eintragungen und Schreiben / Schließen der Files:
	write_txt_header(fileid,Line_lenght,'=')
	fclose(fileid);
	xls.set_worksheet('Parameters');
	xlsn = [file.Path,file.Parameter_Name,'.xls']; % Dateiname .xls-File
	xls.write_output(xlsn);
% catch ME
% 	
% 	% Fehlerbehandlung:
% 	errordlg({'Ein Fehler ist beim Schreiben der Parameterdateien aufgetreten:';...
% 		' ';ME.message},'Fehler beim Schreiben der Parameterdatei');
% end
end

%Hilfsfunktion:
function write_txt_header(fileid,text,line_lenght,style)
%WRITE_TXT_HEADER    erzeugt aus einem Text eine Überschrift mit Seperatorlinien

if nargin == 4 && (length(style) == 1)
	seperation_line(1:line_lenght) = style;
	num_line = length(text);
	new_line = blanks(2*num_line);
	for i=1:num_line
		new_line(2*i-1)=text(i);
		new_line(2*i)=' ';
	end
	new_line = new_line(1:end-1);
	full_header = [seperation_line,'\n'...
		blanks(round((line_lenght-length(new_line))/2)-2),new_line,'\n',...
		seperation_line];
	
elseif nargin == 4 && (length(style) > 1) && strcmpi(style,'Inline')
	num_line = length(text);
	full_header = blanks(line_lenght);
	full_header(1:2:line_lenght) = '-';
	start_idx = round((80-num_line+2)/2);
	full_header(start_idx:start_idx+num_line+1)=[' ',text,' '];
	
elseif nargin == 3 && (length(line_lenght) == 1)
	full_header(1:text) = line_lenght;
end

fprintf(fileid,[full_header,'\n']);	
end