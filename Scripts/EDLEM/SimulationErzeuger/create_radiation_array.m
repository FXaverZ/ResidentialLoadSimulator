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
save_path = [pwd,filesep,'Simulationsergebnisse'];

% definieren der Inhaltsstruktur:
Content.seasons = {'Summer'; 'Winter'; 'Transi'};
Content.orienta = [-120, -105, -90, -75, -60, -45, -30, -15, 0, 15, 30, 45, 60, 75, 90, 105, 120];
Content.inclina = [0, 15, 30, 45, 60, 75, 90];
Content.dat_typ = {'Time', 'Temperature', 'DirectClearSyk_Irradiance', 'Diffuse_Irradiance', 'Global_Irradiance'};
% Zuordnung der Monate zu den Jahreszeiten:
Content.allo_mo.Summer = [ 5,  6,  7,  8];
Content.allo_mo.Winter = [11, 12,  1,  2];
Content.allo_mo.Transi = [ 3,  4,  9, 10];
% es kommen in den Quellfiles maximal 63 Zeitpunkte vor:
Content.max_num_Datapoints = 63;
Content.Datainputfiles.num_columns = 10;
Content.Datainputfiles.num_emptyrows = 2;
Content.Datainputfiles.num_RowHeader = 8;
Content.Datainputfiles.Header.Time = 'Time';
Content.Datainputfiles.Header.Temperature = 'Td';
Content.Datainputfiles.Header.Global_Irradiance = 'G';
Content.Datainputfiles.Header.Diffuse_Irradiance = 'Gd';
Content.Datainputfiles.Header.DirectClearSyk_Irradiance = 'Gc';
Content.Datainputfiles.Header.Global_Irradiance_Tracker = 'A';
Content.Datainputfiles.Header.Diffuse_Irradiance_Tracker = 'Ad';
Content.Datainputfiles.Header.DirectClearSyk_Irradiance_Tracker = 'Ac';
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

% Hilfsfunktionen in Matlab-Suchpfad aufnehmen:
addpath([pwd,filesep,'Hilfsfunktionen']);
diary([save_path,filesep,'Weatherdata_Sola_Radiation.log']);

file_name_start = [];
reading_format_string = [];
% Create a Formatstring for reading Inputfiles:
for i=1:Content.Datainputfiles.num_columns
	reading_format_string = [reading_format_string, '%s ']; %#ok<AGROW>
end
reading_format_string = reading_format_string(1:end-1);


% Die Erbebnisarrays befüllen:
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
				corr_radiation_needed = 0;
				% File-Name zusamensetzen:
				name = [path,filesep,num2str(month,'%02.0f'),filesep,...
					file_name_start,...
					num2str(inclina),'deg_',...
					num2str(orienta),'deg.txt'];
				fileID = fopen(name);
				if fileID == -1
					fprintf(['\t\tMISSING: No data for Inclination ',...
						num2str(inclina),'° and Orientation ',...
						num2str(orienta),'° within Month ',...
						num2str(month,'%02.0f'),' found!\n']);
					missing = true;
					continue;
				end
				% laden des Files:
				data = textscan(fileID,reading_format_string);
				fclose(fileID);
				raw_data = cell(numel(data{1,1}),Content.Datainputfiles.num_columns);
				for m=1:Content.Datainputfiles.num_columns
					raw_data(1:numel(data{1,m}),m) = deal(data{1,m});
				end
				clear data
				header = raw_data(Content.Datainputfiles.num_RowHeader - ...
					Content.Datainputfiles.num_emptyrows,:);
				
				% Ermitteln des Bereichs, in dem die relevanten Daten zu
				% finden sind, basierend auf den Zeitstempeln:
				start_idx = Content.Datainputfiles.num_RowHeader - ...
					Content.Datainputfiles.num_emptyrows + 1;
				idx_Time = find(strcmp(header,...
					Content.Datainputfiles.Header.Time));
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
					Content.Datainputfiles.Header.DirectClearSyk_Irradiance);
				rad_incl_clearsky = str2double(raw_data(start_idx:end_idx,idx));
				rad_incl_clearsky_cor = correct_radiation_data(rad_incl_clearsky);
				if ~isempty(rad_incl_clearsky_cor)
% 					figure;plot(rad_incl_clearsky,'LineWidth',2);hold;plot(rad_incl_clearsky_cor,'r');hold off;
					rad_incl_clearsky = rad_incl_clearsky_cor;
					if ~corr_radiation_needed
					fprintf(['\t\tCORRECTION: Radiation data correction for Inclination ',...
						num2str(inclina),'° and Orientation ',...
						num2str(orienta),'° within Month ',...
						num2str(month,'%02.0f'),' made for ']);
					corr_radiation_needed = 1;
					end
					fprintf('direct');
				end
				
				% Diffuse Einstrahlung auf geneigte Fläche(W/m²):
				idx = strcmp(header, ...
					Content.Datainputfiles.Header.Diffuse_Irradiance);
				rad_incl_diff = str2double(raw_data(start_idx:end_idx,idx));
				rad_incl_diff_cor = correct_radiation_data(rad_incl_diff);
				if ~isempty(rad_incl_diff_cor)
					rad_incl_diff = rad_incl_diff_cor;
					if ~corr_radiation_needed
						fprintf(['\t\tCORRECTION: Radiation data correction for Inclination ',...
							num2str(inclina),'° and Orientation ',...
							num2str(orienta),'° within Month ',...
							num2str(month,'%02.0f'),' made for ']);
						corr_radiation_needed = 1;
						fprintf('indirect');
					else
						fprintf(', indirect');
					end
					
				end
				
				% Globale Einstrahlung auf geneigte Fläche (W/m²):
				idx = strcmp(header, ...
					Content.Datainputfiles.Header.Global_Irradiance);
				rad_incl_global = str2double(raw_data(start_idx:end_idx,idx));
				rad_incl_global_cor = correct_radiation_data(rad_incl_global);
				if ~isempty(rad_incl_global_cor)
					rad_incl_global = rad_incl_global_cor;
					if ~corr_radiation_needed
						fprintf(['\t\tCORRECTION: Radiation data correction for Inclination ',...
							num2str(inclina),'° and Orientation ',...
							num2str(orienta),'° within Month ',...
							num2str(month,'%02.0f'),' made for ']);
						corr_radiation_needed = 1;
						fprintf('global');
					else
						fprintf(', global');
					end
				end
				if corr_radiation_needed
					fprintf(' radiation.\n');
				end
				
				% Tagestemperatur
				idx = strcmp(header, ...
					Content.Datainputfiles.Header.Temperature);
				temp = str2double(raw_data(start_idx:end_idx,idx));
				% Werte ins Ergebnis-Array schreiben:
				num_el = numel(time); % Anzahl der Elemente
				idx = strcmpi(Content.dat_typ,'Time');
				Radiation_fixed_Plane(i,j,k,l,idx,1:num_el)=time;
				idx = strcmpi(Content.dat_typ,'Temperature');
				Radiation_fixed_Plane(i,j,k,l,idx,1:num_el)=temp;
				idx = strcmpi(Content.dat_typ,'DirectClearSyk_Irradiance');
				Radiation_fixed_Plane(i,j,k,l,idx,1:num_el)=rad_incl_clearsky;
				idx = strcmpi(Content.dat_typ,'Diffuse_Irradiance');
				Radiation_fixed_Plane(i,j,k,l,idx,1:num_el)=rad_incl_diff;
				idx = strcmpi(Content.dat_typ,'Global_Irradiance');
				Radiation_fixed_Plane(i,j,k,l,idx,1:num_el)=rad_incl_global;
				% Werte für nachgeführte Ebene müssen nur einmal ermittelt werden:
				if  l==1 && k ==1
					corr_radiation_needed = 0;
					% Einstrahlung auf nachgeführte Fläche (freier Himmel):
					idx = strcmp(header, ...
						Content.Datainputfiles.Header.DirectClearSyk_Irradiance_Tracker);
					rad_trac_clearsky = str2double(raw_data(start_idx:end_idx,idx));
					rad_trac_clearsky_cor = correct_radiation_data(rad_trac_clearsky);
					if ~isempty(rad_trac_clearsky_cor)
						rad_trac_clearsky = rad_trac_clearsky_cor;
						if ~corr_radiation_needed
							fprintf(['\t\tCORRECTION: Radiation data correction for Inclination ',...
								'within Month ', num2str(month,'%02.0f'),' made for ']);
							corr_radiation_needed = 1;
							fprintf('direct tracker');
						end
					end
					
					% Diffuse Einstrahlung auf nachgeführte Fläche (W/m²):
					idx = strcmp(header, ...
						Content.Datainputfiles.Header.Diffuse_Irradiance_Tracker);
					rad_trac_diff = str2double(raw_data(start_idx:end_idx,idx));
					rad_trac_diff_cor = correct_radiation_data(rad_trac_diff);
					if ~isempty(rad_trac_diff_cor)
						rad_trac_diff = rad_trac_diff_cor;
						if ~corr_radiation_needed
							fprintf(['\t\tCORRECTION: Radiation data correction for Inclination ',...
								'within Month ', num2str(month,'%02.0f'),' made for ']);
							corr_radiation_needed = 1;
							fprintf('diffuse tracker');
						else
							fprintf(', diffuse tracker');
						end
					end
					
					% Globale Einstrahlung auf nachgeführte Fläche (W/m²):
					idx = strcmp(header, ...
						Content.Datainputfiles.Header.Global_Irradiance_Tracker);
					rad_trac_global = str2double(raw_data(start_idx:end_idx,idx));
					rad_trac_global_cor = correct_radiation_data(rad_trac_global);
					if ~isempty(rad_trac_global_cor)
						rad_trac_global = rad_trac_global_cor;
						if ~corr_radiation_needed
							fprintf(['\t\tCORRECTION: Radiation data correction for Inclination ',...
								'within Month ', num2str(month,'%02.0f'),' made for ']);
							corr_radiation_needed = 1;
							fprintf('global tracker');
						else
							fprintf(', global tracker');
						end
					end
					
					% Werte ins Ergebnis-Array schreiben:
					idx = strcmpi(Content.dat_typ,'time');
					Radiation_Tracker(i,j,idx,1:num_el)=time;
					idx = strcmpi(Content.dat_typ,'temperature');
					Radiation_Tracker(i,j,idx,1:num_el)=temp;
					idx = strcmpi(Content.dat_typ,'DirectClearSyk_Irradiance');
					Radiation_Tracker(i,j,idx,1:num_el)=rad_trac_clearsky;
					idx = strcmpi(Content.dat_typ,'Diffuse_Irradiance');
					Radiation_Tracker(i,j,idx,1:num_el)=rad_trac_diff;
					idx = strcmpi(Content.dat_typ,'Global_Irradiance');
					Radiation_Tracker(i,j,idx,1:num_el)=rad_trac_global;
					if corr_radiation_needed
						fprintf(' radiation.\n');
					end
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
diary('off');
