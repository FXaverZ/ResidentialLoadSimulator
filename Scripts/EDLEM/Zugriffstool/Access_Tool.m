% ACCESS_TOOL    Zugriffstool auf die Daten von EDLEM
% Franz Zeilinger - 27.09.2011
% Last Modified by GUIDE v2.5 18-Nov-2011 17:03:10

function varargout = Access_Tool(varargin)
% ACCESS_TOOL    Zugriffstool auf die Daten von EDLEM

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Access_Tool_OpeningFcn, ...
                   'gui_OutputFcn',  @Access_Tool_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
% End initialization code - DO NOT EDIT
end

function Access_Tool_CloseRequestFcn(hObject, ~, handles)  %#ok<INUSL>
% Wird beim schließen des Hauptfensters ausgeführt und löscht zum Schluss das GUI
% hObject    Link zur Grafik Access_Tool (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

user_response = questdlg('Soll das Programm wirklich beendet werden?','Beenden?',...
	'Ja', 'Abbrechen', 'Abbrechen');
switch user_response
	case 'Abbrechen'
		% nichts unternehmen
	case 'Ja'
		% Konfiguration speichern:
		Settings = handles.Settings;
		System = handles.System; %#ok<NASGU>
		file = Settings.Last_Conf;
		% Falls Pfad der Konfigurationsdatei nicht vorhanden ist, Ordner erstellen:
		if ~isdir(file.Path)
			mkdir(file.Path);
		end
		save([file.Path,filesep,file.Name,file.Exte],'Settings','System');
		% Hint: delete(hObject) closes the figure
		delete(handles.accesstool_main_window);
end

function Access_Tool_OpeningFcn(hObject, ~, handles, varargin)
% Wird vor sichtbarwerden des Hauptfensters ausgeführt: 
% hObject    Link zur Grafik Access_Tool (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
% varargin   command line arguments to Access_Tool (see VARARGIN)

% Wo ist "Access_Tool.m" zu finden?
[~, Source_File] = fileattrib('Access_Tool.m');
% Ordner, in dem "Simulation.m" sich befindet, enthält Programm:
if ischar(Source_File)
	fprintf([Source_File,' - Current Directory auf Datei setzen, in der sich ',...
		'''Access_Tool.m'' befindet!\n']);
	% Fenster schließen:
	delete(handles.accesstool_main_window);
	return;
end
Path = fileparts(Source_File.Name);
% Subfolder in Search-Path aufnehmen (damit alle Funktionen gefunden werden
% können)
addpath(genpath(Path));
handles.Settings.Main_Path = [Path,'\'];

handles = get_default_values(handles);

try
	file = handles.Settings.Last_Conf;
	load('-mat', [file.Path,filesep,file.Name,file.Exte]);
	handles.Settings = Settings;
	handles.System = System;
	% Die Anzeige anpassen (falls bereits mehrere Erzeugungsanlagen angegeben 
	% wurden):
	todo = {'Sola','Wind'};
	for i = 1:2
		% Wieviele Erzeugungsanlagen sind im Datensatz vorhanden?
		num_plants = size(fieldnames(handles.Settings.(todo{i})),1);
		if num_plants > 2
			% Sicherheitskopie der Einstellungen erstellen:
			plants = handles.Settings.(todo{i});
			% Default-Struktur wiederherstellen:
			handles.Settings.(todo{i}) = [];
			handles.Settings.(todo{i}).Plant_1 = handles.System.(todo{i}).Default_Plant;
			handles.Settings.(todo{i}).Plant_2 = handles.System.(todo{i}).Default_Plant;
			% Falls mehr als die Defaultmäßig definierten vorhanden sind, zusätzliche
			% Parameterfelder erzeugen, damit diese dargestellt werden können:
			for j=1:num_plants-2
				handles = add_gernation_plant_to_gui(handles,todo{i});
			end
			% Einstellungen wiederherstellen:
			handles.Settings.(todo{i}) = plants;
		end
	end
	
	% Versuch, die Datenbankeinstellungen zu laden:
	if isfield(handles.Settings, 'Database')
		try
			db = handles.Settings.Database;
			load([db.Path,filesep,db.Name,filesep,db.Name,'.mat']);
			handles.Settings.Database.setti = setti;
			handles.Settings.Database.files = files;
		catch ME
			disp('Fehler beim Laden der Datenbankeinstellungen:');
			disp(ME.message);
		end
	end
catch ME
	disp('Fehler beim Laden der Konfigurationsdatei:');
	disp(ME.message);
end

% Wochentage und Jahreszeiten anpassen:
seas = handles.System.seasons;
week = handles.System.weekdays;
for i=1:3
	set(handles.(['radio_season_',num2str(i)]),'String',seas{i,2});
	set(handles.(['radio_weekday_',num2str(i)]),'String',week{i,2});
end

handles = refresh_display(handles);

% Update handles structure
guidata(hObject, handles);

function check_create_several_datasets_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Create_Several_Datasets = get(hObject,'Value');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function edit_create_several_datasets_number_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_create_several_datasets_number (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
% Eingabe auslesen:
handles.Settings.Several_Datasets_Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_genera_pv_1_installed_power_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Sola', 1,'installed_power');

function edit_genera_pv_1_number_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Sola', 1,'number');

function edit_genera_pv_2_installed_power_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Sola', 2,'installed_power');

function edit_genera_pv_2_number_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Sola', 2,'number');

function edit_genera_wind_1_installed_power_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Wind', 1,'installed_power');

function edit_genera_wind_1_number_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Wind', 1,'number');

function edit_genera_wind_2_installed_power_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Wind', 2,'installed_power');

function edit_genera_wind_2_number_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Wind', 2,'number');

function push_export_data_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    Link zur Grafik push_data_save (siehe GCBO)
% eventdata  nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% andere Schaltflächen deaktivieren:
set(handles.push_close,'Enable','off');
set(handles.push_data_save,'Enable','off');
set(handles.push_set_path_database,'Enable','off');
set(handles.push_export_data,'Enable','off');

drawnow;
handles = get_data(handles);

% Daten nachbearbeiten:
handles = adobt_data_for_display(handles);

set(handles.push_close,'Enable','on');
set(handles.push_data_save,'Enable','on');
set(handles.push_set_path_database,'Enable','on');
set(handles.push_export_data,'Enable','on');
handles = refresh_display(handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

% User informieren:
user_response = questdlg({'Daten erfolgreich extrahiert!';'';
	'Bitte nächsten Schritt auswählen...'},...
	'Datenextraktion erfolgreich',...
	'Zurück', 'Daten anzeigen', 'Daten speichern', 'Daten anzeigen');
switch user_response
	case 'Daten anzeigen'
		push_data_show_Callback(hObject, eventdata, handles)
	case 'Daten speichern'
		push_data_save_Callback(hObject, eventdata, handles)
end

% handles-Struktur aktualisieren:
guidata(hObject, handles);

function push_set_path_database_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik push_set_path_database (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

Main_Path = uigetdir(handles.Settings.Database.Path,['Auswählen des Hauptordners ',...
	'einer Datenbank:']);
if ischar(Main_Path)
	[pathstr, name] = fileparts(Main_Path);
	handles.Settings.Database.Path = pathstr;
	handles.Settings.Database.Name = name;
	% Laden der Datenbankeinstellungen:
	try
		load([pathstr,filesep,name,filesep,name,'.mat']);
		handles.Settings.Database.setti = setti;
		handles.Settings.Database.files = files;
		helpdlg('Datenbank erfolgreich geladen!', 'Laden der Datenbank...');
	catch ME
		errordlg('Am angegebenen Pfad wurde keine gültige Datenbank gefunden!',...
			'Fehler beim laden der Datenbank...');
	end
end

% handles-Structure aktualisieren:
guidata(hObject, handles);

function radio_season_1_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_season_1 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Season = logical([1 0 0]');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function radio_season_2_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_season_2 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Season = logical([0 1 0]');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function radio_season_3_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_season_3 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Season = logical([0 0 1]');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function radio_weekday_1_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_weekday_1 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Weekday = logical([1 0 0]');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function radio_weekday_2_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_weekday_2 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Weekday = logical([0 1 0]');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function radio_weekday_3_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_weekday_3 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Weekday = logical([0 0 1]');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function push_more_days_Callback(hObject, eventdata, handles)
% hObject    handle to push_more_days (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function popup_file_type_output_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_weekday_3 (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Output_Datatyp = get(hObject,'Value');

% aktuelle Dateiendung auslesen:
handles.Settings.Target.Exte = ...
	handles.System.outputdata_types{handles.Settings.Output_Datatyp,1}(2:end);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function popup_time_resolution_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik popup_time_resolution (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Time_Resolution = get(hObject,'Value');

% handles-Structure aktualisieren:
guidata(hObject, handles);

function push_close_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    Link zur Grafik push_close (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

Access_Tool_CloseRequestFcn(hObject, eventdata, handles);

function push_data_save_Callback(hObject, ~, handles) 
% hObject    Link zur Grafik push_data_save (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% aktuelle Dateierweiterung auslesen:

file = handles.Settings.Target;

[file.Name,file.Path] = uiputfile([...
	handles.System.outputdata_types(handles.Settings.Output_Datatyp,:);...
	{'*.*','Alle Dateien'}],...
	'Speicherort für generiete Daten...',...
	[file.Path,filesep,file.Name,file.Exte]);
if ~isequal(file.Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[~, file.Name, file.Exte] = fileparts(file.Name);
	file.Path = file.Path(1:end-1);
	% Konfiguration übernehmen:
	handles.Settings.Target = file;
	% Daten speichern:
	handles = save_data(handles);
	% User informieren:
	helpdlg('Daten erfolgreich gespeichert');
end

% handles-Structure aktualisieren:
guidata(hObject, handles);

function push_data_show_Callback(hObject, ~, handles)
% hObject    Link zur Grafik push_data_show (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Daten-Explorer-GUI aufrufen:
handles = Data_Explorer('Access_Tool', handles.accesstool_main_window);

% handles-Structure aktualisieren:
guidata(hObject, handles);

function push_genera_pv_1_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to push_genera_pv_1_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function push_genera_pv_2_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to push_genera_pv_2_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function push_genera_pv_add_system_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik push_genera_pv_add_system (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = add_gernation_plant_to_gui(handles,'Sola');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_genera_wind_1_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to push_genera_wind_1_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function push_genera_wind_2_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to push_genera_wind_2_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function push_genera_wind_add_system_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik push_genera_wind_add_system (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = add_gernation_plant_to_gui(handles,'Wind');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_hh_coup_pt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'coup_pt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_coup_rt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'coup_rt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_coup_vt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'coup_vt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_fami_1v_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'fami_1v';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_fami_2v_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'fami_2v';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_fami_rt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'fami_rt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_sing_pt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'sing_pt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_sing_rt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'sing_rt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);

function push_hh_sing_vt_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 nicht benötigt (MATLAB spezifisch)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

typ = 'sing_vt';

% detaillierte Daten zu den Haushalten darstellen:
get_houshold_data_for_display(handles, typ);



function edit_hh_coup_pt_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_coup_pt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 4;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_coup_rt_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_coup_rt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 6;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_coup_vt_Callback (hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_coup_vt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 2;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_fami_1v_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_fami_1v (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 8;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_fami_2v_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_fami_2v (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 7;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_fami_rt_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_fami_rt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 9;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_sing_pt_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_sing_pt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 3;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_sing_rt_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_sing_rt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 5;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_hh_sing_vt_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_hh_sing_vt (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

idx_hh = 1;
% Eingabe auslesen:
handles.Settings.Households.(handles.System.housholds{idx_hh,1}).Number = ...
	round(str2double(get(hObject,'String')));

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function popup_genera_pv_1_typ_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Sola', 1,'typ');

function popup_genera_pv_2_typ_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Sola', 2,'typ');

function popup_genera_wind_1_typ_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Wind', 1,'typ');

function popup_genera_wind_2_typ_Callback(hObject, eventdata, ~) %#ok<DEFNU>
% hObject    Link zur Grafik edit_genera_pv_1_installed_power (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% ~          nicht benötigt (MATLAB spezifisch)

set_plant_parameters(hObject, eventdata,'Wind', 2,'typ');

function popup_genera_worstcase_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik popup_hh_worstcase (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Worstcase_Generation = get(hObject,'Value');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function popup_hh_worstcase_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik popup_hh_worstcase (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Settings.Worstcase_Housholds = get(hObject,'Value');

% Anzeige aktualisieren:
handles = refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

% --- create-Funktionen (werden unmittelbar vor sichtbarmachen des GUIs ausgeführt):
function varargout = Access_Tool_OutputFcn(hObject, ~, handles) %#ok<STOUT,INUSD>
function edit_create_several_datasets_number_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_create_several_datasets_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_pv_2_installed_power_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_pv_2_installed_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_pv_1_number_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_pv_1_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_pv_2_number_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_pv_2_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_pv_1_installed_power_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_pv_1_installed_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_wind_2_installed_power_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_wind_2_installed_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_wind_1_installed_power_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_wind_1_installed_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_wind_1_number_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to edit_genera_wind_1_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_genera_wind_2_number_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_genera_wind_2_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_coup_pt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_coup_pt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_coup_rt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_coup_rt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_fami_1v_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_fami_1v (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_fami_rt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_fami_rt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_sing_vt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_sing_vt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_coup_vt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_coup_vt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_sing_pt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_sing_pt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_sing_rt_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_sing_rt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_hh_fami_2v_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to edit_hh_fami_2v (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_genera_pv_1_typ_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to popup_genera_pv_1_typ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_genera_pv_2_typ_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to popup_genera_pv_2_typ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_genera_wind_1_typ_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to popup_genera_wind_1_typ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_genera_worstcase_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to popup_genera_worstcase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_hh_worstcase_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to popup_hh_worstcase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_time_resolution_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to popup_time_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_genera_wind_2_typ_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to popup_genera_wind_2_typ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_file_type_output_CreateFcn(hObject, eventdata, handles)%#ok<DEFNU,INUSD>
% hObject    handle to popup_file_type_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
