classdef Idling_Operation < Interrupted_Operation
	%IDLING_OPERATION Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		Power_Loadcurve
	end
	
	methods
		function obj = Idling_Operation(varargin)
			obj = obj@Interrupted_Operation(varargin{:});
		end
		
		function obj = calculate_schedule(obj)
			obj = calculate_schedule@Interrupted_Operation(obj);
			
			% Einsatzplan um die definierten Lastkurven erweitern:
			loadcu = obj.Power_Loadcurve;
			% Aus Dauer der Lastkurve laufende Zeit ermitteln (Startzeitpunkt
			% nächster Schritt = Startzeitpunkt vorheriger Schritt plus Dauer
			% nächster Schritt)
			for j = 1:size(loadcu,1)-1
				loadcu(j+1,1) = loadcu(j,1) + loadcu(j+1,1);
			end
			starts = obj.Time_Start_Day;
			sched = [];
			for i = 1:size(starts,1)
				% Endzeitpunkte: Startzeitpunkt + laufende Zeit
				t2 = starts(i)+loadcu(:,1);
				% Startzeitpunkte: erster Wert = Startzeitpunkt
				% weitere Werte = Endzeitpunkte ohne letzten Wert
				t1 = [starts(i);t2(1:end-1,1)];
				
				% nachprüfen, ob es zu Überschneidungen der einzelnen Lastkurven
				% kommt - anders als bei der Klasse Loadcurve_Operation wird aber
				% hier die Überschneidung nicht beseitigt, sondern nur richtig im
				% Einsatzplan eingetragen (es kommt quasi zu einer Überlappung, der
				% der höchste Leistungswert wird angenommen):
				if i>1
					idx = find(sched(:,2) > starts(i),1);
					if~isempty(idx)
						% der Lastkurve die späteren Teile abschneiden:
						sched = sched(1:idx,:);
						% Endzeit des überschnittenen Teils = Startzeit des kommenden
						% Teils:
						sched(idx,2) = starts(i);
					end
				end
				
				% Start- und Endzeiten der jeweiligen Lastperioden
				% aneinanderfügen:
				sched(end+1:end+size(loadcu,1),:)=[t1, t2, loadcu(:,2)];
			end
			% an Bereich 00:00:00 bis 23:59:59 anpassen:
			obj = obj.adapt_schedule_day(sched);
			% neue Startzeiten speichern:
			obj.Time_Start_Day = starts;
		end
	end
	
end

