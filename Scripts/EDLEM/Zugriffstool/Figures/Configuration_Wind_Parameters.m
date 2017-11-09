% Last Modified by GUIDE v2.5 23-Dec-2011 12:37:30

% Franz Zeilinger 02.01.2012

function varargout = Configuration_Wind_Parameters(varargin)

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Configuration_Wind_Parameters_OpeningFcn, ...
                   'gui_OutputFcn',  @Configuration_Wind_Parameters_OutputFcn, ...
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

function Configuration_Wind_Parameters_OpeningFcn(hObject, ~, handles, varargin)
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
	disp('   plant = ...                                                        ');
	disp('       Configuration_Wind_Parameters(handles,''Parameters'',plant);   ');
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
handles = refresh_display_wind_configuration (handles);

% handles-Struktur aktualisieren:
guidata(hObject, handles);

% UIWAIT makes Configuration_Wind_Parameters wait for user response (see UIRESUME)
uiwait(handles.gui_configuration_pv_parameters);

function varargout = Configuration_Wind_Parameters_OutputFcn(hObject, ~, handles) 
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
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_inertia_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_inertia (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Inertia = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_number_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.Number = round(str2double(get(hObject,'String')));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_power_installed_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_power_installed (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Änderung der installierten Leistung hat eine entsprechende Änderung des
% Rotordurchmessers zur Folge, diese ermitteln:
new_power = str2double(get(hObject,'String'))*1000;
old_power = handles.plant.Power_Installed;
old_size = handles.plant.Size_Rotor;

new_size = sqrt(new_power/old_power)*old_size;

handles.plant.Power_Installed = new_power;
handles.plant.Size_Rotor = new_size;

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_rho_Callback(~, ~, handles) %#ok<DEFNU>
% ~          Link zur Grafik edit_rotor_typ (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Anzeige aktualisieren:
refresh_display_wind_configuration (handles);

function edit_rotor_typ_Callback(~, ~, handles) %#ok<DEFNU>
% ~          Link zur Grafik edit_rotor_typ (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Anzeige aktualisieren:
refresh_display_wind_configuration (handles);

function edit_size_rotor_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik edit_size_rotor (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% eine Änderung des Rotordurchmessers hat eine enstprechende Änderung der
% installierten Leistung zur Folge:
new_size = str2double(get(hObject,'String'));
old_size = handles.plant.Size_Rotor;
old_power = handles.plant.Power_Installed;

new_power = ((new_size/old_size)^2)*old_power;

handles.plant.Power_Installed = new_power;
handles.plant.Size_Rotor = new_size;

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_v_cut_off_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.v_cut_off = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function edit_v_nominal_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 Link zur Grafik edit_v_nominal (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

refresh_display_wind_configuration (handles);

function edit_v_start_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    Link zur Grafik check_create_several_datasets (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.plant.v_start = str2double(get(hObject,'String'));

handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
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

plant = handles.plant;
% Aktuellen Wert einlesen:
plant.Typ = get(hObject,'Value');

% Die Werte der ausgewählten Anlage übernehmen:
parameters = get_wind_turbine_parameters(plant.Typ-1);
plant.Power_Installed = parameters{4};
plant.v_nominal = parameters{5};
plant.v_start = parameters{6};
plant.v_cut_off = parameters{7};
plant.Typ_Rotor = parameters{2};
plant.Size_Rotor = parameters{3};
plant.c_p =  parameters{8};

handles.plant = plant;
handles.new_data = true; % neue Daten sind vorhanden!
% Anzeige aktualisieren:
handles = refresh_display_wind_configuration (handles);
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
handles = refresh_display_wind_configuration (handles);
% handles-Struktur aktualisieren:
guidata(hObject, handles);

function push_show_c_p_f_v_wind_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 Link zur Grafik push_show_c_p_f_v_wind (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

c_p = handles.plant.c_p;

v_wind_fine = 0:0.5:25;
c_p_act = interp1(c_p(:,1),c_p(:,2),v_wind_fine);

fig_diagr = figure;
axe_diagr = axes('Parent',fig_diagr);
plot(axe_diagr, v_wind_fine, c_p_act);
set(axe_diagr,'XGrid','on','YGrid','on');
xlabel(axe_diagr,'v_{Wind} [m/s]');
ylabel(axe_diagr,'c_P [-]');
title(axe_diagr,'Darstellung des Leistungsbeiwertes c_P = f (v_{Wind})',...
	'FontWeight','bold');

function push_show_P_f_v_wind_Callback(~, ~, handles) %#ok<DEFNU>
% ~			 Link zur Grafik push_show_c_p_f_v_wind (siehe GCBO)
% ~			 nicht benötigt (MATLAB spezifisch)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

c_p = handles.plant.c_p;
d_rotor = handles.plant.Size_Rotor;
rho = handles.plant.Rho;

v_wind_fine = 0:0.5:25;
c_p_act = interp1(c_p(:,1),c_p(:,2),v_wind_fine);

pow_act = rho/2*(d_rotor^2*pi/4)*(v_wind_fine.^3.*c_p_act);

fig_diagr = figure;
axe_diagr = axes('Parent',fig_diagr);
plot(axe_diagr, v_wind_fine, pow_act);
set(axe_diagr,'XGrid','on','YGrid','on');
xlabel(axe_diagr,'v_{Wind} [m/s]');
ylabel(axe_diagr,'P [W]');
title(axe_diagr,'Darstellung der abgegebenen Leistung (P = f (v_{Wind}) )',...
	'FontWeight','bold');

function handles = refresh_display_wind_configuration (handles)
main_h = handles.main_handles;
plant = handles.plant;

% String und Wert des Popup-Menüs aktualisieren:
set(handles.popup_typ,...
	'String',main_h.System.Wind.Typs(:,1),...
	'Value',plant.Typ...
	);

% die angezeigten Werte aktualisieren:
set(handles.edit_number, 'String', num2str(plant.Number));
set(handles.edit_power_installed, 'String', num2str(plant.Power_Installed/1000));
set(handles.edit_v_cut_off, 'String', num2str(plant.v_cut_off));
set(handles.edit_v_start, 'String', num2str(plant.v_start));
set(handles.edit_size_rotor, 'String', num2str(plant.Size_Rotor));
set(handles.edit_efficiency, 'String', num2str(plant.Efficiency*100));
set(handles.edit_rotor_typ, 'String', plant.Typ_Rotor);
set(handles.edit_v_nominal, 'String', num2str(plant.v_nominal));
set(handles.edit_inertia, 'String', num2str(plant.Inertia));
set(handles.edit_rho, 'String', num2str(plant.Rho));
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
function edit_inertia_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_inertia (see GCBO)
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
function edit_power_installed_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_power_installed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_rho_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_rho (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_rotor_typ_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_rotor_typ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_size_rotor_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_size_rotor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_v_cut_off_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_v_cut_off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_v_nominal_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_v_nominal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_v_start_CreateFcn(hObject, eventdata, handles)%#ok<INUSD,DEFNU>
% hObject    handle to edit_v_start (see GCBO)
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