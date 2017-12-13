function data_phase = model_pv_fix(plant, content, data_cloud_factor, ...
	radiation_data, month)
%MODEL_PV_FIX    Modell einer fix aufgest�nderten PV-Anlage
%    DATA_PHASE = MODEL_PV_FIX(PLANT, CONTENT, DATA_CLOUD_FACTOR, RADIATION_DATA,...
%    MONTH) ermittelt aus den �bergebenen Einstrahlungsdaten (RADIATION_DATA
%    mit dem Inhalten definiert in der Struktur CONTENT) und den
%    Bew�lkungsfaktoren DATA_CLOUD_FACTOR f�r den Monat MONTH (1...12) die
%    eingespeiste Leistung DATA_PHASE ([t,6]-Matrix f�r t Zeitpunkte).
%    Die Anlagenparamerter, nach der diese Berechnung durchgef�hrt wird, sind in der
%    Struktur PLANT enthalten.

% Franz Zeilinger - 28.06.2012

% % ---  FOR DEBUG OUTPUTS  ---
% function data_phase = model_pv_fix(plant, content, data_cloud_factor, ...
% 	radiation_data, month, xls)
% % --- --- --- --- --- --- ---

% Daten auslesen, zuerst die Zeit (ist f�r alle Orientierungen und Neigungen gleich,
% daher wird diese nur vom ersten Element ausgelesen):
idx = strcmpi(content.dat_typ,'Time');
time = squeeze(radiation_data(month,1,1,idx,:))';
% Strahlungsdaten (f�r alle Orientierungen und Neigungen sowie nur jene Zeitpunkte,
% die gr��er Null sind (= nicht vorhandene Elemente)):
idx = strcmpi(content.dat_typ,'DirectClearSyk_Irradiance');
data_dir = squeeze(radiation_data(month,:,:,idx,time>0));
idx = strcmpi(content.dat_typ,'Diffuse_Irradiance');
data_dif = squeeze(radiation_data(month,:,:,idx,time>0));
% Temperatur:
% temp = squeeze(Radiation_fixed_Plane(month,:,:,2,time>0));
% Vektoren, mit den St�tzstellen der Daten f�r die Interpolation erstellen:
time = time(time > 0); % Zeitpunkte = 0 --> keine Daten sind vorhanden
orienta = content.orienta;
inclina = content.inclina;
% Meshgrid erzeugen, mit den Basisvektoren:
[x,y,z] = meshgrid(inclina, orienta, time);
time_fine = time(1):1/86400:time(end);
[X,Y,Z] = meshgrid(plant.Inclination,plant.Orientation,time_fine);
% neue Zeit mit Sekundenaufl�sung:
% Interpolieren der Zeitreihen, zuerst direkte Einstrahlung:
rad_dir = squeeze(...
	interp3(x,y,z,data_dir,X,Y,Z,'spline',0))';
% dann die diffuse Strahlung:
rad_dif = squeeze(...
	interp3(x,y,z,data_dif,X,Y,Z,'spline',0))';

% Zeitpunkte vor Sonnenauf- und Untergang hinzuf�gen (Strahlung = 0):
time_add_fine = -1/86400:1/86400:time(1);
time_add_fine = time_add_fine(1:end-1); % letzter Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
time_fine = [time_add_fine, time_fine];
rad_dir = [rad_add_fine, rad_dir];
rad_dif = [rad_add_fine, rad_dif];

time_add_fine = time(end):1/86400:(1+1/86400);
time_add_fine = time_add_fine(2:end); % erster Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
time_fine = [time_fine, time_add_fine];
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

% % ---  FOR DEBUG OUTPUTS  ---
rad_dir_d = rad_dir';
rad_dif_d = rad_dif';
xls.set_worksheet('rad_dir');
xls.write_values(rad_dir_d);
xls.reset_row;
xls.set_worksheet('rad_dif');
xls.write_values(rad_dif_d);
xls.reset_row;
% % --- --- --- --- --- --- ---

% Nun liegen die Strahlungswerte in Sekundenaufl�sung f�r 24h vor interpoliert auf
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
	% Nachststunden keine Strahlung vorhanden ist, k�nnen die fehlenden Werte einfach
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
	% zuerst direkte Einstrahlung (abgeschw�cht durch Wolkeneinfluss):
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

