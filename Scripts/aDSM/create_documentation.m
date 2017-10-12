%% Datenbeschreibung aDSM Haushaltsdaten Auszug
% Die hier vorliegenden Daten enstprechen dem Auszug der aDSM Haushalte (126 aus den 
% simulierten 1260) entsprechend der Datei <\\ea.tuwien.ac.at\freigaben\intern\Projekte%20-%20laufend\aDSM\3_Durchf�hrung\AP1\5_Synthetische_HH_Lasten\04_Auswertung_Ausstattung\2013-02-11%20Haushaltsdefinition%20126%20aus%201260.xlsx>. Dazu
% wurde das Script |get_devices_profile_data.m| verwendet. Entsprechend der der
% Definition in der Excel-Datei wurden die Jahresdaten der Einzelger�teleistungsaufnahmen
% und deren Aktivit�t zusammengefasst und in 126 Einzeldateien mit dem Namensformat
% |HH_XXX.mat| im Ordner "aDSM_HH_Daten_aufbereitet" abgelegt.
% Im Folgendem wird der Aufbau der Daten beschrieben und ein Beispiel f�r den Zugriff auf
% diese gegeben.
%% Aufbau der Daten
% F�r jeden Haushalt steht eine eigene Datei mit dem Namensformat |HH_XXX.mat| zur
% Verf�gung. Das Namensformat ist duch die Excel-Definition festgelegt. Im Ordner
% "aDSM_HH_Daten_aufbereitet" findet sich neben diesen Dateien noch eine Log-Datei, die
% noch zus�tzliche Informationen �ber den Vorgang des Zusammenf�hrens enth�lt, z.B. die ID
% innerhalb der Haushaltskategorie der jeweilinge Haushalte (f�r sp�tere Kontrollen).
%
% In jeder der Teildateien befindet sich eine gleichnamige Strukur (|HH_XXX|), welche die
% Daten des jeweiligen Haushalts enth�lt.
% Die Daten selbst werden auf Haushaltsebene in einer |[n, 2, t]| - Matrix abgespeichert,
% welche �ber |HH_XXX.Time_Data| erreicht werden k�nnen (siehe Beispiel sp�ter).
%
% �ber die *1. Dimension* kann auf die einzelnen Ger�te zugegriffen werden (Anzahl |n| in dem
% jeweiligen Haushalt), die Bezeichnungen der Ger�te sind �ber |HH_XXX.Device_Names|
% verf�gbar (siehe Beispiel sp�ter). 
%
% �ber die *2. Dimension* kann einerseits die Leistungsaufname oder die Aktivit�tsmatrix
% ausgew�hlt werden.
%
% Die *3. Dimension* ist dann die Zeitreihe mit |t| Zeitpunkten, wobei |t = 1440 * 365| der
% Gesamtanzahl an Minuten eines Jahres entspricht.  
%% Verf�gbare und simulierte Ger�te
% Nachfolgend ein Cell-Array, das die Zuordnung
% der Namen zu den einzelnen Ger�tearten beschreibt. Der Hinweis "Mehrere Einzel-Ger�te
% zusammengefasst" bedeutet, dass hier zwar mehrere einzelne Instanzen dieser Ger�tetypen
% simuliert wurden, nach der Simulation deren Leistungsaufnahme auf eine Zeitreihe
% zusammengefasst wurde. Auch die Aktivit�t dieser Ger�te spiegelt nur wieder, ob eines dieser
% Ger�te gerade aktiv ist, oder nicht, jedoch nicht Aktivit�t der einzelnen Ger�te.
Devices_Pool = {...
	'refrig', 'K�hlschr�nke';...
	'freeze', 'Gefrierger�te';...
	'pc_des', 'Desktop PCs';...
	'pc_not', 'Notebooks';...
	'mon_pc', 'Monitore (PCs)';...
	'pr_las', 'Laserdrucker';...
	'pr_ink', 'Tintenstrahldrucker';...
	'offdiv', 'Diverse B�roger�te';...
	'tv_set', 'Fernseher';...
	'set_to', 'Set-Top-Boxen';...
	'vid_eq', 'Video-Equipment';...
	'gam_co', 'Game-Konsolen';...
	'hi_fi_', 'Hi-Fi-Ger�te';...
	'radio_', 'Radios';...
	'illumi', 'Beleuchtung';...          % Mehrere Einzel-Ger�te zusammengefasst
	'washer', 'Waschmaschinen';...
	'dishwa', 'Geschirrsp�ler';...
	'cl_dry', 'W�schetrockner';...
	'cir_pu', 'Umw�lzpumpen';...
	'div_de', 'Diverse Ger�te';...       % Mehrere Einzel-Ger�te zusammengefasst
	'stove_', 'Herd';...                 % Mehrere Einzel-Ger�te zusammengefasst
	'oven__', 'Backrohr';...             % Mehrere Einzel-Ger�te zusammengefasst
	'microw', 'Mikrowelle';...           % Mehrere Einzel-Ger�te zusammengefasst
	'ki_mis', 'Diverse K�chenger.';...   % Mehrere Einzel-Ger�te zusammengefasst
	'wa_hea', 'Durchlauferhitzer';...
	'wa_boi', 'Warmwasserboiler';...
	'hea_ra', 'Heizk�rper';...
	'hea_wp', 'W�rmepumpe';...
	};
%% Beispiel f�r Zugriff auf die Daten
% Zun�chst muss festgelegt werden, welcher Haushaltsdatensatz geladen werden soll und der
% enstprechende Name zusammengesetzt werden (z.B. Haushalt Nr. 27):
hh_num = 27;
hh_name = ['HH_',num2str(hh_num,'%03.0f'),'.mat'];
%%
% Mit dem korrekten Pfad auf die Daten kann nun die enstprechende Datei mit der jeweiligen
% Datenstrukutr (im Beispiel die Struktur |HH_027|) geladen werden:
path = [pwd, filesep,'aDSM_HH_Daten_aufbereitet'];
load([path,filesep,hh_name]);
%%
% Nun steht die Datenstruktur |HH_027| zur Verf�gung. Check, welche Ger�te in diesem
% Haushalt verf�gbar sind:
HH_027.Device_Names

%% 
% Um Zugriff auf die Datenreihen der K�hlschr�nke zu erhalten, m�ssen diese enstprechend
% selektiert werden:
idx = strcmp(HH_027.Device_Names, 'refrig');
refrig_data_power = squeeze(HH_027.Time_Data(idx,1,:));
%%
% Nun kann z.B. die Leistungsaufnahme der zwei K�hschr�ne der ersten 10 Stunden angezeigt
% werden:
t=1:600;
plot(t,refrig_data_power(:,t));
title('Leistungsaufnahme K�hlschr�nke [W]');

%%
% Auch kann die Aktivit�t der K�hlschr�nke abgefragt werden. Hier bedeutet ein Wert von
% |'1'| Aktiviit�t, |'0'| Inaktivit�t des Ger�ts. Z.B. Darstellung des ersten K�hlschranks: 
refrig_data_activity = squeeze(HH_027.Time_Data(idx,2,:));
plot(t,refrig_data_activity(1,t));
ylim([-0.1, 1.1]);
title('Aktivit�t eines K�hlschrankes');
%%
% Interessant ist auch die Untersuchung der Aktivit�t einzelner Ger�te z.B. die Waschmaschine, dieses Haushalts,
% hier kann man nach dem ersten Zeitindex suchen, zu dem das
% Ger�t eingeschalteet wurde. Dazu wird die Aktivit�tsmatrix genutzt:
idx = strcmp(HH_027.Device_Names, 'washer');
washer_data_activity = squeeze(HH_027.Time_Data(idx,2,:));
t_idx_start = find(washer_data_activity > 0, 1)
%%
% d.h. bereits in Minute 50 (also 00:50 Uhr) startet diese Waschmaschine das erste Mal!
% Dies ist auch in der Leistungsaufnahme zu sehen (Beispiel eines vollst�ndigen Zugriffs
% auf die Zeitdaten:)
t=1:1440;
ax = plotyy(t, squeeze(HH_027.Time_Data(idx,1,t)), t, squeeze(HH_027.Time_Data(idx,2,t)));
title('Waschmaschine, 24h');axes(ax(1));ylabel('Leistungsaufnahme [W]');
axes(ax(2));ylim([-0.1,1.5]);ylabel('Aktivit�t [0,1]');
%%
% Mit Hilfe der Aktivit�tsmatrix l�sst sich einfach nachvollziehen, wann Ger�te aktiv sind
% oder wie oft Ger�te eigentlich aktiviert werden. Dazu wird eine "Delta-Matrix erstellt"
% die die Einschaltflanken als +1, Ausschlatflanken als -1 darstellt. Dann k�nnen einfach
% die Flanken gez�hlt werden:
delta = washer_data_activity(2:end) - washer_data_activity(1:end-1);
delta = [0; delta];
sum_start = sum(delta > 0)
%%
% d.h. diese Waschmaschine wird 245 mal im Jahr verwendet und zwar zu den Zeitpunkten (als
% laufende Minuten eines Jahres, Ausgabe der ersten 10 Eins�tze):
t_idxs_start = find(delta > 0);
t_idxs_start(1:10)
%%
% Auch die Gesamtleistungsaufnahme des Haushalts l�sst sich relativ einfach ermitteln und
% darstellen:
power_hh = squeeze(sum(HH_027.Time_Data(:,1,:)));
t=1:2880;
figure;
plot(t,power_hh(t));
title('Gesamtleistungsaufnahme Haushalt �ber 48h [W]');