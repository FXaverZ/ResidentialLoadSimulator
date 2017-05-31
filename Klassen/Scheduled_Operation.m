classdef Scheduled_Operation < Device
	%SCHEDULED_OPERATION    Klasse aller Geräte mit zeitlich definierten Einsatz
	%    SCHEDULED_OPERATION repräsentiert all jene Geräte, deren Einsatz durch
	%    einen sog. Einsatzplan (d.h. mit definierten Ein- und Ausschaltzeiten
	%    mit dazugehöriger Leistungsaufnahme) repräsentiert werden kann. Dazu
	%    gehören einerseits Geräte mit zeitlich periodischen Verhalten
	%    (PERIODIC_OPERATION) sowie Geräte mit statistisch verteilten Einsatz
	%    (PROBABLE_OPERATION).
	%
	%    Argumentenübergabe erfolgt gleich wie bei Superklasse DEVICE (nähere
	%    Infos dort).
	%
	%    Parameter (werden in Parameterliste übergeben): 
	%        'Power_Nominal' 
	%            Anschlussleistung des Geräts
	%        'Power_Stand_by'
	%            Stand-by-Verbrauch des Gerätes
	% 	     'Time_Start_Day'
	%            Liste mit Einschaltzeiten des Gerätes in min. Als String
	%            'HH:MM' übergebbar (z.B. '12:31')
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Gerät aktiv ist. Kann eine zu einer
	%            Startzeitliste gehörende Liste sein (definert dann für jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Gerät aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit für die
	%            generelle Aktivität angibt (für die gesamte Simulationsdauer).
	%        'Time_typ_Run' 
	%            übliche Laufzeit des Geräts zum angegebenen Startzeitpunkt.
	%
	%    Eigenschaften (Properties der Klasse):
	%	     'Phase_Index'
	%            Index der Phase, an der das Gerät angeschlossen ist
	%        'Activity'
	%            Ist das Gerät irgendwann im Einsatz? (Nach Erzeugen der
	%            Geräteinstanzen könne so alle nichtaktiven Geräte aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	%	     'Operating'               
	%            gibt an, ob das Gerät gerade aktiv ist (d.h. eingeschaltet).
	%        'DSM'
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
	%        'Time_Schedule_Day'
	%            Fahrplan des Gerätes in lfd. Minuten eines Tages:
	%            [Startzeit, Endzeit, Leistung]
	%        'Time_Start'
	%            Liste mit Einschaltzeiten des Gerätes in laufender Matlab-Zeit
	%        'Time_Schedule'
	%            Fahrplan des Gerätes in laufender Matlabzeit
	%        'Fast_computing_at_no_dsm = 1'
	%            diese Geräteklasse eignet sich dazu, falls der Einsatz von DSM nicht
	%            simuliert werden muss, eine schnellere Berechnungsmethode
	%            heranzuziehen
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%    Franz Zeilinger - 18.11.2011
	
	properties
		Power_Stand_by
	%            Stand-by-Verbrauch des Gerätes
	    Cos_Phi_Stand_by = 1
	%            Cos_Phi im Stand-by-Modus
		Time_Start_Day
	%            Liste mit Einschaltzeiten des Gerätes in min. Als String
	%            'HH:MM' übergebbar (z.B. '12:31')
		Time_typ_Run
	%            übliche Laufzeit des Geräts zum angegebenen Startzeitpunkt.
	    Time_min_Run = 0
	%            minimale Laufzeit des Gerätes
	end
	
	properties (Hidden)
		Time_Schedule_Day
	%            Fahrplan des Gerätes in lfd. Minuten eines Tages:
	%            [Startzeit, Endzeit, Leistung]
		Time_Start
	%            Liste mit Einschaltzeiten des Gerätes in laufender Matlab-Zeit
		Time_Schedule
	%            Fahrplan des Gerätes in laufender Matlabzeit
	end
	
	methods
		
		function obj = Scheduled_Operation(varargin)
			%SCHEDULED_OPERATION    Konstruktor der Klasse SCHEDULED_OPERATION
			%    Verwendet den Konstruktor der Superklasse DEVICE zur
			%    Parametervariierung.
			%    Erstellt daran anschließend einen Einsatzplan und überprüft, ob
			%    das Gerät überhaupt zum Einsatz kommt.
			
			% gleicher Konstruktor wie in Superklasse DEVCIE:
			obj = obj@Device(varargin{:});
			
			% Erstellen des Einsatzplanes für jedes Gerät:
			obj = calculate_schedule(obj);
			obj = check_activity(obj);
			
			% bei dieser Geräteklasse ist eine schnellere Berechnung im Fall, dass
			% kein DSM simuliert werden muss, möglich:
			obj.Fast_computing_at_no_dsm = 1;
			
			% Falls kein Stand-by-Verbrauch angegeben wurde, diesen auf Null
			% setzen:
			if isempty (obj.Power_Stand_by)
				obj.Power_Stand_by = 0;
			end
		end
		
		function obj = check_activity(obj)
			%CHECK_ACTIVITY    überprüft, ob Gerät zum Einsatz kommt.
			%    OBJ = CHECK_ACTIVITY(OBJ) überprüft, ob Gerät überhaupt für
			%    Simulation als aktiv gilt und setzt dementsprechend 
			%    OBJ.ACTIVITY. Dieser Wert hilft der das Gerät verwendenden
			%    Funktion zu entscheiden, ob dieses Gerät überhaupt für den
			%    Simulationsdurchlauf gespeichert werden soll oder einfach
			%    ignoriert wird (da es keinen Beitrag zum Gesamtergebnis
			%    liefert).
			
			if ~isempty(obj.Time_Schedule_Day)
				% Wenn Einsatzplan vorhanden ist, ist auch Gerät als aktiv zu
				% kennzeichnen:
				obj.Activity = 1;
			else
				% Falls nichts zutrifft: keine Aktivität:
				obj.Activity = 0;
			end
		end
		
		function obj = update_device_activity(obj, varargin)
			%UPDATE_DEVICE_ACTIVITY führt Neuberechnung des Geräteeinsatzes durch
			%    OBJ = UPDATE_DEVICE_ACTIVITY(OBJ, ARGS) geht die Argumenteliste ARGS
			%    durch und aktualisiert alle Parameter, die den Geräteeinsatz, jedoch
			%    NICHT die Geräteeigenschaften betreffen.
			%    Dazu wird eine gleiche Argumenteliste übergeben, wie bei der
			%    Instanzenerzeugung, diese Funktion sucht sich die relevanten
			%    Parameter heraus und ändert diese.
			%    Danach erfolgt eine Neuberechnung der Einsatzpläne des Geräts mit
			%    den neuen Parameterwerten:
			
			obj = update_device_activity@Device(obj, varargin{:});
			
			% Erstellen des Einsatzplanes für jedes Gerät:
			obj = calculate_schedule(obj);
			obj = check_activity(obj);

		end
		
		function obj = adapt_schedule_day(obj, sched)
			%ADAPT_SCHEDULE_DAY    passt Einsatzplan an 24h-Tag an
			%    OBJ = ADAPT_SCHEDULE_DAY(SCHED) führt eine Anpassung der Zeiten
			%    in einem Einsatzplan für einen Bereich von 00:00:00 bis
			%    23:59:59 durch. So wird ein fließender Übergang der Lastkurve
			%    über Mitternacht gewährleistet. SCHED ist der Einsatzplan in
			%    der Form [start, end, power].
			
			if ~isempty(sched)
				% alle "negativen" Zeiten (Vortag) um 1440 Minuten (ein Tag)
				% erhöhen:
				sched(sched(:,1:2)<0)=sched(sched(:,1:2)<0)+1440;
				% alle Zeiten vom nächsten Tag (> 1440 min) um einen Tag
				% reduzieren
				sched(sched(:,1:2)>=1440)=sched(sched(:,1:2)>=1440)-1440;
				% nur die Startzeiten übernehmen, bei denen es auch zu einem
				% Geräteeinsatz kommt:
				obj.Time_Start_Day = sched(:,1);
			end
			% Übernehmen des neuen Einsatzplanes:
			obj.Time_Schedule_Day = sched;
			
		end
		
		function obj = adapt_for_simulation(obj, Date_Start, Date_End, varargin)
			%ADAPT_FOR_SIMULATION    passt Einsatzplan an Simulationsdauer an
			%    OBJ = ADAPT_SCHEDULE(OBJ, DATE_START, DATE_END) erzeugt einen
			%    Einsatzplan aus dem bereits vorhandenen 24h-Einsatzplan
			%    TIME_SCHEDULE_DAY und der Simulationsdauer, definiert durch
			%    DATE_START und DATE_END in Matlab-Zeit. Hierbei wird bei
			%    mehrtägiger Simulationsdauer der 24h-Einsatzplan je nach Anzahl
			%    der Tage wiederholt.
			%    Diese Funktion muss einmal zu Beginn der Simulation für jede
			%    Geräteinstanz aufgerufen werden.
			
			sched_day = obj.Time_Schedule_Day;
			if isempty(sched_day)
				return;
			end
			% Auf Tage umrechnen (1d = 1440min)
			sched_day(:,1:2) = sched_day(:,1:2)/1440;
			% Wenn ein Einsatzpunkt über Mitternacht hinausgeht, diesen speziell
			% behandeln:
			sched_day(sched_day(:,1)>sched_day(:,2),1)=...
				sched_day(sched_day(:,1)>sched_day(:,2),1)-1;
			% Arraygröße und Anzahl Tage ermitteln:
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
			% CALCULATE_SCHEDULE    ermittlet den Einsatzplan des Gerätes
			%     OBJ = CALCULATE_SCHEDULE(OBJ) ermittlet den Einsatzplan des
			%     Gerätes je nach vorhandenen Parametern. Dies erfolgt jeweils in
			%     den überladenen Funktionen in der jweiligen Geräteklasse.
		end
		
		function obj = next_step(obj, time, varargin)
			% NEXT_STEP ermittelt die Reaktion des Gerätes
			%    OBJ = NEXT_STEP(OBJ, TIME) ermittelt die Reaktion der
			%    Geräteinstanz zum Zeitpunkt TIME. Die Reaktion besteht
			%    vordergründig in der aufgenommen Leistung zu diesem Zeitpunkt.
			
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
			%    Minuten in normale Zeitangaben umgerechnet und für eine Ausgabe
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
				value = 'Kein Geräteeinsatzplan vorhanden!';
			end
		end
		
		function value = show_Time_Schedule(obj)
			% SHOW_TIME_SCHEDULE    anzeigen des aktuellen Gesamt-Einsatzplanes
			%    VALUE = SHOW_TIME_SCHEDULE(OBJ)dient zur Veranschaulichung
			%    des Einsatzplanes in der Konsole: hierzu werden die Zeiten von
			%    Matlab-Zeit in normale Zeitangaben umgerechnet und für eine
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
				value = 'Kein Geräteeinsatzplan vorhanden!';
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
			%    aufgenommene Leistung POWER des Gerätes zum Zeitpunkt TIME. Dazu
			%    wird der Einsatzplan des Gerätes SCHED verwendet.
			%
			%    [POWER, OPERATING] = GET_POWER_FROM_SCHEDULE(TIME, SCHED) gibt
			%    zusätzlich den aktuellen Betriebszustand des Gerätes
			%    (OPERATING) zurück (ob gerade aktiv oder nicht).
			
			power = 0;
			cosphi = 1;
			operating = 0;
			% ist Einsatzplan vorhanden?
			if isempty(sched)
				return;
			end
			% läuft Gerät zu diesem Zeitpunkt laut Einsatzplan?
			power_sched = sched(sched(:,1)<=time & sched(:,2)>time,3:4);
			% Übergabe der Leistungswerte:
			if ~isempty(power_sched)
				power = power_sched(1,1);
				cosphi = power_sched(1,2);
				operating = 1;
			end
		end
	end
end