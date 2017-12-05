% Mit Hilfe dieses Scripts wird ein Array mit den Einstrahlungsdaten erzeugt, welche
% aus PV-GIS entnommen worden sind.
%
% Aufbau des Arrays für geneigte Flächen (fix montiert):
% 1. Dimension: Jahreszeit [Summer, Transi, Winter]
% 2. Dimension: Monat innerhalb einer Jahreszeit (je 4 Monate)
% 3. Dimension: Orientierung [-120°,..., 0°, 15°, ... +120°] (0° = Süd; -90° = Ost)
% 4. Dimension: Neigung [0° ,15°, 30°, 45°, 60°, 90°]   ( 0°  = waagrecht,
%                                                        90° = senkrecht,
%                                                        )
% 5. Dimension: Datenart [Zeit, Temperatur, Direkt, Diffus, Global]
% 6. Dimension: Zeitpunkte (Bruchteile eines Tages, Werte in W/m^2 oder °C
%
% Beim Array für die nachgeführten Anlagen (Tracker) entfallen die Dimensionen für
% "Orientierung" und "Neigung"!
%
% Die Struktur "Content" enthält die korrekten Bezeichnungen/Werte der einzelnen
% Dimensionen für die spätere Weiterverarbeitung (für Indexsuche bzw.
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

% Die Erbebnisarrays befüllen:
for i=1:numel(Content.seasons)
	season = Content.seasons{i};
	for j=1:numel(Content.allo_mo.(season))
		month = Content.allo_mo.(season)(j);
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
						num2str(inclina),'° and Orientation ',...
						num2str(orienta),'° within Month ',...
						num2str(month,'%02.0f'),' found!\n'])
					continue;
				end
				% laden des Files:
				data = textscan(fileID,reading_format_string);
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
				
				% Einstrahlung auf geneigte Fläche (freier Himmel)(W/m²):
				idx = strcmp(header, ...
					Content.Header_Datainputfiles.DirectClearSyk_Irradiation);
				rad_incl = str2double(raw_data(start_idx:end_idx,idx));
				% Diffuse Einstrahlung auf geneigte Fläche(W/m²):
				idx = strcmp(header, ...
					Content.Header_Datainputfiles.Diffuse_Irradiation);
				rad_incl_diff = str2double(raw_data(start_idx:end_idx,idx));
				% Globale Einstrahlung auf geneigte Fläche (W/m²):
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
				% Werte für nachgeführte Ebene müssen nur einmal ermittelt werden:
				if  l==1 && k ==1
					% Einstrahlung auf nachgeführte Fläche (freier Himmel):
					idx = strcmp(header, ...
						Content.Header_Datainputfiles.DirectClearSyk_Irradiation_Tracker);
					rad_trac = str2double(raw_data(start_idx:end_idx,idx));
					% Diffuse Einstrahlung auf nachgeführte Fläche (W/m²):
					idx = strcmp(header, ...
						Content.Header_Datainputfiles.Diffuse_Irradiation_Tracker);
					rad_trac_diff = str2double(raw_data(start_idx:end_idx,idx));
					% Globale Einstrahlung auf nachgeführte Fläche (W/m²):
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
	end
end

% Daten speichern:
save([path,filesep,'Weatherdata_Sola_Radiation.mat'],'Radiation_Tracker',...
	'Radiation_fixed_Plane', 'Content');

% % Daten weiterverarbeiten: (Test)
% % Eingangsparameter:
% season = 2;
% month = 3;
% % Anlagenparameter:
% orienta_dev = 7.5;
% inclina_dev = 55;

% % Daten auslesen, zuerst die Zeit (ist für alle Orientierungen und Neigungen gleich,
% % daher wird diese nur vom ersten Element ausgelesen):
% time = squeeze(Radiation_fixed_Plane(season,month,1,1,1,:))';
% % Strahlungsdaten (für alle Orientierungen und Neigungen sowie nur jene Zeitpunkte,
% % die größer Null sind (= nicht vorhandene Elemente)):
% % temp = squeeze(Radiation_fixed_Plane(season,month,:,:,2,time>0));
% data_dir = squeeze(Radiation_fixed_Plane(season,month,:,:,3,time>0));
% data_dif = squeeze(Radiation_fixed_Plane(season,month,:,:,4,time>0));
% % Vektoren, auf denen die Daten beruhen, erstellen:
% time = time(time > 0);
% orienta = Content.orienta;
% inclina = Content.inclina;
% % Meshgrid erzeugen, mit den Basisvektoren:
% [x,y,z] = meshgrid(inclina, orienta, time);
% % neue Zeit mit Sekundenauflösung:
% time_fine = time(1):1/86400:time(end);
% % Interpolieren der Zeitreihen:
% rad_dev_dir = squeeze(...
% 	interp3(x,y,z,data_dir,inclina_dev,orienta_dev,time_fine,'spline'))';
% rad_dev_dif = squeeze(...
% 	interp3(x,y,z,data_dif,inclina_dev,orienta_dev,time_fine,'spline'))';
% 
% % Zeitpunkte vor Sonnenauf- und Untergang hinzufügen:
% time_add_fine = 0:1/86400:time(1);
% time_add_fine = time_add_fine(1:end-1); % letzter Zeitpunkt ist bereits vorhanden.
% rad_add_fine = zeros(size(time_add_fine));
% time_fine = [time_add_fine, time_fine];
% rad_dev_dir = [rad_add_fine, rad_dev_dir];
% rad_dev_dif = [rad_add_fine, rad_dev_dif];
% time_add_fine = time(end):1/86400:1;
% time_add_fine = time_add_fine(2:end); % erster Zeitpunkt ist bereits vorhanden.
% rad_add_fine = zeros(size(time_add_fine));
% time_fine = [time_fine, time_add_fine];
% rad_dev_dir = [rad_dev_dir, rad_add_fine];
% rad_dev_dif = [rad_dev_dif, rad_add_fine];
