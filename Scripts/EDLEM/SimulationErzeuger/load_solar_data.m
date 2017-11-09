function [time_fine, rad_incl_fine,rad_trac_fine,rad_incl_diff_fine,rad_trac_diff_fine] = ...
	load_solar_data(path, name)

[~, ~, raw_data] = xlsread([path,filesep,name,'.xls'],name);

% extrahieren der relevanten Daten:
% ermitteln, an welcher Stelle die relvanten Daten zu finden sind (die ersten neun
% Zeilen enthalten nur allgemeine Infos!)
for i = 9:size(raw_data,1)
	if isnan(raw_data{i,1})
		end_idx = i-1;
		break;
	end
end

% Zeiten:
time = raw_data(9:end_idx,1);
time = cell2mat(time);
% Einstrahlung auf geneigte Fläche (freier Himmel)(W/m²):
rad_incl = raw_data(9:end_idx,7);
rad_incl = cell2mat(rad_incl);
% Einstrahlung auf nachgeführte Fläche (freier Himmel):
rad_trac = raw_data(9:end_idx,13);
rad_trac = cell2mat(rad_trac);
% Diffuse Einstrahlung auf geneigte Fläche(W/m²):
rad_incl_diff = raw_data(9:end_idx,5);
rad_incl_diff = cell2mat(rad_incl_diff);
% Diffuse Einstrahlung auf nachgeführte Fläche (W/m²):
rad_trac_diff = raw_data(9:end_idx,11);
rad_trac_diff = cell2mat(rad_trac_diff);
% % Umgebungstemperatur:
% temp = raw_data(9:end_idx,15);
% temp = cell2mat(temp);
clear raw_data;

% neue Zeit mit Sekundenauflösung:
time_fine = time(1):1/86400:time(end);
time_fine = time_fine';
% Interpolieren der Einstrahlungsdaten:
rad_incl_fine = interp1(time, rad_incl, time_fine, 'cubic');
rad_trac_fine = interp1(time, rad_trac, time_fine, 'cubic');
rad_incl_diff_fine = interp1(time, rad_incl_diff, time_fine, 'cubic');
rad_trac_diff_fine = interp1(time, rad_trac_diff, time_fine, 'cubic');

% Zeitpunkte vor Sonnenauf- und Untergang hinzufügen:
time_add_fine = 0:1/86400:time(1);
time_add_fine = time_add_fine(1:end-1)'; %letzter Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
time_fine = [time_add_fine; time_fine];
rad_incl_fine = [rad_add_fine; rad_incl_fine];
rad_trac_fine = [rad_add_fine; rad_trac_fine];
rad_incl_diff_fine = [rad_add_fine; rad_incl_diff_fine];
rad_trac_diff_fine = [rad_add_fine; rad_trac_diff_fine];

time_add_fine = time(end):1/86400:1;
time_add_fine = time_add_fine(2:end)'; %erster Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
time_fine = [time_fine; time_add_fine];
rad_incl_fine = [ rad_incl_fine; rad_add_fine];
rad_trac_fine = [rad_trac_fine; rad_add_fine];
rad_incl_diff_fine = [ rad_incl_diff_fine; rad_add_fine];
rad_trac_diff_fine = [rad_trac_diff_fine; rad_add_fine];
% plot(time_fine, [rad_incl_fine, rad_trac_fine]);
% hold;
% plot(time, [rad_incl, rad_trac]);

% Solardaten in feiner Auflösung:
% rad_fine = [time_fine, rad_incl_fine, rad_trac_fine];
