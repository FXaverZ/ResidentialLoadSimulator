function simulation_single_cycle_for_load_profiles (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

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
% Ger�teparameter laden:
Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
% �berpr�fen, ob beim Laden Fehler aufgetreten sind:
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

% Ger�tezusammenstellung gem�� den Einstellungen auf den neuesten Stand bringen
% (notwendig f�r Ger�tegruppen):
for i=1:size(Model.Devices_Pool,1)
	% alle Ger�te, die direkt ausgew�hlt wurden, �bernehmen:
	name = Model.Devices_Pool{i,1};
	if isfield(Model.Device_Assembly, name)
		Model.Device_Assembly_Simulation.(name) = Model.Device_Assembly.(name);
	else
		% die anderen Ger�te auf null setzen (werden im n�chsten Schritt behandelt)
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

% Ger�teinstanzen erzeugen:
str = 'Erzeuge Ger�te-Instanzen: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

clear Devices
% if Configuration.Options.compute_parallel
% 	Devices = create_devices_parallel(hObject, Model);
% else
	Devices = create_devices_for_loadprofiles(hObject, Model, Households);
% end
% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
handles = guidata(hObject);
% �berpr�fen, ob bei Ger�teerzeugung von User abgebrochen wurde:
if handles.System.cancel_simulation
	str = '--> Ger�teerzeugung abgebrochen';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end
% �berpr�fen, ob Fehler bei Ger�teerzeugung aufgetreten ist:
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
	% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten
	% Gesamtzeit:
	t_total = waitbar_reset(hObject);
	fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
end
% handles-Struktur aktualisieren
guidata(hObject, handles);

% den einzelnen Haushalten die Ger�te zuweisen:
str = 'Zuordnen der Ger�teinstanzen zu den Haushalten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

Households = pick_devices_households (Households, Devices);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t\t ',str,'\n ']);

% Simulieren der Ger�te:
str = 'Simuliere die Ger�te: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

% Simulation durchf�hren:
if Configuration.Options.compute_parallel
	Result = simulate_devices_for_load_profiles_parallel(hObject, Devices, ...
		Households,	Time);
else
	Result = simulate_devices_for_load_profiles(hObject, Devices, Households, Time);
end

% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
handles = guidata(hObject);
% �berpr�fen, ob w�hrend der Ger�teerzeugung abgebrochen wurde:
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
% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten Gesamtzeit:
t_total = waitbar_reset(hObject);
fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
Result.Sim_date = Sim_date;

% Nachbehandlung der Ergebnisse:
Result = postprocess_results_for_loadprofiles (Households, Model, Time, Devices, ...
	Result);

% Daten zur�ck in handles-Struktur speichern:
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

% Gong ert�nen lassen
f = rand()*9.2+0.8;
load gong.mat;
sound(y, f*Fs);

% Daten zur�ck in handles-Struktur speichern:
handles.Configuration = Configuration;

% Simulationslog beenden
diary off

% handles-Struktur aktualisieren
guidata(hObject, handles);
end