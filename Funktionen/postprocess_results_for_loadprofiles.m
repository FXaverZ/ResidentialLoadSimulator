function Result = postprocess_results_for_loadprofiles (Households, Model, Time, ...
	Devices, Result)
%POSTPROCESS_RESULTS_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% ACHTUNG! Debug-Einstellung bzw. für Testzwecke:
typ = Households.Types{1};

% die Lastprofile der einzelnen Haushalte berechnen (mit Hilfe der zuvor ermittelten
% Indizes der einzelnen Geräte):
hh_devices = Households.Devices.(typ);
power_ra = Result.Raw_Data.Households_Power;
power_hh = zeros(3,size(hh_devices,2),Time.Number_Steps);
for i=1:size(hh_devices,2)
	idx = squeeze(hh_devices(:,i,:));
	for j=1:size(idx,1)
		dev_idx = idx(j,:);
		dev_idx(dev_idx == 0) = [];
		if ~isempty(dev_idx)
			power_hh(:,i,:) = squeeze(power_hh(:,i,:)) + ...
				squeeze(sum(power_ra(:,j,dev_idx,:),3));
		end
	end
end
% Einzelleistungsaufnahme der Haushalte aufgeteilt auf die einzelnen Phasen:
Result.Raw_Data.Households_Power_Phase = power_hh;
% Einzelleistungsaufnahme der Haushalte Gesamt:
Result.Raw_Data.Households_Power_Total = squeeze(sum(power_hh,1));

% für die weitere Verarbeitung die einzelnen Geräte zu den Gerätegruppen
% zusammenfassen (um die Funktionen der Simulation ohne Haushaltsaufteilung verwenden
% zu können:
Result.Raw_Data.Power = squeeze(sum(power_ra,3));
% Weitere Nachbehandlung der Ergebnisse:
Result = postprocess_results(Model, Time, Devices, Result);
end

