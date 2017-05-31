function Result = simulate_devices_parallel(hObject, Devices, Time)
%SIMULATE_DEVICES    f�hrt die eigentliche Simulation durch
%    RESULT = SIMULATE_DEVICES(HOBJECT, DEVICES, TIME) f�hrt die eigentliche
%    Simulation aus. Dazu wird �ber jeden Zeitschritt (gem�� TIME) und jedes
%    Ger�t (DEVICES) itteriert und deren aktuelle Leistung ermittelt und in die
%    RESULT-Struktur gespeichert. Weiters erfolgt eine Ausgabe des Fortschritts
%    in der Konsole. HOBJECT liefert den Zugriff auf das aufrufende GUI-Fenster
%    (f�r Statusanzeige).

%    Franz Zeilinger - 10.08.2011

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: Ger�tearten
% - 3. Dimension: Zeitpunkte
Power = zeros([3 size(Devices.Elements_Varna,2) (Time.Number_Steps)]);

% Ersten Zeitpnkt simulieren und dabei alle Ger�te-Einsatzpl�ne auf laufende
% Matlabzeit umrechnen:
device = cell(1,size(Devices.Elements_Varna,2));
step = 1;
time = Time.Date_Start;
for i = 1:size(Devices.Elements_Varna,2)
	% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen)
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
		% berechnet wird!
		dev = dev.next_step(time, 0);
		Power(:,i,step) = Power(:,i,step) + ...
			dev.Power_Input;
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
	device{i} = Devices.(Devices.Elements_Varna{i});
end

waitbar_start; % Messen der Zeit, die ben�tigt wird - Start
number_steps = Time.Number_Steps;
date_start = Time.Date_Start;
base = Time.Base;
% Berechnen der Reaktionen der Verbraucher f�r die restlichen Zeitpunkte:
parfor i = 1:size(Devices.Elements_Varna,2)
% for i = 1:size(Devices.Elements_Varna,2)
	for step = 2:number_steps
		% Aktuellen Zeitpunkt ermitteln:
		time = date_start + (step-1)*base/86400;
		% Reaktion der Verbraucher ermitteln
		% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen)
		for j = 1:size(device{i},2)
			dev = device{i}(j);
			dev = dev.next_step(time, base);
			Power(:,i,step) = Power(:,i,step) + ...
				dev.Power_Input;
			device{i}(j) = dev;
		end
	end
end

Result.Raw_Data.Power = Power;

end