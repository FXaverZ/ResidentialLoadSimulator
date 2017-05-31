% Hauptfile für Simulation von Verbrauchern mit DSM - inkl. GUI
% Franz Zeilinger - 29.07.2011
% Last Modified by GUIDE v2.5 15-Jun-2011 11:58:19

function varargout = Simulation(varargin)

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Simulation_OpeningFcn, ...
                   'gui_OutputFcn',  @Simulation_OutputFcn, ...
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

function Simulation_OpeningFcn(hObject, ~, handles, varargin)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
% varargin   weiter Parameter bei Aufruf in Kommandozeile

% Wo ist "Simulation.m" zu finden?
[~, Source_File] = fileattrib('Simulation.m');
% Ordner, in dem "Simulation.m" sich befindet, enthält Programm:
if ischar(Source_File)
	fprintf([Source_File,' - Current Directory auf Datei setzen, in der sich ',...
		'''Simulation.m'' befindet!\n']);
	% Fenster schließen:
	delete(handles.main_window);
	return;
end
Path = fileparts(Source_File.Name);
% Subfolder in Search-Path aufnehmen (damit alle Funktionen gefunden werden
% können)
addpath(genpath(Path));
handles.Configuration.Save.Settings.Path = [Path,'\'];

% Defaultwerte erzeugen:
handles = get_default_values(handles);
% obige Funktion liefert 
%    handles.Configuration     und 
%    handles.Model             (ohne Geräteparameter) 
handles.Devices = [];
handles.Joblist = {};

% Systemvariablen:
handles.System.cancel_simulation = false;    %Simulationsabbruch auf aus setzen

% Laden der letzten verwendeten Konfiguration (Falls vorhanden bzw möglich):
try
	file = handles.Configuration.Save.Settings;
	load('-mat', [file.Path,file.Name,file.Ext]);
	handles.Configuration = Configuration;
	% Laden der letzen Simulationsdaten (Falls vorhanden):
	try
		file = Configuration.Save.Data;
		load([file.Path,file.Data_Name,'.mat']);
		% Paramtetereinstellungen der gespeicherten Daten anpassen (damit
		% ev. neue Parameter nicht verloren gehen):
		Model.Parameter_Pool = handles.Model.Parameter_Pool;
		Model.DSM_Param_Pool = handles.Model.DSM_Param_Pool;
		handles.Model = Model;
		handles.Devices = Devices;
		handles.Result = Result;
		handles.Frequency = Frequency;
	catch ME
		disp('Fehler beim Laden der Simulationsdaten:');
		disp(ME.message);
	end
	
	% Laden der Joblist-Datei
	try
	file = handles.Configuration.Save.Joblist;
	handles.Joblist = load_joblist(file.Path, file.List_Name);
	catch ME 
		disp('Fehler beim Laden der Joblistdatei:');
		disp(ME.message);
	end
		
catch ME
	disp('Fehler beim Bearbeiten der Konfigurationsdatei:');
	disp(ME.message);
end

% Anzeigen auf Startanzeige einrichten:
set(handles.edit_date_end,'String',handles.Model.Date_End);
set(handles.edit_date_start,'String',handles.Model.Date_Start);
% Fortschrittsanzeige auf Null setzen:
pos = get(handles.Waitbar_white,'Position');
pos(3) = 0.05;
set(handles.Wait_bar_color,'Position',pos);
set(handles.Waitbar_status_text,'String',' ');
% Alle anderen Anzeigen einstellen:
refresh_display (handles);
refresh_status_text(hObject,'Bereit für Simulation');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function main_window_CloseRequestFcn(~, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

user_response = questdlg('Soll das Programm wirklich beendet werden?','Beenden?',...
	'Ja', 'Abbrechen', 'Abbrechen');
switch user_response
case 'Abbrechen'
	% nichts unternehmen
case 'Ja'
	% Konfiguration speichern:
    Configuration = handles.Configuration;
	file = Configuration.Save.Settings;
	% Falls Pfad der Konfigurationsdatei nicht vorhanden ist, Ordner erstellen:
	if ~isdir(file.Path)
		mkdir(file.Pathh);
	end
	save([file.Path,file.Name,file.Ext],'Configuration');
	
	% Fenster schließen:
	delete(handles.main_window);
end

function start_simulation_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Setzen verschiedener Einstellungen für GUI:
handles.system.cancel_simulation = false;
set(handles.cancel_simulation,'Enable','on');
set(handles.start_simulation,'Enable','off');
set (handles.push_display_result,'Enable','off');
set (handles.push_display_result,'Enable','off');
set (handles.push_set_device_parameter,'Enable','off');

% handles-Struktur aktualisieren
guidata(hObject, handles);

% Je nach Simulationsmodus die Simulationen durchführen:
if handles.Configuration.Options.multiple_simulation && ~isempty(handles.Joblist)
	simulation_multip_cycle (hObject, handles);
else
	simulation_single_cycle (hObject, handles);
end

% aktuelle handles-Struktur auslesen (wurde in den Funktionen erweitert):
handles = guidata(hObject);

% Setzen verschiedener Einstellungen für GUI:
set(handles.cancel_simulation,'Enable','off');
set(handles.start_simulation,'Enable','on');
set (handles.push_display_result,'Enable','on');
set (handles.push_set_device_parameter,'Enable','on');

handles.system.cancel_simulation = false;

% Anzeigen aktualisieren:
refresh_display (handles);
% handles-Struktur aktualisieren
guidata(hObject, handles);

function cancel_simulation_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
handles.system.cancel_simulation = true;
set(handles.cancel_simulation,'Enable','off');
set(handles.start_simulation,'Enable','on');
set(handles.Waitbar_white,'String',' ');
% Anzeigen aktualisieren:
refresh_display (handles);
% handles-Structure aktualisieren
guidata(hObject, handles);

function pop_sim_res_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

contents = cellstr(get(hObject,'String'));
handles.Model.Sim_Resolution = contents{get(hObject,'Value')};
% handles-Structure aktualisieren
guidata(hObject, handles);

function edit_number_user_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Number_User = round(str2double(get(hObject,'String')));
% handles-Structure aktualisieren
guidata(hObject, handles);

function menu_show_frequency_data_Callback(~, ~, handles)
% hObject    handle to menu_show_frequency_data (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'Frequency')
	warndlg('Keine Frequenzdaten vorhanden!','Frequenzdaten');
	return;
end

% Create figure
figure1 = figure;
% Create axes
axes1 = axes('Parent',figure1);
box('on');
hold('all');

time = handles.Frequency(1,:);
Frequency = handles.Frequency(2,:);
plot(time,Frequency);

timeticks = time(1):1/24:time(end);

xlabel('Uhrzeit');
set(gca,'XTick',timeticks,'XGrid','on');
datetick('x','HH:MM','keepticks')

set(gca,'YLim',[47 51],'YTick',45:0.5:55);
ylabel('Frequenz');

function menu_frequency_data_generate_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik des Hauptfensters
% eventdata	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Simulationszeiteinstellungen ermitteln:
Time = get_time_settings(handles.Model);
% Frequenzdaten erzeugen:
handles.Frequency = create_frequency_data(Time);
% erzeugte Daten anzeigen:
menu_show_frequency_data_Callback(hObject, eventdata, handles)
% handles-Structure aktualisieren
guidata(hObject, handles);
% Anzeigen aktualisieren:
refresh_display(handles);

function menu_frequency_data_load_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~     	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = 'Laden von Frequenzdaten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

file = handles.Configuration.Save.Frequency;

[file.Name,file.Path] = uigetfile(['*',file.Extension],...
	'Zu ladende Frequenzdaten auswählen',...
	file.Path);
if ischar(file.Name)
	try
		load([file.Path,file.Name],'-mat');
		handles.Frequency = Frequency;
		% Entfernen der Dateierweiterung:
		[~, file.Name] = fileparts(file.Name);
		
		% Konfiguration übernehmen:
		handles.Configuration.Save.Frequency = file;
		
		% handles-Structure aktualisieren
		guidata(hObject, handles);
		
		% Ausgabe an Anzeige
		str = '--> erledigt!';
		refresh_status_text(hObject,str,'Add');
		fprintf([str,'\n']);
	catch ME
		disp('Fehler beim Laden der Frequenzdaten:');
		disp(ME.message);
		errordlg('Keine gültigen Frequenzdaten in Datei gefunden!');
		str = 'Fehler beim Laden der Daten!';
		refresh_status_text(hObject,str,'Add');
	end
end

refresh_display(handles);

function menu_savepath_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

Main_Path = uigetdir(handles.Configuration.Save.Data.Main_Path);
if ischar(Main_Path)
	handles.Configuration.Save.Data.Main_Path = [Main_Path,'\'];
end
% handles-Structure aktualisieren
guidata(hObject, handles);

function menu_save_data_as_xls_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

savas_xls = handles.Configuration.Options.savas_xls;
handles.Configuration.Options.savas_xls = 1;

str = 'Speichern der Daten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

% Automatisches Speichern der relevanten Daten:
handles.Configuration = save_sim_data (handles.Configuration, handles.Model,...
	handles.Devices, handles.Frequency, handles.Result);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf([str,'\n']);

handles.Configuration.Options.savas_xls = savas_xls;

% Anzeigen aktualisieren:
refresh_display(handles);
% handles-Struktur aktualisieren
guidata(hObject, handles);

function menu_load_data_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = 'Laden von Simulationsdaten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

file = handles.Configuration.Save.Data;

[file.Data_Name,file.Path] = uigetfile('*.mat',...
	'Zu ladende Simulationsdaten auswählen',...
	file.Main_Path);
if ischar(file.Data_Name)
	try
		load([file.Path,file.Data_Name]);
		handles.Result = Result;
		% Paramtetereinstellungen der gespeicherten Daten anpassen (damit
		% ev. neue Parameter nicht verloren gehen):
		Model.Parameter_Pool = handles.Model.Parameter_Pool;
		Model.DSM_Param_Pool = handles.Model.DSM_Param_Pool;
		handles.Model = Model;
		handles.Devices = Devices;
		handles.Frequency = Frequency;
		% Entfernen der Dateierweiterung:
		[~, file.Data_Name] = fileparts(file.Data_Name);
		
		% Parameterdateinamen ermitteln:
		file.Parameter_Name = [datestr(Result.Sim_date,'HHhMM.SS'),...
			' - Parameterwerte - ',Model.Sim_Resolution,' - ',...
			num2str(Model.Number_User)];
		
		% Konfiguration übernehmen:
		handles.Configuration.Save.Data = file;
		
		% handles-Structure aktualisieren
		guidata(hObject, handles);
		
		% Ausgabe an Anzeige
		str = 'Daten erfolgreich geladen! ';
		str2 = ['(',datestr(Result.Sim_date,'yy.mm.dd - HHhMM.SS'),')'];
		refresh_status_text(hObject,[str,str2],'Add');
		fprintf([str2,' --> erledigt!\n']);
	catch ME
		disp('Fehler beim Laden der Simulationsdaten:');
		disp(ME.message);
		errordlg('Keine gültigen Simulationsdaten in Datei gefunden!');
		str = 'Fehler beim Laden der Daten!';
		refresh_status_text(hObject,str,'Add');
	end
end

refresh_display(handles);

function menu_load_device_parameter_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

file = handles.Configuration.Save.Source;

[file.Parameter_Name,file.Path] = uigetfile({...
	'*.xls','Excel-Parameterdatei (.xls)';...
	'*.*','Alle Dateien'},...
	'Zu ladende Parameterdatei auswählen',...
	[file.Path,file.Parameter_Name]);

if ~isequal(file.Parameter_Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[~, file.Parameter_Name] = fileparts(file.Parameter_Name);
	% Konfiguration übernehmen:
	handles.Configuration.Save.Source = file;
	% Parameter einlesen:
	handles.Model = load_device_parameter(file.Path, file.Parameter_Name, ...
		handles.Model);
	refresh_display (handles);
end

% handles-Struktur aktualisieren
guidata(hObject, handles)

function menu_multiple_sim_joblist_load_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt menu_multiple_sim_joblist_load (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
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

function menu_multiple_sim_settings_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Einstellungs-GUI aufrufen und von dort die Einstellungen übernehmen:
handles = Settings_Multiple_Simulation('Simulation', handles.main_window);

% Anzeige aktualisieren:
refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function menu_save_as_device_parameter_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = 'Speichern der Parameter: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

file = handles.Configuration.Save.Data;

[file.Parameter_Name,file.Path] = uiputfile({...
	'*.xls','Excel-Parameterdatei (.xls)';...
	'*.*','Alle Dateien'},...
	'Speichern der Parameter',...
	[file.Parameter_Name,file.Path,'.xls']);
if ~isequal(file.Parameter_Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[~, file.Parameter_Name] = fileparts(file.Parameter_Name);
	% Konfiguration übernehmen:
	handles.Configuration.Save.Data = file;
	% Neue Quellparameterdatei:
	handles.Configuration.Save.Source = file;
	% Parameterdateien speichern:
	save_model_parameters(handles.Configuration, handles.Model)
	
	str = '--> erledigt!';
	refresh_status_text(hObject,str,'Add');
	fprintf([str,'\n']);
else
	str = 'FEHLER! Nicht durchgeführt!';
	refresh_status_text(hObject,str,'Add');
	fprintf([str,'\n']);
end


% handles-Struktur aktualisieren
guidata(hObject, handles)

function menu_set_device_parameter_Callback(~, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

file = handles.Configuration.Save.Source;
winopen([file.Path,file.Parameter_Name,'.xls']);

function menu_show_device_parameter_Callback(~, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

file = handles.Configuration.Save.Source;
winopen([file.Path,file.Parameter_Name,'.xls']);

function menu_save_data_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = 'Speichern der Daten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

% Automatisches Speichern der relevanten Daten:
handles.Configuration = save_sim_data (handles.Configuration, handles.Model, ...
	handles.Devices, handles.Frequency, handles.Result);

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf([str,'\n']);

% handles-Struktur aktualisieren
guidata(hObject, handles)

function menu_frequency_data_save_Callback(hObject, ~, handles)
% hObject    handle to menu_frequency_data_save (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

str = 'Speichern der Frequenzdaten: ';
refresh_status_text(hObject,str);
fprintf(['\n\t\t',str]);

Frequency = handles.Frequency;
file = handles.Configuration.Save.Frequency;

[file.Name,file.Path] = uiputfile({...
	['*',file.Extension],['Frequenzdatendatei (',file.Extension,')'];...
	'*.*','Alle Dateien'},...
	'Speichern der Parameter',...
	[file.Name,file.Path,file.Extension]);
if ~isequal(file.Name,0) && ~isequal(file.Path,0)
	% Entfernen der Dateierweiterung:
	[~, file.Name] = fileparts(file.Name);
	% Konfiguration übernehmen:
	handles.Configuration.Save.Frequency = file;
	save([file.Path,file.Name,file.Extension],'Frequency');
end

str = '--> erledigt!';
refresh_status_text(hObject,str,'Add');
fprintf([str,'\n']);

% handles-Struktur aktualisieren
guidata(hObject, handles)

function menu_frequency_data_set_generation_Callback(~, ~, ~)
% hObject    Link zu Grafikobjekt menu_frequency_data_set_generation (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
open('create_frequency_data.m');

function push_display_result_Callback(~, ~, handles)
% hObject    Link zu Grafikobjekt push_display_result (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

disp_result(handles.Model, handles.Frequency, handles.Result);

function push_open_data_explorer_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafikobjekt push_open_data_explorer (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Daten-Explorer-GUI aufrufen:
handles = Data_Explorer('Simulation', handles.main_window);

% Anzeige aktualisieren:
refresh_display(handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);


function push_set_device_parameter_Callback(~, ~, handles)
% hObject    Link zu Grafikobjekt push_set_device_parameter (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

file = handles.Configuration.Save.Source;
winopen([file.Path,file.Parameter_Name,'.xls']);

function edit_date_end_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt edit_date_end (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = get(hObject,'String');
try
	datenum(str);
	handles.Model.Date_End = str;
catch ME
	errordlg('Kein gültiger Zeitstring!');
	set(hObject,'String',handles.Model.Date_End);
	disp('Fehler beim Einlesen des End-Zeitstrings:');
	disp(ME.message);
end

str = get(handles.edit_date_end,'String');
date = datenum(str);
set(handles.edit_date_end,'String',datestr(date,0));

% handles-Struktur aktualisieren
guidata(hObject, handles);	

function edit_date_start_Callback(hObject, ~, handles)
% hObject    Link zu Grafikobjekt edit_date_start (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = get(hObject,'String');
try
	datenum(str);
	handles.Model.Date_Start = str;
catch ME
	errordlg('Kein gültiger Zeitstring!');
	set(hObject,'String',handles.Model.Date_Start);
	disp('Fehler beim Einlesen des End-Zeitstrings:');
	disp(ME.message);
end

str = get(handles.edit_date_start,'String');
date = datenum(str);
set(handles.edit_date_start,'String',datestr(date,0));

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_1_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{1,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_2_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{2,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_3_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{3,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_4_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{4,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_5_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{5,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_6_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{6,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_7_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{7,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_8_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{8,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_9_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{9,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_10_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{10,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_11_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{11,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_Device_Assembly_12_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Device_Assembly.(handles.Model.Device_Assembly_Pool{12,1}) = ...
	get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_show_data_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Configuration.Options.show_data = get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_savas_xls_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Configuration.Options.savas_xls = get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_use_last_frequency_data_Callback(hObject, ~, handles)
% hObject    handle to check_use_last_frequency_data (see GCBO)
% ~          reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Configuration.Options.use_last_frequency_data = get(hObject,'Value');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_use_dsm_Callback(hObject, ~, handles)
% hObject    Link zu Grafik des Hauptfensters
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Model.Use_DSM = logical(get(hObject,'Value'));


% handles-Struktur aktualisieren
guidata(hObject, handles);

function varargout = Simulation_OutputFcn(hObject, ~, handles)
function main_window_CreateFcn(hObject, ~, handles)
function pop_sim_res_CreateFcn(hObject, ~, handles)
% hObject    handle to pop_sim_res (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
	
	
end
function edit_number_user_CreateFcn(hObject, ~, handles)
% hObject    handle to edit_number_user (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function main_window_WindowKeyPressFcn(hObject, ~, handles)
function menu_file_Callback(hObject, ~, handles)
function edit_date_start_CreateFcn(hObject, ~, handles)
% hObject    handle to edit_date_start (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_date_end_CreateFcn(hObject, ~, handles)
% hObject    handle to edit_date_end (see GCBO)
% ~  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function menu_Callback(hObject, ~, handles)
function menu_multiple_sim_Callback(hObject, ~, handles)
function menu_frequency_Callback(hObject, ~, handles)
