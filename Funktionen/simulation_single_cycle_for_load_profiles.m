function simulation_single_cycle_for_load_profiles (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

%    Franz Zeilinger - 23.08.2011

% Einlesen vorhandener Daten aus handles-Struktur:
Configuration = handles.Configuration;
Model =         handles.Model;
% Devices =       handles.Devices;
% Households =    handles.Households;

%Simulationszeitpunkt festhalten.
Sim_date = now; 
% Erzeugen eines Unterordners mit Simulationsdatum:
file = Configuration.Save.Data;
file.Path = [file.Main_Path, datestr(Sim_date,'yy.mm.dd'),'\'];
if ~isdir(file.Path)
	mkdir(file.Path);
end
% Simulationslog mitschreiben:
file.Diary_Name = [datestr(Sim_date,'HHhMM.SS'),...
	' - Simulations-Log - ',Model.Sim_Resolution,' - ',...
	num2str(Model.Number_User),'.txt'];
diary([file.Path,file.Diary_Name]);
fprintf('\n\tStart der Generierung von Lastprofilen:');
Configuration.Save.Data = file;

% aktuelle Modellparameter einlesen:
str = 'Lade Parameter: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str,]);

file = Configuration.Save.Source;
% Wenn gefordert, Simulationsparameter aus Parameterdatei laden:
if Configuration.Options.simsettings_load_from_paramfile
	Model = load_simulation_parameter(file.Path,file.Parameter_Name, Model);
end
% Geräteparameter laden:
Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
% Überprüfen, ob beim Laden Fehler aufgetreten sind:
if isempty(Model)
	str = '--> ein Fehler ist aufgetreten: Abbruch!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end
% Haushaltskonfiguration laden:
Households = load_household_parameter(file.Path, file.Parameter_Name, Model);
if isempty(Households)
	str = '--> ein Fehler ist aufgetreten: Abbruch!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end
% Modellparameter gem. den Haushaltsdaten anpassen:
Model.Number_User = Households.Number_Persons.Total;
Model.Use_DSM = 0;

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t\t ',str,'\n ']);

% Simulationszeiteinstellungen ermitteln:
Time = get_time_settings(Model);

% Gerätezusammenstellung gemäß den Einstellungen auf den neuesten Stand bringen
% (notwendig für Gerätegruppen):
for i=1:size(Model.Devices_Pool,1)
	% alle Geräte, die direkt ausgewählt wurden, übernehmen:
	name = Model.Devices_Pool{i,1};
	if isfield(Model.Device_Assembly, name)
		Model.Device_Assembly_Simulation.(name) = Model.Device_Assembly.(name);
	else
		% die anderen Geräte auf null setzen (werden im nächsten Schritt behandelt)
		Model.Device_Assembly_Simulation.(name) = 0;
	end
end
for i=1:size(Model.Device_Groups_Pool,1)
	grp_name = Model.Device_Groups_Pool{i,1};
	if isfield(Model.Device_Groups, grp_name)
		Model = ...
			Model.Device_Groups.(grp_name).update_device_assembly(Model);
	end
end

% Geräteinstanzen erzeugen:
str = 'Erzeuge Geräte-Instanzen: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

clear Devices
% if Configuration.Options.compute_parallel
% 	Devices = create_devices_parallel(hObject, Model);
% else
	Devices = create_devices_for_loadprofiles(hObject, Model, Households);
% end
% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
handles = guidata(hObject);
% Überprüfen, ob bei Geräteerzeugung von User abgebrochen wurde:
if handles.System.cancel_simulation
	str = '--> Geräteerzeugung abgebrochen';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end
% Überprüfen, ob Fehler bei Geräteerzeugung aufgetreten ist:
if isempty(Devices)
	str = '--> Ein Fehler ist aufgetreten: Abbruch!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
else
	% Erfolgsmeldung (in Konsole + GUI):
	str = '--> abgeschlossen!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str]);
	% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten
	% Gesamtzeit:
	t_total = waitbar_reset(hObject);
	fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
end
% handles-Struktur aktualisieren
guidata(hObject, handles);

% den einzelnen Haushalten die Geräte zuweisen:
str = 'Zuordnen der Geräteinstanzen zu den Haushalten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

Households = pick_devices_households (Households, Devices);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t\t ',str,'\n ']);

% Simulieren der Geräte:
str = 'Simuliere die Geräte: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

% Simulation durchführen:
if Configuration.Options.compute_parallel
	Result = simulate_devices_for_load_profiles_parallel(hObject, Devices, ...
		Households,	Time);
else
	Result = simulate_devices_for_load_profiles(hObject, Devices, Households, Time);
end

% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
handles = guidata(hObject);
% Überprüfen, ob während der Geräteerzeugung abgebrochen wurde:
if handles.System.cancel_simulation || isempty(Result)
	str = '--> Simulation abgebrochen';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end
% Statustextausgabe (in Konsole):
str = '--> abgeschlossen!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t\t',str]);
% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten Gesamtzeit:
t_total = waitbar_reset(hObject);
fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
Result.Sim_date = Sim_date;

% Nachbehandlung der Ergebnisse:
Result = postprocess_results_for_loadprofiles (Households, Model, Time, Devices, ...
	Result);

% Daten zurück in handles-Struktur speichern:
handles.Model =         Model;
handles.Result =        Result;
handles.Households =    Households;

% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden Fehlern
% erhalten bleiben!)
guidata(hObject, handles);

% Automatisches Speichern der relevanten Daten:
str = 'Speichern der Daten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

Configuration = save_sim_data_for_loadprofiles (Configuration, Model,...
	Households, Devices, Result);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(str);
fprintf('\n\t=================================\n');

% Gong ertönen lassen
f = rand()*9.2+0.8;
load gong.mat;
sound(y, f*Fs);

% Daten zurück in handles-Struktur speichern:
handles.Configuration = Configuration;

% Simulationslog beenden
diary off

% handles-Struktur aktualisieren
guidata(hObject, handles);
end