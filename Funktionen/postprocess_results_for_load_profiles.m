function Result = postprocess_results_for_load_profiles (Households, Model, Time, ...
	Devices, Result)
%POSTPROCESS_RESULTS_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 21.09.2011
% Letzte �nderung durch:   Franz Zeilinger - 18.12.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;
% Auslesen der Zuordnung der Ger�te zu den Haushalten:
hh_devices = Households.Devices.(typ).Allocation;
% Array erstellen mit den Leistungsdaten der Haushalte:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: einzelne Haushalte
% - 3. Dimension: Zeitpunkte
power_hh = zeros(3,size(hh_devices,2),Time.Number_Steps);
power_rea_hh = power_hh;

% die Lastprofile der einzelnen Haushalte berechnen (mit Hilfe der zuvor
% ermittelten Indizes der einzelnen Ger�te):
power_ra = Result.Raw_Data.Households_Power;
power_reactive_ra = Result.Raw_Data.Households_Power_Reactive;
for i=1:size(hh_devices,2)
	idx = squeeze(hh_devices(:,i,:));
	for j=1:size(idx,1)
		dev_idx = idx(j,:);
		dev_idx(dev_idx == 0) = [];
		if ~isempty(dev_idx)
			power_hh(:,i,:) = squeeze(power_hh(:,i,:)) + ...
				squeeze(sum(power_ra(:,j,dev_idx,:),3));
			power_rea_hh(:,i,:) = squeeze(power_rea_hh(:,i,:)) + ...
				squeeze(sum(power_reactive_ra(:,j,dev_idx,:),3));
		end
	end
end
% f�r die weitere Verarbeitung die einzelnen Ger�te zu den Ger�tegruppen
% zusammenfassen (um die Funktionen der Simulation ohne Haushaltsaufteilung verwenden
% zu k�nnen:
Result.Raw_Data.Power = squeeze(sum(power_ra,3));
Result.Raw_Data.Power_Reactive = squeeze(sum(power_reactive_ra,3));


% Simulationszeitpunkte mitspeichern:
Result.Time = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;
Result.Time_Base = Time.Base;

% Einzelleistungsaufnahme der Haushalte aufgeteilt auf die einzelnen Phasen:
Result.Raw_Data.Households_Power_Phase = power_hh;
Result.Raw_Data.Households_Power_Reactive_Phase = power_rea_hh;
% Einzelleistungsaufnahme der Haushalte Gesamt:
Result.Raw_Data.Households_Power_Total = squeeze(sum(power_hh,1));
Result.Raw_Data.Households_Power_Reactive_Total = squeeze(sum(power_rea_hh,1));
% Weitere Nachbehandlung der Ergebnisse:
Result = postprocess_results(Model, Time, Devices, Result);
end

