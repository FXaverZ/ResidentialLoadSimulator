clear;

% Maximale Anzahl an Datensätzen in einem Teilergebnisfile:
max_profiles_per_file = 50;
% Speicherort für die Simulationsergebnisse:
save_path = [pwd,'\','Simulationsergebnisse'];
sep = ' - '; %Seperator im Dateinamen

% File mit Windgeschwindigkeiten:
source_path = [pwd,filesep,'Wetterdaten',filesep,'Windgewschindigkeitsdaten'];
source_name = 'ALADIN_Wolfsegg_2004-2008';

v_wind_year = load_wind_data(source_path, source_name);

simdate = now;
seasons = {'Winter', 'Summer', 'Transi'};

for l=1:3
	data_counter = 0; % Zähler, Anzahl der vorhandenen Datensätze
	idx_counter = 1;  % Zähler für aktuelle Indexdatei
	season = seasons{l};
	
	% Auslesen der Windgeschwindigkeiten dieser Jahreszeit:
	v_wind_season = v_wind_year.(season);
	% Ergebnisarray (mit den Windgeschwindigkeiten):
	data_v_wind = [];
	% Winddaten generieren für jeweils 24h (pro Tag 24 Datenpunkte, da je 60min ein
	% Datenpunkt):
	for k=0:24:size(v_wind_season,1)-24
		% Aktuelle Tageswindgeschwindigkeit einlesen:
		v_wind = v_wind_season(k+1:k+24);
		% Winddaten von 60min auf 1sec umrechnen, dabei nah Windmodell Böen
		% einarbeiten:
		v_wind_fine = zeros(86401,1);
		% Erste Messperiode:
		v_wind_fine(1) = v_wind(1); % erster Datenpunkt stimmt überein
		for j = 1:3600
			% für die 60*60 = 3600 folgenden Sekunden ein Böenmodell (stochastischer
			% Pfad) anwenden:
			v_t = v_wind_fine(j);
			v_t_p_1 = 0.17*v_t+0.83*v_wind(1)+0.91*randn();
			v_wind_fine(j+1) = v_t_p_1;
		end
		% Am Ende der Periode, den ermittelten Werte so anpassen, dass zum zweiten
		% Mess-Zeitpunkt die beiden Werte wiederrum übereinstimmen (Stützstellen
		% bleiben erhalten):
		delta = v_wind(2) - v_wind(1); % Um wieviel weichen die Werte ab?
		step = 0:delta/3599:delta;     % linerare Anpassung um die Abweichung
		if ~isempty(step)
			v_wind_fine(1:3600) = v_wind_fine(1:3600) + step';
		end
		% Die weiteren Messperioden, Ablauf analog zur ersten Periode:
		for i = 1:size(v_wind,1)-2
			for j = 0:3600-1
				v_t = v_wind_fine(i*3600+j);
				v_t_p_1 = 0.17*v_t+0.83*v_wind(i+1)+0.91*randn();
				v_wind_fine(i*3600+j+1) = v_t_p_1;
			end
			delta = v_wind(i+2) - v_wind(i+1);
			step = 0:delta/3599:delta;
			if ~isempty(step)
				v_wind_fine(i*3600+1:i*3600+3600) = ...
					v_wind_fine(i*3600+1:i*3600+3600) + step';
			end
		end
		% letzte Messperiode:
		i = size(v_wind,1)-1;
		for j = 0:3600
			v_t = v_wind_fine(i*3600+j);
			v_t_p_1 = 0.17*v_t+0.83*v_wind(i+1)+0.91*randn();
			v_wind_fine(i*3600+j+1) = v_t_p_1;
		end
		% Alle Windgeschwindigkeiten, die ev. negativ sind, zu Null setzen:
		v_wind_fine(v_wind_fine<0)=0;
		
		%       % Nachfolgende Debug-Code bzw. anwenden eines Filters, der die Trägheit des
		%       % Windrades simuliert. Diese Filterung wird aber erst beim Turbinenmodell
		%       % angewendet, hier ist sie nur zu Testzwecken angeführt:
		%       plot(v_wind_fine)
		% 		% Filtern der Windgeschwindigkeit (Trägheit des Windrades):
		% 		[b a] = butter(3,0.0125/(0.5),'low');
		% 		% Für Filter dummy-Werte einfügen (zum Einschwingen):
		% 		v_wind_fine = [ones(200,1)*v_wind(1); v_wind_fine]; %#ok<AGROW>
		% 		% Filtern:
		% 		v_wind_fine = filter(b,a,v_wind_fine);
		% 		% dummy-Daten wieder löschen:
		% 		v_wind_fine = v_wind_fine(200:end);
		% 		plot(v_wind_fine)
		% 		% Darstellen der Frequenzanteile in v_wind_fine;
		% 		Fs = 1;                    % Sampling frequency
		% 		T = 1/Fs;                  % Sample time
		% 		L = 86400;                 % Length of signal
		% 		NFFT = 2^nextpow2(L); % Next power of 2 from length of y
		% 		Y = fft(v_wind_fine,NFFT)/L;
		% 		f = Fs/2*linspace(0,1,NFFT/2000+1);
		% 		plot(f,2*abs(Y(1:NFFT/2000+1)));
		% 		title('Einseitiges Amplituden Spektrum von v_wind_fine(t)')
		% 		xlabel('Frequenz (Hz)')
		% 		ylabel('|v_wind_fine(f)|')
		
		if isempty(data_v_wind)
			data_v_wind = v_wind_fine;
		else
			data_v_wind = [data_v_wind, v_wind_fine]; %#ok<AGROW>
		end
		% Datenzähler um eins erhöhen:
		data_counter = data_counter + 1;
		if data_counter >= max_profiles_per_file
			% Daten speichern:
			filename = [datestr(simdate,'HHhMM.SS'),sep,...
				'Gene',sep,'Wind',sep,season,sep,num2str(idx_counter,'%03.0f')];
			save([save_path,filesep,filename,'.mat'],'data_v_wind');
			idx_counter = idx_counter + 1;
			% überprüfen, wie viele Daten noch gespeichert werden sollen:
			data_counter = 0;
			data_v_wind = [];
		end
	end
	filename = [datestr(simdate,'HHhMM.SS'),sep,...
		'Gene',sep,'Wind',sep,season,sep,num2str(idx_counter,'%03.0f')];
	save([save_path,filesep,filename,'.mat'],'data_v_wind');
end