function handles = add_settings(handles)
%GET_DATA_SETTINGS    sichert die Konfigurationseinstellungen der aktuellen Daten
%    Ausfühliche Beschreibung fehlt!

% Franz Zeilinger - 13.02.2011

% Sichern der aktuellen Einstellungen des aktuellen Datenbankauszugs:
handles.Result.Current_Settings = handles.Current_Settings;
handles.Result.System = handles.System;

end

