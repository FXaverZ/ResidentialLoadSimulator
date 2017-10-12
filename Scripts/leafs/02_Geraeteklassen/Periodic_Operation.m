classdef Periodic_Operation < Scheduled_Operation
	%PERIODIC_OPERATION    Ger�te mit periodischen Verhalten �ber der Zeit
	%    PERIODIC_OPERATION charakterisiert elektrische Verbraucher welche ein
	%    periodisches Verhalten aufweisen.
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
	%            'HH:MM' �bergebbar (z.B. '12:31') [Optional]
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Ger�t aktiv ist. Kann eine zu einer
	%            Startzeitliste geh�rende Liste sein (definert dann f�r jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Ger�t aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit f�r die
	%            generelle Aktivit�t angibt (f�r die gesamte Simulationsdauer).
	%        'Time_typ_Run' 
	%            �bliche Laufzeit des Ger�ts zum angegebenen Startzeitpunkt.
	%        'Time_Period'
	%            Bei periodischem Verhalten Periodendauer des Ger�ts
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
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%    Franz Zeilinger - 04.06.2010

	properties
		Time_Period             
	%            Bei periodischem Verhalten Periodendauer des Ger�ts
	end

	methods
		
		function obj = Periodic_Operation(varargin)
			%PERIODIC_OPERATION    Konstruktor der Klasse PERIODIC_OPERATION
			%    Werden keine Parameter �bergeben, wird ein Default-Wert erzeugt.
			%    Verwendet den Konstruktor der Superklasse SCHEDULED_OPERATION zur
			%    Erstellung eines Einsatzplans.
			obj = obj@Scheduled_Operation(varargin{:});		
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
			obj = check_activity@Device(obj);
		end
		
		function obj = calculate_schedule(obj)
			% CALCULATE_SCHEDULE    ermittlet den Einsatzplan des Ger�tes
			%     OBJ = CALCULATE_SCHEDULE(OBJ) ermittlet den Einsatzplan des
			%     Ger�tes gem�� dem gegebenen periodischen Verhalten. Die
			%     Einschaltzeit wird (sofern keine dezitiert angegeben wurde)
			%     zuf�llig ermittelt.
			
			if isempty(obj.Time_Period) || isempty(obj.Time_typ_Run)
				% Wenn wichtige Parameter fehlen: abbrechen
				return;
			end
			if ~isempty(obj.Time_Start_Day)
				% Wurde Startzeit angegeben? Wenn ja, erste aus Liste
				% �bernehmen:
				start = obj.Time_Start_Day(1);
			else
				% Wenn nicht, zuf�llige ermitteln:
				start = rand() * 1440;
			end
			
			% Zeitliste aus Start, Endzeiten plus Startzeit (wird so gelegt,
			% dass ein Startpunkt mit dem angegebenen Startzeitpunkt
			% zusammenf�llt, daher Trennung in Bereich vor und nach der
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
