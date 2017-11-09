% Last Modified by GUIDE v2.5 14-Aug-2012 14:56:50

% Erstellt von:            Franz Zeilinger - 26.06.2012
% Letzte Änderung durch:   Franz Zeilinger - 14.08.2012

function varargout = Configuration_Time_Series_Parameters(varargin)
%CONFIGURATION_TIME_SERIES_PARAMETERS    Sub-GUI zur Parametriesierung der Zeitreihen
%    genaue Beschreibung fehlt, siehe Source-Code!

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Configuration_Time_Series_Parameters_OpeningFcn, ...
                   'gui_OutputFcn',  @Configuration_Time_Series_Parameters_OutputFcn, ...
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

function configuration_time_series_parameters_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

uiresume(handles.configuration_time_series_parameters);

function Configuration_Time_Series_Parameters_OpeningFcn(hObject, ~, handles, varargin)
% Diese Funktion wird vor Sichtbarwerden des Fensters ausgeführt, sie hat keine 
% Rückgabewerte, dafür ist _OUTPUTFCN zuständig!
% hObject    Link zur Grafik Access_Tool (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
% varargin   Übergabevariablen an Access_Tool (see VARARGIN)

dontOpen = false;
% Überprüfen, ob dieses GUI vom richtigen GUI aufgerufen wird:
try
	start_gui_Input = find(strcmp(varargin, 'Access_Tool'));
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
	end
catch ME %#ok<NASGU>
end

% Wenn nicht vom richtigen GUI aufgerufen --> Fehlermeldung in Konsole:
if dontOpen
	disp('---------------------------------------------------------------');
	disp('Falsche Argumente bei Aufruf. Es muss ein Parameter-Werte-Paar')
	disp('übergeben werden dessen Name ''Access_Tool'' und Wert der Handle')
	disp('auf das GUI von Acces_Tool.m ist! z.B.:');
	disp('   x = Acces_Tool();');
	disp('   y = Configuration_Time_Series_Parameters(''Access_Tool'', ...');
	disp('       handles.accesstool_main_window);');
	disp('---------------------------------------------------------------');
	% Update handles structure
	guidata(hObject, handles);
	return;
end

% Default Werte:
handles.new_data = false;
handles.time_series = handles.main_handles.Current_Settings.Data_Extract.Time_Series;

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);

% handles-Struktur aktualisieren:
guidata(hObject, handles);

% UIWAIT lässt Configuration_Wind_Parameters auf Userreaktion warten (siehe UIRESUME)
uiwait(handles.configuration_time_series_parameters);

function varargout = Configuration_Time_Series_Parameters_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
% varargout  Cell-Array für Rückgabe der Output-Argumente (siehe VARARGOUT)
% hObject    Link zu Grafik Data_Explorer (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
if isfield(handles,'main_handles');
	varargout = {handles.main_handles};
else
	varargout = [];
end
% Schließen des Fensters:
delete(handles.configuration_time_series_parameters);

function edit_date_end_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_date_end (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

date_end = get(hObject, 'String');

try
	date_end = datenum(date_end,'dd.mm.yy');
catch ME %#ok<NASGU>
	try 
		date_end = datenum(date_end,'dd.mm.yyyy');
	catch ME %#ok<NASGU>
		% Anzeige aktualisieren:
		handles = refresh_display_timeseries_configuration (handles);
		% handles-Struktur aktualisieren:
		guidata(hObject, handles);
		return;
	end
end

date_start = datenum(handles.time_series.Date_Start,'dd.mm.yyyy');
% Dauer der Zeitreihe ermitteln:
duration = date_end - date_start;
if duration < 0
	errordlg('End-Datum vor Startdatum!');
	% Anzeige aktualisieren:
	handles = refresh_display_timeseries_configuration (handles);
	% handles-Struktur aktualisieren:
	guidata(hObject, handles);
	return;
end
handles.new_data = true;
% Dauer übernehmen:
handles.time_series.Duration = duration;
% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_date_start_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_date_start (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

date_start = get(hObject, 'String');

try
	date_start = datenum(date_start,'dd.mm.yy');
catch ME %#ok<NASGU>
	try 
		date_start = datenum(date_start,'dd.mm.yyyy');
	catch ME %#ok<NASGU>
		% Anzeige aktualisieren:
		handles = refresh_display_timeseries_configuration (handles);
		% handles-Struktur aktualisieren:
		guidata(hObject, handles);
		return;
	end
end

% Daten übernehmen:
handles.time_series.Date_Start = datestr(date_start,'dd.mm.yyyy');
handles.new_data = true;

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function push_cancel_Callback(hObject, eventdata, handles)%#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

if handles.new_data
	user_response = questdlg('Sollen die Änderungen übernommen werden?',...
		'Änderungen übernehmen?',...
		'Ja', 'Nein', 'Nein');
	switch lower(user_response)
		case 'ja'
			handles.main_handles.Current_Settings.Data_Extract.Time_Series = ...
				handles.time_series;
			handles.new_data = false; % keine neuen Daten mehr vorhanden!
			% handles-Struktur aktualisieren:
			guidata(hObject, handles);
	end
end
% Die CloseRequest-Funktion aufrufen, weitere Behandlung erfolgt dort:
configuration_time_series_parameters_CloseRequestFcn(hObject, eventdata, handles);

function push_save_settings_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.main_handles.Current_Settings.Data_Extract.Time_Series = handles.time_series;
handles.new_data = false; % keine neuen Daten mehr vorhanden!

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);

% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_01_sunday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_01_sunday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 1);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_02_monday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_02_monday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 2);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_03_tuesday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_03_tuesday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 3);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_04_wednesday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_04_wednesday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 4);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_05_thursday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_05_thursday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 5);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_06_friday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_06_friday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 6);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_day_07_saturday_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_day_07_saturday (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles = next_startdate_2_weekday(handles, 7);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_duration_01_arbitrarily_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_duration_01_arbitrarily (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

set(handles.radio_duration_02_week, 'Value',0);
set(handles.radio_duration_03_month, 'Value',0);
set(handles.radio_duration_04_season, 'Value',0);
set(handles.radio_duration_05_year, 'Value',0);

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_duration_02_week_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik radio_duration_02_week (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

set(handles.radio_duration_01_arbitrarily, 'Value',0);
set(handles.radio_duration_03_month, 'Value',0);
set(handles.radio_duration_04_season, 'Value',0);
set(handles.radio_duration_05_year, 'Value',0);

handles.time_series.Duration = 7;

% Anzeige aktualisieren:
handles = refresh_display_timeseries_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function radio_duration_03_month_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>

function radio_duration_04_season_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>

function radio_duration_05_year_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>

function handles = refresh_display_timeseries_configuration (handles)

date_start = datenum(handles.time_series.Date_Start,'dd.mm.yyyy');
date_end = date_start + handles.time_series.Duration;
set(handles.edit_date_start, 'String', handles.time_series.Date_Start);
set(handles.edit_date_end, 'String', datestr(date_end,'dd.mm.yyyy'));

% Welcher Zeitraum wurde ausgewählt?
if handles.time_series.Duration == 7
	set(handles.radio_duration_02_week, 'Value',1);
	set(handles.radio_duration_01_arbitrarily, 'Value',0);
	set(handles.radio_duration_03_month, 'Value',0);
	set(handles.radio_duration_04_season, 'Value',0);
	set(handles.radio_duration_05_year, 'Value',0);
else
	set(handles.radio_duration_01_arbitrarily, 'Value',1);
	set(handles.radio_duration_02_week, 'Value',0);
	set(handles.radio_duration_03_month, 'Value',0);
	set(handles.radio_duration_04_season, 'Value',0);
	set(handles.radio_duration_05_year, 'Value',0);
end

% Welcher Startwochentag wurde ausgewählt?
set(handles.radio_day_01_sunday, 'Value',0);
set(handles.radio_day_02_monday, 'Value',0);
set(handles.radio_day_03_tuesday, 'Value',0);
set(handles.radio_day_04_wednesday, 'Value',0);
set(handles.radio_day_05_thursday, 'Value',0);
set(handles.radio_day_06_friday, 'Value',0);
set(handles.radio_day_07_saturday, 'Value',0);

wkd = weekday(date_start);
switch wkd
	case 1
		set(handles.radio_day_01_sunday, 'Value',1);
	case 2
		set(handles.radio_day_02_monday, 'Value',1);
	case 3
		set(handles.radio_day_03_tuesday, 'Value',1);
	case 4
		set(handles.radio_day_04_wednesday, 'Value',1);
	case 5
		set(handles.radio_day_05_thursday, 'Value',1);
	case 6
		set(handles.radio_day_06_friday, 'Value',1);
	case 7
		set(handles.radio_day_07_saturday, 'Value',1);
end

% "Einstellungen übernehmen" Button aktivieren:
if handles.new_data
	set(handles.push_save_settings,'Enable','on');
else
	set(handles.push_save_settings,'Enable','off');
end

function handles = next_startdate_2_weekday(handles, wkd)

% aktuelles Start-Datum:
date_start = datenum(handles.time_series.Date_Start,'dd.mm.yyyy');

% welcher Wochentag ist das?
wkd_start = weekday(date_start);

delta = wkd_start-wkd;
if abs(delta) > 3
	date_start = date_start + 7*sign(delta) - delta;
else
	date_start = date_start - delta;
end
handles.new_data = true;
handles.time_series.Date_Start = datestr(date_start, 'dd.mm.yyyy');

% --- create-Funktionen (werden unmittelbar vor Sichtbarmachen des GUIs ausgeführt):
function edit_date_start_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_date_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_date_end_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_date_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
