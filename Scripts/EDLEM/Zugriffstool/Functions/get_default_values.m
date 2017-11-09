function handles = get_default_values(handles)
%GET_DEFAULT_VALUES    lädt Standardeinstellungen für ACCESS_TOOL
%    HANDLES = GET_DEFAULT_VALUES(HANDLES) fügt der HANDLES-Struktur Standardwerte 
%    hinzu. Mit Hilfe dieser Funktion werden die Haupteinstellungen vordefiniert und
%    das Startverhalten des Zugriffstools festgelegt.

% Erstellt von:            Franz Zeilinger - 26.06.2012
% Letzte Änderung durch:   Franz Zeilinger - 14.08.2012

% Standardbezeichnungen:
handles.System.seasons =   {... % Typen der Jahreszeiten
	'Summer', 'Sommer';... 
	'Transi', 'Übergang';...
	'Winter', 'Winter';...
	}; 
handles.System.weekdays =  {... % Typen der Wochentage
	'Workda', 'Werktag';...
	'Saturd', 'Samstag';...
	'Sunday', 'Sonntag';...
	};  
handles.System.housholds = {... % Definition der Haushaltskategorien:
	'sing_vt', 'Single Vollzeit';...
	'coup_vt', 'Paar Vollzeit';...
	'sing_pt', 'Single Teilzeit';...
	'coup_pt', 'Paar Teilzeit';...
	'sing_rt', 'Single Pension';...
	'coup_rt', 'Paar Pension';...
	'fami_2v', 'Familie, 2 Mitglieder Vollzeit';...
	'fami_1v', 'Familie, 1 Mitglied Vollzeit';...
	'fami_rt', 'Familie mit Pensionist(en)';...
	};

% die weiteren Daten der Haushalte einlesen:
handles.Households = load_household_parameter();

% Definition der verschiedenen "Worst Cases":
handles.System.wc_households = {...
	'Kein';...
	'Höchster Energieverbrauch';...
	'Niedrigster Energieverbrauch';...
	'Höchste Leistungsaufnahme';...
	};
handles.Current_Settings.Worstcase_Housholds = 1; % Default = 'Kein'
handles.System.wc_generation = {...
	'Kein';...
	'Höchste Tageseinspeisung';...
	'Niedrigste Tageseinspeisung';...
% 	'Höchste Leistung';...
	};
handles.Current_Settings.Worstcase_Generation = 1; % Default = 'Kein'

% Anzahl an maximal möglichen verschiedenen Erzeugungsanlagen im GUI (Gesamtanzahl an
% möglichen Eingabefeldern):
handles.System.Number_Generation_Max = 15;
% Definition der Erzeugungs-Anlagenarten:
handles.System.Sola.Typs = {...
	'Keine Anlage ausgewählt';...
	'Fix montiert';...
	'Tracker';...
	};

% Name der verfügbaren Windkraft-Anlagen auslesen:
handles.System.Wind.Typs = get_wind_turbine_parameters('typs');
handles.System.Wind.Typs = ['Keine Anlage ausgewählt'; handles.System.Wind.Typs];

% Für dynamische Tags der einzelnen Einstellungsmöglichkeiten, deren grobe
% Struktur definieren:
handles.System.Sola.Tags = {...
	'popup_genera_pv_','_typ';...
	'edit_genera_pv_','_number';...
	'edit_genera_pv_','_installed_power'; ...
	'push_genera_pv_','_parameters';...
	'text_genera_pv_','_unit';...
	};
handles.System.Wind.Tags = {...
	'popup_genera_wind_','_typ';...
	'edit_genera_wind_','_number';...
	'edit_genera_wind_','_installed_power';...
	'push_genera_wind_','_parameters';...
	'text_genera_wind_','_unit';...
	};
% Angabe der Höhe eines Eingabefeldes für Erzeugungsanlagen in Pixel:
handles.System.Generation.Input_Field_Height = 27;

% Default Werte einstellen (alle Anlagen aus, Standardwerte), zuerst PV-Anlagen:
Default_Plant.Typ = 1;                  % Typ der Anlage (siehe 
%                                             HANDLES.SYSTEM.SOLA.TYPS)
Default_Plant.Number = 0;               % Anzahl Anlagen           [-]
Default_Plant.Power_Installed = 0;      % Installierte Leistung    [kW]
Default_Plant.Orientation = 0;          % Ausrichtung              [°]
Default_Plant.Inclination = 30;         % Neigung                  [°]
Default_Plant.Efficiency = 0.17;        % Wirkungsgrad Zelle + WR  [-]
Default_Plant.Rel_Size_Collector = 6.5; % Rel. Kollektorfläche     [m²/kWp]
Default_Plant.Size_Collector = ...      % Kollektorfläche          [m²]
	Default_Plant.Power_Installed * Default_Plant.Rel_Size_Collector;
Default_Plant.Sigma_delay_time = 15;    % zeitl. Standardabweichung[s] 
% Zwei Anlagen werden per Default angeboten:
handles.System.Sola.Default_Plant = Default_Plant;
handles.Current_Settings.Sola.Plant_1 = Default_Plant;
handles.Current_Settings.Sola.Plant_2 = Default_Plant;
clear('Default_Plant');

% Windkraftanlagen:
Default_Plant.Typ =             1;      % Anlagen-Typ, 1 = "keine Anlage"
Default_Plant.Number =          0;      % Anzahl der Anlagen               [-]
Default_Plant.Power_Installed = 0;      % Nennleistung der Anlage          [W]
Default_Plant.Rho =         1.225;      % Luftdichte                       [kg/m³]
Default_Plant.v_nominal =      11;      % Windgeschwindigkeit bei der Nennleistung
%                                             verfügbar ist                [m/s]
Default_Plant.Efficiency =   0.98;      % Wirkungsgrad des Wechselrichters [-]
Default_Plant.v_start =       0.8;      % Anlaufwindgeschwindigkeit        [m/s]
Default_Plant.v_cut_off =      15;      % Abschaltwindgeschwindigkeit      [m/s]
Default_Plant.Size_Rotor =    2.5;      % Rotordurchmesser                 [m]
Default_Plant.Typ_Rotor =  'n.d.';      % Art des Rotors
Default_Plant.Inertia =      20.0;      % Trägheit des Windrads            [s]
Default_Plant.c_p =            [];      % Tabelle mit Leistungsbeiwerten bei
%                                             bestimmten Windgeschwindigkeiten (kommt 
%                                             aus Anlagenparameterdatei
%                                             "get_wind_trubine_parameters").
Default_Plant.Sigma_delay_time = 15;    % zeitl. Standardabweichung        [s] 
handles.System.Wind.Default_Plant = Default_Plant;
handles.Current_Settings.Wind.Plant_1 = Default_Plant;
handles.Current_Settings.Wind.Plant_2 = Default_Plant;

% mögliche Zeitauflösungen:
handles.System.time_resolutions = {...
	'sec - Sekunden',     1;...
	'min - Minuten',     60;...
	'5mi - 5 Minuten',  300;...
	'quh - 15 Minuten', 900;...
	};
% Defaultwerte der Datenbehandlungseinstellungen (Auslesen & Speichern):
data_settings.Time_Resolution = 1;    % zeitliche Auflösung
data_settings.get_Sample_Value = 1;   % Sample-Werte ermitteln bzw. speichern.
data_settings.get_Mean_Value = 0;     % Mittelwerte ermitteln bzw. speichern.
data_settings.get_Min_Max_Value = 0;  % Minimal- und Maximalwerte ermitteln bzw. 
                                      %     speichern.
data_settings.get_5_95_Quantile_Value = 0; % Ermitteln des 5- und 95%-Quantils
% Einstellungen für Datenauslesen:
handles.Current_Settings.Data_Extract = data_settings;
% Soll eine Zeitreihe soll erstellt werden?
handles.Current_Settings.Data_Extract.get_Time_Series = 0;
% Einstellungen der Zeitreihe
Time_Series.Date_Start = '27.04.2012'; % Startdatum der Zeitreihe
Time_Series.Duration = 7;              % Dauer der Zeitreihe in Tagen
handles.Current_Settings.Data_Extract.Time_Series = Time_Series;
% Einstellungen für Speicherung:
handles.Current_Settings.Data_Output = data_settings; 
% mögliche Dateiausgabetypen:
handles.System.outputdata_types = {...
	'*.mat','.mat - MATLAB Binärdatei';...
	'*.csv','.csv - Commaseparated Values';...
	'*.xlsx','.xlsx - EXCEL Spreadsheet';...
	'*.xls','.xls - EXCEL 97-2003 Spreadsheet';...
% 	'*.txt','.txt - NEPLAN Lastganglisten (Exper.)';...
	};
% Aktuelle Auswahl des Ausgabedatentyps (siehe HANDLES.SYSTEM.OUTPUTDATA_TYPES):
handles.Current_Settings.Data_Output.Datatyp = 1;
% Auswahl, ob die Daten als einphasige Daten abgespeichert werden sollen:
handles.Current_Settings.Data_Output.Single_Phase = 0;

% Anzahl der Haushalte Null setzen:
for i=1:size(handles.System.housholds,1)
	handles.Current_Settings.Households.(handles.System.housholds{i,1}).Number = 0;
end

% Jahreszeiten setzen:
handles.Current_Settings.Season = logical([1 0 0]');
handles.Current_Settings.Weekday = logical([1 0 0]');

% Standard-Dateipfade, Pfad zur Datenbank:
handles.Current_Settings.Database.Path = handles.Current_Settings.Main_Path;
handles.Current_Settings.Database.Name = 'DLE_Datenbank';
% selbst gespeicherte Konfigurationsdateien:
handles.Current_Settings.Config.Path = handles.Current_Settings.Main_Path;
handles.Current_Settings.Config.Name = 'DLE Zugriffstool Konfiguration';
handles.Current_Settings.Config.Exte = '.cfg';
% automatisch erzeugte Konfigurationsdatei (merken der letzten Einstellungen):
handles.Current_Settings.Last_Conf.Path = handles.Current_Settings.Main_Path;
handles.Current_Settings.Last_Conf.Name = 'Einstellungen';
handles.Current_Settings.Last_Conf.Exte = '.cfg';
% Zielverzeichnis für Datenbankauszüge:
handles.Current_Settings.Target.Path = [handles.Current_Settings.Main_Path,filesep,'Ergebnisse'];
handles.Current_Settings.Target.Name = 'Datenbankauszug';
handles.Current_Settings.Target.Exte = '.mat';
end