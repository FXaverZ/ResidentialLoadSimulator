clear all;

max_profiles_per_file = 500;
turbine_selector = 3;
typ_name = ['wind_',(num2str(turbine_selector))];
rho = 1.225;        % Lufdichte [kg/m³]
v_stop = 25;       % Abschaltwindgeschwindigkeit [m/s]
v_nom = 14;
power_nom = 1000;  % Nennleistung [W]
d_rotor = 5;       % Rotordurchmesser [m]

% cp-Faktoren unterschiedlicher Turbinen laden:
load([pwd,filesep,'Windturbine',filesep,'Cp_factor_wind.mat']);
cp = Cp_factor_wind(:,turbine_selector);

% Speicherort für die Simulationsergebnisse:
save_path = [pwd,filesep,'Simulationsergebnisse'];

% File mit Windgeschwindigkeiten:
source_path = [pwd,filesep,'Wetterdaten'];
source_name = 'Wetterdaten_2006';

v_wind_year = load_wind_data(source_path, source_name);

simdate = now;
seasons = {'Winter', 'Summer', 'Transi'};
k=0;
for l=1:3
	season = seasons{l};
	v_wind_season = v_wind_year.(season);
	% verbleibende Profile
	rem = round((size(v_wind_season,1)-1)/48) - k/48;
	if rem > max_profiles_per_file
		rem = max_profiles_per_file;
	end
	data_counter = 0;
	idx_counter = 1;
	data_phase = zeros(86401,6*rem);
	% Winddaten generieren für 24h:
	for k=0:48:size(v_wind_season,1)-48
		v_wind = v_wind_season(k+1:k+48);
		% Winddaten von 30min auf 1sec umrechnen, dabei nach Windmodell Böen
		% einarbeiten:
		v_wind_fine = zeros(86400,1);
		% Erste Messperiode:
		v_wind_fine(1) = v_wind(1);
		for j = 1:1800
			v_t = v_wind_fine(j);
			v_t_p_1 = 0.17*v_t+0.83*v_wind(1)+0.91*randn();
			v_wind_fine(j+1) = v_t_p_1;
		end
		delta = v_wind(2) - v_wind(1);
		step = 0:delta/1799:delta;
		if ~isempty(step)
			v_wind_fine(1:1800) = v_wind_fine(1:1800) + step';
		end
		% Die weiteren Messperioden:
		for i = 1:size(v_wind,1)-2
			for j = 0:1800-1
				v_t = v_wind_fine(i*1800+j);
				v_t_p_1 = 0.17*v_t+0.83*v_wind(i+1)+0.91*randn();
				v_wind_fine(i*1800+j+1) = v_t_p_1;
			end
			delta = v_wind(i+2) - v_wind(i+1);
			step = 0:delta/1799:delta;
			if ~isempty(step)
				v_wind_fine(i*1800+1:i*1800+1800) = ...
					v_wind_fine(i*1800+1:i*1800+1800) + step';
			end
		end
		% letzte Messperiode:
		i = size(v_wind,1)-1;
		for j = 0:1800-1
			v_t = v_wind_fine(i*1800+j);
			v_t_p_1 = 0.17*v_t+0.83*v_wind(i+1)+0.91*randn();
			v_wind_fine(i*1800+j+1) = v_t_p_1;
		end
		v_wind_fine(v_wind_fine<0)=0;
		% Filtern der Windgeschwindigkeit (Trägheit des Windrades):
		[b,a] = butter(3,0.0125/(0.5),'low');
		% Für Filter dummy-Werte einfügen (zum Einschwingen):
		v_wind_fine = [ones(200,1)*v_wind(1); v_wind_fine]; %#ok<AGROW>
		% Filtern:
		v_wind_fine = filter(b,a,v_wind_fine);
		% dummy-Daten wieder löschen:
		v_wind_fine = v_wind_fine(200:end);
% 		v_wind_fine = 0:27/86400:27-1/86400;
% 		plot([v_wind_fine, v_wind_filter])
% 		Fs = 1;                    % Sampling frequency
% 		T = 1/Fs;                  % Sample time
% 		L = 86400;                 % Length of signal
% 		NFFT = 2^nextpow2(L); % Next power of 2 from length of y
% 		Y = fft(v_wind_fine,NFFT)/L;
% 		f = Fs/2*linspace(0,1,NFFT/2000+1);
% 		% Plot single-sided amplitude spectrum.
% 		plot(f,2*abs(Y(1:NFFT/2000+1)));
% 		title('Single-Sided Amplitude Spectrum of v_wind_fine(t)')
% 		xlabel('Frequency (Hz)')
% 		ylabel('|Y(f)|')
% 		hold;
% 		Y = fft(v_wind_filter,NFFT)/L;
% 		plot(f,2*abs(Y(1:NFFT/2000+1)));
        % die Beiwerte nach Betz berechnen (Interpolieren aus bekannten cp-Werten
		cp_act = interp1(0:25,cp,v_wind_fine,'cubic');
		% Abschaltbedingung:
		v_wind_fine(v_wind_fine>v_stop)=0;
		power = zeros(size(v_wind_fine,1),3);
		power_reactive = power;
		% Phasenzuordnung ermitteln (gleich verteilt über alle drei Phasen):
		Phase_Index = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
		power(:,Phase_Index) = rho/2*(d_rotor^2*pi/4)*v_wind_fine.^3.*cp_act;
		% maximale Anlagenleistung ermitteln, um auf 1kWp installierte Leistung zu
		% normieren!
		v_wind_fine = v_nom:0.5:30;
		v_wind_fine(v_wind_fine>v_stop)=0;
		cp_act = interp1(0:25,cp,v_wind_fine,'cubic');
		max_pow = max(rho/2*(d_rotor^2*pi/4)*v_wind_fine.^3.*cp_act);
		power = power/max_pow;
		power_reactive = power_reactive/max_pow;
		% die Daten zum Ergebnis hinzufügen:
		data_phase(:,(6*(k/48))+1:(6*(k/48))+3) = power;
		data_phase(:,(6*(k/48))+4:(6*(k/48))+6) = power_reactive;
		data_counter = data_counter +1;
		if data_counter >= max_profiles_per_file
			% Daten speichern
			filename = [datestr(simdate,'HHhMM.SS'),...
				' - Erz.prof. Wind - sec - ';season;' - ',typ_name,' - ',...
				num2str(idx_counter,'%03.0f')];
			save([save_path,filesep,filename,'.mat'],'data_total', 'data_phase');
			idx_counter = idx_counter +1;
			% überprüfen, wie viele Daten noch gespeichert werden sollen:
			rem = round((size(v_wind_season,1)-1)/48) - k*48;
			if rem > max_profiles_per_file
				rem = max_profiles_per_file;
			end
			data_counter = 0;
			data_phase = zeros(86401,6*rem);
		end
	end
	% Daten speichern
	filename = [datestr(simdate,'HHhMM.SS'),...
		' - Erz.prof. Wind - sec - ',season,' - ',typ_name,' - ',...
		num2str(idx_counter,'%03.0f')];
	save([save_path,filesep,filename,'.mat'],'data_phase');
	idx_counter = idx_counter +1;
end



