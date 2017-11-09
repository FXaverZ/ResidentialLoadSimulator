function simulation_single_annual_load_profiles (hObject, handles)
% SIMULATION_SINGLE_CYCLE_FOR_DEVICE_PROFILES   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 16.01.2015
% Letzte �nderung durch:   Franz Zeilinger - 05.02.2015

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
	'home_1',  1, 1, 'Haus - 1 Bewohner'             , 41;...
	'home_2',  2, 2, 'Haus - 2 Bewohner'             , 53;...
	'home_3',  3, 3, 'Haus - 3 Bewohner'             , 38;...
	'hom_4p',  4, 6, 'Haus - 4 und mehr Bewohner'    , 59;...
	'flat_1',  1, 1, 'Wohnung - 1 Bewohner'          , 92;...
	'flat_2',  2, 2, 'Wohnung - 2 Bewohner'          , 59;...
	'flat_3',  3, 3, 'Wohnung - 3 Bewohner'          , 26;...
	'fla_4p',  4, 6, 'Wohnung - 4 und mehr Bewohner' , 27;...
	};

% Wieviele Durchl�ufe sollen gemacht werden?
Model.Number_Runs = 20;

% Aufl�sung der Simulation: 'sec' = Sekundentakt
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
Model.Series_Date_End =   '31.01.2017';

% �ber welchen Zeitraum (in Tagen) sollen die Jahreszeiten "verschliffen" werden?
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
fprintf('\n\tStart der Generierung von Ger�teprofilen:');
str = '---------------------';
fprintf(['\n\t',str]);

% Ask user, if already existing models should be used for further profile Generation?
str = 'Frage an User, ob Model wiederverwendet werden soll... ';
refresh_status_text(hObject,str);
fprintf(['\n\t',str,]);

button = ...
	questdlg({['Soll ein bereits erstelltes Modell f�r die weiteren Simulationen ',...
	'verwendet werden?'];'';...
	['ACHTUNG! Es werden s�mtliche Einstellungen aus den gespeicherten Modellen ',...
	'�bernommen, ausgenommen Start- und Enddatum und zeitliche Aufl�sung!']},...
	'Model wiederverwernden?','Ja','Nein','Abbrechen','Nein');
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
		% Anzahl der Modell�ufe basierend auf den vorhandenen Modellen anpassen:
		Model.Number_Runs = numel(model_files);
		% Speichern der akutellen Einstellungen, um aus diesen die zu �bernehmenden
		% Parameter f�r die geladenen Modellen zu �bernehmen...
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

% Mehrere Durchl�ufe hintereinander:
for a = 1:Model.Number_Runs
	if a > 1
		str = '-=-=-=-=-=-=-=-=-=-=-=-';
		fprintf(['\n\n\t',str]);
	end
	fprintf(['\n\tStarte Durchlauf ',num2str(a),' von ',num2str(Model.Number_Runs),' Durchl�ufen:']);
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
		% Wichte Daten sichern:
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
		str = 'Lade aktuelle Ger�te-Parameter f�r Generiung der Ger�teausstatung... ';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		% F�r die Generierung der Ger�teaustattung den ersten Parametersatz laden:
		file = Configuration.Save.Source;
		[~, ~, file.Parameter_Name] = day2sim_parameter(Model, Time.Days_Year(1));
		
		% Ger�teparameter laden:
		Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
		% �berpr�fen, ob beim Laden Fehler aufgetreten sind:
		if isempty(Model)
			str = '--> ein Fehler ist aufgetreten: Abbruch!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t',str,'\n']);
			diary off;
			return;
		end
		
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
		fprintf(['\n\t\t ',str,'\n ']);
		
		% Ger�teausstattung f�r die einzelnen Haushaltskategorien erstellen:
		str = 'Erzeuge Ger�teausstattung der jeweiligen Haushalte...';
		refresh_status_text(hObject,str);
		fprintf(['\n\t',str,]);
		
		for b = 1:size(Households.Types,1)
			% aktuelle Haushaltskategorie ausw�hlen:
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
			% Ger�teinstanzen erzeugen:
			str = 'Erzeuge Ger�te-Instanzen... ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t',str]);
			
			clear Devices
			Devices = create_devices_for_loadprofiles(hObject, Model, Households);
			
			% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
			handles = guidata(hObject);
			% �berpr�fen, ob bei Ger�teerzeugung von User abgebrochen wurde:
			if handles.System.cancel_simulation
				str = '--> Ger�teerzeugung abgebrochen';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
				return;
			end
			% �berpr�fen, ob Fehler bei Ger�teerzeugung aufgetreten ist:
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
				% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten
				% Gesamtzeit:
				t_total = waitbar_reset(hObject);
				fprintf(['\n\t\t\t\tBerechnungen beendet nach ', sec2str(t_total)]);
			end
			
			% den einzelnen Haushalten die Ger�te zuweisen:
			str = 'Zuordnen der Ger�te-Instanzen... ';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t\t',str]);
			
			Households = pick_devices_households (Households, Devices);
			
			str = '--> erledigt!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\t',str]);
		end
		
		str = '--> Ger�te-Instanzen vollst�ndig erzeugt!';
		refresh_status_text(hObject,str,'Add');
		fprintf(['\n\n\t\t',str,'\n ']);
		
		% Speichern der bisher erstellten Daten, damit diese im Fall eines
		% Simulationsabbruchs zur Verf�gung stehen!
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
	
	% Einzelsimulationen starten und mehrfach durchf�hren:
	str = 'Starte mit Simulationsl�ufen... ';
	refresh_status_text(hObject,str);
	fprintf(['\n\n\t',str,]);
	
	% alle gefordeten Tabe abarbeiten:
	for c = 1:numel(Time.Days_Year)
		
		% Dateiinfos laden:
		file = Configuration.Save.Source;
		
		% akutelle Parameter ermitteln:
		[season, wkd] = day2sim_parameter(Model, Time.Days_Year(c));
		% vorhergehende bzw. nachfolgende Jahreszeit ermitteln, gem��
		% Verschleifeinstellungen:
		[season_overlap, season_1, season_2] = day2season_overlap(Model, Time.Days_Year(c));
		
		str = '-----------------------------';
		fprintf(['\n\t',str]);
		
		if season_overlap
			% Modellparameter anpassen
			str = 'Erstelle �bergangs-Ger�te-Parameter';
			str2 = [str,': ',...
				num2str(season_1.factor*100,'%3.2f'), '%% ',season_1.parafilemname,...
				' <-> ',...
				num2str(season_2.factor*100,'%3.2f'), '%% ',season_2.parafilemname,' ...'];
			refresh_status_text(hObject,[str,'...']);
			fprintf(['\n\t',str2,]);
			
			% Ger�teparameter laden und adaptieren:
			Model = update_model_overlap (file.Path, season_1, season_2, Model);
			% �berpr�fen, ob beim Laden Fehler aufgetreten sind:
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
			str = 'Lade aktuelle Ger�te-Parameter (Einzel)...';
			refresh_status_text(hObject,str);
			fprintf(['\n\t',str,]);
			
			% akutelle Parameter ermitteln:
			[season, wkd, file.Parameter_Name] = day2sim_parameter(Model, Time.Days_Year(c));
			
			% Ger�teparameter laden:
			Model = load_device_parameter(file.Path,file.Parameter_Name,Model);
			% �berpr�fen, ob beim Laden Fehler aufgetreten sind:
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
			
			% aktuelle Haushaltskategorie ausw�hlen:
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
			
			% Ger�teinstanzen erzeugen:
			str = 'Lade und aktualisiere Ger�te-Instanzen...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			Devices = Households.Devices.(typ).Devices;
			clear Result;
			Devices = update_device_parameters (hObject, Devices, ...
				Model, Households);
			
			% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
			handles = guidata(hObject);
			% �berpr�fen, ob bei Ger�teerzeugung von User abgebrochen wurde:
			if handles.System.cancel_simulation
				str = '--> Aktualisierung der Ger�te abgebrochen!';
				refresh_status_text(hObject,str,'Add');
				fprintf(['\n\t\t\t',str,'\n']);
				diary off;
				return;
			end
			% �berpr�fen, ob Fehler bei Ger�teerzeugung aufgetreten ist:
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
				% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten
				% Gesamtzeit:
				t_total = waitbar_reset(hObject);
				fprintf(['\n\t\t\t\tBerechnungen beendet nach ', sec2str(t_total)]);
			end
			
			% Simulieren der Ger�te:
			str = 'Simuliere die Ger�te...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			% Simulation durchf�hren:
			if Configuration.Options.compute_parallel
				Result = simulate_devices_for_load_profiles_parallel(Devices, Time);
			else
				Result = simulate_devices_for_annual_load_profiles(Devices, Time);
			end
			
			% handles Struktur aktualisieren (falls Abbrechen-Button gedr�ckt wurde)
			handles = guidata(hObject);
			% �berpr�fen, ob w�hrend der Ger�teerzeugung abgebrochen wurde:
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
			% Zur�cksetzten Fortschrittsanzeige & Bekanngabe der ben�tigten Gesamtzeit:
			t_total = waitbar_reset(hObject);
			fprintf(['\n\t\t\tBerechnungen beendet nach ', sec2str(t_total),'\n']);
			
			% Nachbehandlung der Ergebnisse:
			str = 'Nachbehandlung der Ergebnisse...';
			refresh_status_text(hObject,[sim_str,str]);
			fprintf(['\n\t\t',str]);
			
			hh_devices = Households.Devices.(typ).Allocation;
			% Array erstellen mit den Leistungsdaten der Haushalte:
			% - 1. Dimension: Phasen 1 bis 3
			% - 2. Dimension: einzelne Haushalte
			% - 3. Dimension: Zeitpunkte
			power_hh = zeros(6,size(hh_devices,2),Time.Number_Steps);
			% F�r jeden Haushalt
			for l=1:size(hh_devices,2)
				% ermitteln der Indizes aller Ger�te dieses Haushalts:
				idx = squeeze(hh_devices(:,l,:));
				% F�r jede Ger�teart:
				for m=1:size(idx,1)
					% die Indizes der aktuellen Ger�tegruppe auslesen, alle Indizes mit den
					% Wert "0" entfernen:
					dev_idx = idx(m,:);
					dev_idx(dev_idx == 0) = [];
					% �berpr�fen, ob �berhaupt Ger�te dieses Typs verwendet werden:
					if ~isempty(dev_idx)
						% Falls ja, die Leistungsdaten dieser Ger�te auslesen und zur
						% Gesamt-Haushaltsleistung addieren:
						power_hh(:,l,:) = squeeze(power_hh(:,l,:)) + ...
							squeeze(sum(Result(m,:,dev_idx,:),3));
					end
				end
			end
			clear Result;
			Households.Result.(typ) = power_hh;
			
			str = '--> abgeschlossen!';
			refresh_status_text(hObject,str,'Add');
			fprintf(['\n\t\t\t',str]);
			
			% Daten zur�ck in handles-Struktur speichern:
			handles.Model =         Model;
			handles.Households =    Households;
			
			% handles-Struktur aktualisieren (damit Daten bei ev. nachfolgenden
			% Fehlern erhalten bleiben!)
			guidata(hObject, handles);
		end
		
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

str = 'Simulation erfolgreich abgeschlossen!';
refresh_status_text(hObject,str);
fprintf(['\n\n\t',str]);

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