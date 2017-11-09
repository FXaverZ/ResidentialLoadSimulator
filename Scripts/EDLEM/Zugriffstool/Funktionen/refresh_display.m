function handles = refresh_display(handles)

% Franz Zeilinger - 27.09.2011

% Einstellungen der Wochentage und Jahreszeiten anpassen:
for i=1:3
	set(handles.(['radio_season_',num2str(i)]),'Value',handles.Settings.Season(i));
	set(handles.(['radio_weekday_',num2str(i)]),'Value',handles.Settings.Weekday(i));
end
% Weitere Einstellungen:
set(handles.edit_create_several_datasets_number,'String', ...
	num2str(handles.Settings.Several_Datasets_Number));
set(handles.check_create_several_datasets,...
	'Value',handles.Settings.Create_Several_Datasets);
if handles.Settings.Create_Several_Datasets
	set(handles.edit_create_several_datasets_number,'Enable','on');
else
	set(handles.edit_create_several_datasets_number,'Enable','off');
end

% Anlagenparametrierungen zur Anzeige bringen:
todo = {... % Liste mit den möglchen Anlagentypen + Zugehörige Schaltflächennamen
	'Sola','push_genera_pv_add_system';...
	'Wind','push_genera_wind_add_system';...
	};
Number_Generation = 0;
for i=1:size(todo,1)
	plants = fieldnames(handles.Settings.(todo{i,1}));
	Number_Generation = Number_Generation + size(plants,1);
	for j=1:size(plants,1)
		tags = get_plant_gui_tags(handles.System.(todo{i,1}).Tags,j);
		plant = handles.Settings.(todo{i,1}).(['Plant_',num2str(j)]);
		% Erzeugungsanlagentypen als Auswahlmöglichkeiten einstellen:
		set(handles.(tags{1}),'String',handles.System.(todo{i,1}).Typs(:,1));
		% Aktuellen Typ einstellen:
		set(handles.(tags{1}),'Value',plant.Typ);
		% Anzahl dieser Anlagen anzeigen:
		set(handles.(tags{2}),'String',num2str(plant.Number));
		% Installierte Leistung anpassen:
		set(handles.(tags{3}),'String',num2str(plant.Power_Installed));
		% Im Fall, dass kein Anlagentyp ausgewählt wurde, die weiteren Felder
		% deaktivieren:
		if plant.Typ == 1
			set(handles.(tags{2}),'Enable','off');
			set(handles.(tags{3}),'Enable','off');
			set(handles.(tags{4}),'Enable','off');
		else
			set(handles.(tags{2}),'Enable','on');
			set(handles.(tags{3}),'Enable','on');
			set(handles.(tags{4}),'Enable','on');
		end
		
		% Falls vorhergehende Anlage aktiv, Auswahlmöglichkeit für nächste
		% Anlage aktivieren:
		if j > 1 && handles.Settings.(todo{i,1}).(['Plant_',num2str(j-1)]).Typ ~= 1
			set(handles.(tags{1}),'Enable','on');
		elseif j > 1
			set(handles.(tags{1}),'Enable','off');
		end
		% Falls die letzte Einheit gültig ist, den Erweiterungsbutton für
		% weitere Anlagen einblenden:
		if j == size(plants,1) && plant.Typ ~= 1
			set(handles.(todo{i,2}),'Enable','on');
		else
			set(handles.(todo{i,2}),'Enable','off');
		end
	end
end

% Überprüfen, wie groß das Hauptfenster ist und eventuell Einstellugen anpassen
% (Position, Sperren der Möglichkeit, zusätzliche Erzeugungseinheiten hinzuzufügen:
screen_size = get(0, 'ScreenSize');
gui_size = get(handles.accesstool_main_window, 'Position');
y_pos = gui_size(2) + gui_size(4)+28;
if y_pos > screen_size(4)
	new_gui_size = gui_size;
	new_gui_size(2) = gui_size(2) - (y_pos - screen_size(4));
	set(handles.accesstool_main_window,'Position',new_gui_size);
end
if Number_Generation >= handles.Settings.Number_Generation_Max
	set(handles.(todo{1,2}),'Enable','off');
	set(handles.(todo{2,2}),'Enable','off');
end
	
% Falls kein Platz mehr ist für neue Felder, die Hinzufügen-Buttons deaktivieren:
if (gui_size(2)-27) < 0
	set(handles.push_genera_pv_add_system,'Enable','off');
	set(handles.push_genera_wind_add_system,'Enable','off');
end

% Worstcases eintragen:
set(handles.popup_hh_worstcase, 'String', handles.System.wc_households, ...
	'Value', handles.Settings.Worstcase_Housholds);
set(handles.popup_genera_worstcase, 'String', handles.System.wc_generation, ...
	'Value', handles.Settings.Worstcase_Generation);
% Die anderen Popup-Menüs befüllen:
set(handles.popup_file_type_output, 'String', handles.System.outputdata_types(:,2), ...
	'Value', handles.Settings.Output_Datatyp);
set(handles.popup_time_resolution, 'String', handles.System.time_resolutions(:,1), ...
	'Value', handles.Settings.Time_Resolution);

% Einstellungen der Haushalte anpassen:
hh = handles.Settings.Households;
for i=1:size(handles.System.housholds,1)
	number = hh.(handles.System.housholds{i,1}).Number;
	field = ['_hh_',handles.System.housholds{i,1}];
	set(handles.(['edit',field]),'String', num2str(number))
	if number == 0;
		set(handles.(['push',field]),'Enable', 'off');
	else
		set(handles.(['push',field]),'Enable', 'on');
	end
end

if isfield(handles,'Result')
	set(handles.push_data_save, 'Enable','on');
	set(handles.push_data_show, 'Enable','on');
else
	set(handles.push_data_save, 'Enable','off');
	set(handles.push_data_show, 'Enable','off');
end

drawnow;

