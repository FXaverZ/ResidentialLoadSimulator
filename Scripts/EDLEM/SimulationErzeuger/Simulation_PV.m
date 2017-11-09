% Simulieren einer PV-Anlage:

% Startgrad der Bewölkung:
okta = 8; % Grad der Bewölkung: 0 - klarer Himmel
%                       ...
%                     8 - stark bewölkter Himmel

% Wirkungsgrad PV-Anlage + WR:
eta = 0.14;
% power_inst = 1000;

% Anzahl der simulierenen Tage bzw. Anlagen:
num_dev = 75;
idx_counter = 1;

simulation={...
	'Winter', 'incl', '12-90°-0°', 'fix_90°_0°', 8;...
	'Winter', 'incl', '11-90°-0°', 'fix_90°_0°', 8;...
	'Winter', 'incl', '01-90°-0°', 'fix_90°_0°', 8;...
	'Winter', 'incl', '02-90°-0°', 'fix_90°_0°', 8;...
	'Winter', 'incl', '12-90°-0°', 'fix_90°_0°', 8;...
	'Transi', 'incl', '03-90°-0°', 'fix_90°_0°', 4;...
	'Transi', 'incl', '04-90°-0°', 'fix_90°_0°', 4;...
	'Transi', 'incl', '09-90°-0°', 'fix_90°_0°', 4;...
	'Transi', 'incl', '10-90°-0°', 'fix_90°_0°', 4;...
	'Transi', 'incl', '10-90°-0°', 'fix_90°_0°', 4;...
	'Summer', 'incl', '07-90°-0°', 'fix_90°_0°', 4;...
	'Summer', 'incl', '08-90°-0°', 'fix_90°_0°', 0;...
	'Summer', 'incl', '06-90°-0°', 'fix_90°_0°', 0;...
	'Summer', 'incl', '07-90°-0°', 'fix_90°_0°', 0;...
	'Summer', 'incl', '08-90°-0°', 'fix_90°_0°', 0;...
	'Winter', 'incl', '12-30°-0°', 'fix_30°_0°', 8;...
	'Winter', 'incl', '11-30°-0°', 'fix_30°_0°', 8;...
	'Winter', 'incl', '01-30°-0°', 'fix_30°_0°', 8;...
	'Winter', 'incl', '02-30°-0°', 'fix_30°_0°', 8;...
	'Winter', 'incl', '12-30°-0°', 'fix_30°_0°', 8;...
	'Transi', 'incl', '03-30°-0°', 'fix_30°_0°', 4;...
	'Transi', 'incl', '04-30°-0°', 'fix_30°_0°', 4;...
	'Transi', 'incl', '09-30°-0°', 'fix_30°_0°', 4;...
	'Transi', 'incl', '10-30°-0°', 'fix_30°_0°', 4;...
	'Transi', 'incl', '10-30°-0°', 'fix_30°_0°', 4;...
	'Summer', 'incl', '07-30°-0°', 'fix_30°_0°', 0;...
	'Summer', 'incl', '08-30°-0°', 'fix_30°_0°', 0;...
	'Summer', 'incl', '06-30°-0°', 'fix_30°_0°', 0;...
	'Summer', 'incl', '07-30°-0°', 'fix_30°_0°', 0;...
	'Summer', 'incl', '08-30°-0°', 'fix_30°_0°', 0;...
	'Winter', 'trac', '12-90°-0°', 'trac', 8;...
	'Winter', 'trac', '11-90°-0°', 'trac', 8;...
	'Winter', 'trac', '01-90°-0°', 'trac', 8;...
	'Winter', 'trac', '02-90°-0°', 'trac', 8;...
	'Winter', 'trac', '12-90°-0°', 'trac', 8;...
	'Transi', 'trac', '03-90°-0°', 'trac', 4;...
	'Transi', 'trac', '04-90°-0°', 'trac', 4;...
	'Transi', 'trac', '09-90°-0°', 'trac', 4;...
	'Transi', 'trac', '10-90°-0°', 'trac', 4;...
	'Transi', 'trac', '10-90°-0°', 'trac', 0;...
	'Summer', 'trac', '07-90°-0°', 'trac', 0;...
	'Summer', 'trac', '08-90°-0°', 'trac', 0;...
	'Summer', 'trac', '06-90°-0°', 'trac', 0;...
	'Summer', 'trac', '07-90°-0°', 'trac', 0;...
	'Summer', 'trac', '08-90°-0°', 'trac', 0;...
	};

% Speicherort für die Simulationsergebnisse:
save_path = [pwd,'\','Simulationsergebnisse'];

% Pfad zur Datei mit der solaren Einstrahlung:
path = 'D:\Projekte\EDLEM\5_Programm\Simulation dezentraler Erzeuger\Wetterdaten\Einstrahlungsdaten';

% Übergangswahrscheinlichkeit zwischen den verschiedenen Bewölkungsgraden:
cloud_trans = [...
	53.8, 22.5,  7.1,  4.7,  2.7,  2.3,  1.7,  2.6,  2.6;...
	15.5, 45.5, 14.0,  9.1,  4.3,  3.7,  3.2,  3.2,  1.5;...
	7.0, 24.5, 23.4, 15.3,  8.8,  7.2,  6.2,  5.4,  2.2;...
	3.8, 13.4, 17.7, 20.3, 12.6, 10.6,  9.0,  9.1,  3.5;...
	2.2,  8.5, 12.1, 15.9, 16.2, 14.4, 13.4, 13.2,  4.2;...
	1.5,  5.1,  8.1, 12.2, 12.6, 17.3, 18.7, 18.3,  6.2;...
	1.0,  3.0,  5.2,  7.4,  9.5, 14.2, 22.2, 28.0,  9.5;...
	0.6,  2.0,  2.3,  3.0,  3.9,  6.3, 11.3, 50.3, 20.4;...
	0.5,  0.7,  0.8,  1.1,  1.3,  2.0,  3.8, 13.5, 76.3;...
	];
% Diese Übergangswahrscheinlichkeiten anpassen:
for i=1:size(cloud_trans,2)-1
	cloud_trans(:,i+1) = cloud_trans(:,i) + cloud_trans(:,i+1);
end

% Simulationsdurchläufe
for k = 1:size(simulation,1)
	% Anlagenart ('incl' = fix monitert, 'trac' = Trackersystem):
	typ = simulation{k,2};
	% Anlagenname:
	typ_name = simulation{k,4};
	name = simulation{k,3};
	season = simulation{k,1};
	% Startgrad der Bewölkung:
	okta = simulation{k,5}; % Grad der Bewölkung: 0 - klarer Himmel
	%                       ...
	%                     8 - stark bewölkter Himmel
	% Daten laden:
	[time_fine, rad_incl_fine,rad_trac_fine,rad_incl_diff_fine,rad_trac_diff_fine] = ...
		load_solar_data(path, name);
	
	simdate = now;
	data_phase = zeros(86401,6*num_dev);
	for j = 1:num_dev
		cloud_factor = zeros(9,1);
		cloud_factor(1) = okta;
		for i = 1:8
			% Aufgrund der aktuellen Bewölkung die Übergangswahrscheinlichkeiten auslesen:
			proba = cloud_trans(okta+1,:);
			% gleichverteilte Zufallszahl erzeugen:
			fortu = rand()*100;
			if fortu == 0
				okta = 0;
				cloud_factor(i+1) = okta;
				continue;
			end
			% Bestimmen, welcher Bewölkungsgrad im nächsten Schritt vorliegt: ergibt sich
			% über den Übergangsvektor.
			okta = find(proba > fortu,1) - 1;
			if isempty(okta)
				okta = 0;
			end
			cloud_factor(i+1) = okta;
		end
		
		% Den Wolkenfaktor umrechnen (auf Faktor 0...1):
		cloud_factor = cloud_factor/8;
		
		% Einfluss der Bewölkung interpoplieren:
		cloud_factor_fine = interp1((0:1/8:1)',cloud_factor,time_fine, 'cubic');
		% Grenzen anpassen, falls durch Interpolation diese verlassen wurden:
		cloud_factor_fine(cloud_factor_fine < 0) = 0;
		cloud_factor_fine(cloud_factor_fine > 1) = 1;
		
		% Globale Strahlung mit Wolkeneinfluss (langsam) und Abschattung (schnell, durch
		% Wolkenfetzen) ermitteln:
		% zufällige Leistungseinbrüche, werden ähnlich wie die langsame Änderung berechnet
		% Frequenz der schnellen Änderung:
		frequ = 1500;
		fortu_fast = zeros(frequ + 1,1);
		fortu_fast(1) = okta;
		for i = 1:frequ
			% Aufgrund der aktuellen Bewölkung die Übergangswahrscheinlichkeiten auslesen:
			proba = cloud_trans(okta+1,:);
			% gleichverteilte Zufallszahl erzeugen:
			fortu = rand()*100;
			if fortu == 0
				okta = 0;
				fortu_fast(i+1) = okta;
				continue;
			end
			% Bestimmen, welcher Bewölkungsgrad im nächsten Schritt vorliegt: ergibt sich
			% über den Übergangsvektor.
			okta = find(proba > fortu,1) - 1;
			if isempty(okta)
				fortu_fast = 0;
			end
			fortu_fast(i+1) = okta;
		end
		% Einfluss der schnellen Änderung interpolieren
		fortu_fast_fine = interp1((0:1/frequ:1)',fortu_fast,time_fine);
		% diese werden über den Wolkeneinfluss über eine raised-cosine-Gewichtung belegt: so
		% ist sichergestellt, dass bei den Bewölkungsgraden "wolkenlos" und "stark bewölkt"
		% nur mehr geringe Schwankungen vorkommen, in den dazwischenliegenden Bereichen wird
		% diese aber immer stärker ausfallen:
		% Nachfolgend ein Code, um die Gewichtungsfunktion darzustellen:
		%     t = 1:0.1:4;
		%     s = 0.5*(1 + cos((t-0.5)*2*pi);
		%     plot(t,s)
		fortu_fast_fine = fortu_fast_fine .* ...
			(0.5*(1 + cos((cloud_factor_fine-0.5)*2*pi)));
		% Anpassen der Bereiche:
		fortu_fast_fine = fortu_fast_fine / 8;
		% Einfluss der schnellen Änderung hinzufügen:
		cloud_factor_fine = cloud_factor_fine .* (1-fortu_fast_fine);
		
		% resultierende Einstrahlung ermitteln:
		% zuerst direkte Einstrahlung (abgeschwächt durch Wolkeneinfluss):
		rad_incl_fine_cloud = rad_incl_fine .* (1-cloud_factor_fine);
		rad_trac_fine_cloud = rad_trac_fine .* (1-cloud_factor_fine);
		% diffuse Einstrahlung:
		rad_incl_fine_diff = rad_incl_diff_fine .* cloud_factor_fine;
		rad_trac_fine_diff = rad_trac_diff_fine .* cloud_factor_fine;
		% Gesamte Einstrahlung:
		rad_inlc_ges = rad_incl_fine_cloud + rad_incl_fine_diff;
		rad_trac_ges = rad_trac_fine_cloud + rad_trac_fine_diff;
		
		% eingespeiste Leistung ermitteln:
		power_active = zeros(size(rad_inlc_ges,1),3);
		power_reacti = power_active;
		
		% Phasenzuordnung ermitteln (gleich verteilt über alle drei Phasen):
		Phase_Index = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
		
		% eingespeiste Leistung ermitteln:
		switch typ
			case 'incl'
				power_active(:,Phase_Index) = rad_inlc_ges*eta;
			case 'trac'
				power_active(:,Phase_Index) = rad_trac_ges*eta;
		end
		% 	power_active_total = sum(power_active,2);
		% 	power_reacti_total = sum(power_reacti,2);
		
		% die Daten speichern:
		% 	data_total(:,2*j) = power_active_total;
		% 	data_total(:,(2*j)+1) = power_reacti_total;
		data_phase(:,(6*(j-1))+1:(6*(j-1))+3) = power_active;
		data_phase(:,(6*(j-1))+4:(6*(j-1))+6) = power_reacti;
		if max(data_phase)<1e-3;
			max(data_phase)
		end
	end
	
	filename = [datestr(simdate,'HHhMM.SS'),...
		' - Erz.prof. Sola - sec - ',season,' - ',typ_name,' - ',...
		num2str(idx_counter,'%03.0f')];
	save([save_path,filesep,filename,'.mat'], 'data_phase');
	clear 'data_phase';
	% phase_1 = sum(data_phase(:,2:6:end),2);
	% phase_2 = sum(data_phase(:,3:6:end),2);
	% phase_3 = sum(data_phase(:,4:6:end),2);
	% plot([phase_1, phase_2, phase_3])
	% plot(data_total(:,2:2:end))
end
