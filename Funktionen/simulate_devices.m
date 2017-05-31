function Result = simulate_devices(hObject, Devices, Time)
%SIMULATE_DEVICES    f�hrt die eigentliche Simulation durch
%    RESULT = SIMULATE_DEVICES(HOBJECT, DEVICES, TIME) f�hrt die eigentliche
%    Simulation aus. Dazu wird �ber jeden Zeitschritt (gem�� TIME) und jedes
%    Ger�t (DEVICES) itteriert und deren aktuelle Leistung ermittelt und in die
%    RESULT-Struktur gespeichert. Weiters erfolgt eine Ausgabe des Fortschritts
%    in der Konsole. HOBJECT liefert den Zugriff auf das aufrufende GUI-Fenster
%    (f�r Statusanzeige).

%    Franz Zeilinger - 21.09.2011

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: Ger�tearten
% - 3. Dimension: Zeitpunkte
Result.Raw_Data.Power = zeros([3 size(Devices.Elements_Varna,2) (Time.Number_Steps)]);
Result.Raw_Data.Power_Reactive = Result.Raw_Data.Power;
% Ersten Zeitpnkt simulieren und dabei alle Ger�te-Einsatzpl�ne auf laufende
% Matlabzeit umrechnen:
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
		Result.Raw_Data.Power(:,i,step) = Result.Raw_Data.Power(:,i,step) + ...
			dev.Power_Input;
		Result.Raw_Data.Power_Reactive(:,i,step) = ...
			Result.Raw_Data.Power_Reactive(:,i,step) + dev.Power_Input_Reactive;
		Devices.(Devices.Elements_Varna{i})(j) = dev;

	end
end

waitbar_start; % Messen der Zeit, die ben�tigt wird - Start
% Berechnen der Reaktionen der Verbraucher f�r die restlichen Zeitpunkte:
for step = 2:Time.Number_Steps
	% Aktuellen Zeitpunkt ermitteln:
	time = Time.Date_Start + (step-1)*Time.Base/Time.day_to_sec;
	% Reaktion der Verbraucher ermitteln
	for i = 1:size(Devices.Elements_Varna,2)
		% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen)
		for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
			dev = Devices.(Devices.Elements_Varna{i})(j);
			dev = dev.next_step(time, Time.Base);
			Result.Raw_Data.Power(:,i,step) = Result.Raw_Data.Power(:,i,step) + ...
				dev.Power_Input;
			Result.Raw_Data.Power_Reactive(:,i,step) = ...
			Result.Raw_Data.Power_Reactive(:,i,step) + dev.Power_Input_Reactive;
			Devices.(Devices.Elements_Varna{i})(j) = dev;
		end
	end
	% Fortschrittsbalken updaten & �berpr�fen ob ein Abbruch durch User
	% erfolgt ist:
	if waitbar_update (hObject, 5, step-1, Time.Number_Steps-1)
		% Simulation abbrechen:
		Result = [];
		return;
	end
end
end