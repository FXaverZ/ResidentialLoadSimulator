function Result = simulate_devices_with_dsm(hObject, Devices, Frequency, Time)
%SIMULATE_DEVICES_WITH_DSM    führt die eigentliche Simulation durch (inkl. DSM)
%    RESULT = SIMULATE_DEVICES_WITH_DSM (HOBJECT, DEVICES, TIME) führt die
%    eigentliche Simulation mit DSM aus. Dazu wird über jeden Zeitschritt 
%    (gemäß TIME) und jedes Gerät (DEVICES) itteriert und deren aktuelle
%    Leistung ermittelt und in die RESULT-Struktur gespeichert. Weiters erfolgt
%    eine Ausgabe des Fortschritts in der Konsole. HOBJECT liefert den Zugriff
%    auf das aufrufende GUI-Fenster (für Statusanzeige).

%    Franz Zeilinger - 06.08.2010

% Erstellen eines Arrays mit den Leistungsdaten:
Result.Power = zeros([size(Devices.Elements_Varna,2) (Time.Number_Steps)]);
Result.Power_DSM = Result.Power;

% Ersten Zeitpnkt simulieren und dabei alle Geräte-Einsatzpläne auf laufende
% Matlabzeit umrechnen:
step = 1;
time = Time.Date_Start;
freq = Frequency(:,Frequency(1,:) <= time);
for i = 1:size(Devices.Elements_Varna,2)
	% Für jedes Element im Cell-Array Elements_Varna (Variablennamen)
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		dev.DSM = dev.DSM.combine_device_with(dev);
		% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
		% berechnet wird!
		dev = dev.next_step(time, 0);
		Result.Power(i,step) = Result.Power(i,step) + dev.Power_Input;
		dev.DSM = dev.DSM.algorithm(freq, time, 0);
		dev.DSM = dev.DSM.next_step(dev, time, 0);
		Result.Power_DSM(i,step) = Result.Power_DSM(i,step) + ...
			dev.DSM.Power_Input;
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start

% Berechnen der Reaktionen der Verbraucher für die restlichen Zeitpunkte:
for step = 2:Time.Number_Steps
	% Aktuellen Zeitpunkt ermitteln:
	time = Time.Date_Start + (step-1)*Time.Base/Time.day_to_sec;
	% alle Frequenzpunkte ermitteln, die den letzen Simulationsschritt umfassen:
	freq = Frequency(:,Frequency(1,:) <= time);
	freq = freq(:,freq(1,:) > time - (Time.Base/Time.day_to_sec));
	% Reaktion der Verbraucher ermitteln
	for i = 1:size(Devices.Elements_Varna,2)
		% Für jedes Element im Cell-Array Elements_Varna (Variablennamen)
		for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
			dev = Devices.(Devices.Elements_Varna{i})(j);
			dev = dev.next_step(time, Time.Base);
			Result.Power(i,step) = Result.Power(i,step) + dev.Power_Input;
			dev.DSM = dev.DSM.algorithm(freq, time, Time.Base);
			dev.DSM = dev.DSM.next_step(dev, time, Time.Base);
			Result.Power_DSM(i,step) = Result.Power_DSM(i,step) + ...
				dev.DSM.Power_Input;
			Devices.(Devices.Elements_Varna{i})(j) = dev;
		end
	end
	% Fortschrittsbalken updaten & überprüfen ob ein Abbruch durch User
	% erfolgt ist:
	if waitbar_update (hObject, 5, step-1, Time.Number_Steps-1)
		% Simulation abbrechen:
		return;
	end
end
end