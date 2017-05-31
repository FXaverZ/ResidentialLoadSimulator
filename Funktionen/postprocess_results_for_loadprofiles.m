function Result = postprocess_results_for_loadprofiles (Households, Model, Time, ...
	Devices, Result)
%POSTPROCESS_RESULTS_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Franz Zeilinger - 21.09.2011

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;
% Auslesen der Zuordnung der Geräte zu den Haushalten:
hh_devices = Households.Devices.(typ);
% Array erstellen mit den Leistungsdaten der Haushalte:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: einzelne Haushalte
% - 3. Dimension: Zeitpunkte
power_hh = zeros(3,size(hh_devices,2),Time.Number_Steps);
power_rea_hh = power_hh;

% je nach Berechnungsart (normal oder parallel) ist ein anderes
% Ergebnis-Leistungs-Array entstanden
if isfield(Result.Raw_Data,'Households_Power_parallel')
	power_ra = Result.Raw_Data.Households_Power_parallel(:,1:3,:,:);
	power_reactive_ra = Result.Raw_Data.Households_Power_parallel(:,4:6,:,:);
	% Für jeden Haushalt
	for i=1:size(hh_devices,2)
		% ermitteln der Indizes aller Geräte dieses Haushalts:
		idx = squeeze(hh_devices(:,i,:));
		% Für jede Geräteart:
		for j=1:size(idx,1)
			% die Indizes der aktuellen Gerätegruppe auslesen, alle Indizes mit den
			% Wert "0" entfernen:
			dev_idx = idx(j,:);
			dev_idx(dev_idx == 0) = [];
			% überprüfen, ob überhaupt Geräte dieses Typs verwendet werden:
			if ~isempty(dev_idx)
				% Falls ja, die Leistungsdaten dieser Geräte auslesen und zur
				% Gesamt-Haushaltsleistung addieren:
				power_hh(:,i,:) = squeeze(power_hh(:,i,:)) + ...
					squeeze(sum(power_ra(j,:,dev_idx,:),3));
				power_rea_hh(:,i,:) = squeeze(power_rea_hh(:,i,:)) + ...
					squeeze(sum(power_reactive_ra(j,:,dev_idx,:),3));
			end
		end
	end
% 	% für die weitere Verarbeitung die einzelnen Geräte zu den Gerätegruppen
% 	% zusammenfassen (um die Funktionen der Simulation ohne Haushaltsaufteilung verwenden
% 	% zu können:
% 	power_ra = squeeze(sum(power_ra,3));
% 	power_ra = permute(power_ra, [2 1 3]);
% 	Result.Raw_Data.Power = power_ra;
else
	% die Lastprofile der einzelnen Haushalte berechnen (mit Hilfe der zuvor
	% ermittelten Indizes der einzelnen Geräte):
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
	% für die weitere Verarbeitung die einzelnen Geräte zu den Gerätegruppen
	% zusammenfassen (um die Funktionen der Simulation ohne Haushaltsaufteilung verwenden
	% zu können:
	Result.Raw_Data.Power = squeeze(sum(power_ra,3));
	Result.Raw_Data.Power_Reactive = squeeze(sum(power_reactive_ra,3));
end

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

