function Result = simulate_devices_for_load_profiles(hObject, Devices, Households,...
	Time)
%SIMULATE_DEVICES_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

%    Franz Zeilinger - 22.08.2011

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: Gerätearten
% - 3. Dimension: Geräteinstanz
% - 4. Dimension: Zeitpunkte
Power = zeros([3 size(Devices.Elements_Varna,2) max(Devices.Number_Dev)...
	(Time.Number_Steps)]);

% Ersten Zeitpunkt simulieren und dabei alle Geräte-Einsatzpläne auf laufende
% Matlabzeit umrechnen:
step = 1;
time = Time.Date_Start;
for i = 1:size(Devices.Elements_Varna,2)
	% Für jedes Element im Cell-Array Elements_Varna (Variablennamen)
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
		% berechnet wird!
		dev = dev.next_step(time, 0);
		Power(:,i,dev.ID_Index,step) = dev.Power_Input;
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start
% Berechnen der Reaktionen der Verbraucher für die restlichen Zeitpunkte:
for step = 2:Time.Number_Steps
	% Aktuellen Zeitpunkt ermitteln:
	time = Time.Date_Start + (step-1)*Time.Base/Time.day_to_sec;
	% Reaktion der Verbraucher ermitteln
	for i = 1:size(Devices.Elements_Varna,2)
		% Für jedes Element im Cell-Array Elements_Varna (Variablennamen)
		for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
			dev = Devices.(Devices.Elements_Varna{i})(j);
			dev = dev.next_step(time, Time.Base);
			Power(:,i,j,step) = dev.Power_Input;
			Devices.(Devices.Elements_Varna{i})(j) = dev;
		end
	end
	% Fortschrittsbalken updaten & überprüfen ob ein Abbruch durch User
	% erfolgt ist:
	if waitbar_update (hObject, 5, step-1, Time.Number_Steps-1)
		% Simulation abbrechen:
		Result = [];
		return;
	end
end

Result.Raw_Data.Households_Power = Power;
end