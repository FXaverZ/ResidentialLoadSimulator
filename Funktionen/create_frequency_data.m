function Frequency = create_frequency_data (Time)
%CREATE_FREQUENCY_DATA    erzeugt Dummy-Frequenzdaten zu Testzwecken
%    FREQUENCY = CREATE_FREQUENCY_DATA(TIME) ermittelt Dummy-Frequnzdaten zum
%    Testen der implementierten Funktionen.
%    FREQUENCY ist ein [2,m]-Array, in der ersten Zeile stehen die Zeitwerte
%    des Frequenzpunktes in absoluter Matlabzeit, in der zweiten Zeile die
%    zugehörigen Frequenzwerte. Die gröbste Auflösung der Frequenzdaten ist eine
%    Minute, bei feinerer Simulationsauflösung werden die Frequenzdaten
%    dementsprechend verfeinert.
%    Weiters werden die Frequenzdaten für die gesamte Simulationsdauer
%    aufbereitet (z.B. bei Laufzeit über mehrere Tage).

%    Franz Zeilinger - 12.08.2010

% Ermitteln, über wie viele Tage die Simulation läuft:
Date_Start = floor(Time.Date_Start);
Date_End = ceil(Time.Date_End);
Days = Date_End - Date_Start; 

if Time.Base < 60
	% Erzeugen eines 1 sec-Zeitrasters mit gegebener Startzeit (1 Tag im Vorraus):
	t = Date_Start:1/Time.day_to_sec:Date_Start+Days;
else
	% Erzeugen eines 30sec-Zeitrasters mit gegebener Startzeit (1 Tag im Vorraus):
	t = Date_Start:30/Time.day_to_sec:Date_Start+Days;
end

% Erzeugen eines konstanten Arrays mit Zeitwerten & Frequenzwert 50 Hz:
steps = numel(t);
freq(1:steps) = 50;
Frequency = [t; freq];

% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% %     FREQUENZVERLAUF_VERSCHIEBUNG_LASTSPITZEN
% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% % Definieren interessanter Zeitpunkte in Tagesbruchteilen (von Startzeit weg):
% t_points = [...
% 	Date_Start+7/24,...
% 	Date_Start+8/24,...
% 	Date_Start+9/24,...
% 	Date_Start+10/24,...
% 	Date_Start+12/24,...
% 	Date_Start+13/24,...
% 	Date_Start+14/24,...
% 	Date_Start+16/24,...
% 	Date_Start+17/24,...
% 	Date_Start+19/24,...
% 	Date_Start+20/24,...
% 	];
% 
% % Erzeugen des gewünschten Verlaufs der Netzfrequenz:
% Frequency = frequ_ramp(Frequency, t_points(1), t_points(2), 49);
% Frequency = frequ_const(Frequency, t_points(2), t_points(3), 49);
% Frequency = frequ_ramp(Frequency, t_points(3), t_points(4), 50);
% 
% Frequency = frequ_ramp(Frequency, t_points(5), t_points(6), 49);
% Frequency = frequ_ramp(Frequency, t_points(6), t_points(7), 50);
% 
% Frequency = frequ_ramp(Frequency, t_points(8), t_points(9), 49);
% Frequency = frequ_const(Frequency, t_points(9), t_points(10), 49);
% Frequency = frequ_ramp(Frequency, t_points(10), t_points(11), 50);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%     FREQUENZVERLAUF_VERSCHIEBUNG_LASTSPITZEN_NEU
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Definieren interessanter Zeitpunkte in Tagesbruchteilen (von Startzeit weg):
t_points = Date_Start+1/24:1/24:Date_Start+1;

% Erzeugen des gewünschten Verlaufs der Netzfrequenz:
Frequency = frequ_ramp(Frequency, t_points(7), t_points(8), 49);
Frequency = frequ_const(Frequency, t_points(8), t_points(9), 49);
Frequency = frequ_ramp(Frequency, t_points(9), t_points(10), 50);

Frequency = frequ_ramp(Frequency, t_points(12), t_points(13), 49);
Frequency = frequ_const(Frequency, t_points(13), t_points(15), 49);
Frequency = frequ_ramp(Frequency, t_points(15), t_points(16), 50);

Frequency = frequ_ramp(Frequency, t_points(16), t_points(17), 49);
Frequency = frequ_const(Frequency, t_points(17), t_points(19), 49);
Frequency = frequ_ramp(Frequency, t_points(19), t_points(20), 50);

% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% %     FREQUENZVERLAUF_KURZER_FREQUENZEINBRUCH
% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% % Definieren interessanter Zeitpunkte in Tagesbruchteilen (von Startzeit weg):
% t_points = [...
% 	Date_Start+3/24,...
% 	Date_Start+8/24,...
% 	Date_Start+13/24,...
% 	Date_Start+18/24,...
% 	];
% Frequency = frequ_ramp(Frequency, t_points(1)-5/1440, t_points(1), 49);
% Frequency = frequ_const(Frequency, t_points(1), t_points(1)+5/1440, 49);
% Frequency = frequ_ramp(Frequency, t_points(1)+5/1440, t_points(1)+10/1440, 50);
% 
% Frequency = frequ_ramp(Frequency, t_points(2)-5/1440, t_points(2), 49);
% Frequency = frequ_const(Frequency, t_points(2), t_points(2)+5/1440, 49);
% Frequency = frequ_ramp(Frequency, t_points(2)+5/1440, t_points(2)+10/1440, 50);
% 
% Frequency = frequ_ramp(Frequency, t_points(3)-5/1440, t_points(3), 49);
% Frequency = frequ_const(Frequency, t_points(3), t_points(3)+5/1440, 49);
% Frequency = frequ_ramp(Frequency, t_points(3)+5/1440, t_points(3)+10/1440, 50);
% 
% Frequency = frequ_ramp(Frequency, t_points(4)-5/1440, t_points(4), 49);
% Frequency = frequ_const(Frequency, t_points(4), t_points(4)+5/1440, 49);
% Frequency = frequ_ramp(Frequency, t_points(4)+5/1440, t_points(4)+10/1440, 50);

% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% %     FREQUENZVERLAUF_LANGER_FREQUENZEINBRUCH
% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% % Definieren interessanter Zeitpunkte in Tagesbruchteilen (von Startzeit weg):
% t_points = [...
% 	Date_Start+6/24,...
% 	Date_Start+9/24,...
% 	Date_Start+18/24,...
% 	Date_Start+21/24,...
% 	];
% 
% Frequency = frequ_ramp(Frequency, t_points(1), t_points(2), 49);
% Frequency = frequ_const(Frequency, t_points(2), t_points(3), 49);
% Frequency = frequ_ramp(Frequency, t_points(3), t_points(4), 50);

% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% %     FREQUENZVERLAUF_GROßSTÖRUNG
% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% % Definieren interessanter Zeitpunkte in Tagesbruchteilen (von Startzeit weg):
% t_points = [...
% 	Date_Start+22/24+10/1440, 50;...
% 	Date_Start+22/24+11/1440, 49.15;...
% 	Date_Start+22/24+11.5/1440, 49.22;...
% 	Date_Start+22/24+12/1440, 49.1;...
% 	Date_Start+22/24+13/1440, 49.01;...
% 	Date_Start+22/24+14/1440, 49.01;...
% 	Date_Start+22/24+18/1440, 49.18;...
% 	Date_Start+22/24+19/1440, 49.35;...
% 	Date_Start+22/24+21/1440, 49.55;...
% 	Date_Start+22/24+22/1440, 49.7;...
% 	Date_Start+22/24+27/1440, 50.1;...
% 	Date_Start+22/24+30/1440, 50.18;...
% 	Date_Start+23/24+15/1440, 50;...
% 	];
% for i = 1:size(t_points,1)-1
% 	Frequency = frequ_ramp(Frequency, t_points(i,1), t_points(i+1,1)+...
% 		1/(1440*60),t_points(i+1,2));
% end
% % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Hinzufügen von Rauschen:
Frequency = frequ_add_noise (Frequency, 0.0);
% Auswählen der für den Simulationsdurchlauf notwendigen Frequenzwerte:
Frequency = Frequency(:,Frequency(1,:) <= Time.Date_End);
Frequency = Frequency(:,Frequency(1,:) >= Time.Date_Start);
end

function Frequency = frequ_ramp(Frequency, t_start, t_end, Value_end)
	idx = (Frequency(1,:) > t_start | abs(Frequency(1,:)-t_start)<1e-6) ...
		& Frequency(1,:) <= t_end;
	ind = find(idx,1);
	delta = (Value_end - Frequency(2,ind))/(t_end - t_start);
	delta_f = (Frequency(1,idx)-t_start)*delta;
	Frequency(2,idx) = Frequency(2,ind);
	Frequency(2,idx) = Frequency(2,idx) + delta_f;
end
	
function Frequency = frequ_const(Frequency, t_start, t_end, Value)
	idx = Frequency(1,:) >= t_start & Frequency(1,:) <= t_end;
	Frequency(2,idx) = Value;
end

function Frequency = frequ_add_noise (Frequency, Noise_Amp)
	noise = (rand([1,size(Frequency,2)])-0.5)*2*Noise_Amp;
	Frequency(2,:) = Frequency(2,:) + noise;
end
