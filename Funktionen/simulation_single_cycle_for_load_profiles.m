function simulation_single_cycle_for_load_profiles (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 05.12.2011
% Letzte Änderung durch:   Franz Zeilinger - 06.11.2012

% debug: Zufallszahlengenerator definiert setzen:
% rng(27,'v5uniform');

% Einlesen vorhandener Daten aus handles-Struktur:
Configuration = handles.Configuration;
Model =         handles.Model;

%===============================================================================
%             E I N S T E L L U N G E N  -  S I M U L A T I O N
%-------------------------------------------------------------------------------
% Definition der Haushalte, die Simuliert werden sollen:
Model.Households = {...
	%--- HAUSHALTE FÜR EDLEM ---
	'fami_rt', 3, 6, 'Familie mit Pensionist(en)'        ,  3;...
	'sing_vt', 1, 1, 'Single Vollzeit'                   ,  3;...
	'coup_vt', 2, 2, 'Paar Vollzeit'                     ,  3;...
	'sing_pt', 1, 1, 'Single Teilzeit'                   ,  3;...
	'coup_pt', 2, 2, 'Paar Teilzeit'                     ,  3;...
	'sing_rt', 1, 1, 'Single Pension'                    ,  3;...
	'coup_rt', 2, 2, 'Paar Pension'                      ,  3;...
	'fami_2v', 3, 6, 'Familie, 2 Mitglieder Vollzeit'    ,  3;...
	'fami_1v', 3, 6, 'Familie, 1 Mitglied Vollzeit'      ,  3;...
	%--- HAUSHALTE FÜR aDSM ---
	%   'home_1',  1, 1, 'Haus - 1 Bewohner'             , 10;...
	% 	'home_2',  2, 2, 'Haus - 2 Bewohner'             ,  8;...
	% 	'home_3',  3, 2, 'Haus - 3 Bewohner'             ,  5;...
	% 	'hom_4p',  4, 7, 'Haus - 4 und mehr Bewohner'    ,  4;...
	% 	'flat_1',  1, 1, 'Wohnung - 1 Bewohner'          , 10;...
	% 	'flat_2',  2, 2, 'Wohnung - 2 Bewohner'          ,  8;...
	% 	'flat_3',  3, 3, 'Wohnung - 3 Bewohner'          ,  5;...
	% 	'fla_4p',  4, 7, 'Wohnung - 4 und mehr Bewohner' ,  4;...
	};

% Wieviele Durchläufe sollen gemacht werden?
Model.Number_Runs = 200;

% Auflösung der Simulation: 'sec' = Sekundentakt
%                           'min' = Minutentakt
%                           '5mi' = 5-Minutentakt
%                           'quh' = Viertelstundendtakt
%                           'hou' = Stundentakt
Model.Sim_Resolution = 'sec';
%===============================================================================

Model.Weekdays =  ['Workda'; 'Saturd'; 'Sunday'];  % Typen der Wochentage
Model.Seasons =   {'Summer'; 'Winter'; 'Transi'};  % Typen der Jahreszeiten
Model.Seperator = ' - ';                           % Trenner im Dateinamen

Programm = {...
	'Param - Winter - Sunday', 'Winter', 'Sunday';...
	'Param - Winter - Workda', 'Winter', 'Workda';...
	'Param - Winter - Saturd', 'Winter', 'Saturd';...
	'Param - Summer - Sunday', 'Summer', 'Sunday';...
	'Param - Summer - Workda', 'Summer', 'Workda';...
	'Param - Summer - Saturd', 'Summer', 'Saturd';...
	'Param - Transi - Sunday', 'Transi', 'Sunday';...
	'Param - Transi - Workda', 'Transi', 'Workda';...
	'Param - Transi - Saturd', 'Transi', 'Saturd';...
	};

% handles Struktur aktualisieren
handles.Model = Model;
% Anzeige aktualisieren, um User nicht zu verwirren:
refresh_display (handles)
% Simulationszeitpunkt festhalten.
Sim_date = now;

% Erzeugen eines Unterordners mit Simulationsdatum:
file = Configuration.Save.Data;
file.Path = [file.Main_Path, datestr(Sim_date,'yy.mm.dd'),' - Lastprofile','\'];
if ~isdir(file.Path)
	mkdir(file.Path);
end
Configuration.Save.Data = file;

% Simulationslog mitschreiben:
file.Diary_Name = [datestr(Sim_date,'HH_MM.SS'),...
	' - Simulations-Log - ',Model.Sim_Resolution,'.txt'];
diary([file.Path,file.Diary_Name]);


% Starten:
fprintf('\n\tStart der Generierung von Geräteprofilen:');
str = '---------------------';
fprintf(['\n\t',str]);

% Haushaltskonfiguration laden:
str = 'Lade Haushalts-Parameter... ';
refresh_status_text(hObject,str);
fprintf(['\n\t',str,]);

file = Configuration.Save.Source;
Households = load_household_parameter(file.Path, file.Parameter_Name, Model);
if isempty(Households)
	str = '--> ein Fehler ist aufgetreten: Abbruch!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t ',str,'\n ']);


% aktuelle Modellparameter einlesen:
str = 'Lade aktuelle Geräte-Parameter für Generiung der Geräteausstatung... ';
refresh_status_text(hObject,str);
fprintf(['\n\t',str,]);

% Für die Generierung der Geräteaustattung den ersten Parametersatz laden:
file = Configuration.Save.Source;
file.Parameter_Name = Programm{1,1};

% Geräteparameter laden:
Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
% Überprüfen, ob beim Laden Fehler aufgetreten sind:
if isempty(Model)
	str = '--> ein Fehler ist aufgetreten: Abbruch!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t',str,'\n']);
	diary off;
	return;
end

% Gerätezusammenstellung gemäß den Einstellungen auf den neuesten Stand
% bringen (notwendig für Gerätegruppen):
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

% Simulationszeiteinstellungen ermitteln:
Time = get_time_settings(Model);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf(['\n\t\t ',str,'\n ']);

% Einzelsimulationen wiederholen:
for k = 1:Model.Number_Runs
	% User Informieren:
	if k > 1
		fprintf('\n');
	end
	str = '---------------------';
	fprintf(['\n\t',str]);
	str = ['Durchlauf ',num2str(k),' von ',num2str(Model.Number_Runs),' ...'];
	refresh_status_text(hObject,str);
	fprintf(['\n\t',str,]);
	
	for l=1:size(Households.Types,1)
		% aktuelle Haushaltskategorie auswählen:
		typ = Households.Types{l,1};
		Households.Act_Type = typ;
		
		% User Informieren:
		if l > 1
			fprintf('\n');
		end
		sim_str = ['Bearb. Kat. ',num2str(l),...
			' von ',num2str(size(Households.Types,1)),' (',typ,'): '];
		str1 = ['Bearbeite Kategorie ',num2str(l),...
			' von ', num2str(size(Households.Types,1)),' (',typ,', ',...
			num2str(Households.Statistics.(typ).Number),' Haushalte)...'];
		refresh_status_text(hObject,sim_str);
		fprintf(['\n\t\t',str1]);
		
		% Modellparameter gem. den Haushaltsdaten anpassen:
		Model.Number_User = Households.Statistics.(typ).Number_Per_Tot;
		Model.Use_DSM = 0;
		% Geräteinstanzen erzeugen:
		str = 'Erzeuge Geräte-Instanzen... ';
		refresh_status_text(hObject,[sim_str,str]);
		fprintf(['\n\t\t\t',str]);
		
		clear Devices
		Devices = create_devices_for_loadprofiles(hObject, Model, Households);
		
		% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
		handles = guidata(hObject);
		% Überprüfen, ob bei Geräteerzeugung von User abgebrochen wurde:
		if handles.System.cancel_simulation
			str = '--> Geräteerzeugung abgebrochen';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str,'\n']);
			diary off;
			return;
		end
		% Überprüfen, ob Fehler bei Geräteerzeugung aufgetreten ist:
		if isempty(Devices)
			str = '--> Ein Fehler ist aufgetreten: Abbruch!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str,'\n']);
			diary off;
			return;
		else
			% Erfolgsmeldung (in Konsole + GUI):
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\t\t',str]);
			% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten
			% Gesamtzeit:
			t_total = waitbar_reset(hObject);
			fprintf(['\n\t\t\t\tBerechnungen beendet nach ', sec2str(t_total)]);
		end
		
		% den einzelnen Haushalten die Geräte zuweisen:
		str = 'Zuordnen der Geräte-Instanzen... ';
		refresh_status_text(hObject,[sim_str,str]);
		fprintf(['\n\t\t\t',str]);
		
		Households = pick_devices_households (Households, Devices);
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\t',str]);
		
		% Nun die einzelnen Wochentage und Jahreszeiten durchsimulieren:
		for m=1:size(Programm,1)
			
			% akutelle Parameter aus Programm-Cell-Array auslesen:
			wkd = Programm{m,3};
			season = Programm{m,2};
			file.Parameter_Name = Programm{m,1};
			str = '----';
			fprintf(['\n\t\t\t',str]);
			str = ['Simuliere ', season,', ' wkd,...
				' (',typ,', Durchlauf ',num2str(k),' von ',...
				num2str(Model.Number_Runs),') ...'];
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t',str]);
			
			% aktuelle Modellparameter einlesen:
			str = 'Lade aktuelle Model-Parameter...';
			refresh_status_text(hObject,str);
			fprintf(['\n\t\t\t\t',str,]);
			
			% Geräteparameter laden:
			file = Configuration.Save.Source;
			file.Parameter_Name = Programm{m,1};
			Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
			% Überprüfen, ob beim Laden Fehler aufgetreten sind:
			if isempty(Model)
				str = '--> ein Fehler ist aufgetreten: Abbruch!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\t',str]);
				return;
			end
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\t',str]);
			
			% Modellparameter gem. den Haushaltsdaten anpassen:
			Model.Number_User = Households.Statistics.(typ).Number_Per_Tot;
			Model.Use_DSM = 0;
			
			% Geräteinstanzen aktualisieren:
			str = 'Lade und aktualisiere Geräte-Instanzen...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t\t',str]);
			
			Devices = Households.Devices.(typ).Devices;
			clear Result;
			Devices = update_device_parameters (hObject, Devices, ...
				Model, Households);
			
			% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
			handles = guidata(hObject);
			% Überprüfen, ob bei Geräteerzeugung von User abgebrochen wurde:
			if handles.System.cancel_simulation
				str = '--> Aktualisierung der Geräte abgebrochen!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
				return;
			end
			% Überprüfen, ob Fehler bei Geräteerzeugung aufgetreten ist:
			if isempty(Devices)
				str = '--> Ein Fehler ist aufgetreten: Abbruch!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
				return;
			else
				% Erfolgsmeldung (in Konsole + GUI):
				str = '--> abgeschlossen!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\t\t',str]);
				% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten
				% Gesamtzeit:
				t_total = waitbar_reset(hObject);
				fprintf(['\n\t\t\t\t\tBerechnungen beendet nach ', sec2str(t_total)]);
			end
			
			% Simulieren der Geräte:
			str = 'Simuliere die Geräte...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t\t',str]);
			
			% Simulation durchführen:
			if Configuration.Options.compute_parallel
				Result = simulate_devices_for_load_profiles_parallel(Devices, Time);
			else
				Result = simulate_devices_for_load_profiles(hObject, Devices, Time);
			end
			
			% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
			handles = guidata(hObject);
			% Überprüfen, ob während der Geräteerzeugung abgebrochen wurde:
			if handles.System.cancel_simulation || isempty(Result)
				str = '--> Simulation abgebrochen';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\t',str,'\n']);
				diary off;
				return;
			end
			% Statustextausgabe (in Konsole):
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\t',str]);
			% Zurücksetzten Fortschrittsanzeige & Bekanngabe der benötigten Gesamtzeit:
			t_total = waitbar_reset(hObject);
			fprintf(['\n\t\t\t\t\tBerechnungen beendet nach ', sec2str(t_total)]);
			
			% Nachbehandlung der Ergebnisse:
			str = 'Nachbehandlung der Ergebnisse...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t\t',str]);
			
			if Configuration.Options.compute_parallel
				hh_devices = Households.Devices.(typ).Allocation;
				% Array erstellen mit den Leistungsdaten der Haushalte:
				% - 1. Dimension: Phasen 1 bis 3
				% - 2. Dimension: einzelne Haushalte
				% - 3. Dimension: Zeitpunkte
				power_hh = zeros(6,size(hh_devices,2),Time.Number_Steps);
				% Für jeden Haushalt
				for i=1:size(hh_devices,2)
					% ermitteln der Indizes aller Geräte dieses Haushalts:
					idx = squeeze(hh_devices(:,i,:));
					% Für jede Geräteart:
					for j=1:size(idx,1)
						% die Indizes der aktuellen Gerätegruppe auslesen, alle Indizes mit den
						% Wert "0" entfernen:
						dev_idx = idx(j,:);
						dev_idx(dev_idx == 0) = [];
						% überprüfen, ob überhaupt Geräte dieses Typs verwendet werden:
						if ~isempty(dev_idx)
							% Falls ja, die Leistungsdaten dieser Geräte auslesen und zur
							% Gesamt-Haushaltsleistung addieren:
							power_hh(:,i,:) = squeeze(power_hh(:,i,:)) + ...
								squeeze(sum(Result(j,:,dev_idx,:),3));
						end
					end
				end
				clear Result;
			else
				Result = pick_results_for_load_profiles (Households, Model, Time, ...
					Devices, Result);
			end
			
			% Simulationszeitpunkte mitspeichern:
			Result.Time = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;
			Result.Time_Base = Time.Base;
			Result.Sim_date = Sim_date;
			
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\t',str]);
			
			% Daten zurück in handles-Struktur speichern:
			handles.Model =         Model;
			handles.Result =        Result;
			handles.Households =    Households;
			
			% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden Fehlern
			% erhalten bleiben!)
			guidata(hObject, handles);
			
			% Automatisches Speichern der relevanten Daten:
			str = 'Speichern der Daten: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t\t',str]);
			
			% Dateinamen festlegen:
			file = Configuration.Save.Data;
			sep = Model.Seperator;
			reso = Model.Sim_Resolution;
			date = datestr(Sim_date,'HH_MM.SS');
			idx = num2str(k);
			file.Data_Name = [date,sep,reso,sep,typ,sep,idx,sep,season,sep,wkd];
			Configuration.Save.Data = file;
			
			if Configuration.Options.compute_parallel
				% Speichern der wichtigen Workspacevariablen:
				data_phase = zeros(size(power_hh,3),6*size(power_hh,2));
				data_phase(:,1:6:end) = squeeze(power_hh(1,:,:))';
				data_phase(:,3:6:end) = squeeze(power_hh(2,:,:))';
				data_phase(:,5:6:end) = squeeze(power_hh(3,:,:))';
				data_phase(:,2:6:end) = squeeze(power_hh(4,:,:))';
				data_phase(:,4:6:end) = squeeze(power_hh(5,:,:))';
				data_phase(:,6:6:end) = squeeze(power_hh(6,:,:))'; %#ok<NASGU>
				clear power_hh;
				
				save([file.Path,file.Data_Name,'.mat'], 'data_phase', 'Households');
				clear data_phase;
			else
				Configuration = save_sim_data_for_load_profiles (Configuration, Model,...
					Households, Devices, Result, k);
			end
			
			% Für bessere Speichernutzung, diese Daten löschen...
			clear Result
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\t',str]);
		end
	end
end
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