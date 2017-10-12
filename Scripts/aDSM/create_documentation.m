%% Datenbeschreibung aDSM Haushaltsdaten Auszug
% Die hier vorliegenden Daten enstprechen dem Auszug der aDSM Haushalte (126 aus den 
% simulierten 1260) entsprechend der Datei <\\ea.tuwien.ac.at\freigaben\intern\Projekte%20-%20laufend\aDSM\3_Durchführung\AP1\5_Synthetische_HH_Lasten\04_Auswertung_Ausstattung\2013-02-11%20Haushaltsdefinition%20126%20aus%201260.xlsx>. Dazu
% wurde das Script |get_devices_profile_data.m| verwendet. Entsprechend der der
% Definition in der Excel-Datei wurden die Jahresdaten der Einzelgeräteleistungsaufnahmen
% und deren Aktivität zusammengefasst und in 126 Einzeldateien mit dem Namensformat
% |HH_XXX.mat| im Ordner "aDSM_HH_Daten_aufbereitet" abgelegt.
% Im Folgendem wird der Aufbau der Daten beschrieben und ein Beispiel für den Zugriff auf
% diese gegeben.
%% Aufbau der Daten
% Für jeden Haushalt steht eine eigene Datei mit dem Namensformat |HH_XXX.mat| zur
% Verfügung. Das Namensformat ist duch die Excel-Definition festgelegt. Im Ordner
% "aDSM_HH_Daten_aufbereitet" findet sich neben diesen Dateien noch eine Log-Datei, die
% noch zusätzliche Informationen über den Vorgang des Zusammenführens enthält, z.B. die ID
% innerhalb der Haushaltskategorie der jeweilinge Haushalte (für spätere Kontrollen).
%
% In jeder der Teildateien befindet sich eine gleichnamige Strukur (|HH_XXX|), welche die
% Daten des jeweiligen Haushalts enthält.
% Die Daten selbst werden auf Haushaltsebene in einer |[n, 2, t]| - Matrix abgespeichert,
% welche über |HH_XXX.Time_Data| erreicht werden können (siehe Beispiel später).
%
% Über die *1. Dimension* kann auf die einzelnen Geräte zugegriffen werden (Anzahl |n| in dem
% jeweiligen Haushalt), die Bezeichnungen der Geräte sind über |HH_XXX.Device_Names|
% verfügbar (siehe Beispiel später). 
%
% Über die *2. Dimension* kann einerseits die Leistungsaufname oder die Aktivitätsmatrix
% ausgewählt werden.
%
% Die *3. Dimension* ist dann die Zeitreihe mit |t| Zeitpunkten, wobei |t = 1440 * 365| der
% Gesamtanzahl an Minuten eines Jahres entspricht.  
%% Verfügbare und simulierte Geräte
% Nachfolgend ein Cell-Array, das die Zuordnung
% der Namen zu den einzelnen Gerätearten beschreibt. Der Hinweis "Mehrere Einzel-Geräte
% zusammengefasst" bedeutet, dass hier zwar mehrere einzelne Instanzen dieser Gerätetypen
% simuliert wurden, nach der Simulation deren Leistungsaufnahme auf eine Zeitreihe
% zusammengefasst wurde. Auch die Aktivität dieser Geräte spiegelt nur wieder, ob eines dieser
% Geräte gerade aktiv ist, oder nicht, jedoch nicht Aktivität der einzelnen Geräte.
Devices_Pool = {...
	'refrig', 'Kühlschränke';...
	'freeze', 'Gefriergeräte';...
	'pc_des', 'Desktop PCs';...
	'pc_not', 'Notebooks';...
	'mon_pc', 'Monitore (PCs)';...
	'pr_las', 'Laserdrucker';...
	'pr_ink', 'Tintenstrahldrucker';...
	'offdiv', 'Diverse Bürogeräte';...
	'tv_set', 'Fernseher';...
	'set_to', 'Set-Top-Boxen';...
	'vid_eq', 'Video-Equipment';...
	'gam_co', 'Game-Konsolen';...
	'hi_fi_', 'Hi-Fi-Geräte';...
	'radio_', 'Radios';...
	'illumi', 'Beleuchtung';...          % Mehrere Einzel-Geräte zusammengefasst
	'washer', 'Waschmaschinen';...
	'dishwa', 'Geschirrspüler';...
	'cl_dry', 'Wäschetrockner';...
	'cir_pu', 'Umwälzpumpen';...
	'div_de', 'Diverse Geräte';...       % Mehrere Einzel-Geräte zusammengefasst
	'stove_', 'Herd';...                 % Mehrere Einzel-Geräte zusammengefasst
	'oven__', 'Backrohr';...             % Mehrere Einzel-Geräte zusammengefasst
	'microw', 'Mikrowelle';...           % Mehrere Einzel-Geräte zusammengefasst
	'ki_mis', 'Diverse Küchenger.';...   % Mehrere Einzel-Geräte zusammengefasst
	'wa_hea', 'Durchlauferhitzer';...
	'wa_boi', 'Warmwasserboiler';...
	'hea_ra', 'Heizkörper';...
	'hea_wp', 'Wärmepumpe';...
	};
%% Beispiel für Zugriff auf die Daten
% Zunächst muss festgelegt werden, welcher Haushaltsdatensatz geladen werden soll und der
% enstprechende Name zusammengesetzt werden (z.B. Haushalt Nr. 27):
hh_num = 27;
hh_name = ['HH_',num2str(hh_num,'%03.0f'),'.mat'];
%%
% Mit dem korrekten Pfad auf die Daten kann nun die enstprechende Datei mit der jeweiligen
% Datenstrukutr (im Beispiel die Struktur |HH_027|) geladen werden:
path = [pwd, filesep,'aDSM_HH_Daten_aufbereitet'];
load([path,filesep,hh_name]);
%%
% Nun steht die Datenstruktur |HH_027| zur Verfügung. Check, welche Geräte in diesem
% Haushalt verfügbar sind:
HH_027.Device_Names

%% 
% Um Zugriff auf die Datenreihen der Kühlschränke zu erhalten, müssen diese enstprechend
% selektiert werden:
idx = strcmp(HH_027.Device_Names, 'refrig');
refrig_data_power = squeeze(HH_027.Time_Data(idx,1,:));
%%
% Nun kann z.B. die Leistungsaufnahme der zwei Kühschräne der ersten 10 Stunden angezeigt
% werden:
t=1:600;
plot(t,refrig_data_power(:,t));
title('Leistungsaufnahme Kühlschränke [W]');

%%
% Auch kann die Aktivität der Kühlschränke abgefragt werden. Hier bedeutet ein Wert von
% |'1'| Aktiviität, |'0'| Inaktivität des Geräts. Z.B. Darstellung des ersten Kühlschranks: 
refrig_data_activity = squeeze(HH_027.Time_Data(idx,2,:));
plot(t,refrig_data_activity(1,t));
ylim([-0.1, 1.1]);
title('Aktivität eines Kühlschrankes');
%%
% Interessant ist auch die Untersuchung der Aktivität einzelner Geräte z.B. die Waschmaschine, dieses Haushalts,
% hier kann man nach dem ersten Zeitindex suchen, zu dem das
% Gerät eingeschalteet wurde. Dazu wird die Aktivitätsmatrix genutzt:
idx = strcmp(HH_027.Device_Names, 'washer');
washer_data_activity = squeeze(HH_027.Time_Data(idx,2,:));
t_idx_start = find(washer_data_activity > 0, 1)
%%
% d.h. bereits in Minute 50 (also 00:50 Uhr) startet diese Waschmaschine das erste Mal!
% Dies ist auch in der Leistungsaufnahme zu sehen (Beispiel eines vollständigen Zugriffs
% auf die Zeitdaten:)
t=1:1440;
ax = plotyy(t, squeeze(HH_027.Time_Data(idx,1,t)), t, squeeze(HH_027.Time_Data(idx,2,t)));
title('Waschmaschine, 24h');axes(ax(1));ylabel('Leistungsaufnahme [W]');
axes(ax(2));ylim([-0.1,1.5]);ylabel('Aktivität [0,1]');
%%
% Mit Hilfe der Aktivitätsmatrix lässt sich einfach nachvollziehen, wann Geräte aktiv sind
% oder wie oft Geräte eigentlich aktiviert werden. Dazu wird eine "Delta-Matrix erstellt"
% die die Einschaltflanken als +1, Ausschlatflanken als -1 darstellt. Dann können einfach
% die Flanken gezählt werden:
delta = washer_data_activity(2:end) - washer_data_activity(1:end-1);
delta = [0; delta];
sum_start = sum(delta > 0)
%%
% d.h. diese Waschmaschine wird 245 mal im Jahr verwendet und zwar zu den Zeitpunkten (als
% laufende Minuten eines Jahres, Ausgabe der ersten 10 Einsätze):
t_idxs_start = find(delta > 0);
t_idxs_start(1:10)
%%
% Auch die Gesamtleistungsaufnahme des Haushalts lässt sich relativ einfach ermitteln und
% darstellen:
power_hh = squeeze(sum(HH_027.Time_Data(:,1,:)));
t=1:2880;
figure;
plot(t,power_hh(t));
title('Gesamtleistungsaufnahme Haushalt über 48h [W]');