% Last Modified by GUIDE v2.5 22-Dec-2011 10:40:03

% Franz Zeilinger 21.12.2011

function varargout = Configuration_PV_Parameters(varargin)

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Configuration_PV_Parameters_OpeningFcn, ...
                   'gui_OutputFcn',  @Configuration_PV_Parameters_OutputFcn, ...
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

function Configuration_PV_Parameters_OpeningFcn(hObject, ~, handles, varargin)
% Diese Funktion wird vor Sichtbarwerden des Fensters ausgeführt: 
% hObject    Link zur Grafik Access_Tool (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
% varargin   Übergabevariablen an Access_Tool (see VARARGIN)

dontOpen = false;
% Überprüfen, ob dieses GUI vom richtigen GUI aufgerufen wird:     
try
	Input = find(strcmp(varargin, 'Parameters'), 1);
	% Überprüfen, ob die Parameter richtig übergeben wurden:
	if (isempty(Input)) ||...
			(length(varargin) <= 2) ||...
			(~isstruct(varargin{1}))
		% Falls nicht das richtige GUI diese Funktion aufgerufen hat bzw. nicht
		% die handles-Struktur übergeben wurde --> Abbruch!
		dontOpen = true;
	else
		% ansonsten handles-Struktur aus aufrufenden GUI kopieren:
		handles.main_handles = varargin{1};
		handles.plant = varargin{Input + 1};
	end
catch ME %#ok<NASGU>
end

% Wenn nicht vom richtigen GUI aufgerufen --> Fehlermeldung in Konsole:
if dontOpen
	disp('----------------------------------------------------------------------');
	disp('Falsche Argumente bei Aufruf. Es muss ein Parameter-Werte-Paar über-  ');
	disp('geben werden dessen Name ''Parameters'' und Wert eine Struktur mit Er-');
	disp('zeugungsanlagenparametern ist!                                        ');
	disp('Weiters ist eine gültige ''handles''-Struktur mitzuübergeben! z.B.:   ');
	disp('   plant = Configuration_PV_Parameters(handles,''Parameters'',plant); ');
	disp('----------------------------------------------------------------------');
	% handles-Struktur aktualisieren:
	guidata(hObject, handles);
	delete(handles.data_explorer);
	return;
end

% Default Rückgabewert:
handles.output = handles.plant;
handles.new_data = false;

% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);

% handles-Struktur aktualisieren:
guidata(hObject, handles);

% UIWAIT makes Configuration_PV_Parameters wait for user response (see UIRESUME)
uiwait(handles.gui_configuration_pv_parameters);

function varargout = Configuration_PV_Parameters_OutputFcn(hObject, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Hint: delete(hObject) closes the figure
delete(hObject);

function edit_efficiency_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Efficiency = str2double(get(hObject,'String'));
handles.plant.Efficiency = handles.plant.Efficiency/100;

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_inclination_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Inclination = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_number_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Number = round(str2double(get(hObject,'String')));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_orientation_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Orientation = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_power_installed_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_power_installed (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Power_Installed = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_rel_size_collector_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_rel_size_collector (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Rel_Size_Collector = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function gui_configuration_pv_parameters_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

uiresume(handles.gui_configuration_pv_parameters);

function popup_typ_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Aktuellen Wert einlesen:
handles.plant.Typ = get(hObject,'Value');

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function push_cancel_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% eventdata	 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

if handles.new_data
	user_response = questdlg('Sollen die Änderungen übernommen werden?',...
		'Änderungen übernehmen?',...
		'Ja', 'Abbrechen', 'Abbrechen');
	switch lower(user_response)
		case 'ja'
			% aktuelle Erzeugerstruktur in Output schreiben.
			handles.output = handles.plant; 
			% keine neuen Daten mehr vorhanden!
			handles.new_data = false;
			% handles-Struktur aktualisieren:
			guidata(hObject, handles);
	end
end
% Die CloseRequest-Funktion aufrufen, weitere Behandlung erfolgt dort:
gui_configuration_pv_parameters_CloseRequestFcn(hObject, eventdata, handles)

function push_save_settings_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.output = handles.plant; % aktuelle Erzeugerstruktur in Output schreiben.
handles.new_data = false; % keine neuen Daten mehr vorhanden!

% Anzeige aktualisieren:
handles = refresh_display_pv_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function handles = refresh_display_pv_configuration (handles)
main_h = handles.main_handles;
plant = handles.plant;

% String und Wert des Popup-Menüs aktualisieren:
set(handles.popup_typ,...
	'String',main_h.System.Sola.Typs(:,1),...
	'Value',plant.Typ...
	);
% Anzeigen je nach gewählten Typ anpassen:
typ = main_h.System.Sola.Typs{plant.Typ};
switch lower(typ)
	case 'fix montiert'
		set(handles.edit_orientation, 'Enable', 'on');
		set(handles.edit_inclination, 'Enable', 'on');
	case 'tracker'
		% Bei nachgeführten Anlagen wird die Angabe von Orientierung und Neigung
		% nicht benötigt:
		set(handles.edit_orientation, 'Enable', 'off');
		set(handles.edit_inclination, 'Enable', 'off');
end

% die angezeigten Werte aktualisieren:
set(handles.edit_number, 'String', num2str(plant.Number));
set(handles.edit_power_installed, 'String', num2str(plant.Power_Installed));
set(handles.edit_orientation, 'String', num2str(plant.Orientation));
set(handles.edit_inclination, 'String', num2str(plant.Inclination));
set(handles.edit_efficiency, 'String', num2str(plant.Efficiency*100));
set(handles.edit_rel_size_collector, 'String', num2str(plant.Rel_Size_Collector));

% "Einstellungen übernehmen" Button aktivieren:
if handles.new_data
	set(handles.push_save_settings,'Enable','on');
else
	set(handles.push_save_settings,'Enable','off');
end

% --- Executes during object creation, after setting all properties.
function edit_efficiency_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_efficiency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_inclination_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_inclination (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_number_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_orientation_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_orientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_power_installed_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_power_installed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popup_typ_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to popup_typ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_rel_size_collector_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to edit_rel_size_collector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
