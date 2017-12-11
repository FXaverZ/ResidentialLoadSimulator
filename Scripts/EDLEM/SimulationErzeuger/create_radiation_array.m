% Mit Hilfe dieses Scripts wird ein Array mit den Einstrahlungsdaten erzeugt, welche
% aus PV-GIS entnommen worden sind.
%
% Aufbau des Arrays f�r geneigte Fl�chen (fix montiert):
% 1. Dimension: Jahreszeit [Summer, Transi, Winter]
% 2. Dimension: Monat innerhalb einer Jahreszeit (je 4 Monate)
% 3. Dimension: Orientierung [-120�,..., 0�, 15�, ... +120�] (0� = S�d; -90� = Ost)
% 4. Dimension: Neigung [0� ,15�, 30�, 45�, 60�, 90�]   ( 0�  = waagrecht,
%                                                        90� = senkrecht,
%                                                        )
% 5. Dimension: Datenart [Zeit, Temperatur, Direkt, Diffus, Global]
% 6. Dimension: Zeitpunkte (Bruchteile eines Tages, Werte in W/m^2 oder �C
%
% Beim Array f�r die nachgef�hrten Anlagen (Tracker) entfallen die Dimensionen f�r
% "Orientierung" und "Neigung"!
%
% Die Struktur "Content" enth�lt die korrekten Bezeichnungen/Werte der einzelnen
% Dimensionen f�r die sp�tere Weiterverarbeitung (f�r Indexsuche bzw.
% Interpolationen).
% Die ermittelten Arrays und die Contentstruktur werden im File "Weatherdata_Sola"
% gespeichert. Dieses File wird in der Funktion "merge_sim_data" weiterverarbeitet...
%
% HINWEIS: Falls in der Datenspalten "Zeit" ein Wert "0" eingetragen ist, bedeutet
% dies, dass kein Wert vorhanden ist (tritt am Ende der Datenspalten auf)!

% Franz Zeilinger - 15.12.2009, Last Change: 04.12.2017

clear;

% Pfad festlegen:
path = [pwd,filesep,'Wetterdaten',filesep,'Einstrahlungsdaten'];
save_path = [pwd,filesep,'Simulationsergebnisse'];

% definieren der Inhaltsstruktur:
Content.seasons = {'Summer'; 'Winter'; 'Transi'};
Content.orienta = [-120, -105, -90, -75, -60, -45, -30, -15, 0, 15, 30, 45, 60, 75, 90, 105, 120];
Content.inclina = [0, 15, 30, 45, 60, 75, 90];
Content.dat_typ = {'time', 'temperature', 'direct', 'diffuse', 'global'};
% Zuordnung der Monate zu den Jahreszeiten:
Content.allo_mo.Summer = [ 5,  6,  7,  8];
Content.allo_mo.Winter = [11, 12,  1,  2];
Content.allo_mo.Transi = [ 3,  4,  9, 10];
% es kommen in den Quellfiles maximal 63 Zeitpunkte vor:
Content.max_num_Datapoints = 63;
Content.num_columns_Datainputfiles = 10;
Content.num_emptyrows_Datainputfiles = 2;
Content.num_RowHeader_Datainputfiles = 8;
Content.Header_Datainputfiles.Time = 'Time';
Content.Header_Datainputfiles.Temperature = 'Td';
Content.Header_Datainputfiles.Global_Irradiation = 'G';
Content.Header_Datainputfiles.Diffuse_Irradiation = 'Gd';
Content.Header_Datainputfiles.DirectClearSyk_Irradiation = 'Gc';
Content.Header_Datainputfiles.Global_Irradiation_Tracker = 'A';
Content.Header_Datainputfiles.Diffuse_Irradiation_Tracker = 'Ad';
Content.Header_Datainputfiles.DirectClearSyk_Irradiation_Tracker = 'Ac';
% leere Ergebnisarrays erzeugen:
Radiation_fixed_Plane = zeros(...
	numel(Content.seasons),...
	numel(Content.allo_mo.Summer),...
	numel(Content.orienta),...
	numel(Content.inclina),...
	numel(Content.dat_typ),...
	Content.max_num_Datapoints);

Radiation_Tracker = zeros(...
	numel(Content.seasons),...
	numel(Content.allo_mo.Summer),...
	numel(Content.dat_typ),...
	Content.max_num_Datapoints);

file_name_start = [];
reading_format_string = [];
% Create a Formatstring for reading Inputfiles:
for i=1:Content.num_columns_Datainputfiles
	reading_format_string = [reading_format_string, '%s ']; %#ok<AGROW>
end
reading_format_string = reading_format_string(1:end-1);

% Die Erbebnisarrays bef�llen:
for i=1:numel(Content.seasons)
	season = Content.seasons{i};
	for j=1:numel(Content.allo_mo.(season))
		month = Content.allo_mo.(season)(j);
		missing = false;
		if isdir([path,filesep,num2str(month,'%02.0f')])
			% get the start of the filename of all data files
			if isempty(file_name_start)
				filenames = dir([path,filesep,num2str(month,'%02.0f')]);
				filenames = struct2cell(filenames);
				filenames = filenames(1,3:end);
				filename = filenames{1,1};
				parts = regexp(filename,'_','split');
				file_name_start = [parts{1},'_',parts{2},'_'];
				clear('filenames','filename','parts');
			end
		else
			fprintf(['MISSING: No data for Month ',num2str(month,'%02.0f'),...
				' found!\n'])
			missing = true;
			continue;
		end
		for k=1:numel(Content.orienta)
			orienta = Content.orienta(k);
			for l=1:numel(Content.inclina)
				inclina = Content.inclina(l);
				% File-Name zusamensetzen:
				name = [path,filesep,num2str(month,'%02.0f'),filesep,...
					file_name_start,...
					num2str(inclina),'deg_',...
					num2str(orienta),'deg.txt'];
				fileID = fopen(name);
				if fileID == -1
					fprintf(['MISSING: No data for Inclination ',...
						num2str(inclina),'� and Orientation ',...
						num2str(orienta),'� within Month ',...
						num2str(month,'%02.0f'),' found!\n']);
					missing = true;
					continue;
				end
				% laden des Files:
				data = textscan(fileID,reading_format_string);
				fclose(fileID);
				raw_data = cell(numel(data{1,1}),Content.num_columns_Datainputfiles);
				for m=1:Content.num_columns_Datainputfiles
					raw_data(1:numel(data{1,m}),m) = deal(data{1,m});
				end
				clear data
				header = raw_data(Content.num_RowHeader_Datainputfiles - ...
					Content.num_emptyrows_Datainputfiles,:);
				
				% Ermitteln des Bereichs, in dem die relevanten Daten zu
				% finden sind, basierend auf den Zeitstempeln:
				start_idx = Content.num_RowHeader_Datainputfiles - ...
					Content.num_emptyrows_Datainputfiles + 1;
				idx_Time = find(strcmp(header,...
					Content.Header_Datainputfiles.Time));
				% Zeitpunkte auslesen:
				time = raw_data(:,idx_Time);
				end_idx = [];
				for m=start_idx:numel(time)
					try
						time{m} = datenum(time{m},'HH:MM');
					catch ME
						% When conversion fails, the end of the data-area
						% is discovered:
						if isempty(end_idx)
							end_idx = m-1;
						end
						continue;
					end
				end
				% Convert daytimes to fractions of a whole day
				time = cell2mat(time(start_idx:end_idx));
				time = time - floor(max(time));
				
				% Einstrahlung auf geneigte Fl�che (freier Himmel)(W/m�):
				idx = strcmp(header, ...
					Content.Header_Datainputfiles.DirectClearSyk_Irradiation);
				rad_incl = str2double(raw_data(start_idx:end_idx,idx));
				% Diffuse Einstrahlung auf geneigte Fl�che(W/m�):
				idx = strcmp(header, ...
					Content.Header_Datainputfiles.Diffuse_Irradiation);
				rad_incl_diff = str2double(raw_data(start_idx:end_idx,idx));
				% Globale Einstrahlung auf geneigte Fl�che (W/m�):
				idx = strcmp(header, ...
					Content.Header_Datainputfiles.Global_Irradiation);
				rad_incl_global = str2double(raw_data(start_idx:end_idx,idx));
				% Tagestemperatur
				idx = strcmp(header, ...
					Content.Header_Datainputfiles.Temperature);
				temp = str2double(raw_data(start_idx:end_idx,idx));
				% Werte ins Ergebnis-Array schreiben:
				num_el = numel(time); % Anzahl der Elemente
				Radiation_fixed_Plane(i,j,k,l,1,1:num_el)=time;
				Radiation_fixed_Plane(i,j,k,l,2,1:num_el)=temp;
				Radiation_fixed_Plane(i,j,k,l,3,1:num_el)=rad_incl;
				Radiation_fixed_Plane(i,j,k,l,4,1:num_el)=rad_incl_diff;
				Radiation_fixed_Plane(i,j,k,l,5,1:num_el)=rad_incl_global;
				% Werte f�r nachgef�hrte Ebene m�ssen nur einmal ermittelt werden:
				if  l==1 && k ==1
					% Einstrahlung auf nachgef�hrte Fl�che (freier Himmel):
					idx = strcmp(header, ...
						Content.Header_Datainputfiles.DirectClearSyk_Irradiation_Tracker);
					rad_trac = str2double(raw_data(start_idx:end_idx,idx));
					% Diffuse Einstrahlung auf nachgef�hrte Fl�che (W/m�):
					idx = strcmp(header, ...
						Content.Header_Datainputfiles.Diffuse_Irradiation_Tracker);
					rad_trac_diff = str2double(raw_data(start_idx:end_idx,idx));
					% Globale Einstrahlung auf nachgef�hrte Fl�che (W/m�):
					idx = strcmp(header, ...
						Content.Header_Datainputfiles.Global_Irradiation_Tracker);
					rad_trac_global = str2double(raw_data(start_idx:end_idx,idx));
					% Werte ins Ergebnis-Array schreiben:
					Radiation_Tracker(i,j,1,1:num_el)=time;
					Radiation_Tracker(i,j,2,1:num_el)=temp;
					Radiation_Tracker(i,j,3,1:num_el)=rad_trac;
					Radiation_Tracker(i,j,4,1:num_el)=rad_trac_diff;
					Radiation_Tracker(i,j,5,1:num_el)=rad_trac_global;
				end
			end
		end
		if ~missing
			fprintf(['\tMonth ',num2str(month,'%02.0f'),' complete!\n']);
		end
	end
end

% Daten speichern:
if ~isdir(save_path)
	mkdir(save_path);
end
save([save_path,filesep,'Weatherdata_Sola_Radiation.mat'],'Radiation_Tracker',...
	'Radiation_fixed_Plane', 'Content');
fprintf('---\n');
