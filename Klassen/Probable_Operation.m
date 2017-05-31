classdef Probable_Operation < Scheduled_Operation
	%PROBABLE_OPERATION    Klasse aller Geräte mit statistisch verteilten Einsatz
	%    PROBABLE_OPERATION repräsentiert all jene Geräte, deren Einsatz durch
	%    eine statistische Verteilung charakterisiert ist, aber eine konstante
	%    Eingangsleistung während des Betriebs aufweisen (z.B. EDV-Geräte,
	%    Multimedia, Beleuchtung,...)
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
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%   Franz Zeilinger - 04.06.2010

	methods
		
		function obj = Probable_Operation(varargin)
			%PROBABLE_OPERATION    Konstruktor der Klasse PROBABLE_OPERATION
			%    Verwendet den Konstruktor der Superklasse SCHEDULED_OPERATION zur
			%    Erstellung eines Einsatzplans.
			obj = obj@Scheduled_Operation(varargin{:});
		end
		
		function obj = calculate_schedule(obj)
			% CALCULATE_SCHEDULE    ermittlet den Einsatzplan des Gerätes
			%     OBJ = CALCULATE_SCHEDULE(OBJ) ermittlet den Einsatzplan des
			%     Gerätes In der Geräteklasse PROBABLE_OPERATION wird mit den
			%     Startzeiten und den typischen Laufzeiten der Einsatzplan
			%     erstellt.
			
			% Überprüfen, ob alle notwendigen Parameter vorhanden sind, wenn 
			% nicht --> abbrechen:
			if isempty(obj.Time_Start_Day) || isempty(obj.Time_typ_Run) || ...
				isempty(obj.Power_Nominal) 
				return;
			% Wurden keine Einschaltwahrscheinlichkeiten definiert werden diese 
			% auf 100% gesetzt:
			elseif isempty(obj.Start_Probability)
				obj.Start_Probability = ones(...
					[size(obj.Time_Start_Day) 1])*100;
			end
			% Falls eine typische Laufzeit angegeben wurde, wird ein ein Lastgang
			% für den nächsten Schritt erzeugt:
			if (size(obj.Time_typ_Run,1) == 1) || ...
					(size(obj.Time_typ_Run,1) == size(obj.Time_Start_Day,1))
				% Erzeugen des Einsatzplanes mit diesen Werten:
				pow = repmat(obj.Power_Nominal,size(obj.Time_Start_Day,1),1);
				cos = repmat(obj.Cos_Phi_Nominal,size(obj.Time_Start_Day,1),1);
				t_start = obj.Time_Start_Day;
				t_end = t_start + obj.Time_typ_Run;
				sched = [t_start, t_end, pow, cos];
				% Einsatz je nach Einsatzwahrscheinlichkeit bestimmen:
				proba = obj.Start_Probability/100;
				sched = sched(proba >= rand(size(obj.Time_Start_Day,1),1),:);
				% an Bereich 00:00:00 bis 23:59:59 anpassen:
				obj = obj.adapt_schedule_day(sched);
			end
		end	
	end
end
