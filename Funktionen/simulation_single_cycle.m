function simulation_single_cycle (hObject, handles)
% SIMULATION_SINGLE_CYCLE    führt einen einzelnen Simulationslauf aus
%    SIMULATION_SINGEL_CYCLE(HOBJECT, HANDLES) führt einen einzelnen
%    Simulationsdurchlauf aus. HOBJECT liefert den Zugriff auf das aufrufende
%    GUI, in dessen Statuszeile aktuelle Informationen zum Simulationsablauf
%    angzeigt werden. HANDLES enthält alle notwendigen Daten (siehe GUIDATA).

%    Franz Zeilinger - 11.10.2010

% Einlesen vorhandener Daten aus handles-Struktur:
Configuration = handles.Configuration;
Model =         handles.Model;
Devices =       handles.Devices;

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
fprintf('\n\tStart der Simulation:');
Configuration.Save.Data = file;

% aktuelle Modelparameter einlesen:
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

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t\t ',str,'\n ']);

% Simulationszeiteinstellungen ermitteln:
Time = get_time_settings(Model);

% Frequenzdaten einlesen:
if Configuration.Options.use_last_frequency_data &&...
		isfield(handles, 'Frequency') 
	Frequency = handles.Frequency;
else
	Frequency = create_frequency_data(Time);
end

% Überprüfen, ob eventuell vorhandene Geräteinstanzen verwendet werden:
reply = check_existing_devices (Model, Devices);

% Erzeugen der Geräteinstanzen:
switch lower(reply)
	case 'j'
		% Sichern der aktuellen Geräteinstanzen:
		Old_Devices = Devices;
		% Auswahl der für Simulation benötigten Geräte:
		Devices = pick_devices (Model, Devices);
		fprintf('\n\t\tLade Geräteinstanzen:\n\t\t\t --> erledigt!\n');
	case 'dsm'
		% Geräteinstanzen werden weiterverwendet:
		fprintf('\n\t\tLade Geräteinstanzen:\n\t\t\t --> erledigt!\n');
		% Für alle vorhandenen Geräteklassen DSM-Instanzen erzeugen:
		str = 'Erzeuge DSM-Instanzen: ';
		refresh_status_text(hObject,str);
		fprintf(['\n\t\t',str]);
		Devices = create_dsm_devices(hObject, Model, Devices);
		if ~isempty(Devices)
			% Erfolgsmeldung (in Konsole + GUI):
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str]);
			% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten 
			% Gesamtzeit:
			t_total = waitbar_reset(hObject);
			fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
		end
		% Sichern der Geräteinstanuzen mit den neuen DSM-Instanzen:
		Old_Devices = Devices;
		% Auswahl der für Simulation benötigten Geräte:
		Devices = pick_devices (Model, Devices);
	otherwise
		% ev. vorhandene Geräteinstanzen löschen:
		Old_Devices = [];
		clear Devices
		% Neue Geräteinstanzen erzeugen:
		str = 'Erzeuge Geräte-Instanzen: ';
		refresh_status_text(hObject,str);
		fprintf(['\n\t\t',str]);
		Devices = create_devices(hObject, Model);
		if ~isempty(Devices)
			% Erfolgsmeldung (in Konsole + GUI):
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str]);
			% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten 
			% Gesamtzeit:
			t_total = waitbar_reset(hObject);
			fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
		end
		% Falls notwendig, DSM-Instanzen erzeugen:
		if Model.Use_DSM && ~isempty(Devices)
			str = 'Erzeuge DSM-Instanzen: ';
			refresh_status_text(hObject,str);
			fprintf(['\n\t\t',str]);
			Devices = create_dsm_devices(hObject, Model, Devices);
			if ~isempty(Devices)
				% Erfolgsmeldung (in Konsole + GUI):
				str = '--> abgeschlossen!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str]);
				% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten 
				% Gesamtzeit:
				t_total = waitbar_reset(hObject);
				fprintf(['\n\t\t\tBerechnungen beendet nach ',...
					sec2str(t_total),'\n']);
			end
		end
end
% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
handles = guidata(hObject);
% Überprüfen, ob bei Geräteerzeugung von User abgebrochen wurde:
if handles.system.cancel_simulation
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
end
% Die erzeugten Geräteinstanzen sichern, falls während Simulation abgebrochen
% wird. Wurde bei diesem Durchlauf nur eine Untermenge der vorhandenen
% Geräte verwendet, die ursprüngliche Gerätekonstellation zurückholen:
if ~isempty(Old_Devices)
	handles.Devices = Old_Devices;
else
	handles.Devices = Devices;
end
% handles-Struktur aktualisieren
guidata(hObject, handles);

% Simulieren der Geräte:
if Model.Use_DSM
	% Ausgabe in Konsole und GUI:
	str = 'Simuliere (mit DSM): ';
	refresh_status_text(hObject,str);
	fprintf(['\n\t\t',str]);
	% Simulation durchführen:
	Result = simulate_devices_with_dsm(hObject, Devices, ...
		Frequency, Time);
else
	% Ausgabe in Konsole und GUI:
	str = 'Simuliere (ohne DSM): ';
	refresh_status_text(hObject,str);
	fprintf(['\n\t\t',str]);
	% Simulation durchführen:
	Result = simulate_devices(hObject, Devices, Time);
end
% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
handles = guidata(hObject);
% Überprüfen, ob während der Geräteerzeugung abgebrochen wurde:
if handles.system.cancel_simulation
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
Result = calculate_infos (Model, Time, Devices, Result);

% Daten zurück in handles-Struktur speichern:
handles.Model =         Model;
handles.Result =        Result;
handles.Frequency =     Frequency;

% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden Fehlern
% erhalten bleiben!)
guidata(hObject, handles);

% Anzeigen der Ergebnisse:
if Configuration.Options.show_data
	str = 'Anzeigen der Ergebnisse: ';
	refresh_status_text(hObject,str);
	fprintf(['\n\t\t',str]);
	
	disp_result(Model, Devices, Frequency, Result);
	
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf([str,'\n']);
end

% Automatisches Speichern der relevanten Daten:
str = 'Speichern der Daten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

Configuration = save_sim_data (Configuration, Model, Devices,...
	Frequency, Result);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(str);
fprintf('\n\t=================================\n');

% Daten zurück in handles-Struktur speichern:
handles.Configuration = Configuration;

% Simulationslog beenden
diary off

% handles-Struktur aktualisieren
guidata(hObject, handles);
end