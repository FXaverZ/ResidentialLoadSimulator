function data_phase = model_wind_turbine(plant_parameters, v_wind)
%MODEL_WIND_TURBINE    
%   Detailierte Beschreibung fehlt!

% Franz Zeilinger - 02.01.2012

rho = plant_parameters.Rho;              % Dichte der Luft [kg/m³]
c_p = plant_parameters.c_p;              % Leistungsbeiwerttabelle dieses Windrades 
%                                            erste Spalte: Windgeschwindigkeit
%                                            zweite Spalte: entspr. Leistungsbeiwert
d_rotor = plant_parameters.Size_Rotor;   % Rotordurchmesser [m]
t_interia = plant_parameters.Inertia;    % Trägheit des Windrads [s]
efficency = plant_parameters.Efficiency; % Wirkungsgrad Umrichter [-]

% Ergebnissarray initialisieren:
data_phase = zeros(size(v_wind,1),6*plant_parameters.Number);
for i=1:plant_parameters.Number
	% Anschluss der Anlage an eine Phase ermitteln:
	phase_idx = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
	% Die Windgeschwindigkeiten innerhalb einer gewissen Zeitspanne verschieben, weil 
	% nicht alle Anlagen am gleichen Ort installiert sind. Die fehlenden Werte gemäß
	% dem für die Windaten verwendeten Algorithmus ersetzen (siehe Funktion
	% "Simulation_Wind_Velocity.m")
	delay = round((0.5-rand())*20*60); % Gaussche Verteilung mit 20min Standardabweichung
	if delay < 0
		% Array mit zu generierenden Windgeschwindigkeiten initialisieren:
		v_wind_add = zeros(abs(delay),1);
		% Startwert ist letzter Wert der bekannten Daten:
		v_wind_add(1) = v_wind(end);
		% letzten Stundenmittelwert ermitteln:
		v_wind_mean = mean(v_wind(end-3600:end));
		for j = 1:abs(delay)-1
			% für die folgenden Sekunden ein Böenmodell (stochastischer Pfad) 
			% anwenden:
			v_t = v_wind_add(j);
			v_t_p_1 = 0.17*v_t+0.83*v_wind_mean+0.91*randn();
			v_wind_add(j+1) = v_t_p_1;
		end
		% negative Windgeschwindigkeiten zu Null setzen:
		v_wind_add(v_wind_add<0) = 0;
		% Das neue Geschwindigkeitsarray zusammensetzen:
		v_wind_act = v_wind(abs(delay):end);
		v_wind_act = [v_wind_act; v_wind_add(2:end)]; %#ok<AGROW>
	else
		% Array mit zu generierenden Windgeschwindigkeiten initialisieren:
		v_wind_add = zeros(delay+1,1);
		% Endwert ist letzter Wert der bekannten Daten:
		v_wind_add(end) = v_wind(1);
		% ersten Stundenmittelwert ermitteln:
		v_wind_mean = mean(v_wind(1:3600));
		for j = delay+1:-1:2
			% für die folgenden Sekunden ein Böenmodell (stochastischer Pfad) 
			% anwenden:
			v_t = v_wind_add(j);
			v_t_m_1 = 0.17*v_t+0.83*v_wind_mean+0.91*randn();
			v_wind_add(j-1) = v_t_m_1;
		end
		% negative Windgeschwindigkeiten zu Null setzen:
		v_wind_add(v_wind_add<0) = 0;
		% Das neue Geschwindigkeitsarray zusammensetzen:
		v_wind_act = v_wind(1:end-delay);
		v_wind_act = [v_wind_add(1:end-1);v_wind_act]; %#ok<AGROW>
	end
	% Trägheit des Windrades simulieren (Tiefpassfilterung). Grenzfrequenz ist durch
	% die Angabe der Trägheit in Sekunden gegeben (Reziprokwert), welche aber für die
	% Matlab-Filterfunktion auf die Nyquistfrequenz (= 1/2*Abtastfrequenz; in diesem
	% Fall 0,5 Hz, da mit 1 Hz abgetastet wird (Sekundenwerte!)) normiert werden
	% muss:
	[b,a] = butter(3,(1/t_interia)/(0.5),'low');
	% Für Filter dummy-Werte einfügen (zum Einschwingen des Filters):
	v_wind_act = [ones(200,1)*v_wind_act(1); v_wind_act]; %#ok<AGROW>
	% Filtern:
	v_wind_act = filter(b,a,v_wind_act);
	% dummy-Daten wieder löschen:
	v_wind_act = v_wind_act(201:end);
	% ev. auftretende negative Geschwindigkeiten (durch Filterung) eleminieren:
	v_wind_act(v_wind_act<0)=0;
	
	% die Beiwerte nach Betz berechnen (Interpolieren aus bekannten c_p-Werten):
	c_p_act = interp1(c_p(:,1),c_p(:,2),v_wind_act,'cubic');
	
	% Leistungsarrays initialisieren:
	power_active = zeros(size(v_wind_act,1),3);
	power_reacti = power_active;
	
	% Leistung berechnen:
	power_active(:,phase_idx) = rho/2*(d_rotor^2*pi/4)*(v_wind_act.^3.*c_p_act)*...
		efficency;
	% die Daten speichern, [P_L1, Q_L1, P_L2, ...]:
	data_phase(:,(1:2:6)+6*(i-1)) = power_active;
	data_phase(:,(2:2:6)+6*(i-1)) = power_reacti;
end
end

