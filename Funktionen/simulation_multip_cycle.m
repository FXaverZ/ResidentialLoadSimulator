function simulation_multip_cycle (hObject, handles)
% SIMULATION_MULTIP_CYCLE    f�hrt mehrere Simulationsl�ufe aus
%    SIMULATION_MULTIP_CYCLE(HOBJECT, HANDLES) f�hrt mehrere
%    Simulationsdurchl�ufe gem�� der im Feld JOBLIST der HANDLES-Struktur
%    definierten Auftr�ge durch. HOBJECT liefert den Zugriff auf das aufrufende
%    GUI, in dessen Statuszeile aktuelle Informationen zum Simulationsablauf
%    angzeigt werden. HANDLES enth�lt alle notwendigen Daten (siehe GUIDATA).

%    Franz Zeilinger - 13.10.2010

% Einlesen vorhandener Daten aus handles-Struktur:
Configuration = handles.Configuration;
Model =         handles.Model;
Devices =       handles.Devices;
Joblist =       handles.Joblist;

%Startzeitpunkt der Messreihe feststellen:
Sim_date = now; 
% Erzeugen eines Unterordners f�r die Simulationsreihe mit Namen der
% Joblisten-Datei:
file = Configuration.Save.Data;
jobl = Configuration.Save.Joblist;
file.Path = [file.Main_Path, datestr(Sim_date,'yy.mm.dd'),' - '...
	jobl.List_Name,'\'];
if ~isdir(file.Path)
	mkdir(file.Path);
end
% Simulationslog mitschreiben:
file.Diary_Name = [datestr(Sim_date,'HHhMM.SS')...
	' - Simulations-Log - ',datestr(Sim_date,'yy.mm.dd'),' - '...
	jobl.List_Name,'.txt'];
diary([file.Path,file.Diary_Name]);
Configuration.Save.Data = file;

% Durchlaufen der einzelnen Parameterdateien, welche in Joblist definiert wurden:
for i=1:size(Joblist,1)

	sim_str = ['Simulation ',num2str(i),' von ',num2str(size(Joblist,1)),': '];
	refresh_status_text(hObject,sim_str);
	fprintf(['\n\tStart der ',sim_str]);
	
	% Simulationszeitpunkt festhalten:
	Sim_date = now; 
	
	% aktuelle Modelparameter einlesen:
	str = 'Lade Parameter: ';
	refresh_status_text(hObject,[sim_str,str]);
	fprintf(['\n\t\t',str]);
	
	% Ursprung der Parameterdatei merken:
	Configuration.Save.Source.Path = Joblist{i,1};
	Configuration.Save.Source.Parameter_Name = Joblist{i,2};
	% Wenn gefordert, Simulationsparameter aus Parameterdatei laden:
	if Configuration.Options.simsettings_load_from_paramfile
		Model = load_simulation_parameter(Joblist{i,1}, Joblist{i,2}, Model);
		% Spezielle Konfigurationseinstellungen �bernehmen:
		Configuration.Options.use_same_dsm = Model.Use_Same_DSM;
	end
	% Ger�teparameter laden:
	Model = load_device_parameter(Joblist{i,1}, Joblist{i,2},Model);
	% �berpr�fen, ob beim Laden Fehler aufgetreten sind:
	if isempty(Model)
		str = '--> ein Fehler ist aufgetreten: Abbruch!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t\t',str,'\n']);
		return;
	end
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t ',str,'\n']);
	% Anzeige mit aktuellen Simulationseinstellungen versorgen:
	handles.Model = Model;
	refresh_display(handles);
	
	% Simulationszeiteinstellungen ermitteln:
	Time = get_time_settings(Model);
	
	str = 'Laden von Frequenzdaten: ';
	refresh_status_text(hObject,str);
	fprintf(['\n\t\t',str]);
	% Frequenzdaten einlesen:
	if size(Joblist,2)>2
		% Frequenzdatendateien wurden in der Jobliste angegegeben!
		try
			% �berpr�fen, ob Dateiendung vorhanden, wenn nicht, hinzuf�gen:
			str = [Joblist{i,3},Joblist{i,4}];
			if isempty(findstr(str,Configuration.Save.Frequency.Extension))
				str = [str,Configuration.Save.Frequency.Extension];
			end
			load(str,'-mat');
			handles.Frequency = Frequency;		
		catch ME
			str = '--> Ein Fehler ist aufgetreten: Abbruch!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str,'\n']);
			return;
		end
	else
		if Configuration.Options.use_last_frequency_data &&...
				isfield(handles, 'Frequency')
			Frequency = handles.Frequency;
		else
			Frequency = create_frequency_data(Time);
		end
	end
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf([str,'\n']);
	
	% �berpr�fen, ob eventuell vorhandene Ger�teinstanzen verwendet werden:
	reply = check_existing_devices (Model, Devices, Configuration);
	% Falls in Parameterdatei die Generierung neuer DSM-Instanzen festgelegt
	% wurde:
	if strcmpi(reply,'j') && ~Model.Use_Same_DSM
		reply = 'dsm';
	end
	% Erzeugen der Ger�teinstanzen:
	switch lower(reply)
		case 'j'
			% Sichern der aktuellen Ger�teinstanzen:
			Old_Devices = Devices;
			% Auswahl der f�r Simulation ben�tigten Ger�te:
			Devices = pick_devices (Model, Devices);
			fprintf('\n\t\tLade Ger�teinstanzen:\n\t\t\t --> erledigt!\n');
		case 'dsm'
			% Ger�teinstanzen werden weiterverwendet:
			fprintf('\n\t\tLade Ger�teinstanzen:\n\t\t\t --> erledigt!\n');
			% F�r alle vorhandenen Ger�teklassen DSM-Instanzen erzeugen:
			str = 'Erzeuge DSM-Instanzen: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			Devices = create_dsm_devices(hObject, Model, Devices);
			if ~isempty(Devices)
				% Erfolgsmeldung (in Konsole + GUI):
				str = '--> abgeschlossen!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str]);
				% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten
				% Gesamtzeit:
				t_total = waitbar_reset(hObject);
				fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),...
					'\n']);
			end
			% Sichern der Ger�teinstanuzen mit den neuen DSM-Instanzen:
			Old_Devices = Devices;
			% Auswahl der f�r Simulation ben�tigten Ger�te:
			Devices = pick_devices (Model, Devices);
		otherwise
			% ev. vorhandene Ger�teinstanzen l�schen:
			Old_Devices = [];
			clear Devices
			% Neue Ger�teinstanzen erzeugen:
			str = 'Erzeuge Ger�te-Instanzen: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			Devices = create_devices(hObject, Model);
			if ~isempty(Devices)
				% Erfolgsmeldung (in Konsole + GUI):
				str = '--> abgeschlossen!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str]);
				% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten
				% Gesamtzeit:
				t_total = waitbar_reset(hObject);
				fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),...
					'\n']);
			end
			% Falls notwendig, DSM-Instanzen erzeugen:
			if Model.Use_DSM && ~isempty(Devices)
				str = 'Erzeuge DSM-Instanzen: ';
				refresh_status_text(hObject,[sim_str,str]);
				fprintf(['\n\t\t',str]);
				Devices = create_dsm_devices(hObject, Model, Devices);
				if ~isempty(Devices)
					% Erfolgsmeldung (in Konsole + GUI):
					str = '--> abgeschlossen!';
					refresh_status_text(hObject,str,'Add');
					fprintf(['\n\t\t\t',str]);
					% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten
					% Gesamtzeit:
					t_total = waitbar_reset(hObject);
					fprintf(['\n\t\t\tBerechnungen beendet nach ',...
						sec2str(t_total),'\n']);
				end
			end
	end
	% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
	handles = guidata(hObject);
	% �berpr�fen, ob bei Ger�teerzeugung von User abgebrochen wurde:
	if handles.system.cancel_simulation
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
	end
	% Die erzeugten Ger�teinstanzen sichern, falls w�hrend Simulation abgebrochen
	% wird. Wurde bei diesem Durchlauf nur eine Untermenge der vorhandenen
	% Ger�te verwendet, die urspr�ngliche Ger�tekonstellation zur�ckholen:
	if ~isempty(Old_Devices)
		handles.Devices = Old_Devices;
	else
		handles.Devices = Devices;
	end
	% handles-Struktur aktualisieren
	guidata(hObject, handles);
	
	% Simulieren der Ger�te:
	if Model.Use_DSM
		% Ausgabe in Konsole und GUI:
		str = 'Simuliere (mit DSM): ';
		refresh_status_text(hObject,[sim_str,str]);
		fprintf(['\n\t\t',str]);
		% Simulation durchf�hren:
		Result = simulate_devices_with_dsm(hObject, Devices, ...
			Frequency, Time);
	else
		% Ausgabe in Konsole und GUI:
		str = 'Simuliere (ohne DSM): ';
		refresh_status_text(hObject,[sim_str,str]);
		fprintf(['\n\t\t',str]);
		% Simulation durchf�hren:
		Result = simulate_devices(hObject, Devices, Time);
	end
	% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
	handles = guidata(hObject);
	% �berpr�fen, ob w�hrend der Simulation abgebrochen wurde:
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
	% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten Gesamtzeit:
	t_total = waitbar_reset(hObject);
	fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
	
	% Nachbehandlung der Ergebnisse:
	Result.Sim_date = Sim_date;
	Result = calculate_infos (Model, Time, Devices, Result);
	
	% Anzeigen der Ergebnisse:
	if Configuration.Options.show_data
		str = 'Anzeigen der Ergebnisse: ';
		refresh_status_text(hObject,[sim_str,str]);
		fprintf(['\n\t\t',str]);
		disp_result(Model, Devices, Frequency, Result);
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf([str,'\n']);
	end
	
	% Automatisches Speichern der relevanten Daten:
	str = 'Speichern der Daten: ';
	refresh_status_text(hObject,[sim_str,str]);
	fprintf(['\n\t\t',str]);
	Configuration = save_sim_data (Configuration, Model, Devices,...
		Frequency, Result);
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf(str);
	if i < size(Joblist,1)
		fprintf('\n\t---------------------------------\n');
	end
	% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
	handles = guidata(hObject);	
	if handles.system.cancel_simulation
		str = '--> Simulation abgebrochen';
		refresh_status_text(hObject,str);
		fprintf(['\n\t\t',str,'\n']);
		return;
	end
	% Daten zur�ck in handles-Struktur speichern:
	handles.Configuration = Configuration;
	handles.Model =         Model;
	handles.Frequency =     Frequency;
	handles.Result =        Result;
	
	% handles-Struktur aktualisieren
	guidata(hObject, handles);
end

fprintf('\n\t=================================\n');
% Simulationslog beenden
diary off

end