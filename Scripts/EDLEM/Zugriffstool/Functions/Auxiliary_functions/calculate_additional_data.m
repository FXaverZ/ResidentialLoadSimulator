function structure = calculate_additional_data(structure)
%CALCULATE_ADDITIONAL_DATA    erzeugt in einer Ergebnisstruktur zus�tzliche Daten
%    CALCULATE_ADDITIONAL_DATA f�gt der Datenstruktur STRUCTURE, welche ein Feld mit
%    dem Namen "Data" haben muss, zus�tzliche Daten hinzu. Im Feld "Data" muss ein
%    [m,6*n]-Array mit Leistungsdaten von Haushalten bzw. Einspeisedaten von
%    Erzeugungsanlagen vorhanden sein (m... Anzahl Zeitpunkte; n... Anzahl
%    Einheiten). Die Anordnung der Datenspalten muss den im Zugriffstool
%    "Access_Tool.m" g�ngigen Konventionen gen�gen, d.h. das in je zwei Spalten Wirk-
%    und Blindleistung einer Phase enthalten:
%        [P_L1, Q_L1, P_L2, Q_L2, P_L3, Q_L3]
%
%    Die hinzugef�gten Daten werden in eigenen Feldern der Struktur gespeichert:
%        Active_Power_Total        ... Gesamtwirkleistungsaufnahme
%        Reactive_Power_Total      ... Gesamtblindleistungsaufnahme
%        Active_Power_Phase        ... Gesamtwirkleistungsaufnahme aufgeteilt auf 
%                                          die einzelnen Phasen
%        Reactive_Power_Phase      ... Gesamtblindleistungsaufnahme aufgeteilt auf
%                                          die einzelnen Phasen

% Franz Zeilinger - 14.02.2011

% Gesamtwirkleistungsaufnahme:
structure.Active_Power_Total = sum(structure.Data(:,1:2:end),2);
% Gesamtblindleistungsaufnahme:
structure.Reactive_Power_Total = sum(structure.Data(:,2:2:end),2);
% Gesamtwirkleistungsaufnahme aufgeteilt auf die einzelnen Phasen:
structure.Active_Power_Phase = [...
	sum(structure.Data(:,1:6:end),2),...
	sum(structure.Data(:,3:6:end),2),...
	sum(structure.Data(:,5:6:end),2)];
% Gesamtblindleistungsaufnahme aufgeteilt auf die einzelnen Phasen:
structure.Reactive_Power_Phase = [...
	sum(structure.Data(:,2:6:end),2),...
	sum(structure.Data(:,4:6:end),2),...
	sum(structure.Data(:,6:6:end),2)];
end