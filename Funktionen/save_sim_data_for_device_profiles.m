function Configuration = save_sim_data_for_device_profiles (Configuration, ...
	Model, act_day, run_idx, Households)
%SAV_SIM_DATA_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 23.11.2012
% Letzte Änderung durch:   Franz Zeilinger - 18.12.2012

% Speicherort für Dateien:
file = Configuration.Save.Data;

% Speichernamen erstellen:
sep = Model.Seperator;
reso = Model.Sim_Resolution;
sim_date = datestr(Households.Result.Sim_date,'HH_MM.SS');
date = datestr(act_day,'yyyy-mm-dd');

% akutelle Parameter ermitteln:
[season, wkd] = day2sim_parameter(Model, act_day);

file.Data_Name = [sim_date,sep,num2str(run_idx),sep,date,sep,season,sep,wkd,sep,reso];
Configuration.Save.Data = file;

Result = Households.Result; %#ok<NASGU>

% die ermittelten Daten speichern:
save([file.Path,file.Data_Name,'.mat'],'Result');
end

