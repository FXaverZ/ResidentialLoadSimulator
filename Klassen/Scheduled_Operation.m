classdef Scheduled_Operation < Device
	%SCHEDULED_OPERATION    Klasse aller Ger�te mit zeitlich definierten Einsatz
	%    SCHEDULED_OPERATION repr�sentiert all jene Ger�te, deren Einsatz durch
	%    einen sog. Einsatzplan (d.h. mit definierten Ein- und Ausschaltzeiten
	%    mit dazugeh�riger Leistungsaufnahme) repr�sentiert werden kann. Dazu
	%    geh�ren einerseits Ger�te mit zeitlich periodischen Verhalten
	%    (PERIODIC_OPERATION) sowie Ger�te mit statistisch verteilten Einsatz
	%    (PROBABLE_OPERATION).
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
	%        'Time_typ_Run' 
	%            �bliche Laufzeit des Ger�ts zum angegebenen Startzeitpunkt.
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
	%        'Fast_computing_at_no_dsm = 1'
	%            diese Ger�teklasse eignet sich dazu, falls der Einsatz von DSM nicht
	%            simuliert werden muss, eine schnellere Berechnungsmethode
	%            heranzuziehen
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%    Franz Zeilinger - 18.11.2011
	
	properties
		Power_Stand_by
	%            Stand-by-Verbrauch des Ger�tes
	    Cos_Phi_Stand_by = 1
	%            Cos_Phi im Stand-by-Modus
		Time_Start_Day
	%            Liste mit Einschaltzeiten des Ger�tes in min. Als String
	%            'HH:MM' �bergebbar (z.B. '12:31')
		Time_typ_Run
	%            �bliche Laufzeit des Ger�ts zum angegebenen Startzeitpunkt.
	    Time_min_Run = 0
	%            minimale Laufzeit des Ger�tes
	end
	
	properties (Hidden)
		Time_Schedule_Day
	%            Fahrplan des Ger�tes in lfd. Minuten eines Tages:
	%            [Startzeit, Endzeit, Leistung]
		Time_Start
	%            Liste mit Einschaltzeiten des Ger�tes in laufender Matlab-Zeit
		Time_Schedule
	%            Fahrplan des Ger�tes in laufender Matlabzeit
	end
	
	methods
		
		function obj = Scheduled_Operation(varargin)
			%SCHEDULED_OPERATION    Konstruktor der Klasse SCHEDULED_OPERATION
			%    Verwendet den Konstruktor der Superklasse DEVICE zur
			%    Parametervariierung.
			%    Erstellt daran anschlie�end einen Einsatzplan und �berpr�ft, ob
			%    das Ger�t �berhaupt zum Einsatz kommt.
			
			% gleicher Konstruktor wie in Superklasse DEVCIE:
			obj = obj@Device(varargin{:});
			
			% Erstellen des Einsatzplanes f�r jedes Ger�t:
			obj = calculate_schedule(obj);
			obj = check_activity(obj);
			
			% bei dieser Ger�teklasse ist eine schnellere Berechnung im Fall, dass
			% kein DSM simuliert werden muss, m�glich:
			obj.Fast_computing_at_no_dsm = 1;
			
			% Falls kein Stand-by-Verbrauch angegeben wurde, diesen auf Null
			% setzen:
			if isempty (obj.Power_Stand_by)
				obj.Power_Stand_by = 0;
			end
		end
		
		function obj = check_activity(obj)
			%CHECK_ACTIVITY    �berpr�ft, ob Ger�t zum Einsatz kommt.
			%    OBJ = CHECK_ACTIVITY(OBJ) �berpr�ft, ob Ger�t �berhaupt f�r
			%    Simulation als aktiv gilt und setzt dementsprechend 
			%    OBJ.ACTIVITY. Dieser Wert hilft der das Ger�t verwendenden
			%    Funktion zu entscheiden, ob dieses Ger�t �berhaupt f�r den
			%    Simulationsdurchlauf gespeichert werden soll oder einfach
			%    ignoriert wird (da es keinen Beitrag zum Gesamtergebnis
			%    liefert).
			
			if ~isempty(obj.Time_Schedule_Day)
				% Wenn Einsatzplan vorhanden ist, ist auch Ger�t als aktiv zu
				% kennzeichnen:
				obj.Activity = 1;
			else
				% Falls nichts zutrifft: keine Aktivit�t:
				obj.Activity = 0;
			end
		end
		
		function obj = update_device_activity(obj, varargin)
			%UPDATE_DEVICE_ACTIVITY f�hrt Neuberechnung des Ger�teeinsatzes durch
			%    OBJ = UPDATE_DEVICE_ACTIVITY(OBJ, ARGS) geht die Argumenteliste ARGS
			%    durch und aktualisiert alle Parameter, die den Ger�teeinsatz, jedoch
			%    NICHT die Ger�teeigenschaften betreffen.
			%    Dazu wird eine gleiche Argumenteliste �bergeben, wie bei der
			%    Instanzenerzeugung, diese Funktion sucht sich die relevanten
			%    Parameter heraus und �ndert diese.
			%    Danach erfolgt eine Neuberechnung der Einsatzpl�ne des Ger�ts mit
			%    den neuen Parameterwerten:
			
			obj = update_device_activity@Device(obj, varargin{:});
			
			% Erstellen des Einsatzplanes f�r jedes Ger�t:
			obj = calculate_schedule(obj);
			obj = check_activity(obj);

		end
		
		function obj = adapt_schedule_day(obj, sched)
			%ADAPT_SCHEDULE_DAY    passt Einsatzplan an 24h-Tag an
			%    OBJ = ADAPT_SCHEDULE_DAY(SCHED) f�hrt eine Anpassung der Zeiten
			%    in einem Einsatzplan f�r einen Bereich von 00:00:00 bis
			%    23:59:59 durch. So wird ein flie�ender �bergang der Lastkurve
			%    �ber Mitternacht gew�hrleistet. SCHED ist der Einsatzplan in
			%    der Form [start, end, power].
			
			if ~isempty(sched)
				% alle "negativen" Zeiten (Vortag) um 1440 Minuten (ein Tag)
				% erh�hen:
				sched(sched(:,1:2)<0)=sched(sched(:,1:2)<0)+1440;
				% alle Zeiten vom n�chsten Tag (> 1440 min) um einen Tag
				% reduzieren
				sched(sched(:,1:2)>=1440)=sched(sched(:,1:2)>=1440)-1440;
				% nur die Startzeiten �bernehmen, bei denen es auch zu einem
				% Ger�teeinsatz kommt:
				obj.Time_Start_Day = sched(:,1);
			end
			% �bernehmen des neuen Einsatzplanes:
			obj.Time_Schedule_Day = sched;
			
		end
		
		function obj = adapt_for_simulation(obj, Date_Start, Date_End, varargin)
			%ADAPT_FOR_SIMULATION    passt Einsatzplan an Simulationsdauer an
			%    OBJ = ADAPT_SCHEDULE(OBJ, DATE_START, DATE_END) erzeugt einen
			%    Einsatzplan aus dem bereits vorhandenen 24h-Einsatzplan
			%    TIME_SCHEDULE_DAY und der Simulationsdauer, definiert durch
			%    DATE_START und DATE_END in Matlab-Zeit. Hierbei wird bei
			%    mehrt�giger Simulationsdauer der 24h-Einsatzplan je nach Anzahl
			%    der Tage wiederholt.
			%    Diese Funktion muss einmal zu Beginn der Simulation f�r jede
			%    Ger�teinstanz aufgerufen werden.
			
			sched_day = obj.Time_Schedule_Day;
			if isempty(sched_day)
				return;
			end
			% Auf Tage umrechnen (1d = 1440min)
			sched_day(:,1:2) = sched_day(:,1:2)/1440;
			% Wenn ein Einsatzpunkt �ber Mitternacht hinausgeht, diesen speziell
			% behandeln:
			sched_day(sched_day(:,1)>sched_day(:,2),1)=...
				sched_day(sched_day(:,1)>sched_day(:,2),1)-1;
			% Arraygr��e und Anzahl Tage ermitteln:
			days = ceil(Date_End-Date_Start);
			entrys_per_day = size(sched_day,1);
			sched = zeros((days+1)*entrys_per_day,4);
			% Einsatzplan zusammensetzen:
			for i=1:days+1
				sched((i-1)*entrys_per_day+1:i*entrys_per_day,:)=...
					[sched_day(:,1:2)+(i-1)+floor(Date_Start),sched_day(:,3:4)];
			end
			obj.Time_Schedule = sched(sched(:,1)<Date_End,:);
			% Startzeit in Matlab-Zeit ermitteln:
			obj.Time_Start = floor(Date_Start) + obj.Time_Start_Day/1440;
		end
		
		function obj = calculate_schedule(obj)
			% CALCULATE_SCHEDULE    ermittlet den Einsatzplan des Ger�tes
			%     OBJ = CALCULATE_SCHEDULE(OBJ) ermittlet den Einsatzplan des
			%     Ger�tes je nach vorhandenen Parametern. Dies erfolgt jeweils in
			%     den �berladenen Funktionen in der jweiligen Ger�teklasse.
		end
		
		function obj = next_step(obj, time, varargin)
			% NEXT_STEP ermittelt die Reaktion des Ger�tes
			%    OBJ = NEXT_STEP(OBJ, TIME) ermittelt die Reaktion der
			%    Ger�teinstanz zum Zeitpunkt TIME. Die Reaktion besteht
			%    vordergr�ndig in der aufgenommen Leistung zu diesem Zeitpunkt.
			
			[obj.Power_Input(obj.Phase_Index), cosphi, obj.Operating] = ...
				obj.get_power_from_schedule(time, obj.Time_Schedule);
			obj.Power_Input_Reactive = obj.Power_Input*tan(acos(cosphi));
			if ~obj.Operating
				obj.Power_Input(obj.Phase_Index) = obj.Power_Stand_by;
				obj.Power_Input_Reactive = obj.Power_Input*...
					tan(acos(obj.Cos_Phi_Stand_by));
			end
		end
		
		function value = show_Time_Schedule_Day(obj)
			% SHOW_TIME_SCHEDULE_DAY    anzeigen des aktuellen 24h-Einsatzplanes
			%    VALUE = SHOW_TIME_SCHEDULE_DAY(OBJ)dient zur Veranschaulichung
			%    des Einsatzplanes in der Konsole: hierzu werden die Zeiten von
			%    Minuten in normale Zeitangaben umgerechnet und f�r eine Ausgabe
			%    in der Konsole formatiert (VALUE).
			
			sched = obj.Time_Schedule_Day;
			if ~isempty(sched)
				t1 = datestr(sched(:,1)/1440,'HH:MM:SS');
				t2 = datestr(sched(:,2)/1440,'HH:MM:SS');
				div1 = repmat(' - ',size(sched,1),1);
				div2 = repmat('   ',size(sched,1),1);
				watt = repmat(' W',size(sched,1),1);
				value = [t1, div1, t2, div2, num2str(sched(:,3)), watt, ...
					div2, num2str(sched(:,4))];
			else
				value = 'Kein Ger�teeinsatzplan vorhanden!';
			end
		end
		
		function value = show_Time_Schedule(obj)
			% SHOW_TIME_SCHEDULE    anzeigen des aktuellen Gesamt-Einsatzplanes
			%    VALUE = SHOW_TIME_SCHEDULE(OBJ)dient zur Veranschaulichung
			%    des Einsatzplanes in der Konsole: hierzu werden die Zeiten von
			%    Matlab-Zeit in normale Zeitangaben umgerechnet und f�r eine
			%    Ausgabe in der Konsole formatiert (VALUE).
			
			sched = obj.Time_Schedule;
			if ~isempty(sched)
				t1 = datestr(sched(:,1),0);
				t2 = datestr(sched(:,2),0);
				div1 = repmat(' - ',size(sched,1),1);
				div2 = repmat('   ',size(sched,1),1);
				watt = repmat(' W',size(sched,1),1);
				value = [t1, div1, t2, div2, num2str(sched(:,3)), watt,...
					div2, num2str(sched(:,4))];
			else
				value = 'Kein Ger�teeinsatzplan vorhanden!';
			end
		end
		
		function value = show_Time_Start(obj)
			%SHOW_TIME_START    anzeigen der aktuellen Starzeiten 
			%    VALUE = SHOW_TIME_START(OBJ)dient zur Veranschaulichung der
			%    Startzeiten in der Konsole: hierzu werden die Zeiten von
			%    Minuten in normale Zeitangaben umgerechnet (VALUE).
			
			value = datestr(obj.Time_Start_Day/1440,'HH:MM:SS');
		end
	end
	
	methods (Static)
		
		function [power, cosphi, operating] = get_power_from_schedule(time, sched)
			%GET_POWER_FROM_SCHEDULE    ermittelt aufgenommene Leistung
			%    POWER = GET_POWER_FROM_SCHEDULE(TIME, SCHED) ermittelt die
			%    aufgenommene Leistung POWER des Ger�tes zum Zeitpunkt TIME. Dazu
			%    wird der Einsatzplan des Ger�tes SCHED verwendet.
			%
			%    [POWER, OPERATING] = GET_POWER_FROM_SCHEDULE(TIME, SCHED) gibt
			%    zus�tzlich den aktuellen Betriebszustand des Ger�tes
			%    (OPERATING) zur�ck (ob gerade aktiv oder nicht).
			
			power = 0;
			cosphi = 1;
			operating = 0;
			% ist Einsatzplan vorhanden?
			if isempty(sched)
				return;
			end
			% l�uft Ger�t zu diesem Zeitpunkt laut Einsatzplan?
			power_sched = sched(sched(:,1)<=time & sched(:,2)>time,3:4);
			% �bergabe der Leistungswerte:
			if ~isempty(power_sched)
				power = power_sched(1,1);
				cosphi = power_sched(1,2);
				operating = 1;
			end
		end
	end
end