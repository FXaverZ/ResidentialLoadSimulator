function handles = get_default_values(handles)
%GET_DEFAULT_VALUES    laden der Default-Werte f�r Simulationsprogramm
%    HANDLES = GET_DEFAULT_VALUES(HANDLES) f�gt der HANDLES-Struktur des GUI
%    'Simulation' alle wichtigen Default-Werte und Definitionen hinzu. Falls
%    keine anderen Programmeinstellungen (z.B. von einem fr�heren
%    Simultionsdurchlauf) vorhanden sind, werden diese Werte herangezogen.

%    Franz Zeilinger - 03.08.2011

%===============================================================================
%                  D E F A U L T - D E F I N I T I O N E N
%===============================================================================
%
%-------------------------------------------------------------------------------
% Einstellungen zur Programmkonfiguration (Datei-Verwaltung, Optionen):
%-------------------------------------------------------------------------------
% Speicherort f�r erzeugte Daten / Konfigurationseinstellungen:
Save = handles.Configuration.Save;
Save.Settings.Name = 'Einstellungen';
Save.Settings.Ext = '.conf';
% Ergebnisse und zus�tzliche Daten werden im �bergeordneten Verzeichnis
% abgelegt. Dieses muss zuvor ermittelt werden:
ind = strfind(Save.Settings.Path,'\');
Save.Additional_Data.Path = Save.Settings.Path(1:ind(end-1));
Save.Data.Main_Path = [Save.Additional_Data.Path,'Simulationsergebnisse\'];
% Default-Parameterwerte sollten hier abgelegt sein:
Save.Source.Path = Save.Settings.Path;
Save.Source.Parameter_Name = 'Default_Parameterwerte';
% Parameter f�r Joblistendatei (Multiple Simulationen):
Save.Joblist.Path = Save.Additional_Data.Path;
Save.Joblist.Parameter_Name = Save.Source.Parameter_Name;
Save.Joblist.List_Name = 'Simulationsreihe';
Save.Frequency.Path = Save.Additional_Data.Path;
Save.Frequency.Name = 'Frequenzdaten';
Save.Frequency.Extension = '.fqd';

opt.show_data = 1; %Daten nach Simulation anzeigen
opt.savas_xls = 0; %Daten als .xls nach Sim. speichern
opt.savas_csv = 0; %Daten als .xls nach Sim. speichern
opt.use_last_frequency_data = 0; %Aktuelle Frequenzdaten heranziehen
opt.use_different_frequency_data = 0; % Verwendung von verschiedenen Frequenzdaten
opt.use_same_paramter_file = 0;
opt.multiple_simulation = 0; %Modus auf Einzelsimualtion
opt.simsettings_load_from_paramfile = 0;   %Daten von Parameterdatei laden
opt.simsettings_load_from_main_window = 1; %Einstellungen von Hauptfenster
opt.use_same_devices = 0; %Wenn m�glich, gleiche Ger�teinstanzen verwenden
opt.use_same_dsm = 0; % Wenn m�glich, gleiche DSM-Instanzen verwenden
opt.compute_parallel = 0; % Parallelrechnen per default aus.

Configuration.Save = Save;
Configuration.Options = opt; 
handles.Configuration = Configuration;

%===============================================================================
%               P A R A M E T E R D E F I N I T I O N E N :
%===============================================================================
%
%-------------------------------------------------------------------------------
% M�glichkeiten f�r alle zu simulierenden Ger�te: Cell_Array f�r  
% automatisches Abarbeiten:
%     { Variablenname, ausgeschriebener Name, Handle auf zust�ndige Klasse}
%-------------------------------------------------------------------------------
Model.Devices_Pool = {...
	'refrig', 'K�hlschr�nke',         @Thermal_Storage;...
% 	'refr_1', 'K�hlschr�nke 1',       @Thermal_Storage;...
	'pc_des', 'Desktop PCs',          @Probable_Operation;...
	'pc_not', 'Notebooks',            @Probable_Operation;...
	'mon_pc', 'Monitore (PCs)',       @Probable_Operation;...
	'pr_las', 'Laserdrucker',         @Interrupted_Operation;...
	'pr_ink', 'Tintenstrahldrucker',  @Probable_Operation;...
	'offdiv', 'Diverse B�roger�te',   @Probable_Operation;...
	'tv_set', 'Fernseher',            @Probable_Operation;...
	'set_to', 'Set-Top-Boxen',        @Probable_Operation;...
	'vid_eq', 'Video-Equipment',      @Probable_Operation;...
	'gam_co', 'Game-Konsolen',        @Probable_Operation;...
	'hi_fi_', 'Hi-Fi-Ger�te',         @Probable_Operation;...
	'radio_', 'Radios',               @Probable_Operation;...
	'illumi', 'Beleuchtung',          @Interrupted_Operation;...
	'illum1', 'Beleuchtung 1',        @Interrupted_Operation;...
	'illum2', 'Beleuchtung 2',        @Interrupted_Operation;...
	'illum3', 'Beleuchtung 3',        @Interrupted_Operation;...
	'illum4', 'Beleuchtung 4',        @Interrupted_Operation;...
	'illum5', 'Beleuchtung 5',        @Interrupted_Operation;...
	'illum6', 'Beleuchtung 6',        @Interrupted_Operation;...
	'washer', 'Waschmaschinen',       @Loadcurve_Operation;...
% 	'wash_1', 'Waschmaschinen 1',     @Loadcurve_Operation;...
% 	'wash_2', 'Waschmaschinen 2',     @Loadcurve_Operation;...
% 	'wash_3', 'Waschmaschinen 3',     @Loadcurve_Operation;...
% 	'wash_4', 'Waschmaschinen 4',     @Loadcurve_Operation;...
% 	'wash_5', 'Waschmaschinen 5',     @Loadcurve_Operation;...
% 	'wash_6', 'Waschmaschinen 6',     @Loadcurve_Operation;...
	'dishwa', 'Geschirrsp�ler',       @Loadcurve_Operation;...
% 	'dish_1', 'Geschirrsp�ler 1',     @Loadcurve_Operation;...
% 	'dish_2', 'Geschirrsp�ler 2',     @Loadcurve_Operation;...
% 	'dish_3', 'Geschirrsp�ler 3',     @Loadcurve_Operation;...
% 	'dish_4', 'Geschirrsp�ler 4',     @Loadcurve_Operation;...
	'cl_dry', 'W�schetrockner',       @Loadcurve_Operation;...
% 	'cl_dr1', 'W�schetrockner 1',     @Loadcurve_Operation;...
% 	'cl_dr2', 'W�schetrockner 2',     @Loadcurve_Operation;...
% 	'cl_dr3', 'W�schetrockner 3',     @Loadcurve_Operation;...
% 	'cl_dr4', 'W�schetrockner 4',     @Loadcurve_Operation;...
% 	'cl_dr5', 'W�schetrockner 5',     @Loadcurve_Operation;...
% 	'cl_dr6', 'W�schetrockner 6',     @Loadcurve_Operation;...
	'cir_pu', 'Umw�lzpumpen',         @Probable_Operation;...
% 	'cir_p1', 'Umw�lzpumpen 1',       @Probable_Operation;...
% 	'cir_p2', 'Umw�lzpumpen 2',       @Probable_Operation;...
% 	'cir_p3', 'Umw�lzpumpen 3',       @Probable_Operation;...
% 	'cir_p4', 'Umw�lzpumpen 4',       @Probable_Operation;...
% 	'cir_p5', 'Umw�lzpumpen 5',       @Probable_Operation;...
% 	'cir_p6', 'Umw�lzpumpen 6',       @Probable_Operation;...
	'div_de', 'Diverse Ger�te',       @Probable_Operation;...
	'div_d1', 'Diverse Ger�te 1',     @Probable_Operation;...
	'div_d2', 'Diverse Ger�te 2',     @Probable_Operation;...
	'div_d3', 'Diverse Ger�te 3',     @Probable_Operation;...
	'div_d4', 'Diverse Ger�te 4',     @Probable_Operation;...
	'div_d5', 'Diverse Ger�te 5',     @Interrupted_Operation;...
	'stove_', 'Herd',                 @Interrupted_Operation;...
    'oven__', 'Backrohr',             @Probable_Operation;...
	'microw', 'Mikrowelle',           @Interrupted_Operation;...
	'ki_mis', 'Diverse K�chenger.',   @Interrupted_Operation;...
	'ki_mi1', 'Diverse K�chenger. 1', @Interrupted_Operation;...
	'ki_mi2', 'Diverse K�chenger. 2', @Interrupted_Operation;...
	'ki_mi3', 'Diverse K�chenger. 3', @Interrupted_Operation;...
	'freeze', 'Gefrierger�te',        @Thermal_Storage;...
% 	'frez_1', 'Gefrierger�te 1',      @Thermal_Storage;...
	'wa_hea', 'Durchlauferhitzer',    @Interrupted_Operation;...
% 	'wa_he1', 'Durchlauferhitzer 1',  @Interrupted_Operation;...
% 	'wa_he2', 'Durchlauferhitzer 2',  @Interrupted_Operation;...
	'wa_boi', 'Warmwasserboiler',     @Interrupted_Operation;...
% 	'wa_bo1', 'Warmwasserboiler 1',   @Interrupted_Operation;...
% 	'wa_bo2', 'Warmwasserboiler 2',   @Interrupted_Operation;...
	'hea_ra', 'Heizk�rper',           @Interrupted_Operation;...
% 	'hea_r1', 'Heizk�rper 1',         @Interrupted_Operation;...
% 	'hea_r2', 'Heizk�rper 2',         @Interrupted_Operation;...
	'hea_wp', 'W�rmepumpe',           @Probable_Operation;...
% 	'hea_w1', 'W�rmepumpe 1',         @Probable_Operation;...
% 	'hea_w2', 'W�rmepumpe 2',         @Probable_Operation;...
	}; 

%-------------------------------------------------------------------------------
% M�gliche Ger�tegruppen:
%     { Variablenname, ausgeschriebener Name }
%-------------------------------------------------------------------------------
Model.Device_Groups_Pool = {...
	'gr_avd', 'Gruppe "Audio-Video-Ger�te"';...
	'gr_ill', 'Gruppe "Beleuchtung"';...
	'gr_off', 'Gruppe "B�roger�te"';...
	'gr_hea', 'Gruppe "Heizung"';...
	'gr_kit', 'Gruppe "K�che"';...
	'gr_hwa', 'Gruppe "Warmwasser"';...
	'gr_mis', 'Gruppe "Diverses"';...
% 	'gr_dis', 'Gruppe "Geschirrsp�ler"';...
    'gr_col', 'Gruppe "K�hlger�te"';...
% 	'gr_was', 'Gruppe "Waschmaschinen"';...
% 	'gr_cld', 'Gruppe "W�schetrockner"';...
% 	'gr_cir', 'Gruppe "Umw�lzpumpen"';...
	};

%-------------------------------------------------------------------------------
% Welche Ger�te und Ger�tegruppen sollen �ber das GUI angesprochen werden?
%     { Variablenname, ausgeschriebener Name }
% (ACHTUNG: die hier verwendeten Ger�te bzw. Gruppen m�ssen in den beiden zuvor
% definierten Cell-Arrays (Devices_Pool und Device_Groups_Pool) vorkommen!) 
%-------------------------------------------------------------------------------
Model.Device_Assembly_Pool = {...
	'gr_avd', 'Gruppe "Audio-Video-Ger�te"';
	'gr_ill', 'Gruppe "Beleuchtung"';...
	'gr_off', 'Gruppe "B�roger�te"';...
	'gr_mis', 'Gruppe "Diverses"';...
	'gr_hea', 'Gruppe "Heizung"';...
	'gr_kit', 'Gruppe "K�che"';...
	'gr_hwa', 'Gruppe "Warmwasser"';...
    'gr_col', 'Gruppe "K�hlger�te"';...
% 	'freeze', 'Gefrierger�te';...
% 	'refrig', 'K�hlschr�nke';...
	'dishwa', 'Geschirrsp�ler';...
% 	'gr_dis', 'Gruppe "Geschirrsp�ler"';...
	'cl_dry', 'W�schetrockner';...
% 	'gr_cld', 'Gruppe "W�schetrockner"';...
	'washer', 'Waschmaschinen';...
% 	'gr_was', 'Gruppe "Waschmaschinen"';...
	'cir_pu', 'Umw�lzpumpen';... 
% 	'gr_cir', 'Gruppe "Umw�lzpumpen"';...
	};

%-------------------------------------------------------------------------------
% ACHTUNG: folgende Listen definieren die m�glichen Namen f�r die verschiedenen,
% in diesem Programm vorkommenden Parameter. Werden diese Namen hier ge�ndert,
% m�ssen die korrespondieren Properties in den Ger�teklassen (bzw. bei den
% Simulationsparametern in den Programmfunktionen) dementsprechend ge�ndert
% werden! Diese Definitionen dienen dazu, zuk�nftige weitere Parameter einfach
% ins Programm einf�gen zu k�nnen, da deren Behandlung f�r Einlesen und Ausgabe
% mit Hilfe der rw_Funktinen automatisiert abl�uft.
% F�r n�here Infos siehe Hilfetext der verwendeten rw_-Funktionen (zu
% finden im Ordner 'Hilfsfunktionen' im Programmverzeichnis)
%-------------------------------------------------------------------------------

% Auflistung aller m�glichen Simulationsparameter:
%     {Parametername, Handle auf zust�ndige rw_-Funktion}
Model.Sim_Param_Pool = {...
	'Date_Start',     @rw_sim_parameter;...
	'Date_End',       @rw_sim_parameter;...
	'Sim_Resolution', @rw_sim_parameter;...
	'Number_User',    @rw_sim_parameter;
	'Use_DSM',        @rw_sim_parameter;...
	'Use_Same_DSM',   @rw_sim_parameter;...
	'Device_Assembly',@rw_dev_assembly;...
	};

f_val = '%6.1f'; %Formatstring f�r Parameterwerte
f_sig = '%4.1f'; %Formatstring f�r Varianzen u.d.gl.

% Auflistung m�glicher Parametertypen der Ger�te:
% {Parametername, ...
%      Handle auf zust�ndige rw_-Funktion,...
%      Argumtente f. rw_-Funtkion;}
% Nichtbn�tigte Argumente werden (um Cell-Array zu erm�glichen) mit leeren
% Zellen ('[]') bef�llt, damit jede Zeile die gleiche Spaltenanzahl hat!
Model.Parameter_Pool = {...
	'Power_Nominal',...          % Nennleistung
	    @rw_single_parameter,... 
	    'W',  '%',   f_val, f_sig, [],    [];...
	'Cos_Phi_Nominal',...        % Nennleistungsfaktor
		@rw_single_parameter,... 
	    '',   '%',   f_val, f_sig, [],    [];...
	'Power_Stand_by',...         % Stand-by-Verbrauch
	    @rw_single_parameter,... 
	    'W',  '%',   f_val, f_sig, [],    [];...
	'Cos_Phi_Stand_by',...        % Nennleistungsfaktor im Stand-by-Betrieb
		@rw_single_parameter,... 
	    '',   '%',   f_val, f_sig, [],    [];...
	'Three_Phase_Device',...      % Dreiphasiges Ger�t? (1 = Ja)
		@rw_single_parameter,... 
	    '','n.n.',   f_val, f_sig, [],    [];...
	'Factor_Inrush',...          % Faktor Einschaltspitze
	    @rw_single_parameter,... 
	    '%',  '%',   f_val, f_sig, [],    [];...
	'Time_Inrush_Decay',...      % Abklingezeit Einschaltspitze
	    @rw_single_parameter,... 
	    's'  ,'%',   f_val, f_sig, [],    [];...
	'Dir_therm_Flow',...         % Richtung der thermischen Energiezufuhr
		@rw_single_parameter,... 
	    '','n.n.', '%5.0f', f_sig, [],    [];...
	'Efficency',...              % Wirkungsgrad
	    @rw_single_parameter,... 
	    '%',  '%',   f_val, f_sig, [],    [];...      
	'Switch_Point',...           % Schaltschwelle
	    @rw_single_parameter,... 
	    '�C', '%',   f_val, f_sig, [],    [];...      
	'Heat_Capacity',...          % W�rmekapazit�t 
	    @rw_single_parameter,... 
	    'J/K','%',   f_val, f_sig, [],    [];...      
	'Thermal_Res',...            % thermischer Widerstand
	    @rw_single_parameter,... 
	    'K/W','%',   f_val, f_sig, [],    [];...      
	'Temp_Set',...               % Solltemperatur
	    @rw_single_parameter,... 
	    '�C', '%',   f_val, f_sig, [],    [];...      
	'Temp_Ambiance',...          % Umgebungstemperatur
	    @rw_single_parameter,... 
	    '�C', '%',   f_val, f_sig, [],    [];...      
	'Operat_Sim_Start',...       % Wahrschl. f�r Betrieb bei Simulationsstart
	    @rw_single_parameter,... 
	    '%',  'n.n.',f_val, f_sig, [],    [];...      
	'Time_Period',...            % Periodendauer 
	    @rw_single_parameter,... 
	    'min','%',   f_val, f_sig, [],    [];...      
	'Time_typ_Run',...           % typ. Laufzeit
	    @rw_parameter_list,... 
	    'min','%',   f_val, f_sig,'%5.1f','%5.1f';... 
	'Time_Start',...             % Startzeit
	    @rw_parameter_list,... 
	    'Uhr','min', '%s',  f_sig, '%s' , '%5.1f';...
	'Start_Probability',...      % Einschaltwahrscheinlichkeit
	    @rw_parameter_list,... 
	    '%',  'n.n.',f_val, f_sig,'%5.1f','%5.1f';... 
	'Power_Loadcurve',...        % Lastkurve
	    @rw_loadcurve,...                 
	    [],   [],    [],    [],    [],    [];...    
	'Loadcurve_Allocation',...   % Einschaltwahrscheinlichkeit der versch. Lastkurven
	    @rw_parameter_list,...
	    '%',  'n.n.',f_val, f_sig,'%5.1f','%5.1f';... 
	'Loadcurve_non_stop_Parts',... % Definition der zusammenh�ngenden Teil der Lastk.
	    @rw_loadcurve_parts,...
	    [],   [],    [],    [],    [],    [];...
	'Device_Group_Members',...   % Mitglieder einer Ger�tegruppe
	    @rw_device_group_members,...
	    [],   [],    [],    [],    [],    [];...
	'Time_Starts_per_Hour',...   % Anzahl der Starts pro Stunde
	    @rw_single_parameter,...
	    '1/h','%',   f_val, f_sig, [],    [];...
	'Time_run_Duty_Cycle',...    % typische Laufzeit innerhalb einer Periode
	    @rw_single_parameter,...
	    '%',  '%',   f_val, f_sig, [],    [];...	
	'Time_min_Run',...           % minimale Einschaltzeit eines Ger�tes
	    @rw_single_parameter,...
	    'min','%',   f_val, f_sig, [],    [];...	
		};

% Auflistung m�glicher Parametertype f�r DSM:
Model.DSM_Param_Pool = {...
	'DSM_Input_Mode',...       % Auswahl des zu verwendenden DSM-Algorithmus
	    @rw_dsm_modus,... 
	    [],    [],    [],     [],    [],    [];...      
	'Check_former_Frequ_Data',... % �berpr�fung zur�ckliegender Frequenzdaten
	    @rw_single_parameter,... 
	    'bool','n.n.',[],     [],    [],    [];...      
	'DSM_Output_Mode',...      % A�swahl der Reaktion des Ger�tes
	    @rw_dsm_modus,... 
	    [],    [],    [],     [],    [],    [];...      
	'Frequency_Level',...      % Frequenzwert, ab dem DSM eingreift
	    @rw_single_parameter,... 
	    'Hz',  '%',   f_val,  f_sig, [],    [];...    
	'Frequency_Hysteresis',... % Frequenzwert der Breite der Hysterese der Frequenz 
	    @rw_single_parameter,... 
	    'Hz',  '%',   f_val,  f_sig, [],    [];...  
	'Frequ_Filter_Time',...    % Filterzeitkonstante f�r Frequenzfilterung
	    @rw_single_parameter,... 
	    'min', '%',   f_val,  f_sig, [],    [];...  	
	'Prioritys_Number',...     % Anzahl an Priorit�tsgruppen von Verbrauchern
	    @rw_single_parameter,... 
	    '',    'n.n.','%6.0f',f_sig, [],    [];...      
	'Prioritys_Freq_Range',... % Frequenzbereich der einzelnen Priorit�tsgruppen
	    @rw_parameter_list,... 
	    'Hz',  '%',   f_val,  f_sig,'%5.1f','%5.1f';... 
	'Prioritys_Allocation',... % Verteilung der Verbr. auf die Priorit�tsgruppen
	    @rw_parameter_list,... 
	    '%',   'n.n.',f_val,  f_sig,'%5.1f','%5.1f';... 
	'Time_Delay_Restore_Op',...% Zeitverz�gerung Wiederinbetriebnahme
	    @rw_single_parameter,... 
	    'min', '%',   f_val,  f_sig, [],    [];...  	
	'Temp_Set_Variation',...   % H�he der Soll-Temperatur-�nderung
	    @rw_single_parameter,... 
	    '�C',  '%',   f_val,  f_sig, [],    [];...      
	'Power_Reduction',...      % H�he der Leistungsreduktion
	    @rw_single_parameter,... 
	    '%',   '%',   f_val,  f_sig, [],    [];...      
	'Consider_non_stop_Parts',... % Ber�cksichtung der Non-Stop-Bereiche v. Lastkurve
	    @rw_single_parameter,... 
	    'bool','%',   f_val,  f_sig, [],    [];... 
	'Time_Postpone_Start',...  % Dauer der Einschaltverz�gerung
	    @rw_single_parameter,... 
	    'min', '%',   f_val,  f_sig, [],    [];...  
	'Time_Postpone_max',...    % Maximale Dauer der Einschaltverz�gerung
	    @rw_single_parameter,... 
	    'min', '%',   f_val,  f_sig, [],    [];... 
	};

%-------------------------------------------------------------------------------
% Auflistung der implementierten DSM-Funktionen:
%-------------------------------------------------------------------------------

Model.DSM_Input_Mode = {...			% DSM-Algorithmus:	
	'No_DSM_Function',...               % Keine DSM-Funktion
	'Frequency_Response_Simple',...	    % Frequenzschaltschwelle	
	'Frequency_Response_Priority',...   % Priorit�tsgruppen               
	};
Model.DSM_Output_Mode = {...        % Reaktion des Ger�tes:
	'No_DSM_Function',...               % Keine DSM-Funktion
	'Turn_Off',...					    % Ausschalten
	'Turn_Off_Stand_by',...			    % Verlassen des Stand-by-Modus
	'Change_Temp_Set',...			    % Soll-Temperatur-�nderung
	'Reduce_Input_Power',...		    % Leistungsreduktion
	'Postpone_Start',...			    % Verz�gerung Einschalten
	'Pause_Programm',...                % Programm unterbrechen
	};
	
%===============================================================================
%              S I M U L A T I O N S E I N S T E L L U N G E N
%===============================================================================
%
% Startzeitpunkt TT-Mon-JJJJ HH:MM:SS
Model.Date_Start = '19-Feb-2010 00:00:00';
% Endzeitpunkt   TT-Mon-JJJJ HH:MM:SS
Model.Date_End =   '20-Feb-2010 00:00:00'; 

% Aufl�sung der Simulation: 'sec' = Sekundentakt
%                           'min' = Minutentakt
%                           '5mi' = 5-Minutentakt
%                           'quh' = Viertelstundendtakt
%                           'hou' = Stundentakt
Model.Sim_Resolution = 'quh';
Model.Number_User = 500;     % Anzahl der Personen, die die Ger�te verwenden
Model.Use_DSM = false;       % Soll der DSM-Algorithmus laufen?
Model.Use_Same_DSM = false;% Sollen vorhandene DSM-Instanzen verwendet werden? 
                           %    (nur f�r Simulationsreihe relevant: Wert 'false'
                           %    bedeutet, das ungeachtet der anderen
                           %    Einstellungen neue DSM-Instanzen erzeugt
                           %    werden!)

% ------------------------------------------------------------------------------
%                   Ger�tezusammenstellung und Einsatz:
% ------------------------------------------------------------------------------
for i=1:size(Model.Device_Assembly_Pool,1)
	% alle M�glichkeiten aktiv setzen:
	Model.Device_Assembly.(Model.Device_Assembly_Pool{i,1}) = 1; 
end
for i=1:size(Model.Devices_Pool,1)
	% alle Ger�te aktiv setzen:
	Model.Device_Assembly_Simulation.(Model.Devices_Pool{i,1}) = 1; 
end
%===============================================================================
% Model-Struktur aktualisieren:
handles.Model = Model;