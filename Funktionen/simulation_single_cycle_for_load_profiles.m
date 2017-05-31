function simulation_single_cycle_for_load_profiles (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_LOAD_PROFILES   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 05.12.2011
% Letzte �nderung durch:   Franz Zeilinger - 06.11.2012

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
%--- HAUSHALTE F�R EDLEM --- 
% 	'fami_rt', 3, 6, 'Familie mit Pensionist(en)'    , 2;...
% 	'sing_vt', 1, 1, 'Single Vollzeit'               , 6;... 
% 	'coup_vt', 2, 2, 'Paar Vollzeit'                 , 4;... 
% 	'sing_pt', 1, 1, 'Single Teilzeit'               , 6;... 
%  	'coup_pt', 2, 2, 'Paar Teilzeit'                 , 4;... 
% 	'sing_rt', 1, 1, 'Single Pension'                , 6;... 
% 	'coup_rt', 2, 2, 'Paar Pension'                  , 5;... 
% 	'fami_2v', 3, 6, 'Familie, 2 Mitglieder Vollzeit', 2;...    
% 	'fami_1v', 3, 6, 'Familie, 1 Mitglied Vollzeit'  , 2;... 
%--- HAUSHALTE F�R aDSM ---
    'home_1',  1, 1, 'Haus - 1 Bewohner'             , 10;...
	'home_2',  2, 2, 'Haus - 2 Bewohner'             ,  8;...
	'home_3',  3, 2, 'Haus - 3 Bewohner'             ,  5;...
	'hom_4p',  4, 7, 'Haus - 4 und mehr Bewohner'    ,  4;...
	'flat_1',  1, 1, 'Wohnung - 1 Bewohner'          , 10;...
	'flat_2',  2, 2, 'Wohnung - 2 Bewohner'          ,  8;...
	'flat_3',  3, 3, 'Wohnung - 3 Bewohner'          ,  5;...
	'fla_4p',  4, 7, 'Wohnung - 4 und mehr Bewohner' ,  4;...
	};

% Wieviele Durchl�ufe sollen gemacht werden?
Model.Number_Runs = 100;

% Aufl�sung der Simulation: 'sec' = Sekundentakt
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
% Simulationslog mitschreiben:
file.Diary_Name = [datestr(Sim_date,'HH_MM.SS'),...
	' - Simulations-Log - ',Model.Sim_Resolution,'.txt'];
diary([file.Path,file.Diary_Name]);
fprintf('\n\tStart der Generierung von Lastprofilen:');
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
		
		% Ger�teparameter laden:
		Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
		% �berpr�fen, ob beim Laden Fehler aufgetreten sind:
		if isempty(Model)
			str = '--> ein Fehler ist aufgetreten: Abbruch!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str,'\n']);
			return;
		end
		
		% Simulationszeiteinstellungen ermitteln:
		Time = get_time_settings(Model);
		
		% Ger�tezusammenstellung gem�� den Einstellungen auf den neuesten Stand
		% bringen (notwendig f�r Ger�tegruppen):
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
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t\t ',str,'\n ']);
		
		% die einzelnen Haushaltskategorien simulieren:
		for i = 1:size(Households.Types,1)
% 		try
			% aktuelle Haushaltskategorie ausw�hlen:
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
			
			% Ger�teinstanzen erzeugen:
			str = 'Erzeuge Ger�te-Instanzen: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			clear Devices
			clear Result
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
			% 		% handles-Struktur aktualisieren
			% 		guidata(hObject, handles);
			
			% den einzelnen Haushalten die Ger�te zuweisen:
			str = 'Zuordnen der Ger�teinstanzen zu den Haushalten: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			Households = pick_devices_households (Households, Devices);
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t ',str,'\n ']);
			
			% Simulieren der Ger�te:
			str = 'Simuliere die Ger�te: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			% Simulation durchf�hren:
			if Configuration.Options.compute_parallel
				Result = simulate_devices_for_load_profiles_parallel(Devices, Time);
			else
				Result = simulate_devices_for_load_profiles(hObject, Devices, Time);
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
			
			% Nachbehandlung der Ergebnisse:
			str = 'Nachbehandlung der Ergebnisse: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			if Configuration.Options.compute_parallel
				hh_devices = Households.Devices.(typ).Allocation;
				% Array erstellen mit den Leistungsdaten der Haushalte:
				% - 1. Dimension: Phasen 1 bis 3
				% - 2. Dimension: einzelne Haushalte
				% - 3. Dimension: Zeitpunkte
				power_hh = zeros(6,size(hh_devices,2),Time.Number_Steps);
				% F�r jeden Haushalt
				for m=1:size(hh_devices,2)
					% ermitteln der Indizes aller Ger�te dieses Haushalts:
					idx = squeeze(hh_devices(:,m,:));
					% F�r jede Ger�teart:
					for n=1:size(idx,1)
						% die Indizes der aktuellen Ger�tegruppe auslesen, alle Indizes mit den
						% Wert "0" entfernen:
						dev_idx = idx(n,:);
						dev_idx(dev_idx == 0) = [];
						% �berpr�fen, ob �berhaupt Ger�te dieses Typs verwendet werden:
						if ~isempty(dev_idx)
							% Falls ja, die Leistungsdaten dieser Ger�te auslesen und zur
							% Gesamt-Haushaltsleistung addieren:
							power_hh(:,m,:) = squeeze(power_hh(:,m,:)) + ...
								squeeze(sum(Result(n,:,dev_idx,:),3));
						end
					end
				end
				clear Result;
			else
				Result = postprocess_results_for_load_profiles (Households, Model, Time, ...
					Devices, Result);
			end
			
			Result.Sim_date = Sim_date;
			
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str]);
			
			% Daten zur�ck in handles-Struktur speichern:
			handles.Model =         Model;
			handles.Result =        Result;
			handles.Households =    Households;
			
			% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden Fehlern
			% erhalten bleiben!)
			guidata(hObject, handles);
			
			% Automatisches Speichern der relevanten Daten:
			str = 'Speichern der Daten: ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			% Dateinamen festlegen:
			file = Configuration.Save.Data;
			sep = Model.Seperator;
			reso = Model.Sim_Resolution;
			date = datestr(Sim_date,'HH_MM.SS');
			idx = [num2str(j),sep,num2str(k)];
			file.Data_Name = [date,sep,season,sep,wkd,sep,typ,sep,reso,sep,idx];
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
				
				save([file.Path,file.Data_Name,'.mat'], 'data_phase');
				clear data_phase;
			else
				Configuration = save_sim_data_for_load_profiles (Configuration, Model,...
					Households, Devices, Result, j);
			end
			
			% F�r bessere Speichernutzung, diese Daten l�schen...
			clear Result
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(str);
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
end
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