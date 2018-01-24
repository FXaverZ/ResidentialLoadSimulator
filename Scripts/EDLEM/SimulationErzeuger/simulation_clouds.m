% Simulieren der Bewölkung und damit der Abschwächung der solaren Einstrahlung: Als
% Erbebnis werden Tageswerte mit Bewölkungsfaktoren erzeugt (Array Cloud_Factor),
% wobei der Wert 0 wolkenlosen Himmel und der Wert 1 stark bewölkten Himmel
% darstellt.

% Startgrad der Bewölkung:
okta = 4; % Grad der Bewölkung: 0 - klarer Himmel
%                                ...
%                               8 - stark bewölkter Himmel

% Speicherort für die Simulationsergebnisse:
save_path = [pwd,'\','Simulationsergebnisse'];
sep = ' - '; %Seperator im Dateinamen
% Anzahl an Datensätzen:
num_days = 2000;
% maximale Anzahl an Datensätzen pro File:
max_num_data_sets = 100;
season = 'Summer';

% Übergangswahrscheinlichkeit zwischen den verschiedenen Bewölkungsgraden:
cloud_trans = [...
	53.8, 22.5,  7.1,  4.7,  2.7,  2.3,  1.7,  2.6,  2.6;...
	15.5, 45.5, 14.0,  9.1,  4.3,  3.7,  3.2,  3.2,  1.5;...
	7.0, 24.5, 23.4, 15.3,  8.8,  7.2,  6.2,  5.4,  2.2;...
	3.8, 13.4, 17.7, 20.3, 12.6, 10.6,  9.0,  9.1,  3.5;...
	2.2,  8.5, 12.1, 15.9, 16.2, 14.3, 13.4, 13.2,  4.2;...
	1.5,  5.1,  8.1, 12.2, 12.6, 17.3, 18.7, 18.3,  6.2;...
	1.0,  3.0,  5.2,  7.4,  9.5, 14.2, 22.2, 28.0,  9.5;...
	0.6,  2.0,  2.3,  3.0,  3.9,  6.3, 11.3, 50.2, 20.4;...
	0.5,  0.7,  0.8,  1.1,  1.3,  2.0,  3.8, 13.5, 76.3;...
	];
% Diese Übergangswahrscheinlichkeiten anpassen:
for i=1:size(cloud_trans,2)-1
	cloud_trans(:,i+1) = cloud_trans(:,i) + cloud_trans(:,i+1);
end
% 	% Simulationsstartzeitpunkt festhalten:
% 	simdate = now;

file_counter = 1;
data_set_counter = 0;
Cloud_Factor = zeros(86401, max_num_data_sets);
for j=1:num_days
	data_set_counter = data_set_counter + 1;

	% Groben Wolkeneinfluss aus den Übergangswahrscheinlichkeiten ermitteln: in
	% 3h-Schritten:
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
	time_fine = 0:1/86400:1;
	cloud_factor_fine = interp1((0:1/8:1)',cloud_factor,time_fine, 'PCHIP');
	% Grenzen anpassen, falls durch Interpolation diese verlassen wurden:
	cloud_factor_fine(cloud_factor_fine < 0) = 0;
	cloud_factor_fine(cloud_factor_fine > 1) = 1;
	% plot((0:1/8:1)',cloud_factor)
	% hold;
	% plot(time_fine,cloud_factor_fine);
	
	% Abschattung (schnell, durch Wolkenfetzen) ermitteln:
	frequ = 1000;
	cloud_factor_fast = zeros(frequ + 1,1);
	cloud_factor_fast(1) = okta;
	for i = 1:frequ
		% Aufgrund der aktuellen Bewölkung die Übergangswahrscheinlichkeiten auslesen:
		proba = cloud_trans(okta+1,:);
		% gleichverteilte Zufallszahl erzeugen:
		fortu = rand()*100;
		if fortu == 0
			okta = 0;
			cloud_factor_fast(i+1) = okta;
			continue;
		end
		% Bestimmen, welcher Bewölkungsgrad im nächsten Schritt vorliegt: ergibt sich
		% über den Übergangsvektor.
		okta = find(proba > fortu,1) - 1;
		if isempty(okta)
			cloud_factor_fast = 0;
		end
		cloud_factor_fast(i+1) = okta;
	end
	% Einfluss der schnellen Änderung interpolieren
	cloud_factor_fast_fine = interp1((0:1/frequ:1)',cloud_factor_fast,time_fine);
	% plot(time_fine,cloud_factor_fast_fine)
	% diese werden über den Wolkeneinfluss über eine raised-cosine-Gewichtung belegt: so
	% ist sichergestellt, dass bei den Bewölkungsgraden "wolkenlos" und "stark bewölkt"
	% nur mehr geringe Schwankungen vorkommen, in den dazwischenliegenden Bereichen wird
	% diese aber immer stärker ausfallen:
	% Nachfolgend ein Code, um die Gewichtungsfunktion darzustellen:
	%     t = 0:0.01:1;
	%     s = 0.5*(1 - cos(2*pi*t));
	%     plot(t,s)
	cloud_factor_fast_fine = cloud_factor_fast_fine .* ...
		(0.5*(1 - cos(2*pi*cloud_factor_fine)));
	% Anpassen der Bereiche:
	cloud_factor_fast_fine = cloud_factor_fast_fine / 8;
	% Einfluss der schnellen Änderung hinzufügen:
	cloud_factor_fine = cloud_factor_fine .* (1-cloud_factor_fast_fine);
	% plot(time_fine, cloud_factor_fine)
	Cloud_Factor(:,data_set_counter) = cloud_factor_fine';
	if data_set_counter == max_num_data_sets
		% Speichern des Zwischenergebnisses:
		name = ['Gene',sep,season,sep,'Cloud_Factor',sep,...
			num2str(file_counter,'%03.0f')];
		save([save_path,filesep,name,'.mat'],'Cloud_Factor');
		file_counter = file_counter + 1;
		data_set_counter = 0;
		% Rücksetzen des Arrays:
		Cloud_Factor = zeros(86401, max_num_data_sets);
	end
end

if data_set_counter > 0
	% Speichern der letzten Ergebnisse:
	name = ['Gene',sep,season,sep,'Cloud_Factor',sep,...
		num2str(file_counter,'%03.0f')];
	% Array so zusammenstutzen, dass nur generierte Werte darin vorkommen:
	Cloud_Factor = Cloud_Factor(:,1:data_set_counter);
	save([save_path,filesep,name,'.mat'],'Cloud_Factor');
end
