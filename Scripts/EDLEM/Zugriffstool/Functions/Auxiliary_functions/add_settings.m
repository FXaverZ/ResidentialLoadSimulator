function handles = add_settings(handles)
%ADD_SETTINGS    sichert die Konfigurationseinstellungen der aktuellen Daten
%    ADD_SETTINGS fügt der RESULTS-Struktur die aktuellen Einstellungen hinzu,
%    damit diese zu einem späteren Zeitpunkt aus der Struktur geladen werden können.
%    Dies ist insbesondere beim Speichern der Daten notwendig: Wenn im Zeitraum
%    zwischen dem Auslesen der Daten und dem Speichern dieser die Einstellungen im
%    GUI geändert wurden, gehen die Einstellungen der ausgelesenen Daten verloren!
%    Daher werden beim Speichern die originalen Einstellungen, die hier gesichert
%    werden, verwendet!

% Franz Zeilinger - 13.02.2011

% Sichern der aktuellen Einstellungen des aktuellen Datenbankauszugs:
handles.Result.Current_Settings = handles.Current_Settings;
handles.Result.System = handles.System;

end

