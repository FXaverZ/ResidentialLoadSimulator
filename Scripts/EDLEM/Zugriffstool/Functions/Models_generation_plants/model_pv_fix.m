function data_phase = model_pv_fix(plant, content, data_cloud_factor, ...
	radiation_data, month)
%MODEL_PV_FIX    Modell einer fix aufgeständerten PV-Anlage
%    DATA_PHASE = MODEL_PV_FIX(PLANT, CONTENT, DATA_CLOUD_FACTOR, RADIATION_DATA,...
%    MONTH) ermittelt aus den übergebenen Einstrahlungsdaten (RADIATION_DATA
%    mit dem Inhalten definiert in der Struktur CONTENT) und den
%    Bewölkungsfaktoren DATA_CLOUD_FACTOR für den Monat MONTH (1...12) die
%    eingespeiste Leistung DATA_PHASE ([t,6]-Matrix für t Zeitpunkte).
%    Die Anlagenparamerter, nach der diese Berechnung durchgeführt wird, sind in der
%    Struktur PLANT enthalten.

% Franz Zeilinger - 28.06.2012

% Daten auslesen, zuerst die Zeit (ist für alle Orientierungen und Neigungen gleich,
% daher wird diese nur vom ersten Element ausgelesen):
time = squeeze(radiation_data(month,1,1,1,:))';
% Strahlungsdaten (für alle Orientierungen und Neigungen sowie nur jene Zeitpunkte,
% die größer Null sind (= nicht vorhandene Elemente)):
data_dir = squeeze(radiation_data(month,:,:,3,time>0));
data_dif = squeeze(radiation_data(month,:,:,4,time>0));
% Temperatur:
% temp = squeeze(Radiation_fixed_Plane(month,:,:,2,time>0));
% Vektoren, mit den Stützstellen der Daten für die Interpolation erstellen:
time = time(time > 0); % Zeitpunkte = 0 --> keine Daten sind vorhanden
orienta = content.orienta;
inclina = content.inclina;
% Meshgrid erzeugen, mit den Basisvektoren:
[x,y,z] = meshgrid(inclina, orienta, time);
time_fine = time(1):1/86400:time(end);
[X,Y,Z] = meshgrid(plant.Inclination,plant.Orientation,time_fine);
% neue Zeit mit Sekundenauflösung:
% Interpolieren der Zeitreihen, zuerst direkte Einstrahlung:
rad_dir = squeeze(...
	interp3(x,y,z,data_dir,X,Y,Z,'spline'))';
% rad_dir(rad_dir<0) = 0; % negative Werte zu Null setzen (Überschwingen der
%                                 Interpolation)
% dann die diffuse Strahlung:
rad_dif = squeeze(...
	interp3(x,y,z,data_dif,X,Y,Z,'spline'))';
% rad_dif(rad_dif<0) = 0; % negative Werte zu Null setzen (Überschwingen der
%                                 Interpolation)

% Zeitpunkte vor Sonnenauf- und Untergang hinzufügen (Strahlung = 0):
time_add_fine = 0:1/86400:time(1);
time_add_fine = time_add_fine(1:end-1); % letzter Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
rad_dir = [rad_add_fine, rad_dir];
rad_dif = [rad_add_fine, rad_dif];
time_add_fine = time(end):1/86400:1;
time_add_fine = time_add_fine(2:end); % erster Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
rad_dir = [rad_dir, rad_add_fine];
rad_dif = [rad_dif, rad_add_fine];

% Abschneiden des Schwingens, das durch die Interpolation erzeugt wurde:
idx_sunrise = find(data_dir(1,1,:)>0,1);
idx_zero_front = find(rad_dir(time_fine<time(idx_sunrise+1))<0,1,'last');
rad_dir(1:idx_zero_front) = 0;
idx_zero_back = find(rad_dir<0,1);
rad_dir(idx_zero_back:end) = 0;

idx_zero_front = find(rad_dif(time_fine<time(idx_sunrise+1))<0,1,'last');
rad_dif(1:idx_zero_front) = 0;
idx_zero_back = find(rad_dif<0,1);
rad_dif(idx_zero_back:end) = 0;

% Nun liegen die Strahlungswerte in Sekundenauflösung für 24h vor interpoliert auf
% die Neigung und Orientierung der betrachteten Solaranlagen. Mit diesen Daten werden
% nun die PV-Anlagen simuliert:
data_phase = zeros(size(rad_dir,2),6*plant.Number);
for i=1:plant.Number
	% Anschluss der Anlage an eine Phase ermitteln:
	if strcmpi(plant.Phase_Allocation_Mode,'auto')
		if plant.Power_Installed < plant.Max_Power_4_Single_Phase
			% Einphasig:
			phase_idx = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
			powr_factor = 1;
		else
			% Dreiphasig:
			phase_idx = [1,2,3];
			powr_factor = 3;
		end
	elseif strcmpi(plant.Phase_Allocation_Mode,'1pha')
		% Einphasig:
		phase_idx = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
		powr_factor = 1;
	elseif strcmpi(plant.Phase_Allocation_Mode,'3pha')
		% Dreiphasig:
		phase_idx = [1,2,3];
		powr_factor = 3;
	end
	% Die Wolkeneinflussdaten innerhalb einer gewissen Zeitspanne verschieben, weil
	% nicht alle Anlagen am gleichen Ort installiert sind. Dadurch, dass in den
	% Nachststunden keine Strahlung vorhanden ist, können die fehlenden Werte einfach
	% mit Null ersetzt werden:
	% Gaussche Verteilung angegebener Standardabweichung:
	delay = round((0.5-rand())*plant.Sigma_delay_time);
	if delay < 0
		data_cloud_factor_dev = data_cloud_factor(abs(delay):end);
		data_cloud_factor_dev(end+1:86401) = 0;
	else
		data_cloud_factor_dev = data_cloud_factor(1:end-delay);
		data_cloud_factor_dev = [zeros(delay,1);data_cloud_factor_dev]; %#ok<AGROW>
	end
	
	% Gesamte Einstrahlung ermitteln (setzt sich aus globaler und giffuser Strahlung
	% zusammen):
	% zuerst direkte Einstrahlung (abgeschwächt durch Wolkeneinfluss):
	rad_dir = rad_dir .* (1-data_cloud_factor_dev');
	% diffuse Einstrahlung:
	rad_dif = rad_dif .* data_cloud_factor_dev';
	% Gesamte Einstrahlung:
	rad_total = rad_dir + rad_dif;
	
	% Leistungsarrays initialisieren:
	power_active = zeros(size(rad_total,2),3);
	power_reacti = power_active;
	% Leistungseinspeisung berechnen:
	power_active(:,phase_idx) = repmat((rad_total*...
		plant.Power_Installed*plant.Rel_Size_Collector*...
		plant.Efficiency) / powr_factor, powr_factor,1)';
	% die Daten speichern, [P_L1, Q_L1, P_L2, ...]:
	data_phase(:,(1:2:6)+6*(i-1)) = power_active;
	data_phase(:,(2:2:6)+6*(i-1)) = power_reacti;
end
end

