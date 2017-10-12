classdef Periodic_Operation < Scheduled_Operation
	%PERIODIC_OPERATION    Geräte mit periodischen Verhalten über der Zeit
	%    PERIODIC_OPERATION charakterisiert elektrische Verbraucher welche ein
	%    periodisches Verhalten aufweisen.
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
	%            'HH:MM' übergebbar (z.B. '12:31') [Optional]
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Gerät aktiv ist. Kann eine zu einer
	%            Startzeitliste gehörende Liste sein (definert dann für jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Gerät aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit für die
	%            generelle Aktivität angibt (für die gesamte Simulationsdauer).
	%        'Time_typ_Run' 
	%            übliche Laufzeit des Geräts zum angegebenen Startzeitpunkt.
	%        'Time_Period'
	%            Bei periodischem Verhalten Periodendauer des Geräts
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
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%    Franz Zeilinger - 04.06.2010

	properties
		Time_Period             
	%            Bei periodischem Verhalten Periodendauer des Geräts
	end

	methods
		
		function obj = Periodic_Operation(varargin)
			%PERIODIC_OPERATION    Konstruktor der Klasse PERIODIC_OPERATION
			%    Werden keine Parameter übergeben, wird ein Default-Wert erzeugt.
			%    Verwendet den Konstruktor der Superklasse SCHEDULED_OPERATION zur
			%    Erstellung eines Einsatzplans.
			obj = obj@Scheduled_Operation(varargin{:});		
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
			obj = check_activity@Device(obj);
		end
		
		function obj = calculate_schedule(obj)
			% CALCULATE_SCHEDULE    ermittlet den Einsatzplan des Gerätes
			%     OBJ = CALCULATE_SCHEDULE(OBJ) ermittlet den Einsatzplan des
			%     Gerätes gemäß dem gegebenen periodischen Verhalten. Die
			%     Einschaltzeit wird (sofern keine dezitiert angegeben wurde)
			%     zufällig ermittelt.
			
			if isempty(obj.Time_Period) || isempty(obj.Time_typ_Run)
				% Wenn wichtige Parameter fehlen: abbrechen
				return;
			end
			if ~isempty(obj.Time_Start_Day)
				% Wurde Startzeit angegeben? Wenn ja, erste aus Liste
				% übernehmen:
				start = obj.Time_Start_Day(1);
			else
				% Wenn nicht, zufällige ermitteln:
				start = rand() * 1440;
			end
			
			% Zeitliste aus Start, Endzeiten plus Startzeit (wird so gelegt,
			% dass ein Startpunkt mit dem angegebenen Startzeitpunkt
			% zusammenfällt, daher Trennung in Bereich vor und nach der
			% Startzeit:
			% Vektoren mit Start- und Endzeiten ermitteln:
			beginning = start:obj.Time_Period:1440;
			ending = beginning + obj.Time_typ_Run;
			% Zeitliste nach Starzeitpunkt:
			sched_time_after = [beginning', ending'];
			% Vektoren mit Start- und Endzeiten ermitteln:
			beginning = start-obj.Time_Period:-obj.Time_Period:-obj.Time_Period;
			ending = beginning + obj.Time_typ_Run;
			% Zeitliste vor Startzeitpunkt:
			sched_time_befor = [flipud(beginning'), flipud(ending')];
			% Komplette Zeitliste
			sched_time = [sched_time_befor;sched_time_after];
			% Spalte mit den Leistungen erzeugen:
			sched_power = repmat(obj.Power_Nominal, [size(sched_time,1), 1]);
			% Einsatzplan zusammensetzen:
			sched = [sched_time, sched_power];
			sched(sched<0) = 0;
			% an Bereich 00:00:00 bis 23:59:59 anpassen:
			obj = obj.adapt_schedule_day(sched);
		end
	end
end
