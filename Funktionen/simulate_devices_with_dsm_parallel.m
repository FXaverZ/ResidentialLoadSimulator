function Result = simulate_devices_with_dsm_parallel(hObject, Devices, Frequency, Time)
%SIMULATE_DEVICES_WITH_DSM    führt die eigentliche Simulation durch (inkl. DSM)
%    RESULT = SIMULATE_DEVICES_WITH_DSM (HOBJECT, DEVICES, TIME) führt die
%    eigentliche Simulation mit DSM aus. Dazu wird über jeden Zeitschritt 
%    (gemäß TIME) und jedes Gerät (DEVICES) itteriert und deren aktuelle
%    Leistung ermittelt und in die RESULT-Struktur gespeichert. Weiters erfolgt
%    eine Ausgabe des Fortschritts in der Konsole. HOBJECT liefert den Zugriff
%    auf das aufrufende GUI-Fenster (für Statusanzeige).

%    Franz Zeilinger - 10.08.2011

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: Gerätearten
% - 3. Dimension: Zeitpunkte
Power = zeros([3 size(Devices.Elements_Varna,2) (Time.Number_Steps)]);
DSM_Power = Power;
device = cell(1,size(Devices.Elements_Varna,2));

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
		Power(:,i,step) = Power(:,i,step) + dev.Power_Input;
		dev.DSM = dev.DSM.algorithm(freq, time, 0);
		dev.DSM = dev.DSM.next_step(dev, time, 0);
		DSM_Power(:,i,step) = DSM_Power(:,i,step) + ...
			dev.DSM.Power_Input;
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
	device{i} = Devices.(Devices.Elements_Varna{i});
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start

% Berechnen der Reaktionen der Verbraucher für die restlichen Zeitpunkte:
number_steps = Time.Number_Steps;
date_start = Time.Date_Start;
base = Time.Base;
parfor i = 1:size(Devices.Elements_Varna,2)
	for step = 2:number_steps
		% Aktuellen Zeitpunkt ermitteln:
		time = date_start + (step-1)*base/86400;
		% alle Frequenzpunkte ermitteln, die den letzen Simulationsschritt umfassen:
		freq = Frequency(:,Frequency(1,:) <= time);
		freq = freq(:,freq(1,:) > time - (base/86400));
		% Reaktion der Verbraucher ermitteln
		% Für jedes Element im Cell-Array Elements_Varna (Variablennamen)
		for j = 1:size(device{i},2)
			dev = device{i}(j);
			dev = dev.next_step(time, base);
			Power(:,i,step) = Power(:,i,step) + ...
				dev.Power_Input;
			dev.DSM = dev.DSM.algorithm(freq, time, base);
			dev.DSM = dev.DSM.next_step(dev, time, base);
			DSM_Power(:,i,step) = DSM_Power(:,i,step) + ...
				dev.DSM.Power_Input;
			device{i}(j) = dev;
		end
	end
end

Result.Raw_Data.Power = Power;
Result.Raw_Data.DSM_Power = DSM_Power;
end