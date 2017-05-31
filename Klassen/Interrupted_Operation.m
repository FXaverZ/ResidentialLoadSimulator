classdef Interrupted_Operation < Probable_Operation
    %INTERRUPTED_OPERATION    Klasse aller Geräte mit unterbrochenen Einsatz
	%    INTERRUPTED_OPERATION repräsentiert all jene Geräte, deren Einsatz durch
	%    eine statistische Verteilung charakterisiert ist. Während der "Aktivitätsphase"
	%    schaltet sich das Gerät immer wieder ein oder aus, es ist nicht immer im Betrieb.
	%    --> weitere Beschreibung des Verhaltens
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
	%            übliche Laufzeit des Geräts zum angegebenen Startzeitpunkt. Innherhalb
	%            dieses Zeitraumes wechselt das Gerät zwischen den einzelnen Betriebmodi
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
	
	%   Franz Zeilinger - 19.08.2011
    
    properties
		Time_run_Duty_Cycle
		Time_Starts_per_Hour
	end
    
	methods
		function obj = Interrupted_Operation(varargin)
		%PROBABLE_OPERATION    Konstruktor der Klasse PROBABLE_OPERATION
		%    Verwendet den Konstruktor der Superklasse SCHEDULED_OPERATION zur
		%    Erstellung eines Einsatzplans.
			obj = obj@Probable_Operation(varargin{:});
		end
		
		function obj = calculate_schedule(obj)
			obj = calculate_schedule@Probable_Operation(obj);
			% Nachdem normal der Einsatzplan berechnet wurde, den unterbrochenen
			% Betrieb erzeugen:
			duty_cycle = obj.Time_run_Duty_Cycle/100;       % Bruchteil der echten Funktionszeit
			starts_per_hour = obj.Time_Starts_per_Hour;
			sched = obj.Time_Schedule_Day;
			% Für jeden Eintrag im Einsatzplan:
			for i=1:size(sched,1)
				% Start und Endzeitpunkt des aktuellen Einsatzes: dieser wird nun
				% gemäß den Einstellungen auf 
				t_start = sched(1,1);
				t_stop = sched(1,2);
				%Laufzeit zu diesem Zeitpunkt in Minuten:
				t_dur = t_stop - t_start;
				if t_dur < 0
					% Falls eine negative Zeitdauer ermittelt wurde, deutet das
					% darauf hin, dass der aktuelle Zeitraum über Mitternacht
					% hinweg läuft, daher Anpassung an 24h durchführen:
					t_dur = 1440 + t_dur;
					t_stop = t_stop + 1440;
				end
				%wie oft sollte das Gerät nun in diesem Zeitraum starten?
				numb_start = floor((t_dur/60)*starts_per_hour); 
				%falls hierbei der Wert "0" herauskommt, diesen Schritt beenden, da
				%anscheinend die akutelle Laufzeit zu kurz ist (das Gerät läuft nur
				%einmal)
				if numb_start == 0
					% aktuelle (erste) Zeile des Einsatzplanes ans Ende stellen,
					% damit wieder die erste Zeile für den nächsten
					% Schleifendurchlauf zur Bearbeitung zur Verfügung steht:
					new_sched_part = sched(1,:);
					sched = [sched(2:end,:);new_sched_part];
					continue;
				end
				% die echte Laufzeit und die Auszeit ermitteln:
				t_run = t_dur * duty_cycle;
				t_off = t_dur - t_run;
				% diese Zeiten zufällig in aufteilen:
				d_t_on = rand(numb_start,1);
				d_t_off = rand(numb_start,1);
				d_t_on = d_t_on/sum(d_t_on);
				d_t_off = d_t_off/sum(d_t_off);
				dur_run = t_run.*d_t_on;
				dur_off = t_off.*d_t_off;
				% eine zufällige Starzeit ermitteln:
				start = sched(1,1) + rand()*t_dur;
				% nun die ermittelten Zeiträume (On- und Off-Time mit der Startzeit
				% zusammensetzen:
				t_starts = zeros(numb_start,1);
				t_ends = t_starts;
				for j=1:numb_start
					if j == 1
						t_starts(j) = start;
					else
						t_starts(j) = t_ends(j-1) + dur_off(j-1);
					end
					t_ends(j) = t_starts(j) + dur_run(j);
				end
				% die nun ermittelten Start- und Stopzeiten nun so verschieben, dass
				% sie wieder in das ursprüngliche Aktivitätsintervall passen:
				% ermitteln der Zeit, um die die Zeiten verschoben werden
				% müssen:
				d_t = t_ends(end) + dur_off(end) - t_stop;
				% Anpassung, falls Zeitraum sich über Mitternacht erstreckt:
				if d_t > 0
					t_starts = t_starts - d_t;
					t_ends = t_ends - d_t;
				end
				% Neue Einträge für Einsatzplan erstellen:
				pow = repmat(obj.Power_Nominal, size(t_starts),1);
				new_sched_part = [t_starts, t_ends, pow];
				% diese neuen Einträge ersetzen den aktuellen (der sich immer in der
				% ersten Zeile befindet):
				sched = [sched(2:end,:);new_sched_part];
			end
			% an Bereich 00:00:00 bis 23:59:59 anpassen:
			obj = obj.adapt_schedule_day(sched);
		end
	end
	
end

