% M-File für GUI nach Auswahl 'Simulationsreihe-->Einstellungen'
% Franz Zeilinger - 19.08.2010 - R2008b lauffähig
% Last Modified by GUIDE v2.5 29-Oct-2010 15:56:29

function varargout = Settings_Multiple_Simulation(varargin)

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Settings_Multiple_Simulation_OpeningFcn, ...
                   'gui_OutputFcn',  @Settings_Multiple_Simulation_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
% Ende Initializationscode - NICHT EDITIEREN!
end

function check_simsettings_load_from_main_window_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafikobjekt check_simsettings_load_from_main_window (siehe GCBO)
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.simsettings_load_from_paramfile = ~val;
handles.Configuration.Options.simsettings_load_from_main_window = val;

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_simsettings_load_from_paramfile_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt check_simsettings_load_from_paramfile (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.simsettings_load_from_paramfile = val;
handles.Configuration.Options.simsettings_load_from_main_window = ~val;

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_use_different_frequency_data_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt check_use_same_dsm (siehe GCBO)
% ~	         nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.use_different_frequency_data = val;
if ~val
	handles.Configuration.Options.use_same_paramter_file = 0;
	set(handles.check_use_same_paramter_file,'Value',0);
end

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_use_same_devices_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafikobjekt check_use_same_dsm (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.use_same_devices = val;
if ~val
	handles.Configuration.Options.use_same_dsm = 0;
end

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles)

function check_use_same_dsm_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt check_use_same_dsm (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.use_same_dsm = val;
if val
	handles.Configuration.Options.use_same_devices = 1;
end

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles)

function check_use_same_paramter_file_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt check_use_same_dsm (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.use_same_paramter_file = val;

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles)

function push_joblist_load_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt push_joblist_load (siehe GCBO)
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Laden der Joblist-Datei
file = handles.Configuration.Save.Joblist;
[file.List_Name,file.Path] = uigetfile({...
	'*.xls','Excel-Parameterdatei (.xls)';...
	'*.*','Alle Dateien'},...
	'Zu ladende Job-Liste auswählen',...
	[file.Path,file.List_Name,'.xls']);

if ~isequal(file.List_Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[~, file.List_Name] = fileparts(file.List_Name);
	% Jobliste laden:
	handles.Joblist = load_joblist(file.Path, file.List_Name);
	if ~isempty(handles.Joblist)
		%Übernehmen der neue Konfiguration:
		handles.Configuration.Save.Joblist = file;
		% Simulationsmodus anpassen auf Simulationsreihe:
		handles.Configuration.Options.multiple_simulation = 1;
		handles.changed_data = 0;
	else
		handles.Configuration.Options.multiple_simulation = 0;
		error_text = {...
			'Die Job-Liste konnte nicht geladen werden!';...
			};
		error_titl = 'Fehler beim Laden der Jobliste';
		errordlg(error_text, error_titl);
	end
end

% Anzeigen aktualiesieren:
refresh_display(handles);
% handles-Struktur aktualisieren
guidata(hObject, handles)

function push_joblist_new_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt push_joblist_new (siehe GCBO)
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Joblist = {};

Save = handles.Configuration.Save;
Save.Joblist.Path = Save.Settings.Path;
Save.Joblist.Parameter_Name = Save.Source.Parameter_Name;
Save.Joblist.List_Name = 'Simulationsreihe';

handles.Configuration.Save = Save;
handles.changed_data = 0;

% Anzeigen aktualiesieren:
refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles)

function push_joblist_save_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafikobjekt push_joblist_save (siehe GCBO)
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

file = handles.Configuration.Save.Joblist;

[file.List_Name,file.Path] = uiputfile({...
	'*.xls','Excel-Parameterdatei (.xls)';...
	'*.*','Alle Dateien'},...
	'Speichern der Jobliste',...
	[file.Path,file.List_Name,'.xls']);
if ~isequal(file.List_Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[eventdata, file.List_Name] = fileparts(file.List_Name);
	% Konfiguration übernehmen:
	handles.Configuration.Save.Joblist = file;
	% speichern der Job-Liste:
	if save_joblist(handles.Configuration, handles.Joblist);
		handles.changed_data = 0;
	end
end
% Anzeigen aktualiesieren:
refresh_display(handles);
% handles-Struktur aktualisieren
guidata(hObject, handles)

function push_joblist_show_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafikobjekt push_joblist_show (siehe GCBO)
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

if handles.changed_data
	ask_text = ['Die Daten der Job-Liste haben sich geändert!',...
		' Sollen die Änderungen gespeichert werden?'];
	title_text = 'Daten speichern?';
	user_response = questdlg(ask_text,...
		title_text,'Speichern', 'Änderungen verwerfen', 'Speichern');
	switch lower(user_response)
		case 'änderungen verwerfen'
		case 'speichern'
			push_joblist_save_Callback(hObject, eventdata, handles)
			handles = guidata(hObject);
		otherwise
			return;
	end
end
try
	file = handles.Configuration.Save.Joblist;
	winopen([file.Path,file.List_Name,'.xls']);
catch ME
	error_text = {...
		'Fehler sind beim Laden der Job-Listendatei aufgetreten:';...
		' ';...
		[' - ',ME.message]};
	error_titl = 'Fehler beim Laden der Parameterdatei';
	errordlg(error_text, error_titl);
end

function push_parameter_add_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt push_parameter_add (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Simulationsmodus anpassen auf Simulationsreihe:
handles.Configuration.Options.multiple_simulation = 1;

file = handles.Configuration.Save.Joblist;

if ~handles.Configuration.Options.use_same_paramter_file || ...
	isempty(handles.Joblist)
	% Festlegen der nächsten Parameterdatei:
	[file.Parameter_Name,file.Path] = uigetfile({...
		'*.xls','Excel-Parameterdatei (.xls)';...
		'*.*','Alle Dateien'},...
		'Zu ladende Parameterdatei auswählen',...
		file.Path);
end
if ~isequal(file.Parameter_Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[~, file.Parameter_Name] = fileparts([file.Path, file.Parameter_Name]);
	Joblist = {file.Path, file.Parameter_Name};
	handles.Configuration.Save.Joblist = file;
	handles.changed_data = 1;
end

if handles.Configuration.Options.use_different_frequency_data
	% Festlegen der nächsten Frequenzdatendatei:
	file = handles.Configuration.Save.Frequency;
	
	[file.Name,file.Path] = uigetfile(['*',file.Extension],...
		'Zu ladende Frequenzdaten auswählen',...
		file.Path);
	if ~isequal(file.Name,0) && ~isequal(file.Path,0)
		% Entfernen der Dateierweiterung:
		[~, file.Name] = fileparts([file.Path, file.Name]);
		Joblist = {Joblist{:}, file.Path, [file.Name, file.Extension]};
		handles.Configuration.Save.Frequency = file;
	end
end
handles.Joblist(end+1,:)=Joblist;
% Anzeigen aktualiesieren:
refresh_display(handles);
% handles-Struktur aktualisieren
guidata(hObject, handles)

function radio_simmod_multip_cyc_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafikobjekt radio_simmod_multip_cyc (siehe GCBO)
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.multiple_simulation = val;

% Anzeigen aktualiesieren:
refresh_display(handles);
% handles-Struktur aktualisieren
guidata(hObject, handles)

function radio_simmod_single_cyc_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik des Hauptfensters
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

val = get(hObject,'Value');
handles.Configuration.Options.multiple_simulation = ~val;

if val
	handles.Configuration.Options.use_different_frequency_data = 0;
	set(handles.check_use_different_frequency_data,'Value',0);
	handles.Configuration.Options.use_same_paramter_file = 0;
	set(handles.check_use_same_paramter_file,'Value',0);
end

refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function refresh_display(handles)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

opt = handles.Configuration.Options;

if opt.multiple_simulation 
	set(handles.radio_simmod_multip_cyc,'Value',1);
	set(handles.radio_simmod_single_cyc,'Value',0);
else
	set(handles.radio_simmod_multip_cyc,'Value',0);
	set(handles.radio_simmod_single_cyc,'Value',1);
end

set(handles.check_simsettings_load_from_paramfile,'Value',...
	opt.simsettings_load_from_paramfile);
set(handles.check_simsettings_load_from_main_window,'Value',...
	opt.simsettings_load_from_main_window);
set(handles.check_use_different_frequency_data,'Value',...
	opt.use_different_frequency_data);
set(handles.check_use_same_devices,'Value',opt.use_same_devices);
set(handles.check_use_same_dsm,'Value',opt.use_same_dsm);
set(handles.check_use_same_paramter_file,'Value',opt.use_same_paramter_file);

% Ist Joblistendatei vorhanden?
try
	file = handles.Configuration.Save.Joblist;
	fid = fopen([file.Path,file.List_Name,'.xls'],'r');
	set (handles.push_joblist_show,'Enable','On');
	if isempty(ferror(fid))
		fclose(fid);
	end
catch ME
	set (handles.push_joblist_show,'Enable','Off');
end
if isempty(handles.Joblist)
	set (handles.push_joblist_show,'Enable','Off');
	set(handles.push_joblist_new, 'Enable', 'off');
end

% Sind neue Daten zum Speichern vorhanden?
if handles.changed_data
	set(handles.push_joblist_save, 'Enable', 'on');
	set(handles.push_joblist_new, 'Enable', 'on');
else
	set(handles.push_joblist_save, 'Enable', 'off');
end
	
% Bei Einzelsimulation ausgrauen nicht benötigter Felder:
if ~opt.multiple_simulation
	set(handles.push_joblist_new, 'Enable', 'off');
	set(handles.push_joblist_show, 'Enable', 'off');
	set(handles.push_joblist_save, 'Enable', 'off');
	set(handles.check_use_same_devices, 'Enable', 'off');
	set(handles.check_use_same_dsm, 'Enable', 'off');
	set(handles.check_use_different_frequency_data, 'Enable', 'off');
	set(handles.check_use_same_paramter_file, 'Enable', 'off');
else
	set(handles.check_use_same_devices, 'Enable', 'on');
	set(handles.check_use_different_frequency_data, 'Enable', 'on');
end

% Wenn zusätzliche Frequenzdaten angegeben werden:
if opt.use_different_frequency_data
	set(handles.check_use_same_paramter_file, 'Enable', 'on');
else
	set(handles.check_use_same_paramter_file, 'Enable', 'off');
end

if opt.use_same_devices
	set(handles.check_use_same_dsm, 'Enable', 'on');
else
	set(handles.check_use_same_dsm, 'Enable', 'off');
end

function settings_multiple_sim_CloseRequestFcn(hObject, eventdata, handles)
% hObject    Link zu Grafik des Hauptfensters
% eventdata  wird in zukünftigen Versionen von Matlab benötigt
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

if handles.changed_data
	ask_text = ['Die Daten der Job-Liste haben sich geändert!',...
		' Sollen die Änderungen gespeichert werden?'];
	title_text = 'Daten speichern?';
	user_response = questdlg(ask_text,...
		title_text,'Speichern', 'Änderungen verwerfen', 'Speichern');
	switch lower(user_response)
		case 'änderungen verwerfen'
		otherwise
			push_joblist_save_Callback(hObject, eventdata, handles)
			handles = guidata(hObject);
	end
end

% Konfiguration übernehmen:
handles.main_handles.Configuration = handles.Configuration;
handles.main_handles.Joblist = handles.Joblist;

% handles-Struktur aktualisieren
guidata(hObject, handles);

% Warten auf Usereingabe beenden:
uiresume(handles.settings_multiple_sim);

function Settings_Multiple_Simulation_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    Link zu Grafik des Hauptfensters
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
% varargin   Command-Line Argumente für Settings_Multiple_Simulation (siehe VARARGIN)

dontOpen = false;
% Überprüfen, ob dieses GUI vom richtigen GUI aufgerufen wird:     
try
	start_gui_Input = find(strcmp(varargin, 'Simulation'));
	if (isempty(start_gui_Input)) ||...
			(length(varargin) <= start_gui_Input) ||...
			(~ishandle(varargin{start_gui_Input+1}))
		% Falls nicht das richtige GUI diese Funktion aufgerufen hat bzw. nicht
		% die handles-Struktur übergeben wurde --> Abbruch!
		dontOpen = true;
	else
		% ansonsten handles-Struktur aus aufrufenden GUI kopieren:
		start_gui_hObject = varargin{start_gui_Input+1};
		main_handles = guidata(start_gui_hObject);
		handles.main_handles = main_handles;
		
		% Die wichtigen Strukturen in handles-Struktur laden:
		handles.Configuration = main_handles.Configuration;
		if isfield(main_handles,'Joblist')
			handles.Joblist = main_handles.Joblist;
		else
			% Falls noch keine Jobliste vorhanden ist, leere erzeugen:
			handles.Joblist = {};
		end
		
		% Merker für neue Daten:
		handles.changed_data = 0;
		
		% Anzeigen aktualisieren:
		refresh_display(handles);
	end
catch ME
end

% Wenn nicht vom richtigen GUI aufgerufen --> Fehlermeldung in Konsole:
if dontOpen
	disp('---------------------------------------------------------------');
	disp('Falsche Argumente bei Aufruf. Es muss ein Parameter-Wert Paar')
	disp('übergeben werden dessen Name ''Simulation'' und Wert der Handle')
	disp('auf das GUI von Simulation.m ist! z.B.');
	disp('   x = Simulation()');
	disp('   Settings_Multiple_Simulation(...');
	disp('                           ''Simulation'', handles.main_window)');
	disp('---------------------------------------------------------------');
	% Update handles structure
	guidata(hObject, handles);
	delete(handles.settings_multiple_sim);
	return;
end

% handles-Struktur aktualisieren
guidata(hObject, handles);

% Warten auf Usereingabe
uiwait(handles.settings_multiple_sim);

function varargout = Settings_Multiple_Simulation_OutputFcn(hObject, eventdata, handles)
% varargout  Cell-Array für Rückgabe der Output-Argumente (siehe VARARGOUT);
% hObject    Link zu Grafik des Hauptfensters
% eventdata			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

varargout = {handles.main_handles};

% Schließen des Fensters:
delete(handles.settings_multiple_sim);


% --- Executes on button press in check_use_different_frequency_data.


% Hint: get(hObject,'Value') returns toggle state of check_use_different_frequency_data


% --- Executes on button press in check_use_same_paramter_file.


% Hint: get(hObject,'Value') returns toggle state of check_use_same_paramter_file


