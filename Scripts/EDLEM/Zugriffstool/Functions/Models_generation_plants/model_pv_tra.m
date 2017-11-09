function data_phase = model_pv_tra(plant, content, data_cloud_factor, ...
	radiation_data, month, time_resolution)
%MODEL_PV_TRA Summary 
%   Detaillierte Beschreibung fehlt!

% Franz Zeilinger - 22.12.2011

% Daten auslesen, zuerst die Zeit (ist für alle Orientierungen und Neigungen gleich,
% daher wird diese nur vom ersten Element ausgelesen):
time = squeeze(radiation_data(month,1,:))';
% Strahlungsdaten (nur jene Zeitpunkte, die größer Null sind (= nicht vorhandene
% Elemente)):
data_dir = squeeze(radiation_data(month,3,time>0))';
data_dif = squeeze(radiation_data(month,4,time>0))';
% Temperatur:
% temp = squeeze(Radiation_fixed_Plane(month,2,time>0));
% Vektoren, mit den Stützstellen der Daten für die Interpolation erstellen:
time = time(time > 0); % Zeitpunkte = 0 --> keine Daten sind vorhanden
% neue Zeit mit Sekundenauflösung:
time_fine = time(1):1/86400:time(end);
% Interpolieren der Zeitreihen, zuerst direkte Einstrahlung:
rad_dev_dir = interp1(time,data_dir,time_fine,'cubic');
rad_dev_dir(rad_dev_dir<0) = 0; % negative Werte zu Null setzen (Überschwingen der 
%                                 Interpolation)
% dann die diffuse Strahlung:
rad_dev_dif = interp1(time,data_dif,time_fine,'cubic');
rad_dev_dif(rad_dev_dif<0) = 0; % negative Werte zu Null setzen (Überschwingen der 
%                                 Interpolation)

% Zeitpunkte vor Sonnenauf- und Untergang hinzufügen (Strahlung = 0):
time_add_fine = 0:1/86400:time(1);
time_add_fine = time_add_fine(1:end-1); % letzter Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
rad_dev_dir = [rad_add_fine, rad_dev_dir];
rad_dev_dif = [rad_add_fine, rad_dev_dif];
time_add_fine = time(end):1/86400:1;
time_add_fine = time_add_fine(2:end); % erster Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
rad_dev_dir = [rad_dev_dir, rad_add_fine];
rad_dev_dif = [rad_dev_dif, rad_add_fine];

% Nun liegen die Strahlungswerte in Sekundenauflösung für 24h vor interpoliert auf
% die Neigung und Orientierung der betrachteten Solaranlagen. Mit diesen Daten werden
% nun die PV-Anlagen simuliert:
data_phase = zeros(size(data_cloud_factor,1),6*plant.Number);
for i=1:plant.Number
	% Anschluss der Anlage an eine Phase ermitteln:
	phase_idx = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
	% Die Strahlungsdaten innerhalb einer gewissen Zeitspanne verschieben, weil nicht
	% alle Anlagen am gleichen Ort installiert sind. Dadurch, dass in den
	% Nachststunden keine Strahlung vorhanden ist, können die fehlenden Werte einfach
	% mit Null ersetzt werden:
	delay = round((0.5-rand())*20*60); % Gaussche Verteilung mit 10min Standardabweichung
	if delay < 0
		rad_dev_dir_dev = rad_dev_dir(abs(delay):end);
		rad_dev_dir_dev(end+1:86401) = 0;
		rad_dev_dif_dev = rad_dev_dif(abs(delay):end);
		rad_dev_dif_dev(end+1:86401) = 0;
	else
		rad_dev_dir_dev = rad_dev_dir(1:end-delay);
		rad_dev_dir_dev = [zeros(1,delay),rad_dev_dir_dev]; %#ok<AGROW>
		rad_dev_dif_dev = rad_dev_dif(1:end-delay);
		rad_dev_dif_dev = [zeros(1,delay),rad_dev_dif_dev]; %#ok<AGROW>
	end
	% Die Einstrahlungsdaten an die zeitliche Auflösung anpassen:
	rad_dev_dir_dev = rad_dev_dir_dev(1:time_resolution:end);
	rad_dev_dif_dev = rad_dev_dif_dev(1:time_resolution:end);
	
	% Gesamte Einstrahlung ermitteln (setzt sich aus globaler und giffuser Strahlung
	% zusammen):
	% zuerst direkte Einstrahlung (abgeschwächt durch Wolkeneinfluss):
	rad_dev_dir_dev = rad_dev_dir_dev .* (1-data_cloud_factor');
	% diffuse Einstrahlung:
	rad_dev_dif_dev = rad_dev_dif_dev .* data_cloud_factor';
	% Gesamte Einstrahlung:
	rad_dev_total = rad_dev_dir_dev + rad_dev_dif_dev;
	
	% Leistungsarrays initialisieren:
	power_active = zeros(size(rad_dev_dir_dev,2),3);
	power_reacti = power_active;
	% Leistungseinspeisung berechnen:
	power_active(:,phase_idx) = rad_dev_total*...
		plant.Power_Installed*plant.Rel_Size_Collector*...
		plant.Efficiency;
	% die Daten speichern, [P_L1, Q_L1, P_L2, ...]:
	data_phase(:,(1:2:6)+6*(i-1)) = power_active;
	data_phase(:,(2:2:6)+6*(i-1)) = power_reacti;
end


end

