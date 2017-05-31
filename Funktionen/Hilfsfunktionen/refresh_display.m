function refresh_display (handles)
% REFRESH_DISPLAY    aktualisiert die Anzeige des GUI 'Simulation'
%    REFRESH_DISPLAY(HANDLES) nimmt alle Änderungen vor, die für eine aktuelle
%    Anzeige im GUI 'Simulation' notwendig sind. Dazu werden verschiedene
%    Dateien auf deren Existenz untersucht. Die notwendigen Daten dazu werden
%    der aktuellen HANDLES-Struktur des GUI entnommen, welche in dieser
%    Funktion nicht verändert werden kann!

%    Franz Zeilinger - 13.10.2010

set(handles.edit_number_user,'String',num2str(handles.Model.Number_User));

switch handles.Model.Sim_Resolution
	case 'sec'
		val = 1;
	case 'min'
		val = 2;
	case '5mi'
		val = 3;
	case 'quh'
		val = 4;
	case 'hou'
		val = 5;
end
set(handles.pop_sim_res,'Value',val);

if isfield(handles,'Result') && isfield(handles,'Frequency')
	set (handles.push_display_result,'Enable','on');
else
	set (handles.push_display_result,'Enable','off');
end

% Überprüfen, ob Geräteparameter verfügbar sind:
file = handles.Configuration.Save.Source;
try
	fid = fopen([file.Path,file.Parameter_Name,'.xls'],'r');
	if fid > 0
		fclose(fid);
		set (handles.menu_show_device_parameter,'Enable','On');
		set (handles.push_set_device_parameter,'Enable','On');
	else
		set (handles.menu_show_device_parameter,'Enable','Off');
		set (handles.push_set_device_parameter,'Enable','Off');
	end
catch ME
	set (handles.menu_show_device_parameter,'Enable','Off');
	set (handles.push_set_device_parameter,'Enable','Off');
end

% Überprüfen, ob Rohdaten in xls-Format vorliegen:
file = handles.Configuration.Save.Data;
try
	fid = fopen([file.Path,file.Data_Name,'.xls'],'r');
	if fid > 0
		fclose(fid);
		set (handles.menu_save_data_as_xls,'Enable','Off');
	else
		if isfield(handles, 'Result')
			set (handles.menu_save_data_as_xls,'Enable','On');
		end
	end
catch ME
	set (handles.menu_save_data_as_xls,'Enable','Off');
end

str = handles.Model.Date_End;
date = datenum(str);
set(handles.edit_date_end,'String',datestr(date,0));
str = handles.Model.Date_Start;
date = datenum(str);
set(handles.edit_date_start,'String',datestr(date,0));

% Gerätezusammentstellung anpassen:
for k=1:12
	field = ['check_Device_Assembly_',num2str(k)];
	if k <= size(handles.Model.Elements_Pool,1)
		% Gerätenamen neben Checkbox setzen und Box aktivieren:
		set(handles.(field), 'String', handles.Model.Elements_Pool{k,2},...
			'Visible','On','Value',...
			handles.Model.Device_Assembly.(handles.Model.Elements_Pool{k,1}));
		if handles.Configuration.Options.simsettings_load_from_paramfile
			set(handles.(field), 'Enable', 'Off');
		else
			set(handles.(field), 'Enable', 'On');
		end
	else
		% Alle anderen Felder ausschalten:
		set(handles.(field),'Visible','Off')
	end
end

set(handles.check_show_data,'Value',handles.Configuration.Options.show_data);
set(handles.check_savas_xls,'Value',handles.Configuration.Options.savas_xls);
set(handles.check_use_dsm,'Value',handles.Model.Use_DSM);

% falls die Simulationseinstellungen von der Parameterdatei geladen werden
% sollen, ausgrauen aller betroffenen Felder:
if handles.Configuration.Options.simsettings_load_from_paramfile
	set(handles.edit_number_user,'Enable','off');
	set(handles.pop_sim_res,'Enable','off');
	set(handles.edit_date_start,'Enable','off');
	set(handles.edit_date_end,'Enable','off');
else
	set(handles.edit_number_user,'Enable','on');
	set(handles.pop_sim_res,'Enable','on');
	set(handles.edit_date_start,'Enable','on');
	set(handles.edit_date_end,'Enable','on');
end

% Anzeigen, wenn Simulationsreihe gestartet werden kann:
if isfield(handles,'Joblist')
	if ~isempty(handles.Joblist) && handles.Configuration.Options.multiple_simulation
		set(handles.start_simulation,'String','Starte Simulationsreihe');
	else
		set(handles.start_simulation,'String','Starte Simulation');
	end
end

% Wenn aktuelle Frequenzdaten vorhanden sind, betreffende Felder
% aktivieren:
if isfield(handles,'Frequency')
	set(handles.check_use_last_frequency_data,'Enable','On');
else
	set(handles.check_use_last_frequency_data,'Enable','Off');
end

if size(handles.Joblist,2)>2 && handles.Configuration.Options.multiple_simulation
	set(handles.check_use_last_frequency_data,'Enable','Off','Value',0);
end

drawnow;