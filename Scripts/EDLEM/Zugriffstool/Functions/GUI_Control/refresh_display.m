function handles = refresh_display(handles)
%REFRESH_DISPLAY    führt eine Aktualisierung des Haupt-GUIs von Access_Tool durch
%    HANDLES = REFRESH_DISPLAY(HANDLES) führt verschiedene Operationen durch, um das
%    Erscheinungsbild des Hauptfensters des GUIs von Access_Tool zu aktualisieren.
%    Diese Funktion sollte nach jeder Änderung von Parameterwerten aufgerufen werden!

% Erstellt von:            Franz Zeilinger - 26.06.2012
% Letzte Änderung durch:   Franz Zeilinger - 14.08.2012

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%      Siedlungsstruktur
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Einstellungen der Haushalte anpassen:
hh = handles.Current_Settings.Households;
for i=1:size(handles.System.housholds,1)
	number = hh.(handles.System.housholds{i,1}).Number;
	field = ['_hh_',handles.System.housholds{i,1}];
	% vorhandenen Haushaltsanzahl eintragen:
	set(handles.(['edit',field]),'String', num2str(number))
	% Alle Dateilbuttons einblenden:
	set(handles.(['push',field]),'Enable', 'on');
end

% Worstcases eintragen:
set(handles.popup_hh_worstcase, 'String', handles.System.wc_households, ...
	'Value', handles.Current_Settings.Worstcase_Housholds);

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%      Einstellungen - Auslesen der Daten
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Einstellungen der Wochentage und Jahreszeiten anpassen:
for i=1:3
	set(handles.(['radio_season_',num2str(i)]),...
		'Value',handles.Current_Settings.Season(i));
	set(handles.(['radio_weekday_',num2str(i)]),...
		'Value',handles.Current_Settings.Weekday(i));
	% Bei Zeitreihen Eingaben einschränken:
	if handles.Current_Settings.Data_Extract.get_Time_Series
		set(handles.(['radio_weekday_',num2str(i)]),...
			'Enable','Off');
	else
		set(handles.(['radio_weekday_',num2str(i)]),...
			'Enable','On');
	end
end
% Einstellungen für Zeitreihen aktivieren:
if handles.Current_Settings.Data_Extract.get_Time_Series
	set(handles.push_time_series_settings, 'Enable','On');
	set(handles.check_get_time_series, 'Value',1);
else
	set(handles.push_time_series_settings, 'Enable','Off');
	set(handles.check_get_time_series, 'Value',0);
end
% Befüllen des Pop-Up-Menüs:
set(handles.popup_time_resolution, 'String', handles.System.time_resolutions(:,1), ...
	'Value', handles.Current_Settings.Data_Extract.Time_Resolution);
% Checkboxen für Behandlung der Daten setzen:
if handles.Current_Settings.Data_Extract.Time_Resolution == 1
	set(handles.check_extract_sample_value,'Value',1,'Enable','off');
	handles.Current_Settings.Data_Extract.get_Sample_Value = 1;
	set(handles.check_extract_mean_value,'Value',0,'Enable','off');
	handles.Current_Settings.Data_Extract.get_Mean_Value = 0;
	set(handles.check_extract_min_max_value,'Value',0,'Enable','off');
	handles.Current_Settings.Data_Extract.get_Min_Max_Value = 0;
	set(handles.check_extract_5_95_quantile_value,'Value',0,'Enable','off');
	handles.Current_Settings.Data_Extract.get_5_95_Quantile_Value = 0;
else
	set(handles.check_extract_sample_value,...
		'Value',handles.Current_Settings.Data_Extract.get_Sample_Value,...
		'Enable','on');
	set(handles.check_extract_mean_value,...
		'Value',handles.Current_Settings.Data_Extract.get_Mean_Value,...
		'Enable','on');
	set(handles.check_extract_min_max_value,...
		'Value',handles.Current_Settings.Data_Extract.get_Min_Max_Value,...
		'Enable','on');
	set(handles.check_extract_5_95_quantile_value,...
		'Value',handles.Current_Settings.Data_Extract.get_5_95_Quantile_Value,...
		'Enable','on');
end

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%      Einstellungen - Speichern der Daten
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Die Popup-Menüs und Einstellungen befüllen und aktuelle Werte eintragen:
set(handles.popup_file_type_output, 'String', handles.System.outputdata_types(:,2),...
	'Value', handles.Current_Settings.Data_Output.Datatyp);
set(handles.popup_time_resolution_output, 'String', ...
	handles.System.time_resolutions(:,1), ...
	'Value', handles.Current_Settings.Data_Output.Time_Resolution);
set(handles.check_data_save_single_phase,'Value', ...
	handles.Current_Settings.Data_Output.Single_Phase);

% Checkboxen für Behandlung der Daten setzen:
if handles.Current_Settings.Data_Output.Time_Resolution == 1
	set(handles.check_output_sample_value,'Value',1,'Enable','off');
	handles.Current_Settings.Data_Output.get_Sample_Value = 1;
	set(handles.check_output_mean_value,'Value',0,'Enable','off');
	handles.Current_Settings.Data_Output.get_Mean_Value = 0;
	set(handles.check_output_min_max_value,'Value',0,'Enable','off');
	handles.Current_Settings.Data_Output.get_Min_Max_Value = 0;
	set(handles.check_output_5_95_quantile_value,'Value',0,'Enable','off');
	handles.Current_Settings.Data_Output.get_5_95_Quantile_Value = 0;
else
	set(handles.check_output_sample_value,...
		'Value',handles.Current_Settings.Data_Output.get_Sample_Value,...
		'Enable','on');
	set(handles.check_output_mean_value,...
		'Value',handles.Current_Settings.Data_Output.get_Mean_Value,...
		'Enable','on');
	set(handles.check_output_min_max_value,...
		'Value',handles.Current_Settings.Data_Output.get_Min_Max_Value,...
		'Enable','on');
	set(handles.check_output_5_95_quantile_value,...
		'Value',handles.Current_Settings.Data_Output.get_5_95_Quantile_Value,...
		'Enable','on');
end

if isfield(handles,'Result') && ...
		handles.Current_Settings.Data_Output.Time_Resolution ~= 1
	% Falls schon Daten geladen wurden, die Auswahlmöglichkeiten einschränken.
	extract = handles.Result.Current_Settings.Data_Extract;
	output = handles.Current_Settings.Data_Output;
	if (extract.get_Sample_Value && ...
			extract.Time_Resolution <= output.Time_Resolution) || ...
			extract.Time_Resolution == 1
		set(handles.check_output_sample_value,...
			'Value',output.get_Sample_Value,'Enable','on');
	else
		set(handles.check_output_sample_value,'Value',0,'Enable','off');
		handles.Current_Settings.Data_Output.get_Sample_Value = 0;
	end
	if output.Time_Resolution == 1 && extract.Time_Resolution > 1
		set(handles.check_output_sample_value,'Value',0,'Enable','off');
		handles.Current_Settings.Data_Output.get_Sample_Value = 0;
	end		
	if (extract.get_Mean_Value && ...
			extract.Time_Resolution <= output.Time_Resolution) || ...
			extract.Time_Resolution == 1
		set(handles.check_output_mean_value,...
			'Value',output.get_Mean_Value,'Enable','on');
	else
		set(handles.check_output_mean_value,'Value',0,'Enable','off');
		handles.Current_Settings.Data_Output.get_Mean_Value = 0;
	end
	if (extract.get_Min_Max_Value && ...
			extract.Time_Resolution <= output.Time_Resolution) || ...
			extract.Time_Resolution == 1
		set(handles.check_output_min_max_value,...
			'Value',output.get_Min_Max_Value,'Enable','on');
	else
		set(handles.check_output_min_max_value,'Value',0,'Enable','off');
		handles.Current_Settings.Data_Output.get_Min_Max_Value = 0;
	end
	if (extract.get_5_95_Quantile_Value && ...
			extract.Time_Resolution <= output.Time_Resolution) || ...
			extract.Time_Resolution == 1
		set(handles.check_output_5_95_quantile_value,...
			'Value',output.get_5_95_Quantile_Value,'Enable','on');
	else
		set(handles.check_output_5_95_quantile_value,'Value',0,'Enable','off');
		handles.Current_Settings.Data_Output.get_5_95_Quantile_Value = 0;
	end
end


%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%      Erzeugungsstruktur
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Die Anzeige der Erzeugungsanlagen anpassen (falls bereits mehrere
% Erzeugungsanlagen angegeben wurden):
todo = {'Sola','Wind'};
for i = 1:2
	% Wieviele Erzeugungsanlagen sind im Datensatz vorhanden?
	num_plants = size(fieldnames(handles.Current_Settings.(todo{i})),1);
	% Wieviele GUI-Eingabefelder gibt es gerade?
	found_last_gui_tag = false;
	% Zähler für die Felder, Start bei 2, weil mind. 2 Felder vorhanden sind:
	gui_tag_counter = 2;
	while ~found_last_gui_tag
		gui_tag_counter = gui_tag_counter + 1;
		last_tag = get_plant_gui_tags(handles.System.(todo{i}).Tags, gui_tag_counter);
		% überprüfen, ob es die akutellen Felder gibt:
		if ~isfield(handles,last_tag{1})
			% Wenn nicht, wurde das letze Tagfeld gefunden:
			found_last_gui_tag = true;
			% Zähler auf reae Anzahl von Eingabefelder zurücksetzen:
			gui_tag_counter = gui_tag_counter - 1;
		end
	end
	% Überprüfen, ob noch Eingabefelder fehlen:
	if num_plants > gui_tag_counter
		% Sicherheitskopie der Einstellungen erstellen:
		plants = handles.Current_Settings.(todo{i});
		% Default-Struktur wiederherstellen:
		handles.Current_Settings.(todo{i}) = [];
		handles.Current_Settings.(todo{i}).Plant_1 = ...
			handles.System.(todo{i}).Default_Plant;
		handles.Current_Settings.(todo{i}).Plant_2 = ...
			handles.System.(todo{i}).Default_Plant;
		% Falls mehr als die Defaultmäßig definierten vorhanden sind, zusätzliche
		% Parameterfelder erzeugen, damit diese dargestellt werden können:
		for j=1:num_plants-gui_tag_counter
			handles = add_gernation_plant_to_gui(handles,todo{i});
		end
		% Einstellungen wiederherstellen:
		handles.Current_Settings.(todo{i}) = plants;
	elseif gui_tag_counter > num_plants
		% Es sind mehr Eingabefelder als definierte Anlagen vorhanden, die
		% überzähligen Anlagen auf Default setzen (deaktivieren):
		for j=num_plants+1:gui_tag_counter
			handles.Current_Settings.(todo{i}).(['Plant_',num2str(j)]) = ...
				handles.System.(todo{i}).Default_Plant;
		end
	end
end

% Anlagenparametrierungen zur Anzeige bringen:
todo = {... % Liste mit den möglchen Anlagentypen + Zugehörige Schaltflächennamen
	'Sola','push_genera_pv_add_system';...
	'Wind','push_genera_wind_add_system';...
	};
Number_Generation = 0;
for i=1:size(todo,1)
	plants = fieldnames(handles.Current_Settings.(todo{i,1}));
	Number_Generation = Number_Generation + size(plants,1);
	for j=1:size(plants,1)
		tags = get_plant_gui_tags(handles.System.(todo{i,1}).Tags,j);
		plant = handles.Current_Settings.(todo{i,1}).(['Plant_',num2str(j)]);
		% Erzeugungsanlagentypen als Auswahlmöglichkeiten einstellen:
		set(handles.(tags{1}),'String',handles.System.(todo{i,1}).Typs(:,1));
		% Aktuellen Typ einstellen:
		set(handles.(tags{1}),'Value',plant.Typ);
		% Anzahl dieser Anlagen anzeigen:
		set(handles.(tags{2}),'String',num2str(plant.Number));
		% Installierte Leistung anpassen:
		switch todo{i,1}
			case 'Sola'
				set(handles.(tags{3}),'String',num2str(plant.Power_Installed));
			case 'Wind'
				set(handles.(tags{3}),'String',num2str(plant.Power_Installed/1000));
		end
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
		if j > 1 && handles.Current_Settings.(todo{i,1}).(['Plant_',num2str(j-1)]).Typ ~= 1
			set(handles.(tags{1}),'Enable','on');
		elseif j > 1 && handles.Current_Settings.(todo{i,1}).(['Plant_',num2str(j)]).Typ == 1
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
if Number_Generation >= handles.System.Number_Generation_Max
	set(handles.(todo{1,2}),'Enable','off');
	set(handles.(todo{2,2}),'Enable','off');
end

% Worstcases eintragen:
set(handles.popup_genera_worstcase, 'String', handles.System.wc_generation, ...
	'Value', handles.Current_Settings.Worstcase_Generation);

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%      Allgemeine Bereiche des GUIs
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Wenn Daten vorhanden, die Schaltflächen "Daten anzeigen" und "Daten speichern"
% aktivieren:
if isfield(handles,'Result')
	set(handles.push_data_save, 'Enable','on');
	set(handles.push_data_show, 'Enable','on');
else
	set(handles.push_data_save, 'Enable','off');
	set(handles.push_data_show, 'Enable','off');
end

% Wenn eine gültige Datenbank geladen wurde, die Schaltfläche "Daten extrahieren"
% aktivieren:
if isfield(handles.Current_Settings.Database,'setti')
	set(handles.push_export_data, 'Enable','on');
else
	set(handles.push_export_data, 'Enable','off');
end
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
drawnow;

