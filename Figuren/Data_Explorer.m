% M-File für GUI nach Auswahl 'Datenexplorer ...'
% Franz Zeilinger - 04.08.2011
% Last Modified by GUIDE v2.5 20-Jul-2011 16:47:33

function varargout = Data_Explorer(varargin)

% Beginn Initializationscode - NICHT EDITIEREN!
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Data_Explorer_OpeningFcn, ...
                   'gui_OutputFcn',  @Data_Explorer_OutputFcn, ...
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

function check_automatic_zoom_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik check_automatic_zoom (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)
handles.Options.automatic_zoom = get(hObject,'Value');

if handles.Options.automatic_zoom
	% Felder und Pushbuttons der manuellen Eingabe deaktivieren:
	set (handles.edit_date_end, 'Enable', 'off');
	set (handles.edit_date_start, 'Enable', 'off');
	set (handles.edit_y_axis_max, 'Enable', 'off');
	set (handles.edit_y_axis_min, 'Enable', 'off');
	set (handles.push_date_end_higher, 'Enable', 'off');
	set (handles.push_date_end_lower, 'Enable', 'off');
	set (handles.push_date_start_higher, 'Enable', 'off');
	set (handles.push_date_start_lower, 'Enable', 'off');
	set (handles.push_y_axis_max_higher, 'Enable', 'off');
	set (handles.push_y_axis_max_lower, 'Enable', 'off');
	set (handles.push_y_axis_min_higher, 'Enable', 'off');
	set (handles.push_y_axis_min_lower, 'Enable', 'off');
else
	set (handles.edit_date_end, 'Enable', 'on');
	set (handles.edit_date_start, 'Enable', 'on');
	set (handles.edit_y_axis_max, 'Enable', 'on');
	set (handles.edit_y_axis_min, 'Enable', 'on');
	set (handles.push_date_end_higher, 'Enable', 'on');
	set (handles.push_date_end_lower, 'Enable', 'on');
	set (handles.push_date_start_higher, 'Enable', 'on');
	set (handles.push_date_start_lower, 'Enable', 'on');
	set (handles.push_y_axis_max_higher, 'Enable', 'on');
	set (handles.push_y_axis_max_lower, 'Enable', 'on');
	set (handles.push_y_axis_min_higher, 'Enable', 'on');
	set (handles.push_y_axis_min_lower, 'Enable', 'on');
end

% aktualisieren der Darstellung:
push_refresh_display_Callback(hObject, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_show_frequency_data_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik check_show_frequency_data (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Options.show_frequency_data = get(hObject,'Value');

% aktualisieren der Darstellung:
push_refresh_display_Callback(hObject, eventdata, handles);
	
% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_show_hor_grid_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik check_show_hor_grid (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

handles.Options.show_hor_grid = get(hObject,'Value');

% aktualisieren der Darstellung:
push_refresh_display_Callback(hObject, eventdata, handles);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function check_stay_on_top_Callback(hObject, ~, handles)
% hObject    Link zu Grafik check_stay_on_top (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Auslesen des Wertes der Checkbox (aktiviert oder nicht)
val = get(hObject,'Value');
% Menüfenster soll je nach Auswahl der Checkbox im Vordergrund bleiben:
% val = 1 --> Immer im Vordergrund
% val = 0 --> normales Fensterverhalten
winontop(handles.data_explorer, val);
	
function data_explorer_CloseRequestFcn(hObject, ~, handles)
% hObject    Link zu Grafik Data_Explorer (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Diagrammfenster schließen:
if isfield(handles, 'Diagramm') && ishandle(handles.Diagramm.fig_diagr)
	delete(handles.Diagramm.fig_diagr);
end

% handles-Struktur aktualisieren
guidata(hObject, handles);

% Warten auf Usereingabe beenden:
uiresume(handles.data_explorer);

function Data_Explorer_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    Link zu Grafik Data_Explorer
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert
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
	end
catch ME
end

% Wenn nicht vom richtigen GUI aufgerufen --> Fehlermeldung in Konsole:
if dontOpen
	disp('---------------------------------------------------------------');
	disp('Falsche Argumente bei Aufruf. Es muss ein Parameter-Werte-Paar')
	disp('übergeben werden dessen Name ''Simulation'' und Wert der Handle')
	disp('auf das GUI von Simulation.m ist! z.B.:');
	disp('   x = Simulation();');
	disp('   Data_Explorer(''Simulation'', handles.main_window);');
	disp('---------------------------------------------------------------');
	% Update handles structure
	guidata(hObject, handles);
	delete(handles.data_explorer);
	return;
end

% Diagrammfenster öffnen:
create_plot_window(hObject, eventdata, handles);
handles = guidata(hObject);

% Ermitteln der Einträge für die Pop-Up-Menüs
set(handles.pop_results_cont, 'String', ...
	[{''};fields(handles.main_handles.Result.Displayable)]);

% Standard-Darstellungen:
string_pop_predefined = {};
string_pop_predefined(end+1) = {''};
string_pop_predefined(end+1) = {'Verbrauchergruppen'};
string_pop_predefined(end+1) = {'Verbrauchergruppen + Gesamtleistung'};
string_pop_predefined(end+1) = {'Aufteilung auf Phasen'};
string_pop_predefined(end+1) = {'Aufteilung auf Phasen + Gesamtleistung'};

% Sind Daten mit Einsatz von DSM vorhanden?
if isfield(handles.main_handles.Result.Displayable, 'DSM_Power_Class_kW')
	% Wenn ja, zusätzliche Darstellungen einfügen:
	string_pop_predefined(end+1) = {'Verbrauchergruppen mit DSM'};
	string_pop_predefined(end+1) = {'Verbrauchergruppen mit DSM + Gesamtleistung'};
	string_pop_predefined(end+1) = {'Aufteilung auf Phasen mit DSM'};
	string_pop_predefined(end+1) = {'Aufteilung auf Phasen mit DSM + Gesamtleistung'};
	string_pop_predefined(end+1) = {'   - - - V E R G L E I C H E - - -'};
	string_pop_predefined(end+1) = {'Verbrauchergruppen mit und ohne DSM'};
	string_pop_predefined(end+1) = {'Gesamtleistung mit und ohne DSM'};
	string_pop_predefined(end+1) = {['Verbrauchergruppen + Gesamtleistung mit ',...
		'und ohne DSM']};
	string_pop_predefined(end+1) = {'Aufteilung auf Phasen mit und ohne DSM'};
	string_pop_predefined(end+1) = {['Aufteilung auf Phasen + Gesamtleistung mit ',...
		'und ohne DSM']};
	% Zusätzlich die Checkbox aktivieren, falls Frequenzdaten vorhanden sind:
	set(handles.check_show_frequency_data, 'Enable', 'on');
else
	% Falls keine DSM-Daten vorhanden sind, ist eine Darstellung der Frequenzdaten
	% nicht interessant:
	set(handles.check_show_frequency_data, 'Enable', 'off');
end
set(handles.pop_predefined, 'String', string_pop_predefined)

% Default-Einstellungen laden:
handles.Options.show_frequency_data = 0;
handles.Options.show_hor_grid = 0;
handles.Options.automatic_zoom = 1;
m_z.date_end = datenum('20-Feb-2010 00:00:00');
m_z.date_start =  datenum('19-Feb-2010 00:00:00');
m_z.y_axis_max = Inf;
m_z.y_axis_min = 0;
handles.Options.manual_zoom = m_z;

% handles-Struktur aktualisieren
guidata(hObject, handles);

% Warten auf Usereingabe
uiwait(handles.data_explorer);

function create_plot_window(hObject, ~, handles)
%CREATE_PLOT_WINDOW    erzeugen eines Fensters für die Diagramme des Datenexplorers
% hObject    Link zu Grafik Data_Explorer (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Diagrammfenster öffnen:
fig_diagr = figure;
% Fenster auf möglichst großes Fenster setzen:
screen_size = get(0, 'ScreenSize');
window_posi = [1 48 screen_size(3) screen_size(4)-160];
set(fig_diagr, 'Position', window_posi);

% Digrammbereich einfügen
axe_diagr = axes('Parent',fig_diagr);

% Handle des Diagrammfensters speichern:
handles.Diagramm.fig_diagr = fig_diagr;
handles.Diagramm.axe_diagr = axe_diagr;
box('on');

% handles-Struktur aktualisieren
guidata(hObject, handles);

function varargout = Data_Explorer_OutputFcn(hObject, ~, handles) 
% varargout  Cell-Array für Rückgabe der Output-Argumente (siehe VARARGOUT)
% hObject    Link zu Grafik Data_Explorer (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

varargout = {handles.main_handles};

% Schließen des Fensters:
delete(handles.data_explorer);

function edit_date_end_Callback(hObject, ~, handles)
% hObject    Link zu Grafik edit_date_end (siehe GCBO)
% ~     	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = get(hObject,'String');
try
	date = datenum(str);
	% Überprüfen, ob Datum gültig:
	if date > handles.Options.manual_zoom.date_start
		handles.Options.manual_zoom.date_end = date;
	else
		errordlg_repos(handles,'End-Zeit muss nach Start-Zeit liegen!');
		set(hObject,'String',datestr(handles.Options.manual_zoom.date_end));
	end
catch ME
	% Error, falls kein gültiger Zeitstring eingegeben wurde und zurücksetzen des
	% Eingabefeldes auf den vorherigen Wert:
	errordlg_repos(handles,'Kein gültiger Zeitstring!');
	set(hObject,'String',datestr(handles.Options.manual_zoom.date_end));
	disp('Fehler beim Einlesen des End-Zeitstrings:');
	disp(ME.message);
end

% korrekte Darstellung des Datums erzwingen:
str = get(handles.edit_date_end,'String');
date = datenum(str);
set(handles.edit_date_end,'String',datestr(date,0));

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_date_start_Callback(hObject, ~, handles)
% hObject    Link zu Grafik edit_date_start (siehe GCBO)
% ~     	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = get(hObject,'String');
try
	date = datenum(str);
	% Überprüfen, ob Datum gültig:
	if date < handles.Options.manual_zoom.date_end
		handles.Options.manual_zoom.date_start = date;
	else
		errordlg_repos(handles,'Start-Zeit muss vor End-Zeit liegen!');
		set(hObject,'String',datestr(handles.Options.manual_zoom.date_start));
	end
catch ME
	% Error, falls kein gültiger Zeitstring eingegeben wurde und zurücksetzen des
	% Eingabefeldes auf den vorherigen Wert:
	errordlg_repos(handles,'Kein gültiger Zeitstring!');
	set(hObject,'String',datestr(handles.Options.manual_zoom.date_start));
	disp('Fehler beim Einlesen des End-Zeitstrings:');
	disp(ME.message);
end

% korrekte Darstellung des Datums erzwingen:
str = get(handles.edit_date_start,'String');
date = datenum(str);
set(handles.edit_date_start,'String',datestr(date,0));

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_y_axis_max_Callback(hObject, ~, handles)
% hObject    Link zu Grafik edit_y_axis_max (siehe GCBO)
% ~     	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = get(hObject,'String');
try
	y_max = str2double(str);
	
	% Überprüfen, ob Eingabe passen kann:
	if y_max > handles.Options.manual_zoom.y_axis_min
		handles.Options.manual_zoom.y_axis_max = y_max;
	else
		errordlg_repos(handles,'Max-Wert muss größer sein als Min-Wert!');
		set(hObject, 'String', handles.Options.manual_zoom.y_axis_max);
	end
catch ME
	% Error, falls keine gültige Zahl eingegeben wurde:
	errordlg_repos(handles,'Kein gültiger Zahlenwert!');
	set(hObject, 'String', handles.Options.manual_zoom.y_axis_max);
	disp('Fehler beim Einlesen des End-Zeitstrings:');
	disp(ME.message);
end

% erzwingen der richtigen Darstellung der Eingabe:
str = get(hObject,'String');
y_max = str2double(str);
str = num2str(y_max, '%8.2f');
set(hObject,'String', str);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function edit_y_axis_min_Callback(hObject, ~, handles)
% hObject    Link zu Grafik edit_y_axis_min (siehe GCBO)
% ~     	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

str = get(hObject,'String');
try
	y_min = str2double(str);
	
	% Überprüfen, ob Eingabe passen kann:
	if y_min < handles.Options.manual_zoom.y_axis_max
		handles.Options.manual_zoom.y_axis_min = y_min;
	else
		errordlg_repos(handles,'Min-Wert muss kleiner sein als Max-Wert!');
		set(hObject, 'String', handles.Options.manual_zoom.y_axis_min);
	end
catch ME
	% Error, falls keine gültige Zahl eingegeben wurde:
	errordlg_repos(handles,'Kein gültiger Zahlenwert!');
	set(hObject, 'String', handles.Options.manual_zoom.y_axis_min);
	disp('Fehler beim Einlesen des End-Zeitstrings:');
	disp(ME.message);
end

% erzwingen der richtigen Darstellung der Eingabe:
str = get(hObject,'String');
y_min = str2double(str);
str = num2str(y_min, '%8.2f');
set(hObject,'String', str);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function errordlg_repos (handles, errorstring)
%ERRORDLG_REPOS    Errordialog mit angepasster Position
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

fig_err = errordlg(errorstring);
		pos_data_exp = get(handles.data_explorer, 'Position');
		set(fig_err, 'Units', 'pixels');
		pos_err_dlg = get(fig_err, 'Position');
		screen_size = get(0, 'ScreenSize');
		
		new_pos_left = pos_data_exp(1) + pos_data_exp(3) + 40;
		if new_pos_left + pos_err_dlg (3) > screen_size(3)
			new_pos_left = pos_data_exp(1) - pos_err_dlg (3) - 40;
		end
		pos_err_dlg(1) = new_pos_left;
		set(fig_err, 'Position', pos_err_dlg);

function pop_predefined_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik pop_predefined (siehe GCBO)
% eventdata  reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Auswahl des anderen Pop_up_Menüs deaktivieren:
set(handles.pop_results_cont, 'Value', 1);

% Datenstrukturen einlesen:
Result = handles.main_handles.Result;
Devices = handles.main_handles.Devices;
DSM_data = zeros(1,numel(Result.Time));

% Falls Diagrammfenster geschlossen wurde, ein neues erzeugen:
if ~ishandle(handles.Diagramm.fig_diagr)
	create_plot_window(hObject, eventdata, handles)
	handles = guidata(hObject);
end
% Handle des Diagrammfensters einlesen:
fig_diagr = handles.Diagramm.fig_diagr;
axe_diagr = handles.Diagramm.axe_diagr;

% Zeitdaten und Frequenzdaten auslesen:
if Result.Time_Base < 60
	stepsize = 1;
else
	stepsize = Result.Time_Base/30;
end
% Auswahl der Zeitpunkte:
t_points = Result.Time;
if handles.Options.automatic_zoom
	idx_zoom = ones(1,numel(t_points)) == 1;
else
	m_z = handles.Options.manual_zoom;
	% statt (x <= y) wird (x < y | abs(x-y) < eps) verwendet (Gleitkommafehler!)
	% eps = 1e-7 --> entspricht Genauigkeit von ca. 10 ms!
	idx_zoom = (t_points < m_z.date_end | abs(t_points - m_z.date_end) < 1e-7) &...
		(t_points > m_z.date_start | abs(t_points - m_z.date_start)<1e-7);
end
t_points = t_points(idx_zoom);
frequency = handles.main_handles.Frequency(:,1:stepsize:end);
% Ermitteln der Frequenzdaten für Anzeige, siehe Funktion CREATE_FREQUENCY_DATA!
% statt (x <= y) wird (x < y | abs(x-y) < eps) verwendet (Gleitkommafehler!)
% eps = 1e-7 --> entspricht Genauigkeit von ca. 10 ms!
idx = (frequency(1,:) > t_points(1) | abs(frequency(1,:) - t_points(1)) < 1e-7) & ...
	(frequency(1,:) < t_points(end) | abs(frequency(1,:) - t_points(end)) < 1e-7);
frequency = frequency(2,idx);

% Welche Auswahl wurde getroffen?
contents = cellstr(get(hObject,'String')); 
value = contents{get(hObject,'Value')}; 

% Für die jeweilige Auswahl die Anzeige ausgeben:
switch value
	case 'Verbrauchergruppen'
		data = Result.Displayable.Power_Class_kW.Data; %darzustellende Daten
		legend_entries = Result.Displayable.Power_Class_kW.Legend;  %Legendeneinträge
		typ_diagr = 'single';                     %normale Darstellunng
	case 'Verbrauchergruppen + Gesamtleistung'
		data = Result.Displayable.Power_Class_and_Total_kW.Data;
		legend_entries = Result.Displayable.Power_Class_and_Total_kW.Legend;
		typ_diagr = 'single';
	case 'Aufteilung auf Phasen'
		data = Result.Displayable.Power_Phase_kW.Data;
		legend_entries = Result.Displayable.Power_Phase_kW.Legend;
		typ_diagr = 'single';
	case 'Aufteilung auf Phasen + Gesamtleistung'
		data = Result.Displayable.Power_Phase_and_Total_kW.Data;
		legend_entries = Result.Displayable.Power_Phase_and_Total_kW.Legend;
		typ_diagr = 'single';
	case 'Verbrauchergruppen mit DSM'
		data = Result.Displayable.DSM_Power_Class_kW.Data;
		legend_entries = Result.Displayable.DSM_Power_Class_kW.Legend;
		typ_diagr = 'single';
	case 'Verbrauchergruppen mit DSM + Gesamtleistung'
		data = Result.Displayable.DSM_Power_Class_and_Total_kW.Data;
		legend_entries = Result.Displayable.DSM_Power_Class_and_Total_kW.Legend;
		typ_diagr = 'single';
	case 'Aufteilung auf Phasen mit DSM'
		data = Result.Displayable.DSM_Power_Phase_kW.Data;
		legend_entries = Result.Displayable.DSM_Power_Phase_kW.Legend;
		typ_diagr = 'single';
	case 'Aufteilung auf Phasen mit DSM + Gesamtleistung'
		data = Result.Displayable.DSM_Power_Phase_and_Total_kW.Data;
		legend_entries = Result.Displayable.DSM_Power_Phase_and_Total_kW.Legend;
		typ_diagr = 'single';
	case 'Verbrauchergruppen mit und ohne DSM'
		data = Result.Displayable.Power_Class_kW.Data;         %darzustell. Daten o. DSM
		DSM_data = Result.Displayable.DSM_Power_Class_kW.Data; %darzustell. Daten m. DSM
		legend_entries = Result.Displayable.Power_Class_kW.Legend; %Legendeneinträge
		typ_diagr = 'comparison';                                  %Darstellung als Vergleich
	case 'Gesamtleistung mit und ohne DSM'
		data = Result.Displayable.Power_Total_kW.Data;
		DSM_data = Result.Displayable.DSM_Power_Total_kW.Data;
		legend_entries = Result.Displayable.Power_Total_kW.Legend;
		typ_diagr = 'comparison';
	case 'Verbrauchergruppen + Gesamtleistung mit und ohne DSM'
		data = Result.Displayable.Power_Class_and_Total_kW.Data;
		DSM_data = Result.Displayable.DSM_Power_Class_and_Total_kW.Data;
		legend_entries = Result.Displayable.Power_Class_and_Total_kW.Legend;
		typ_diagr = 'comparison';
	case 'Aufteilung auf Phasen mit und ohne DSM'
		data = Result.Displayable.Power_Phase_kW.Data;
		DSM_data = Result.Displayable.DSM_Power_Phase_kW.Data;
		legend_entries = Result.Displayable.Power_Phase_kW.Legend;
		typ_diagr = 'comparison';
	case 'Aufteilung auf Phasen + Gesamtleistung mit und ohne DSM'
		data = Result.Displayable.Power_Phase_and_Total_kW.Data;
		DSM_data = Result.Displayable.DSM_Power_Phase_and_Total_kW.Data;
		legend_entries = Result.Displayable.Power_Phase_and_Total_kW.Legend;
		typ_diagr = 'comparison';
	otherwise
		return;
end

% Daten an Zeitzoombereich anpassen:
data = data(:,idx_zoom);
DSM_data = DSM_data(:,idx_zoom);

if handles.Options.show_frequency_data
	% Normale Darstellung inkl. Frequenzdaten:
	[yy_axes, lin_diagr_1, lin_diagr_2] = ...
		plotyy(axe_diagr, t_points, data, t_points, frequency);
	% Legendeneinträge erweitern:
	legend_entries = [legend_entries, {'Netzfrequenz'}];
	% Frequnzlinie formatieren:
	set(lin_diagr_2,'LineStyle','--','Color','b');
	set(yy_axes(2),'XColor','b','YColor','b');
else
	% Normale Darstellung ohne Frequenzdaten:
	lin_diagr_1 = plot(axe_diagr, t_points, data);
end

switch typ_diagr
	case 'single'
		if handles.Options.show_frequency_data
			% Legende für einfache Daten + Netzfrequenz:
			leg_diagr = legend(axe_diagr, [lin_diagr_1; lin_diagr_2],...
				legend_entries);
		else
			% Legende für einfache Daten:
			leg_diagr = legend(axe_diagr, lin_diagr_1, legend_entries);
		end
	case 'comparison'
		hold(axe_diagr, 'on');
		lin_diagr_3 = plot(axe_diagr, t_points, DSM_data);
		color = get(lin_diagr_1, 'Color');
		if numel(lin_diagr_3) > 1
			%Falls mehrere Datenreihen, die gleichen Farben verwenden:
			for i=1:numel(lin_diagr_3)
				set(lin_diagr_3(i),'Color',color{i});
			end
		else
			% Falls nur eine Datereihe vorhanden:
			set(lin_diagr_1,'Color','r');
			set(lin_diagr_3,'Color','r');
		end
		% Werte ohne DSM punktiert darstellen (für Übersichtlichkeit):
		set(lin_diagr_1,'LineStyle',':');
		
		if handles.Options.show_frequency_data
			% Legende für einfache Daten + Netzfrequenz:
			leg_diagr = legend(axe_diagr, [lin_diagr_3; lin_diagr_2],...
				legend_entries);
		else
			% Legende für einfache Daten:
			leg_diagr = legend(axe_diagr, lin_diagr_3, legend_entries);
		end
end

% Zeitachseneinteilung (je nach Zoombereich unterschiedlicher Raster):
if t_points(end)-t_points(1) >= (4/24+1/14410)
	timeticks = t_points(1):1/24:t_points(end);
elseif t_points(end)-t_points(1) >= (2/(4*24)+1/14410)
	timeticks = t_points(1):1/(4*24):t_points(end);
else
	timeticks = t_points(1):1/(60*24):t_points(end);
end
set(axe_diagr,'XTick',timeticks,'XGrid','on');
datetick(axe_diagr,'x','HH:MM','keepticks')

% Falls gewünscht, horizontales Gitter einblenden:
if handles.Options.show_hor_grid
	set(axe_diagr,'YGrid','on');
else
	set(axe_diagr,'YGrid','off');
end

if handles.Options.show_frequency_data
	% Achsenbeschriftungen:
	set(get(yy_axes(1),'Ylabel'),'String','Aufgenommene Leistung [kW]');
	set(get(yy_axes(2),'Ylabel'),'String','Netzfrequenz [Hz]');
	xlabel(yy_axes(1),'Uhrzeit');
	% Frequenzachse:
	axis(yy_axes(2),[-Inf, Inf, 45.5, 51]);
	ylimits = get(yy_axes(2),'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
	set(yy_axes(2),'YTick',ylimits(1):yinc:ylimits(2));
	% Zeitachsenraster für 2.Y-Achse deaktivieren (da gleich wie 1.Y-Achse)
	set(yy_axes(2),'XTick',[]);
else
	% Achsenbeschriftungen:
	xlabel(axe_diagr,'Uhrzeit');
	ylabel(axe_diagr,'Aufgenommene Leistung [kW]');
end

% Achsenskalierung einstellen:
if handles.Options.automatic_zoom
	if ~isempty(DSM_data) && max(max(DSM_data)) >= ...
			max(max(data))
		if max(max(DSM_data)) > 1
			axis(axe_diagr,[-Inf, Inf, 0, ...
				(11/4)*ceil(max(max(DSM_data))/2.5)]);
		elseif max(max(DSM_data)) < 1 && ...
				max(max(DSM_data)) > 0
			axis(axe_diagr,[-Inf, Inf, 0, ...
				(11/40)*ceil(max(max(DSM_data))/0.25)]);
		else
			axis(axe_diagr,[-Inf, Inf, -0.1, 0.1]);
		end
	else
		if max(max(data)) > 1
			axis(axe_diagr,[-Inf, Inf, 0, ...
				(11/4)*ceil(max(max(data))/2.5)]);
		elseif max(max(data)) < 1 && ...
				max(max(data)) > 0
			axis(axe_diagr,[-Inf, Inf, 0, ...
				(11/40)*ceil(max(max(data))/0.25)]);
		else
			axis(axe_diagr,[-Inf, Inf, -0.1, 0.1]);
		end
	end
	ylimits = get(axe_diagr,'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
else
	axis(axe_diagr,[-Inf, Inf, m_z.y_axis_min, m_z.y_axis_max]);
	ylimits = get(axe_diagr,'YLim');
	yinc = (ylimits(2)-ylimits(1))/10;
end
set(axe_diagr,'YTick',ylimits(1):yinc:ylimits(2),'YTickLabel',...
	ylimits(1):yinc:ylimits(2));

% Legende formatieren:
legend(axe_diagr,'show');
% set(leg_diagr,'Location','Best','String',legend_entries);
set(leg_diagr,'Location','Best');

% Löschen der Achsen wieder erlauben:
hold(axe_diagr, 'off');
% Menüfenster wieder in Vordergrund:
figure(handles.data_explorer);

% Einstellungen des Autozooms eintragen und für manuelle Einstellungen übernehmen:
set (handles.edit_date_end, 'String', datestr(t_points(end), 0));
m_z.date_end = t_points(end);
set (handles.edit_date_start, 'String', datestr(t_points(1), 0));
m_z.date_start =  t_points(1);
set (handles.edit_y_axis_max, 'String', sprintf('%8.2f',ylimits(2)));
m_z.y_axis_max = ylimits(2);
set (handles.edit_y_axis_min, 'String', sprintf('%8.2f',ylimits(1)));
m_z.y_axis_min = ylimits(1);
handles.Options.manual_zoom = m_z;

% handles-Struktur aktualisieren
guidata(hObject, handles);

function pop_results_cont_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik pop_results_cont (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Auswahl des anderen Pop_up_Menüs deaktivieren:
set(handles.pop_predefined, 'Value', 1);

% Datenstrukturen einlesen:
Result = handles.main_handles.Result;

% Falls Diagrammfenster geschlossen wurde, ein neues erzeugen:
if ~ishandle(handles.Diagramm.fig_diagr)
	create_plot_window(hObject, eventdata, handles)
	handles = guidata(hObject);
end
% Handle des Diagrammfensters einlesen:
fig_diagr = handles.Diagramm.fig_diagr;
axe_diagr = handles.Diagramm.axe_diagr;

% Zeitdaten und Frequenzdaten auslesen
if Result.Time_Base < 60
	stepsize = 1;
else
	stepsize = Result.Time_Base/30;
end
% Auswahl der Zeitpunkte:
t_points = Result.Time;
if handles.Options.automatic_zoom
	idx_zoom = ones(1,numel(t_points)) == 1;
else
	m_z = handles.Options.manual_zoom;
	% statt (x <= y) wird (x < y | abs(x-y) < eps) verwendet (Gleitkommafehler!)
	% eps = 1e-7 --> entspricht Genauigkeit von ca. 10 ms!
	idx_zoom = (t_points < m_z.date_end | abs(t_points - m_z.date_end) < 1e-7) &...
		(t_points > m_z.date_start | abs(t_points - m_z.date_start)<1e-7);
end
t_points = t_points(idx_zoom);
frequency = handles.main_handles.Frequency(:,1:stepsize:end);
% Ermitteln der Frequenzdaten für Anzeige, siehe Funktion CREATE_FREQUENCY_DATA!
% statt (x <= y) wird (x < y | abs(x-y) < eps) verwendet (Gleitkommafehler!)
% eps = 1e-7 --> entspricht Genauigkeit von ca. 10 ms!
idx = (frequency(1,:) > t_points(1) | abs(frequency(1,:) - t_points(1)) < 1e-7) & ...
	(frequency(1,:) < t_points(end) | abs(frequency(1,:) - t_points(end)) < 1e-7);
frequency = frequency(2,idx);

% Welche Auswahl wurde getroffen?
contents = cellstr(get(hObject,'String')); 
value = contents{get(hObject,'Value')}; 
if isempty(value)
	return;
end
data = Result.Displayable.(value).Data;
legend_entries = Result.Displayable.(value).Legend;
% Daten an Zeitzoombereich anpassen:
data = data(:,idx_zoom);

if handles.Options.show_frequency_data
	% Normale Darstellung inkl. Frequenzdaten:
	[yy_axes, lin_diagr_1, lin_diagr_2] = ...
		plotyy(axe_diagr, t_points, data, t_points, frequency);
	% Frequnzlinie formatieren:
	set(lin_diagr_2,'LineStyle','--','Color','b');
	set(yy_axes(2),'XColor','b','YColor','b');
	% Legende für einfache Daten + Netzfrequenz:
	legend_entries = [legend_entries, {'Netzfrequenz'}];
	leg_diagr = legend(axe_diagr, [lin_diagr_1; lin_diagr_2],...
		legend_entries);
else
	% Normale Darstellung ohne Frequenzdaten:
	lin_diagr_1 = plot(axe_diagr, t_points, data);
	% Legende für einfache Daten:
	leg_diagr = legend(axe_diagr, lin_diagr_1, legend_entries);
end

% Legende formatieren:
legend(axe_diagr,'show');
% set(leg_diagr,'Location','Best','String',legend_entries);
set(leg_diagr,'Location','Best');

if numel(lin_diagr_1) < 2
	set(lin_diagr_1,'Color','r');
end

% Zeitachseneinteilung (je nach Zoombereich unterschiedlicher Raster):
if t_points(end)-t_points(1) >= (4/24+1/14410)
	timeticks = t_points(1):1/24:t_points(end);
elseif t_points(end)-t_points(1) >= (2/(4*24)+1/14410)
	timeticks = t_points(1):1/(4*24):t_points(end);
else
	timeticks = t_points(1):1/(60*24):t_points(end);
end
set(axe_diagr,'XTick',timeticks,'XGrid','on');
datetick(axe_diagr,'x','HH:MM','keepticks')

% Falls gewünscht, horizontales Gitter einblenden: 
if handles.Options.show_hor_grid
	set(axe_diagr,'YGrid','on');
else
	set(axe_diagr,'YGrid','off');
end

if handles.Options.show_frequency_data
	% Achsenbeschriftungen:
	set(get(yy_axes(1),'Ylabel'),'String', value, 'Interpreter', 'none');
	set(get(yy_axes(2),'Ylabel'),'String','Netzfrequenz [Hz]');
	xlabel(yy_axes(1),'Uhrzeit');
	% Frequenzachse:
	axis(yy_axes(2),[-Inf, Inf, 45.5, 51]);
	ylimits = get(yy_axes(2),'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
	set(yy_axes(2),'YTick',ylimits(1):yinc:ylimits(2));
	% Zeitachsenraster für 2.Y-Achse deaktivieren (da gleich wie 1.Y-Achse)
	set(yy_axes(2),'XTick',[]);
else
	% Achsenbeschriftungen:
	xlabel(axe_diagr,'Uhrzeit');
	ylabel(axe_diagr, value);
	set(get(axe_diagr, 'Ylabel'), 'Interpreter', 'none'); %LaTex Interpreter deaktivieren
end

% Achsenskalierung einstellen:
if handles.Options.automatic_zoom
	if max(max(data)) > 1
		axis(axe_diagr,[-Inf, Inf, 0, ...
			(11/4)*ceil(max(max(data))/2.5)]);
	elseif max(max(data)) < 1 && ...
			max(max(data)) > 0
		axis(axe_diagr,[-Inf, Inf, 0, ...
			(11/40)*ceil(max(max(data))/0.25)]);
	else
		axis(axe_diagr,[-Inf, Inf, -0.1, 0.1]);
	end
	ylimits = get(axe_diagr,'YLim');
	yinc = (ylimits(2)-ylimits(1))/11;
else
	axis(axe_diagr,[-Inf, Inf, m_z.y_axis_min, m_z.y_axis_max]);
	ylimits = get(axe_diagr,'YLim');
	yinc = (ylimits(2)-ylimits(1))/10;
end
set(axe_diagr,'YTick',ylimits(1):yinc:ylimits(2),'YTickLabel',...
	ylimits(1):yinc:ylimits(2));

% Löschen der Achsen wieder erlauben:
hold(axe_diagr, 'off');
% Menüfenster wieder in Vordergrund:
figure(handles.data_explorer);

% Einstellungen des Autozooms eintragen und für manuelle Einstellungen übernehmen:
set (handles.edit_date_end, 'String', datestr(t_points(end), 0));
m_z.date_end = t_points(end);
set (handles.edit_date_start, 'String', datestr(t_points(1), 0));
m_z.date_start =  t_points(1);
set (handles.edit_y_axis_max, 'String', ylimits(2));
m_z.y_axis_max = ylimits(2);
set (handles.edit_y_axis_min, 'String', ylimits(1));
m_z.y_axis_min = ylimits(1);
handles.Options.manual_zoom = m_z;

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_close_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_close (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

data_explorer_CloseRequestFcn(hObject, eventdata, handles)

function push_date_end_higher_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_date_end_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% aktuelle Zeit um 1h erhöhen und zurückschreiben, mit Hilfe der Callbackfunktion die
% Richtigkeit der Eingabe checken:
date = datenum(get(handles.edit_date_end, 'String')) + 1/24;
set(handles.edit_date_end, 'String', datestr(date,0));
edit_date_end_Callback(handles.edit_date_end, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_date_end_lower_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_date_end_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% aktuelle Zeit um 1h verringern und zurückschreiben, mit Hilfe der Callbackfunktion 
% die Richtigkeit der Eingabe checken:
date = datenum(get(handles.edit_date_end, 'String')) - 1/24;
set(handles.edit_date_end, 'String', datestr(date,0));
edit_date_end_Callback(handles.edit_date_end, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_date_start_higher_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_date_start_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% aktuelle Zeit um 1h erhöhen und zurückschreiben, mit Hilfe der Callbackfunktion die
% Richtigkeit der Eingabe checken:
date = datenum(get(handles.edit_date_start, 'String')) + 1/24;
set(handles.edit_date_start, 'String', datestr(date,0));
edit_date_start_Callback(handles.edit_date_start, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_date_start_lower_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_date_start_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% aktuelle Zeit um 1h verringern und zurückschreiben, mit Hilfe der Callbackfunktion 
% die Richtigkeit der Eingabe checken:
date = datenum(get(handles.edit_date_start, 'String')) - 1/24;
set(handles.edit_date_start, 'String', datestr(date,0));
edit_date_start_Callback(handles.edit_date_start, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_refresh_display_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_refresh_display (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% aktualisieren der Darstellung:
if get(handles.pop_results_cont, 'Value') > 1
	pop_results_cont_Callback(handles.pop_results_cont, eventdata, handles)
	handles = guidata(hObject);
	
elseif get(handles.pop_predefined, 'Value') > 1
	pop_predefined_Callback(handles.pop_predefined, eventdata, handles)
	handles = guidata(hObject);
end

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_y_axis_max_higher_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_y_axis_max_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Wert einlesen:
val = str2double(get(handles.edit_y_axis_max, 'String'));
% Schrittweite je nach Wertgröße anpassen:
if abs(val) >= 100
	dif = 100;
elseif abs(val) >= 10
	dif = 10;
elseif abs(val) >= 1
	dif = 1;
elseif abs(val) >= 0.1
	dif = 0.1;
else
	dif = 1;
end
% Wert anpassen:
val = val + dif;
% Wert zurückschreiben
set(handles.edit_y_axis_max, 'String', num2str(val));
% Richtigkeit der Eingabe überprüfen:
edit_y_axis_max_Callback(handles.edit_y_axis_max, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_y_axis_max_lower_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_y_axis_max_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Wert einlesen:
val = str2double(get(handles.edit_y_axis_max, 'String'));
% Schrittweite je nach Wertgröße anpassen:
if abs(val) > 100
	dif = 100;
elseif abs(val) > 10
	dif = 10;
elseif abs(val) > 1
	dif = 1;
elseif abs(val) > 0.1
	dif = 0.1;
else
	dif = 1;
end
% Wert anpassen:
val = val - dif;
% Wert zurückschreiben
set(handles.edit_y_axis_max, 'String', num2str(val));
% Richtigkeit der Eingabe überprüfen:
edit_y_axis_max_Callback(handles.edit_y_axis_max, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_y_axis_min_higher_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_y_axis_min_higher (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Wert einlesen:
val = str2double(get(handles.edit_y_axis_min, 'String'));
% Schrittweite je nach Wertgröße anpassen:
if abs(val) >= 100
	dif = 100;
elseif abs(val) >= 10
	dif = 10;
elseif abs(val) >= 1
	dif = 1;
elseif abs(val) >= 0.1
	dif = 0.1;
else
	dif = 1;
end
% Wert anpassen:
val = val + dif;
% Wert zurückschreiben
set(handles.edit_y_axis_min, 'String', num2str(val));
% Richtigkeit der Eingabe überprüfen:
edit_y_axis_min_Callback(handles.edit_y_axis_min, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

function push_y_axis_min_lower_Callback(hObject, eventdata, handles)
% hObject    Link zu Grafik push_y_axis_min_lower (siehe GCBO)
% eventdata	 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Wert einlesen:
val = str2double(get(handles.edit_y_axis_min, 'String'));
% Schrittweite je nach Wertgröße anpassen:
if abs(val) > 100
	dif = 100;
elseif abs(val) > 10
	dif = 10;
elseif abs(val) > 1
	dif = 1;
elseif abs(val) > 0.1
	dif = 0.1;
else
	dif = 1;
end
% Wert anpassen:
val = val - dif;
% Wert zurückschreiben
set(handles.edit_y_axis_min, 'String', num2str(val));
% Richtigkeit der Eingabe überprüfen:
edit_y_axis_min_Callback(handles.edit_y_axis_min, eventdata, handles);
handles = guidata(hObject);

% handles-Struktur aktualisieren
guidata(hObject, handles);

% --- Executing during object creation, after setting all properties:
function pop_predefined_CreateFcn(hObject, eventdata, handles)
% hObject    Link zu Grafik pop_predefined (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Setzen der Hintergrundfarbe:
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pop_results_cont_CreateFcn(hObject, eventdata, handles)
% hObject    Link zu Grafik pop_results_cont (siehe GCBO)
% ~			 reserviert (MATLAB spezifisch, wird in zukünftigen Versionen definiert)
% handles    Struktur mit Grafiklinks und User-Daten (siehe GUIDATA)

% Setzen der Hintergrundfarbe:
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_y_axis_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_y_axis_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_date_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_date_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_date_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_date_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_y_axis_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_y_axis_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
