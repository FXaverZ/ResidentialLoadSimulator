classdef Loadcurve_Operation < Probable_Operation
	%LOADCURVE_OPERATION    Klasse aller Ger�te mit definierten Lastgang 
	%    LOADCURVE_OPERATION charakterisiert alle Ger�te, die einen Lastgang
	%    aufweisen, z.B. weil sie ein Programm abarbeiten (z.B. Waschmaschine,
	%    Geschirrsp�ler,...). Es k�nnen mehrere Programme sowie deren Verteilung
	%    ber�cksichtigt werden.
	%
	%    Argumenten�bergabe erfolgt gleich wie bei Superklasse DEVICE (n�here
	%    Infos dort).
	%
	%    Parameter (werden in Parameterliste �bergeben): 
	%        'Power_Nominal' 
	%            Anschlussleistung des Ger�ts
	%        'Power_Stand_by'
	%            Stand-by-Verbrauch des Ger�tes
	% 	     'Time_Start_Day'
	%            Liste mit Einschaltzeiten des Ger�tes in min. Als String
	%            'HH:MM' �bergebbar (z.B. '12:31')
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Ger�t aktiv ist. Kann eine zu einer
	%            Startzeitliste geh�rende Liste sein (definert dann f�r jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Ger�t aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit f�r die
	%            generelle Aktivit�t angibt (f�r die gesamte Simulationsdauer).
	%        'Power_Loadcurve'
	%            Lastkurve des Ger�ts ([m,2]-Matrix):
	% 	             [Dauer (in min), Leistung (in W)]
	%            Diese wird Zeile f�r Zeile abgearbeitet. Es k�nnen n Lastkurven
	%            vorliegen ([m,2n]-Matrix), es wird dann eine Lastkurve pro
	%            Startzeitpunkt ausgew�hlt. Wird w�hrend Objekterzeugung in eine
	%			 Struktur mit den einzelnen Lastkurven umgewandelt (siehe
	%			 Funktion CALCULATE_SCHEDULE).
	%        'Loadcurve_Allocation' 
	%            Wahrscheinlichkeitsdichte f�r die einzelnen Lastkurven, falls
	%            mehrere angegeben wurden.
	%	     'Loadcurve_non_stop_Parts' 
	%            [m,2] Indexliste jener Teile der Lastkurve, die nicht unterbrochen
	%            werden d�rfen, in der Form:
	%                [ Start_Index, End_Index ]
	%
	%    Eigenschaften (Properties der Klasse):
	%	     'Phase_Index'
	%            Index der Phase, an der das Ger�t angeschlossen ist
	%        'Activity'
	%            Ist das Ger�t irgendwann im Einsatz? (Nach Erzeugen der
	%            Ger�teinstanzen k�nne so alle nichtaktiven Ger�te aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	%	     'Operating'               
	%            gibt an, ob das Ger�t gerade aktiv ist (d.h. eingeschaltet).
	%        'DSM'
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
	%        'Time_Schedule_Day'
	%            Fahrplan des Ger�tes in lfd. Minuten eines Tages:
	%            [Startzeit, Endzeit, Leistung]
	%        'Time_Start'
	%            Liste mit Einschaltzeiten des Ger�tes in laufender Matlab-Zeit
	%        'Time_Schedule'
	%            Fahrplan des Ger�tes in laufender Matlabzeit
	%	     'Time_Stop_Day'          
	%            Endzeiten der einzelnen Lastg�nge in laufenden Minuten
	%	     'Time_Stop'            
	%            Endzeiten der einzelnen Lastg�nge in laufender Matlab-Zeit
	%		 'Picked_Loadcurves'     
	%            gibt an, welche Lastkurve zu welcher Startzeit geh�rt.
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	%

	%    Franz Zeilinger - 09.09.2010
	
	properties
		
		Power_Loadcurve
	%            Lastkurve des Ger�ts ([m,2]-Matrix):
	% 	             [Dauer (in min), Leistung (in W)]
	%            Diese wird Zeile f�r Zeile abgearbeitet. Es k�nnen n Lastkurven
	%            vorliegen ([m,2n]-Matrix), es wird dann eine Lastkurve pro
	%            Startzeitpunkt ausgew�hlt. Wird w�hrend Objekterzeugung in eine
	%			 Struktur mit den einzelnen Lastkurven umgewandelt (siehe
	%			 Funktion CALCULATE_SCHEDULE).
		Loadcurve_Allocation
	%            Wahrscheinlichkeitsdichte f�r die einzelnen Lastkurven, falls
	%            mehrere angegeben wurden.
		Loadcurve_non_stop_Parts
	%            [m,2] Indexliste jener Teile der Lastkurve, die nicht unterbrochen
	%            werden d�rfen, in der Form:
	%                [ Start_Index, End_Index ]
	end
	
	properties (Hidden)
		
		Picked_Loadcurves
	%            gibt an, welche Lastkurve zu welcher Startzeit geh�rt.
	    Loadcurve_Struct
	%            Lastkurvenstruktur, die die einzelnen m�glichen Lastkurven
	%            enth�lt. Diese Struktur wird w�hrend der Simulation ver�ndert!
		Time_Stop_Day
	%            Endzeiten der einzelnen Lastg�nge in laufenden Minuten
		Time_Stop
	%            Endzeiten der einzelnen Lastg�nge in laufender Matlab-Zeit	
	end
	
	methods
		
		function obj = Loadcurve_Operation(varargin)
			%LOADCURVE_OPERATION    Konstruktor der Klasse LOADCURVE_OPERATION
			%    Verwendet den Konstruktor der Superklasse SCHEDULED_OPERATION zur
			%    Erstellung eines Einsatzplans.
			
			% Erzeugen der Parameterwerte:
			obj = obj@Probable_Operation(varargin{:});
		end
		
		function obj = calculate_schedule(obj)
			% CALCULATE_SCHEDULE    ermittlet erstmalig den Einsatzplan des Ger�tes
			%     OBJ = CALCULATE_SCHEDULE(OBJ) ermittlet den Einsatzplan des
			%     Ger�tes je nach vorhandenen Parametern. 
			%     In der Klasse LOADCURVE_OPERATION werden die �bergebenen
			%     Lastkurven verwendet um den Einsatzplan zu erstellen.
			%     Diese Funktion wird bei der Instanzerstellung aufgerufen, und
			%     ver�ndert die Propertys 'Loadcurve' und 'Time_Start_Day'
			%     dahingehend, dass diese f�r den k�nftigen Programmablauf
			%     weiterverwendet werden k�nnen.
			
			% Sind Startzeiten vorhanden, wenn nicht: aussteigen.
			if isempty(obj.Time_Start_Day)
				return;
				% Wurden keine Einschaltwahrscheinlichkeiten definiert
				% werden diese auf eins gesetzt:
			elseif isempty(obj.Start_Probability)
				obj.Start_Probability = ones([size(obj.Time_Start_Day) 1]);
			end
			% Wenn ein Lastgang definiert wurde, wird dieser �bernommen:
			if ~isempty(obj.Power_Loadcurve)
				loadc = obj.Power_Loadcurve;
				% Bei Angabe einer typischen Laufzeit wird ein ein Lastgang
				% f�r weiteren Schritt erzeugt:
			elseif ~isempty(obj.Time_typ_Run) && ~isempty(obj.Power_Nominal)
				loadc = [obj.Time_typ_Run, obj.Power_Nominal];
			end
			
			proba = obj.Start_Probability/100;
			start = obj.Time_Start_Day; % Startzeit in laufenden Minuten eines Tages!
			ns_pa = obj.Loadcurve_non_stop_Parts;
			
			% F�r jede Startzeit zuf�llig ermitteln, ob Ger�t �berhaupt
			% eingeschaltet wird (gleichverteilt):
			fort = rand(size(proba));
			start = start(proba >= fort);
			
			if isempty(start)
				% Falls keine Startzeit ermittelt wurde, Einsatzplan auf Leer
				% setzen und Funktion beenden:
				sched = [];
				obj = obj.adapt_schedule_day(sched);
				return;
			end
			
			% Lastkurven aufteilen & Vorberechnungen durchf�hren:
			for i = 1:floor(size(loadc,2)/2)
				loadc_act_day = loadc(:,2*i-1:2*i);
				loadc_act_day = loadc_act_day(~isnan(loadc_act_day));
				loadc_act_day = reshape(loadc_act_day,[],2);
				% Indizes f�r non-stop-Bereiche aufteilen:
				if ~isempty(ns_pa) && ...
					(i <= floor(size(ns_pa,2)/2))
					ns_pa_act = ns_pa(:,2*i-1:2*i);
					ns_pa_act = ns_pa_act(~isnan(ns_pa_act));
					ns_pa_act = reshape(ns_pa_act,[],2);
				else
					ns_pa_act = [];
				end
				
				% Aus Dauer der Lastkurve laufende Zeit ermitteln (Startzeitpunkt
				% n�chster Schritt = Startzeitpunkt vorheriger Schritt plus Dauer
				% n�chster Schritt)
				for j = 1:size(loadc_act_day,1)-1
					loadc_act_day(j+1,1) = loadc_act_day(j,1) + loadc_act_day(j+1,1);
				end
				% Lastgang von min auf Tage umrechnen:
				loadc_act = loadc_act_day;
				loadc_act(:,1) = loadc_act(:,1)/1440;
				% Lastgangstrukturen erzeugen:
				load_struct_day.(['Loadcurve_',num2str(i)]) = ...
					loadc_act_day;
				load_struct_day.(['non_stop_idx_',num2str(i)]) = ...
					ns_pa_act;
				load_struct.(['Loadcurve_',num2str(i)]) = loadc_act;
				load_struct.(['non_stop_idx_',num2str(i)]) = ...
					ns_pa_act;
			end
			% Anzahl der Gesamten Lastkurven speichern:
			load_struct_day.Number_Loadcurves = floor(size(loadc,2)/2);
			load_struct.Number_Loadcurves = load_struct_day.Number_Loadcurves;
			% Indexliste aller m�glichen Lastkurven erstellen:
			list = (1:floor(size(loadc,2)/2))';
			obj.Picked_Loadcurves = zeros(size(start));
			% Liste der Startzeiten durchlaufen:
			for i = 1:size(start,1)
				% Ausw�hlen, welches Lastkurve f�r die aktuelle Startzeit
				% herangezogen werden soll:
				if ~isempty(obj.Loadcurve_Allocation) && (size(loadc,2) > 2)
					idx = vary_parameter(list,obj.Loadcurve_Allocation,'List');
				else
					idx = 1;
				end
				obj.Picked_Loadcurves(i) = idx;
			end
			
			% erstellen eines Tageseinsatzplanes:
			[sched, start, stop] = obj.create_schedule (load_struct_day, start);
			% an Bereich 00:00:00 bis 23:59:59 anpassen:
			obj = obj.adapt_schedule_day(sched);
			
			obj.Time_Start_Day = start;
			obj.Time_Stop_Day = stop;
			obj.Loadcurve_Struct = load_struct;
		end
		
		function [sched, start, stop] = create_schedule (obj, loadc, start)
			%CREATE_SCHEDULE    erstellt einen Einsatzplan
			%    [SCHED, START, STOP] = CREATE_SCHEDULE (OBJ, LOADC, START)
			%    erstellt aus der Startzeitliste START und der Lastkurven-
			%    Struktur LOADC einen Einsatzplan SCHED. OBJ.PICKED_LOADCURVES 
			%    gibt an, welche Lastkurve zu welchem Startzeitpunkt geh�rt.
			%    Es wird darauf geachtet, dass es zu keiner �berschneidung
			%    einzelner Lastkurven kommen kann.
			%    Neben SCHED werden auch noch die aktuellen Startzeiten START
			%    sowie jene Zeitpunkte, bei denen die Abarbeitung der Lastkurve
			%    abgeschlossen wurde (STOP) zur�ckgegeben.
			
			pcklc = obj.Picked_Loadcurves;
			stop = zeros(size(start));
			sched = [];
			for i = 1:size(start,1)
				% ermitteln, ob sich Startzeiten mit Laufzeiten
				% �berschneiden:
				run_time = loadc.(['Loadcurve_',num2str(pcklc(i))])(end,1);
				if i>1
					if stop(i-1) > start(i)
						% Falls sich Startzeit des n�chsten Durchlaufes mit
						% der Laufzeit des vorherigen �berschneidet,
						% Startzeit auf Ende des vorigen Durchlaufs setzen:
						start(i) = stop(i-1);
					end
				end
				stop(i) = start(i) + run_time;
				% Auslesen der f�r aktuellen Startzeitpunkt g�ltigen Lastkurve:
				loadc_act = loadc.(['Loadcurve_',num2str(pcklc(i))]);
				% Endzeitpunkte: Startzeitpunkt + laufende Zeit
				t2 = start(i)+loadc_act(:,1);
				% Startzeitpunkte: erster Wert = Startzeitpunkt
				% weitere Werte = Endzeitpunkte ohne letzten Wert
				t1 = [start(i);t2(1:end-1,1)];
				% Start- und Endzeiten der jeweiligen Lastperioden
				% aneinanderf�gen:
				sched(end+1:end+size(loadc_act,1),:)=[t1, t2, loadc_act(:,2)];
			end
		end
		
		function obj = adapt_for_simulation(obj, Date_Start, Date_End, varargin)
			%ADAPT_SCHEDULE    passt Einsatzplan an Simulationsdauer an
			%    OBJ = ADAPT_SCHEDULE(OBJ, DATE_START, DATE_END) verwendet die
			%    zuerst die gleiche Funktion der Klasse SCHEDULED_OPERATION
			%    (siehe dort).
			%    Zus�tzlich werden hier die Endzeiten der Lastkurven an die
			%    Simulationszeiten angepasst.
			
			obj = adapt_for_simulation@Scheduled_Operation(obj, ...
				Date_Start, Date_End, varargin);
			% Stopzeit in Matlab-Zeit ermitteln:
			obj.Time_Stop = floor(Date_Start) + obj.Time_Stop_Day/1440;
		end
		
		function obj = recalculate_schedule (obj)
			%RECALCULATE_SCHEDULE    ermittelt aktualisieren Einsatzplan
			%    OBJ = RECALCULATE_SCHEDULE (OBJ) ermittelt einen neuen
			%    Einsatzplan aus den vorhandenen (absoluten) Matlabstartzeiten,
			%    die sich nach Aufruf dieser Klasse in einer Simulation ergeben
			%    haben. 
			%    Diese Startzeiten wurden durch den vorangehenden Code ver�ndert
			%    und werden nun zu einen g�ltigen Einsatzplan verarbeitet.
			
			[obj.Time_Schedule, obj.Time_Start, obj.Time_Stop] = ...
				obj.create_schedule (obj.Loadcurve_Struct, obj.Time_Start);
		end
		
		function obj = split_loadcurve(obj, time, con_ns_parts)
			%SPLIT_LOADCURVES    unterbrechen eines Lastganges
			%    OBJ = SPLIT_LOADCURVE(OBJ, TIME, CON_NS_PARTS) spaltet eine 
			%    Lastkurve zum Zeitpunkt TIME in zwei separate Lastkurven (eine
			%    vor TIME und eine nach TIME) auf. Dazu muss ein aktueller
			%    Einsatzplan in laufender Matlab-Zeit vorliegen (ergibt sich
			%    w�hrend eines Simulationsdurchlaufes).
			%    Nachdem ermittelt wurde, welche Lastkurve gespaltet werden
			%    muss, wird zus�tzlich noch �berpr�ft, ob dies aufgrund eines
			%    unenterbrechbaren Teiles der Lastkurve nicht m�glich ist.
			%    Mit der Option CON_NS_PARTS = 1 (TRUE) wird diese �berpr�fung
			%    durchgef�hrt. Ist diese Option nicht aktiviert, wird die
			%    Lastkurve unmittelbar unterbrochen, der ununterbrechbare Teil
			%    wird aber f�r die n�chste Teillastkurve komplett gehalten.
			%    Nach der Spaltung wird die Lastkurvenstruktur
			%    OBJ.LOADCURVE_STRUCT mit den neuen Teillastkurven erweitert
			%    sowie die Startzeiten OBJ.TIME_START und die Zuordnungsliste
			%    der Lastkurven zu den Startzeiten OBJ.PICKED_LOADCURVES
			%    aktualisiert.
			
			% Herausfinden, welche Lastkurve gerade aktiv ist:
			idx_sp = find (time > obj.Time_Start &...
				time < obj.Time_Stop);
			if isempty (idx_sp)
				% Falls keine Lastkurve aktiv ist, Funktion verlassen!
				return;
			end
			
			idx = [];
			
			% Auslesen der relevanten Daten:
			start = obj.Time_Start(idx_sp);
			pcklc = obj.Picked_Loadcurves(idx_sp);
			loadc = obj.Loadcurve_Struct.(['Loadcurve_',num2str(pcklc)]);
			ns_pa = obj.Loadcurve_Struct.(['non_stop_idx_',num2str(pcklc)]);
			l_tim = loadc(:,1)+start;
			l_tim_start = [start;l_tim(1:end-1)];
			
			% Kann das Programm �berhaupt an dieser Stelle unterbrochen werden?
			if ~isempty(ns_pa)
				ns_ti_stop = l_tim(ns_pa(:,2));
				ns_ti_start = l_tim_start(ns_pa(:,1));
				idx = find (time > ns_ti_start &...
					time < ns_ti_stop, 1);
				if ~isempty (idx) && con_ns_parts
					% Falls Zeitpunkt in ununterbrechbaren Bereich der Lastkurve f�llt,
					% Funktion verlassen:
					return;
				end
			end
			
			act_time = time;
			
			% Wo soll das Programm unterbrochen werden?
			if ~isempty (idx)
				idx = ns_pa(idx,1);
				time = l_tim_start(idx);
			else
				% Zum Zeitpunkt time
				idx = find(l_tim>=time,1);
			end
			
			% An dieser Stelle wird die Lastkurve unterbrochen, d.h. der
			% verbleibende Teil (jener nach Zeitpunkt time) wird einer neuen
			% Lastkurve mit Startzeitpunkt time zugeordnet:
			rem_t = l_tim(idx) - time;
			% erste Zeile der neuen Lastkurve besteht aus verbleibender Zeit des
			% aktuellen Programmschritts:
			n_loc_1r = [rem_t, loadc(idx,2)];
			% restlichen Zeilen aus den weiteren Lastgangschritten:
			n_loc_rr = loadc(idx+1:end,:);
			% bisherige Laufzeiten entfernen und verbleibende Laufzeit hinzuf�gen:
			n_loc_rr(:,1) = n_loc_rr(:,1) - loadc(idx,1) + rem_t;
			n_loc = [n_loc_1r; n_loc_rr];
			% non_stop-Bereiche dieser neuen Ladekurve ermitteln:
			if ~isempty(ns_pa) && idx > 1
				n_nsp = ns_pa(ns_pa > idx) - idx+1;
				n_nsp = reshape(n_nsp,[],2);
				p_nsp = ns_pa(ns_pa <= idx);
				p_nsp = reshape(p_nsp,[],2);
			elseif ~isempty(ns_pa) && idx == 1
				n_nsp = ns_pa;
				p_nsp = [];
			else
				n_nsp = [];
				p_nsp = [];
			end
			
			% ermitteln der bereits absolvierten Lastkurve:
			if idx > 1
				p_loc_rr = loadc(1:idx-1,:);
				pre_t = time - l_tim(idx-1)+ p_loc_rr(end,1);
				p_loc_lr = [pre_t, loadc(idx,2)];
				p_loc = [p_loc_rr; p_loc_lr];
			else
				pre_t = time - start;
				p_loc = [pre_t, loadc(1,1)];
			end
			
			% Neue Lastkurven der Lastkurvenstruktur hinzuf�gen:
			num_lc = obj.Loadcurve_Struct.Number_Loadcurves + 1;
			obj.Loadcurve_Struct.(['Loadcurve_',num2str(num_lc)]) = n_loc;
			obj.Loadcurve_Struct.(['non_stop_idx_',num2str(num_lc)]) = n_nsp;
			num_lc = num_lc + 1;
			obj.Loadcurve_Struct.(['Loadcurve_',num2str(num_lc)]) = p_loc;
			obj.Loadcurve_Struct.(['non_stop_idx_',num2str(num_lc)]) = p_nsp;
			obj.Loadcurve_Struct.Number_Loadcurves = num_lc;
			% Neue Startzeiten f�r aktuelle Lastkurve hinzuf�gen:
			obj.Time_Start(end+1) = act_time;
			% Sicherstellen, das Startzeiten einen Spaltenvektor bilden:
			obj.Time_Start = reshape(obj.Time_Start,[],1);
			obj.Picked_Loadcurves(end+1) = num_lc-1; %weiterf�hrende Lastkurve
			obj.Picked_Loadcurves(idx_sp) = num_lc; % bereits erledigte Lastkurve
			% Zeiten sortieren:
			[obj.Time_Start,IX] = sort(obj.Time_Start);
			obj.Picked_Loadcurves = obj.Picked_Loadcurves(IX);
		end
	end
end
