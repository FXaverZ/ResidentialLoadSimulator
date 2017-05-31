function Configuration = save_sim_data_for_device_profiles (Configuration, Model,...
	Time, Households, Devices)  %#ok<INUSD>
%SAV_SIM_DATA_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 23.11.2012
% Letzte Änderung durch:   Franz Zeilinger - 27.11.2012

% Speicherort für Dateien:
file = Configuration.Save.Data;

% die ermittelten Daten speichern:
save([file.Path,file.Data_Name,'.mat'],'Model','Time','Households','Devices');
end

