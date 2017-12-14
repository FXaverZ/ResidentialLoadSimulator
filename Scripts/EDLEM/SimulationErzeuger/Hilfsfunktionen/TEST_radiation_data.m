clear;
% Daten laden:
[upupFolder,upFolderName] = fileparts(fileparts(pwd));
load([upupFolder,filesep,upFolderName,filesep,'Simulationsergebnisse',filesep,...
	'Weatherdata_Sola_Radiation.mat']);

% Daten weiterverarbeiten: (Test)
% Eingangsparameter:
season = 1;
month = 3;
% Anlagenparameter:
orienta_dev = -90;
inclina_dev = 30;

% Daten auslesen, zuerst die Zeit (ist für alle Orientierungen und Neigungen gleich,
% daher wird diese nur vom ersten Element ausgelesen):
idx = strcmpi(Content.dat_typ,'Time');
time = squeeze(Radiation_fixed_Plane(season,month,1,1,idx,:))';
% Strahlungsdaten (für alle Orientierungen und Neigungen sowie nur jene Zeitpunkte,
% die größer Null sind (= nicht vorhandene Elemente)):
% idx = strcmpi(Content.dat_typ,'temperature');
% temp = squeeze(Radiation_fixed_Plane(season,month,:,:,idx,time>0));
idx = strcmpi(Content.dat_typ,'DirectClearSyk_Irradiance');
data_dir = squeeze(Radiation_fixed_Plane(season,month,:,:,idx,time>0));
idx = strcmpi(Content.dat_typ,'Diffuse_Irradiance');
data_dif = squeeze(Radiation_fixed_Plane(season,month,:,:,idx,time>0));
data_single = squeeze(data_dir(3,3,:));
figure;plot(data_single);
data_single = squeeze(data_dir(15,3,:));
figure;plot(data_single);
% Vektoren, auf denen die Daten beruhen, erstellen:
time = time(time > 0);
orienta = Content.orienta;
inclina = Content.inclina;
% Meshgrid erzeugen, mit den Basisvektoren:
[x,y,z] = meshgrid(inclina, orienta, time);
% neue Zeit mit Sekundenauflösung:
time_fine = time(1):1/86400:time(end);
% Interpolieren der Zeitreihen:
rad_dev_dir = squeeze(...
	interp3(x,y,z,data_dir,inclina_dev,orienta_dev,time_fine,'spline',0))';
rad_dev_dif = squeeze(...
	interp3(x,y,z,data_dif,inclina_dev,orienta_dev,time_fine,'spline',0))';

% Zeitpunkte vor Sonnenauf- und Untergang hinzufügen:
time_add_fine = 0:1/86400:time(1);
time_add_fine = time_add_fine(1:end-1); % letzter Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
time_fine = [time_add_fine, time_fine];
rad_dev_dir = [rad_add_fine, rad_dev_dir];
rad_dev_dif = [rad_add_fine, rad_dev_dif];
time_add_fine = time(end):1/86400:1;
time_add_fine = time_add_fine(2:end); % erster Zeitpunkt ist bereits vorhanden.
rad_add_fine = zeros(size(time_add_fine));
time_fine = [time_fine, time_add_fine];
rad_dev_dir = [rad_dev_dir, rad_add_fine];
rad_dev_dif = [rad_dev_dif, rad_add_fine];
% figure;plot(rad_dev_dir);
% figure;plot(rad_dev_dif);

% Abschneiden des Schwingens, das durch die Interpolation erzeugt wurde:
idx_sunrise = find(data_dir(1,1,:)>0,1);
idx_zero_front = find(rad_dev_dir(time_fine<time(idx_sunrise+1))<0,1,'last');
rad_dev_dir(1:idx_zero_front) = 0;
idx_zero_back = find(rad_dev_dir<0,1);
rad_dev_dir(idx_zero_back:end) = 0;
figure;plot(rad_dev_dir);

idx_sunrise = find(data_dif(1,1,:)>0,1);
idx_zero_front = find(rad_dev_dif(time_fine<time(idx_sunrise+1))<0,1,'last');
rad_dev_dif(1:idx_zero_front) = 0;
idx_zero_back = find(rad_dev_dif<0,1);
rad_dev_dif(idx_zero_back:end) = 0;
% figure;plot(rad_dev_dif);

% Darstellen einzelnen Daten:
d=11;
data_single = data_dir(:,:,d);
date = datestr(time(d),'HH:MM')
figure; surf(data_single);

