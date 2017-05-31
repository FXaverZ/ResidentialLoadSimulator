function simulation_single_annual_load_profiles_device_level (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_DEVICE_PROFILES   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 16.01.2015
% Letzte Änderung durch:   Franz Zeilinger - 19.08.2016

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
	% 	'fami_rt', 3, 6, 'Familie mit Pensionist(en)'    , 2;...
	% 	'sing_vt', 1, 1, 'Single Vollzeit'               , 6;...
	% 	'coup_vt', 2, 2, 'Paar Vollzeit'                 , 4;...
	% 	'sing_pt', 1, 1, 'Single Teilzeit'               , 6;...
	%  	'coup_pt', 2, 2, 'Paar Teilzeit'                 , 4;...
	% 	'sing_rt', 1, 1, 'Single Pension'                , 6;...
	% 	'coup_rt', 2, 2, 'Paar Pension'                  , 5;...
	% 	'fami_2v', 3, 6, 'Familie, 2 Mitglieder Vollzeit', 2;...
	% 	'fami_1v', 3, 6, 'Familie, 1 Mitglied Vollzeit'  , 2;...
	%--- HAUSHALTE FÜR aDSM ---
	'home_1',  1, 1, 'Haus - 1 Bewohner'             , 20;...%, 41;...%, 41;...
	'home_2',  2, 2, 'Haus - 2 Bewohner'             , 27;...%, 53;...%, 53;...
	'home_3',  3, 3, 'Haus - 3 Bewohner'             , 19;...%, 38;...%, 38;...
	'hom_4p',  4, 6, 'Haus - 4 und mehr Bewohner'    , 29;...%, 59;...%, 59;...
	'flat_1',  1, 1, 'Wohnung - 1 Bewohner'          , 46;...%, 92;...%, 92;...
	'flat_2',  2, 2, 'Wohnung - 2 Bewohner'          , 29;...%, 59;...%, 59;...
	'flat_3',  3, 3, 'Wohnung - 3 Bewohner'          , 13;...%, 26;...%, 26;...
	'fla_4p',  4, 6, 'Wohnung - 4 und mehr Bewohner' , 14;...%, 27;...%, 27;...
	};

% Wieviele Durchläufe sollen gemacht werden?
Model.Number_Runs = 4;

% Auflösung der Simulation: 'sec' = Sekundentakt
%                           '5se' = 5-Sekunden-Takt
%                           '10s' = 10-Sekunden-Takt
%                           'min' = Minutentakt
%                           '2.5m'= 2.5-Minuten-Takt
%                           '5mi' = 5-Minutentakt
%                           'quh' = Viertelstundendtakt
%                           'hou' = Stundentakt
Model.Sim_Resolution = '10s';

% Welches Jahr soll simuliert werden?
Model.Series_Date_Start = '01.01.2017';
Model.Series_Date_End =   '01.01.2018';

% Über welchen Zeitraum (in Tagen) sollen die Jahreszeiten "verschliffen" werden?
Model.Seasons_Overlap = 14;
%===============================================================================

Model.Weekdays =  {'Workda'; 'Saturd'; 'Sunday'};  % Typen der Wochentage
Model.Seasons =   {'Summer'; 'Winter'; 'Transi'};  % Typen der Jahreszeiten
Model.Seperator = ' - ';                           % Trenner im Dateinamen

% handles Struktur aktualisieren
handles.Model = Model;
% Anzeige aktualisieren, um User nicht zu verwirren:
refresh_display (handles)
% Simulationszeitpunkt festhalten.
Sim_date = now;
% Erzeugen eines Unterordners mit Simulationsdatum:
file = Configuration.Save.Data;
file.Path = [file.Main_Path, datestr(Sim_date,'yy.mm.dd'),' - Jahreslastprofile','\'];
if ~isdir(file.Path)
	mkdir(file.Path);
end
% Simulationslog mitschreiben:
file.Diary_Name = [datestr(Sim_date,'HH_MM.SS'),...
	' - Simulations-Log.txt'];
diary([file.Path,file.Diary_Name]);
Configuration.Save.Data = file;

% Simulationszeiteinstellungen ermitteln:
Time = get_time_settings(Model);

% Starten der eigentlichen Simulation:
fprintf('\n\tStart der Generierung von Geräteprofilen:');
str = '---------------------';
fprintf(['\n\t',str]);

% Ask user, if already existing models should be used for further profile Generation?
str = 'Frage an User, ob Model wiederverwendet werden soll... ';
refresh_status_text(hObject,str);
fprintf(['\n\t',str,]);

button = ...
	questdlg({['Soll ein bereits erstelltes Modell für die weiteren Simulationen ',...
	'verwendet werden?'];'';...
	['ACHTUNG! Es werden sämtliche Einstellungen aus den gespeicherten Modellen ',...
	'übernommen, ausgenommen Start- und Enddatum und zeitliche Auflösung!'];'';...
	['HINWEIS: Es wird ein kompletter Ordner durchsucht! Bitte sicherstellen, dass nur ', ...
	'das gewünschte Modell darin enthalten ist!']},...
	'Model wiederverwenden?','Ja','Nein','Abbrechen','Nein');
switch button
	case 'Ja'
		Model.Reuse = 1;
		str = '--> Ja!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t ',str,'\n ']);
	case 'Nein'
		Model.Reuse = 0;
		str = '--> Nein!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t ',str,'\n ']);
	otherwise
		str = '--> Abbruch durch User!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t',str,'\n']);
		diary off;
		return;
end

if Model.Reuse
	% load the Modeldata from a specified folder:
	str = 'Lade Modell(e) ';
	refresh_status_text(hObject,str);
	fprintf(['\n\t',str,]);
	
	file = Configuration.Save.Data;
	Path = uigetdir([file.Path],...
		'Auswahl des Ordners mit Modelldaten...');
	
	if ischar(Path)
		
		str = ['von ', strrep(Path,'\','\\'),'\\ ...'];
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		% Check, if simulation data files are present in this folder:
		files = dir(Path);
		files = struct2cell(files);
		files = files(1,3:end);
		model_files = files(cellfun(@(x) strcmp(x(end-13:end-4),'Modeldaten'), files));
		Loaded_Models = cell(1,numel(model_files));
		for i = 1:numel(model_files)
			Loaded_Model = load([Path, filesep, model_files{i}]);
			Loaded_Models{i} = Loaded_Model;
		end
		% Anzahl der Modelläufe basierend auf den vorhandenen Modellen anpassen:
		Model.Number_Runs = numel(model_files);
		% Speichern der akutellen Einstellungen, um aus diesen die zu übernehmenden
		% Parameter für die geladenen Modellen zu übernehmen...
		Model_old = Model;
		
		str = ['--> erledigt! ', num2str(numel(model_files)), ' Modelle geladen.'];
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t ',str,'\n ']);
	else
		str = '--> Abbruch durch User!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t',str,'\n']);
		diary off;
		return;
	end
end

% Mehrere Durchläufe hintereinander:

% % Zusammenfassung erstellen:
% Summary = [];
for a = 1:Model.Number_Runs
	if a > 1
		str = '-=-=-=-=-=-=-=-=-=-=-=-';
		fprintf(['\n\n\t',str]);
	end
	fprintf(['\n\tStarte Durchlauf ',num2str(a),' von ',num2str(Model.Number_Runs),' Durchläufen:']);
	str = '-=-=-=-=-=-=-=-=-=-=-=-';
	fprintf(['\n\t',str]);
	
	if Model.Reuse
		% aktuelle Modellparameter einlesen:
		str = 'Lade aktuelle gespeicherte Modellparameter... ';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		Model = Loaded_Models{a}.Model;
		Model.Reuse = Model_old.Reuse;
		Model.Series_Date_Start = Model_old.Series_Date_Start;
		Model.Series_Date_End = Model_old.Series_Date_End;
		Model.Sim_Resolution = Model_old.Sim_Resolution;
		Households = Loaded_Models{a}.Households;
		% Simulationszeitpunkt mitspeichern:
		Households.Result.Sim_date = Sim_date;
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t ',str,'\n ']);
		
		% Erstellen einer Kopie des Modells:
		str = 'Erstellen einer lokalen Kopie des verwendeten Modells...';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		file = Configuration.Save.Data;
		file.Modelcopy_Name = [datestr(Sim_date,'HH_MM.SS'),...
			' - ',num2str(a),' - Modeldaten.mat'];
		% Simulationszeitpunkt mitspeichern:
		Households.Result.Sim_date = Sim_date;
		% Dateieinstellungen speichern:
		Configuration.Save.Data = file;
		% Wichtige Daten sichern:
		save([file.Path,file.Modelcopy_Name], ...
			'Model', 'Households', 'Time', 'Configuration');
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t',str]);
		
	else
		% Haushaltskonfiguration laden:
		str = 'Lade Haushalts-Parameter... ';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		file = Configuration.Save.Source;
		Households = load_household_parameter(file.Path, file.Parameter_Name, Model);
		if isempty(Households)
			str = '--> ein Fehler ist aufgetreten: Abbruch!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t',str,'\n']);
			diary off;
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
		[~, ~, file.Parameter_Name] = day2sim_parameter(Model, Time.Days_Year(1));
		
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
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t ',str,'\n ']);
		
		% Geräteausstattung für die einzelnen Haushaltskategorien erstellen:
		str = 'Erzeuge Geräteausstattung der jeweiligen Haushalte...';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		for b = 1:size(Households.Types,1)
			% aktuelle Haushaltskategorie auswählen:
			typ = Households.Types{b,1};
			Households.Act_Type = typ;
			
			% User Informieren:
			if b > 1
				fprintf('\n');
			end
			sim_str = ['Bearb. Kat. ',num2str(b),...
				' von ',num2str(size(Households.Types,1)),' (',typ,'): '];
			str1 = ['Bearbeite Kategorie ',num2str(b),...
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
		end
		
		str = '--> Geräte-Instanzen vollständig erzeugt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\n\t\t',str,'\n ']);
		
		% Speichern der bisher erstellten Daten, damit diese im Fall eines
		% Simulationsabbruchs zur Verfügung stehen!
		str = 'Speichern des erstellten Modells...';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		file = Configuration.Save.Data;
		file.Modelcopy_Name = [datestr(Sim_date,'HH_MM.SS'),...
			' - ',num2str(a),' - Modeldaten.mat'];
		% Simulationszeitpunkt mitspeichern:
		Households.Result.Sim_date = Sim_date;
		% Dateieinstellungen speichern:
		Configuration.Save.Data = file;
		% Wichte Daten sichern:
		save([file.Path,file.Modelcopy_Name], ...
			'Model', 'Households', 'Time', 'Configuration');
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\t\t',str]);
	end
	
	% Einzelsimulationen starten und mehrfach durchführen:
	str = 'Starte mit Simulationsläufen... ';
	refresh_status_text(hObject,str);
	fprintf(['\n\n\t',str,]);
	
	% alle gefordeten Tage abarbeiten:
	for c = 1:numel(Time.Days_Year)
		
		% Dateiinfos laden:
		file = Configuration.Save.Source;
		
		% akutelle Parameter ermitteln:
		[season, wkd] = day2sim_parameter(Model, Time.Days_Year(c));
		% vorhergehende bzw. nachfolgende Jahreszeit ermitteln, gemäß
		% Verschleifeinstellungen:
		[season_overlap, season_1, season_2] = day2season_overlap(Model, Time.Days_Year(c));
		
		str = '-----------------------------';
		fprintf(['\n\t',str]);
		
		if season_overlap
			% Modellparameter anpassen
			str = 'Erstelle Übergangs-Geräte-Parameter';
			str2 = [str,': ',...
				num2str(season_1.factor*100,'%3.2f'), '%% ',season_1.parafilemname,...
				' <-> ',...
				num2str(season_2.factor*100,'%3.2f'), '%% ',season_2.parafilemname,' ...'];
			refresh_status_text(hObject,[str,'...']);
			fprintf(['\n\t',str2,]);
			
			% Geräteparameter laden und adaptieren:
			Model = update_model_overlap (file.Path, season_1, season_2, Model);
			% Überprüfen, ob beim Laden Fehler aufgetreten sind:
			if isempty(Model)
				str = '--> ein Fehler ist aufgetreten: Abbruch!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
				return;
			end
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t ',str,'\n ']);
		else
			% aktuelle Modellparameter einlesen:
			str = 'Lade aktuelle Geräte-Parameter (Einzel)...';
			refresh_status_text(hObject,str);
			fprintf(['\n\t',str,]);
			
			% akutelle Parameter ermitteln:
			[season, wkd, file.Parameter_Name] = day2sim_parameter(Model, Time.Days_Year(c));
			
			% Geräteparameter laden:
			Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
			% Überprüfen, ob beim Laden Fehler aufgetreten sind:
			if isempty(Model)
				str = '--> ein Fehler ist aufgetreten: Abbruch!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
				return;
			end
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t ',str,'\n ']);
		end
		
		% die einzelnen Haushaltskategorien simulieren:
		for d = 1:size(Households.Types,1)
			
			% aktuelle Haushaltskategorie auswählen:
			typ = Households.Types{d,1};
			Households.Act_Type = typ;
			
			% User Informieren:
			if d > 1
				fprintf('\n');
			end
			sim_str = ['Durchl. ',num2str(a),', Tag ',num2str(c),...
				': Bearb. Kat. ',num2str(d),...
				' von ',num2str(size(Households.Types,1)),' (',typ,'): '];
			str1 = ['Durchlauf ', num2str(a),' von ',num2str(Model.Number_Runs),...
				', Tag ',num2str(c),' von ',num2str(numel(Time.Days_Year)),...
				' (',season,', ',wkd,', ',datestr(Time.Days_Year(c),'dd.mm.yyyy'),'):'];
			str2 = ['Bearbeite Kategorie ',num2str(d),...
				' von ', num2str(size(Households.Types,1)),' (',typ,', ',...
				num2str(Households.Statistics.(typ).Number),' Haushalte):'];
			refresh_status_text(hObject,sim_str);
			
			fprintf(['\n\t',str1]);
			fprintf(['\n\t',str2]);
			
			% Modellparameter gem. den Haushaltsdaten anpassen:
			Model.Number_User = Households.Statistics.(typ).Number_Per_Tot;
			Model.Use_DSM = 0;
			
			% Geräteinstanzen erzeugen:
			str = 'Lade und aktualisiere Geräte-Instanzen...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
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
				fprintf(['\n\t\t\t\tBerechnungen beendet nach ', sec2str(t_total)]);
			end
			
			% Simulieren der Geräte:
			str = 'Simuliere die Geräte...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			% Simulation durchführen:
			if Configuration.Options.compute_parallel
				Result = simulate_devices_for_load_profiles_parallel(Devices, Time);
			else
				Result = simulate_devices_for_load_profiles_new(Devices, Time);
			end
			
			% handles Struktur aktualisieren (falls Abbrechen-Button gedrückt wurde)
			handles = guidata(hObject);
			% Überprüfen, ob während der Geräteerzeugung abgebrochen wurde:
			if handles.System.cancel_simulation || isempty(Result)
				str = '--> Simulation abgebrochen';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
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
			str = 'Nachbehandlung der Ergebnisse...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			% Auslesen der Zuordnung der Geräte zu den Haushalten:
			hh_devices = Households.Devices.(typ).Allocation;
			dev_names = Devices.Elements_Varna;
			% Array erstellen mit den Leistungsdaten der Haushalte:
			Households.Result.(typ) = cell(size(hh_devices,2),7);
			% Für jeden Haushalt
			for m=1:size(hh_devices,2)
				% Indizes der einzelnen Geräte des aktuellen Haushalts:
				idx = squeeze(hh_devices(:,m,:));
				% wieviele einzelne Geräte hat dieser Haushalt?:
				num_dev = sum(sum(idx>0));
				% Ein Ergebnisarray erstellen:
				dev_hh_power = zeros(num_dev,3,Time.Number_Steps);
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
						dev_hh_power(dev_counter,:,:) = ...
							squeeze(Result(n,1:3,dev_idx,:));
						dev = Devices.(dev_names{n})(dev_idx);
						dev_hh_devices{dev_counter} = dev;
						dev_hh_names{dev_counter} = dev_names{n};
						dev_counter = dev_counter + 1;
					end
				end
				Households.Result.(typ){m,1} = dev_hh_names;
				Households.Result.(typ){m,2} = dev_hh_devices;
				Households.Result.(typ){m,3} = dev_hh_power;
				Households.Result.(typ){m,6} = squeeze(sum(dev_hh_power));
			end
			clear Result;
			
			% Simulationszeit speichern:
			Result.Sim_date = Sim_date;
			
			% Allgemeine Nachbehandlung:
			Households = ...
				postprocess_results_for_annual_profiles_device_level (Households,...
			Devices, Model, Time);
			
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str]);
			
% 			% Zusammenfassung erstellen bzw. aktualisieren:
% 			str = 'Aktualisieren der Zusammenfassung...';
% 			refresh_status_text(hObject,[sim_str,str]);
% 			fprintf(['\n\n\t\t',str]);
% 			
% 			Summary = update_summary_for_device_profiles(Model, Devices, ...
% 				Households, Summary, season, wkd);
% 			
% 			str = '--> erledigt!';
% 			refresh_status_text(hObject,str,'Add');
% 			fprintf(['\n\t\t\t',str]);
			
			% Daten zurück in handles-Struktur speichern:
			handles.Model =         Model;
			handles.Households =    Households;
			
			% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden
			% Fehlern erhalten bleiben!)
			guidata(hObject, handles);
		end
		
% 		% Anzahl an Tagen in der Zusammenfassung aktualisieren:
% 		if isfield(Summary, season) && ...
% 				isfield(Summary.(season), wkd) && ...
% 				isfield(Summary.(season).(wkd), 'Number_Days')
% 			Summary.(season).(wkd).Number_Days = ...
% 				Summary.(season).(wkd).Number_Days + 1;
% 		else
% 			Summary.(season).(wkd).Number_Days = 1;
% 		end
		
		% Automatisches Speichern der relevanten Daten:
		str = 'Speichern der Simulationsergebnisse...';
		refresh_status_text(hObject,[sim_str,str]);
		fprintf(['\n\n\t',str]);
		
		Configuration = save_sim_data_for_device_profiles (Configuration,...
			Model, Time.Days_Year(c), a, Households);
		
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(str);
	end
end

% % Speichern der Zusammenfassung:
% str = 'Speichern der Zusammenfassung der Daten...';
% refresh_status_text(hObject,[sim_str,str]);
% fprintf(['\n\n\t',str]);
% 
% Configuration = save_summary_data_for_device_profiles(Configuration, Summary, ...
% 	Households, Devices, Model, Time);
% 
% str = '--> erledigt!';
% refresh_status_text(hObject,str,'Add');
% fprintf(str);


str = 'Simulation erfolgreich abgeschlossen!';
refresh_status_text(hObject,str);
fprintf(['\n\n\t',str]);

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