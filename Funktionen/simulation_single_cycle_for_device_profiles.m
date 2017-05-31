function simulation_single_cycle_for_device_profiles (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_DEVICE_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 05.12.2011
% Letzte Änderung durch:   Franz Zeilinger - 28.11.2012

% debug: Zufallszahlengenerator definiert setzen:
rng(27,'v5uniform');

% Einlesen vorhandener Daten aus handles-Struktur:
Configuration = handles.Configuration;
Model =         handles.Model;

%===============================================================================
%             E I N S T E L L U N G E N  -  S I M U L A T I O N
%-------------------------------------------------------------------------------
% Definition der Haushalte, die Simuliert werden sollen:
Model.Households = {... 
%--- HAUSHALTE FÜR EDLEM --- 
% 	'fami_rt', 3, 6, 'Familie mit Pensionist(en)'    , 2;... % 30 - 10
% 	'sing_vt', 1, 1, 'Single Vollzeit'               , 6;... % 20 - 20
% 	'coup_vt', 2, 2, 'Paar Vollzeit'                 , 4;... % 20 - 0
% 	'sing_pt', 1, 1, 'Single Teilzeit'               , 6;... % 10 - -10
%  	'coup_pt', 2, 2, 'Paar Teilzeit'                 , 4;... % 20 - 0
% 	'sing_rt', 1, 1, 'Single Pension'                , 6;... % 30 - 10
% 	'coup_rt', 2, 2, 'Paar Pension'                  , 5;... % 90 - 70
% 	'fami_2v', 3, 6, 'Familie, 2 Mitglieder Vollzeit', 2;... % 40 - 20    
% 	'fami_1v', 3, 6, 'Familie, 1 Mitglied Vollzeit'  , 2;... % 70 - 50
%--- HAUSHALTE FÜR aDSM ---
% 	'home_1',  1, 1, 'Haus - 1 Bewohner'             , 13;...
% 	'home_2',  2, 2, 'Haus - 2 Bewohner'             , 17;...
% 	'home_3',  3, 2, 'Haus - 3 Bewohner'             , 12;...
% 	'hom_4p',  4, 7, 'Haus - 4 und mehr Bewohner'    , 19;...
% 	'flat_1',  1, 1, 'Wohnung - 1 Bewohner'          , 29;...
% 	'flat_2',  2, 2, 'Wohnung - 2 Bewohner'          , 19;...
% 	'flat_3',  3, 3, 'Wohnung - 3 Bewohner'          ,  9;...
	'fla_4p',  4, 7, 'Wohnung - 4 und mehr Bewohner' ,  8;...
	};

% Wieviele Durchläufe sollen gemacht werden?
Model.Number_Runs = 1;

% Auflösung der Simulation: 'sec' = Sekundentakt
%                           'min' = Minutentakt
%                           '5mi' = 5-Minutentakt
%                           'quh' = Viertelstundendtakt
%                           'hou' = Stundentakt
Model.Sim_Resolution = 'min';
%===============================================================================

Model.Weekdays =  ['Workda'; 'Saturd'; 'Sunday'];  % Typen der Wochentage
Model.Seasons =   {'Summer'; 'Winter'; 'Transi'};  % Typen der Jahreszeiten
Model.Seperator = ' - ';                           % Trenner im Dateinamen

Programm = {...
	'Param - Summer - Sunday', 'Summer', 'Sunday';...
% 	'Param - Summer - Workda', 'Summer', 'Workda';...
% 	'Param - Summer - Workda', 'Summer', 'Workda';...
% 	'Param - Summer - Workda', 'Summer', 'Workda';...
% 	'Param - Summer - Workda', 'Summer', 'Workda';...
% 	'Param - Summer - Workda', 'Summer', 'Workda';...
% 	'Param - Summer - Saturd', 'Summer', 'Saturd';...
% 	'Param - Winter - Sunday', 'Winter', 'Sunday';...
% 	'Param - Winter - Workda', 'Winter', 'Workda';...
% 	'Param - Winter - Workda', 'Winter', 'Workda';...
% 	'Param - Winter - Workda', 'Winter', 'Workda';...
% 	'Param - Winter - Workda', 'Winter', 'Workda';...
% 	'Param - Winter - Workda', 'Winter', 'Workda';...
% 	'Param - Winter - Saturd', 'Winter', 'Saturd';...
	};

% handles Struktur aktualisieren
handles.Model = Model;
% Anzeige aktualisieren, um User nicht zu verwirren:
refresh_display (handles)
% Simulationszeitpunkt festhalten.
Sim_date = now;
% Erzeugen eines Unterordners mit Simulationsdatum:
file = Configuration.Save.Data;
file.Path = [file.Main_Path, datestr(Sim_date,'yy.mm.dd'),' - Geräteprofile','\'];
if ~isdir(file.Path)
	mkdir(file.Path);
end
% Simulationslog mitschreiben:
file.Diary_Name = [datestr(Sim_date,'HH_MM.SS'),...
	' - Simulations-Log - ',Model.Sim_Resolution,'.txt'];
diary([file.Path,file.Diary_Name]);
fprintf('\n\tStart der Generierung von Geräteprofilen:');
Configuration.Save.Data = file;

file = Configuration.Save.Source;

% Haushaltskonfiguration laden:
Households = load_household_parameter(file.Path, file.Parameter_Name, Model);
if isempty(Households)
	str = '--> ein Fehler ist aufgetreten: Abbruch!';
	refresh_status_text(hObject,str,'Add');
	fprintf(['\n\t\t\t',str,'\n']);
	return;
end
% Einzelsimulationen wiederholen:
for j = 1:Model.Number_Runs
	for k=1:size(Programm,1)
		
		file = Configuration.Save.Source;
		
		% akutelle Parameter aus Programm-Cell-Array auslesen:
		wkd = Programm{k,3};
		season = Programm{k,2};
		file.Parameter_Name = Programm{k,1};
		str = '---------------------';
		fprintf(['\n\t',str]);
		
		% aktuelle Modellparameter einlesen:
		str = 'Lade Parameter: ';
		refresh_status_text(hObject,str);
		fprintf(['\n\t\t',str,]);
		
		% Geräteparameter laden:
		Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
		% Überprüfen, ob beim Laden Fehler aufgetreten sind:
		if isempty(Model)
			str = '--> ein Fehler ist aufgetreten: Abbruch!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str,'\n']);
			return;
		end
		
		% Simulationszeiteinstellungen ermitteln:
		Time = get_time_settings(Model);
		
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
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t\t ',str,'\n ']);
		
		% die einzelnen Haushaltskategorien simulieren:
		for i = 1:size(Households.Types,1)
% 		try
			% aktuelle Haushaltskategorie auswählen:
			typ = Households.Types{i,1};
			Households.Act_Type = typ;

			% User Informieren:
			if i > 1
				fprintf('\n');
			end
			sim_str = ['Durchl. ',num2str(j),': Bearb. Kat. ',num2str(i),...
				' von ',num2str(size(Households.Types,1)),' (',typ,'): '];
			str1 = ['Durchlauf ', num2str(j),', ',season,', ',wkd,':']; 
			str2 = ['Bearbeite Kategorie ',num2str(i),...
				' von ', num2str(size(Households.Types,1)),' (',typ,', ',...
				num2str(Households.Statistics.(typ).Number),' Haushalte):'];
			refresh_status_text(hObject,sim_str);
			fprintf(['\n\t',str1]);
			fprintf(['\n\t',str2]);
			
			% Modellparameter gem. den Haushaltsdaten anpassen:
			Model.Number_User = Households.Statistics.(typ).Number_Per_Tot;
			Model.Use_DSM = 0;
			
			% Geräteinstanzen erzeugen:
			str = 'Erzeuge Geräte-Instanzen: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			clear Devices
			clear Result
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
			
			% den einzelnen Haushalten die Geräte zuweisen:
			str = 'Zuordnen der Geräteinstanzen zu den Haushalten: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			Households = pick_devices_households (Households, Devices);
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t ',str,'\n ']);
			
			% Simulieren der Geräte:
			str = 'Simuliere die Geräte: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
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
			
			% Nachbehandlung der Ergebnisse:
			str = 'Nachbehandlung der Ergebnisse: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			% Bei paralleler Simulation direkte Bearbeitung der Ergebnisse (bessere
			% Speichernutzung und schneller...)
			if Configuration.Options.compute_parallel
				% Auslesen der Zuordnung der Geräte zu den Haushalten:
				hh_devices = Households.Devices.(typ);
				dev_names = Devices.Elements_Varna;
				% Array erstellen mit den Leistungsdaten der Haushalte:
				Households.Devices_Power.(typ) = cell(size(hh_devices,2),3);
				% Für jeden Haushalt
				for m=1:size(hh_devices,2)
					% Indizes der einzelnen Geräte des aktuellen Haushalts:
					idx = squeeze(hh_devices(:,m,:));
					% wieviele einzelne Geräte hat dieser Haushalt?:
					num_dev = sum(sum(idx>0));
					% Ein Ergebnisarray erstellen:
					dev_hh_power = zeros(num_dev,Time.Number_Steps);
					dev_hh_names =cell(num_dev,1);
					dev_hh_devices =cell(num_dev,1);
					dev_counter = 1;
					% Für jede Geräteart:
					for n=1:size(idx,1)
						% die Indizes der aktuellen Gerätegruppe auslesen, alle
						% Indizes mit den Wert "0" entfernen:
						dev_idxs = idx(n,:);
						dev_idxs(dev_idxs == 0) = [];
						for o=1:numel(dev_idxs)
							dev_idx = dev_idxs(o);
							dev_hh_power(dev_counter,:) = sum(squeeze(Result(n,1:3,dev_idx,:)));
							dev = Devices.(dev_names{n})(dev_idx);
							dev_hh_devices{dev_counter} = dev;
							dev_hh_names{dev_counter} = dev_names{n};
							dev_counter = dev_counter + 1;
						end
					end
					Households.Devices_Power.(typ){m,1} = dev_hh_names;
					Households.Devices_Power.(typ){m,2} = dev_hh_devices;
					Households.Devices_Power.(typ){m,3} = dev_hh_power;
					Households.Devices_Power.(typ){m,6} = sum(dev_hh_power);
					Households.Devices_Power.(typ){m,7} = sum(sum(dev_hh_power))/60000;
				end
				clear Result;
			end
			
			% Simulationszeit speichern:
			Result.Sim_date = Sim_date;
			Households.Devices_Power.Sim_date = Sim_date;
			
			% Allgemeine Nachbehandlung:
			Households = postprocess_results_for_device_profiles (Households,...
					Time, Devices, Result);
			
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str]);
			
			% Daten zurück in handles-Struktur speichern:
			handles.Model =         Model;
			handles.Result =        Result;
			handles.Households =    Households;
			
			% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden Fehlern
			% erhalten bleiben!)
			guidata(hObject, handles);
% 		catch ME
% 			% Falls Fehler aufgetreten ist:
% 			str = 'Ein Fehler ist aufgetreten:';
% 			refresh_status_text(hObject,[sim_str,str]);
% 			fprintf(['\n\t\t',str]);
% 			str = ME.message;
% 			fprintf(['\n\t\t',str]);
% 			str = 'Worker werden neu gestartet:';
% 			fprintf(['\n\t\t',str]);
% 			if Configuration.Options.compute_parallel && matlabpool('size') == 0
% 				matlabpool('open');
% 			end
% 			if Configuration.Options.compute_parallel && matlabpool('size') > 0;
% 				matlabpool('close');
% 				matlabpool('open');
% 			end
% 			str = ['Simulation wird fortgesetzt, ',...
% 				'Daten des aktuellen Durchlaufs gehen verloren!'];
% 			fprintf(['\n\t\t',str]);
% 		end
		end
	end
	
	% Automatisches Speichern der relevanten Daten:
	str = 'Speichern der Daten: ';
	refresh_status_text(hObject,[sim_str,str]);
	fprintf(['\n\n\t',str]);
	
	% Dateinamen festlegen:
	file = Configuration.Save.Data;
	sep = Model.Seperator;
	reso = Model.Sim_Resolution;
	date = datestr(Sim_date,'HH_MM.SS');
	idx = num2str(j);
	file.Data_Name = [date,sep,season,sep,wkd,sep,reso,sep,idx];
	Configuration.Save.Data = file;
	
	Configuration = save_sim_data_for_device_profiles (Configuration, Model,...
		Time, Households, Devices);
	
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf(str);
	
	% Zusammenfassung erstellen bzw. aktualisieren:
	str = 'Aktualisieren der Zusammenfassung: ';
	refresh_status_text(hObject,[sim_str,str]);
	fprintf(['\n\n\t',str]);
	
	% Insert Code here...
	
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf(str);
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