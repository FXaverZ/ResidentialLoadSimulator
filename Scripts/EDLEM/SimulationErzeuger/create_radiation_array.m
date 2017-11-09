% Mit Hilfe dieses Scripts wird ein Array mit den Einstrahlungsdaten erzeugt, welche
% aus PV-GIS entnommen worden sind.
%
% Aufbau des Arrays für geneigte Flächen (fix montiert):
% 1. Dimension: Jahreszeit [Summer, Transi, Winter]
% 2. Dimension: Monat innerhalb einer Jahreszeit (je 4 Monate)
% 3. Dimension: Orientierung [-15°, 0°, 15°] (0° = Süd; -90° = Ost)
% 4. Dimension: Neigung [15°, 30°, 45°, 60°, 90°] (0°  = waagrecht, 
%                                                        90° = senkrecht, 
%                                                        trac = Tracker)
% 5. Dimension: Datenart [Zeit, Temperatur, Direkt, Diffus]
% 6. Dimension: Werte in W/m^2
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

% Franz Zeilinger - 15.12.2009

clear;

% Pfad festlegen:
path = [pwd,filesep,'Wetterdaten',filesep,'Einstrahlungsdaten'];

% definieren der Inhaltsstruktur:
Content.seasons = {'Summer'; 'Winter'; 'Transi'};
Content.orienta = [-15, 0, 15];
Content.inclina = [15, 30, 45, 60, 90];
Content.dat_typ = {'time', 'temperature', 'direct', 'diffuse'};
% Zuordnung der Monate zu den Jahreszeiten:
Content.allo_mo.Summer = [ 5,  6,  7,  8];
Content.allo_mo.Winter = [11, 12,  1,  2];
Content.allo_mo.Transi = [ 3,  4,  9, 10];
% es kommen in den Quellfiles maximal 63 Zeitpunkte vor:
Content.max_num_Datapoints = 63;

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

% Die Erbebnisarrays befüllen:
for i=1:numel(Content.seasons)
	season = Content.seasons{i};
	for j=1:numel(Content.allo_mo.(season))
		month = Content.allo_mo.(season)(j);
		for k=1:numel(Content.orienta)
			orienta = Content.orienta(k);
			for l=1:numel(Content.inclina)
				inclina = Content.inclina(l);
				% File-Name zusamensetzen:
				if orienta < 0
					% negative Orientierung an Dateibenennung anpassen (nur positive
					% Winkel):
					orienta = orienta + 360;
				end
				name = [num2str(month,'%02.0f'),'-',...
					num2str(inclina,'%2.0f'),'°-',num2str(orienta,'%2.0f'),...
					'°'];
				% laden des Files:
				[~, ~, raw_data] = xlsread([path,filesep,name,'.xls'],name);
				% Ermitteln des Bereichs, in dem die relevanten Daten zu finden sind:
				start_idx = 9; % die ersten neun Zeilen enthalten nur allgemeine Infos!
				for m = start_idx:size(raw_data,1)
					if isnan(raw_data{m,1})
						end_idx = m-1;
						break;
					end
				end
				% Zeitpunkte auslesen:
				time = raw_data(start_idx:end_idx,1);
				time = cell2mat(time);
				% Einstrahlung auf geneigte Fläche (freier Himmel)(W/m²):
				rad_incl = raw_data(9:end_idx,7);
				rad_incl = cell2mat(rad_incl);
				% Diffuse Einstrahlung auf geneigte Fläche(W/m²):
				rad_incl_diff = raw_data(9:end_idx,5);
				rad_incl_diff = cell2mat(rad_incl_diff);
				% Tagestemperatur
				temp = raw_data(9:end_idx,15);
				% Alle fehlenden Werte durch NaN ersetzen:
				temp_double = NaN(size(temp));
				temp_double(~cellfun(@ischar,temp)) = cell2mat(temp(~cellfun(@ischar,temp)));
				% Werte ins Ergebnis-Array schreiben:
				num_el = numel(time); % Anzahl der Elemente
				Radiation_fixed_Plane(i,j,k,l,1,1:num_el)=time;
				Radiation_fixed_Plane(i,j,k,l,2,1:num_el)=temp_double;
				Radiation_fixed_Plane(i,j,k,l,3,1:num_el)=rad_incl;
				Radiation_fixed_Plane(i,j,k,l,4,1:num_el)=rad_incl_diff;
				% Werte für nachgeführte Ebene müssen nur einmal ermittelt werden:
				if  l==1 && k ==1
					% Einstrahlung auf nachgeführte Fläche (freier Himmel):
					rad_trac = raw_data(9:end_idx,13);
					rad_trac = cell2mat(rad_trac);
					% Diffuse Einstrahlung auf nachgeführte Fläche (W/m²):
					rad_trac_diff = raw_data(9:end_idx,11);
					rad_trac_diff = cell2mat(rad_trac_diff);
					% Tagestemperatur
					temp = raw_data(9:end_idx,15);
					% Alle fehlenden Werte durch NaN ersetzen:
					temp_double = NaN(size(temp));
					temp_double(~cellfun(@ischar,temp)) = cell2mat(temp(~cellfun(@ischar,temp)));
					% Werte ins Ergebnis-Array schreiben:
					Radiation_Tracker(i,j,1,1:num_el)=time;
					Radiation_Tracker(i,j,2,1:num_el)=temp_double;
					Radiation_Tracker(i,j,3,1:num_el)=rad_trac;
					Radiation_Tracker(i,j,4,1:num_el)=rad_trac_diff;
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
% season = 3;
% month = 4;
% % Anlagenparameter:
% orienta_dev = 7.5;
% inclina_dev = 55;
% 
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
% 	interp3(x,y,z,data_dir,inclina_dev,orienta_dev,time_fine,'cubic'))';
% rad_dev_dif = squeeze(...
% 	interp3(x,y,z,data_dif,inclina_dev,orienta_dev,time_fine,'cubic'))';
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
