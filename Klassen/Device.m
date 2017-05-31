classdef Device
	%DEVICE    Superklasse aller Elektrogeräte
	%    DEVICE fasst alle Eigenschaften, die Elektrogeräte gemeinsam haben,
	%    zusammen.
	%
	%    Argumente werden in Dreiergruppen übergeben:
	%         - 1. Argument:   Name des Parameters (z.B. 'Power_Nominal')
	%         - 2. Argument:   Mittelwert(e) des oder der Parameter
	%         - 3. Argument:   Standardabweichung(en) (in % des Mittelwerts)
	%    Die Parameter werden bei der Objekterzeugung normalverteilt variiert
	%    gem. der angegebenen Standardabweichung. Die Parameter können, müssen
	%    aber keine Standardabweichung haben. Falls keine Standardabweichung
	%    gewünscht ist, den Wert '0' als drittes Argument einfügen (z.B. bei
	%    Verteilungsfunktionen)
	%
	%    Parameter (werden in Parameterliste übergeben): 
	%        'Power_Nominal' 
	%            Anschlussleistung des Geräts. 
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Gerät aktiv ist. Kann eine zu einer
	%            Startzeitliste gehörende Liste sein (definert dann für jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Gerät aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit für die
	%            generelle Aktivität angibt (für die gesamte Simulationsdauer).
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
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%    Franz Zeilinger - 21.09.2011
	
	properties
		Phase_Index
	%            Index der Phase, an der das Gerät angeschlossen ist
		Power_Nominal
	%            Anschlussleistung des Geräts
	    Cos_Phi_Nominal = 1
	%            Leistungsfaktor bei Normalbetrieb
		Start_Probability
	%            Wahrscheinlichkeit, dass Gerät aktiv ist. Kann eine zu einer
	%            Startzeitliste gehörende Liste sein (definert dann für jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Gerät aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit für die
	%            generelle Aktivität angibt (für die gesamte Simulationsdauer).
		Power_Input = zeros(3,1)
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	    Power_Input_Reactive = zeros(3,1)
	%            Blindleistungsaufnahme des Geräts zum aktuellen Zeitpunkt.
	end
	
	properties (Hidden)
		Activity
	%            Ist das Gerät irgendwann im Einsatz? (Nach Erzeugen der
	%            Geräteinstanzen könne so alle nichtaktiven Geräte aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	    Operating               
	%            gibt an, ob das Gerät gerade aktiv ist (d.h. eingeschaltet).
		DSM
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
		Fast_computing_at_no_dsm = 0
	%            diese Option zeigt an, ob im Fall, dass kein DSM simuliert werden
	%            muss, eine schnellere Berechnung durchgeführt werden kann (d.h.
	%            nicht jeder Zeitschritt extra). Diese Option ist generell
	%            deaktiviert und muss in den entsprechnenden Geärteklassen auf Eins
	%            gesetzt werden!
	end
	
	methods
		
		function obj = Device(varargin)
			%DEVICE    Konstruktor der Geräteklasse DEVICE.
			%    OBJ = DEVICE (ARGLIST) durchläuft die Parameterliste ARGLIST
			%    und führt diese einer Variation der gegebenen Parameterwerte
			%    gemäß einer Normalverteilung zu.
			
			input = varargin; % Übernehemen der Eingangsvariablen
			% Sind die Argumente Dreiergruppen --> wenn nicht --> Fehler:
			if (mod(nargin,3) == 0)
				% Durchlaufen aller Eingangsparameter (in 3er Schritten):
				for i = 1:3:nargin
					parameter = varargin{i};
					% Erster Teil: Parametername, ist dieser ein String -->
					% wenn nicht --> Fehler:
					if ischar(parameter)
						try
							obj = add_parameter(obj, parameter, input{i+1}, ...
								input{i+2});
						catch ME
							error('device:paramlist',...
								['Fehler beim Bearbeiten des Parameters ''',...
								parameter,''' ist folgender Fehler aufgetreten: ',...
								ME.message]);
						end
					else
						% Fehler, weil erster Eintrag in Parameterliste kein
						% Text war:
						error('device:paramlist', ['Wrong inputarguments.',...
							' Input looks like (''Parameter_Name'',',...
							' Mean_Value, Standard_Deviation)']);
					end
				end
				obj = check_activity(obj);
			else
				% Fehler, weil Parameter nicht in Dreiergruppe übergeben wurde:
				error('device:paramlist', ['Wrong number of inputarguments',...
					'. Input looks like (''Parameter_Name'', Mean_Value,',...
					' Standard_Deviation)']);
			end
			
			% Phasenzuordnung ermitteln (gleich verteilt über alle drei Phasen):
			obj.Phase_Index = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
		end
		
		function obj = add_parameter(obj, parameter, input_1, input_2)
			% Überprüfung, ob Parameter übergeben wurden, die eine gesonderte
			% Behandlung benötigen, ansonsten normale Parametervariierung:
			switch parameter
				case 'Time_Start'
					% Umrechnen der Zeitstrings in Minuten:
					input_1 = Device.clocktime_to_min(input_1);
					% Bei Parameter 'Time_Start' darf die Variierung nicht in %
					% um den Mittelwert erfolgen (dieser ist ja ein Zeitpunkt)
					% sondern um Minuten um den vorgesehenen Zeitpunkt.
					obj.Time_Start_Day = vary_parameter(input_1, input_2, 'Time');
				case 'Temp_Set'
					% Parametervariation, negative Werte werden zugelassen:
					obj.(parameter) = vary_parameter(...
						input_1,input_2);
				case 'Time_run_Duty_Cycle'
					% normale Parametervariation, solange bis der Wert zwischen 0 und
					% 100% liegt:
					value = -1;
					while (value < 0) || (value > 100)
					 value = vary_parameter(...
						input_1,input_2);
					end
					obj.(parameter) = value;
				case 'Cos_Phi_Nominal'
					value = vary_parameter(...
						input_1,input_2);
					% Keine Cos_Phi größer 1 zulassen:
					value(value>1)=1;
					obj.(parameter) = value;
				case 'Cos_Phi_Stand_by'
					value = vary_parameter(...
						input_1,input_2);
					% Keine Cos_Phi größer 1 zulassen:
					value(value>1)=1;
					obj.(parameter) = value;
				case 'Power_Loadcurve'
					% Noramle Parametervariation:
					value = vary_parameter(...
						input_1,input_2);
					% Keine Cos_Phi größer 1 zulassen:
					cos = value(:,3:3:end);
					cos(cos>1)=1;
					value(:,3:3:end) = cos;
					obj.(parameter)=value;
				otherwise
					% Noramle Parametervariation:
					obj.(parameter) = vary_parameter(...
						input_1,input_2);
					% Keine negativen Parameter zulassen:
					obj.(parameter)(obj.(parameter)<0)=0;
			end
		end
		
		function obj = check_activity(obj)
			%CHECK_ACTIVITY    überprüfen ob Gerät zum Einsatz kommt.
			%    OBJ = CHECK_ACTIVITY(OBJ) überprüft, ob Gerät überhaupt für
			%    Simulation als aktiv gilt und setzt dementsprechend 
			%    OBJ.ACTIVITY. Dieser Wert hilft der das Gerät verwendenden
			%    Funktion zu entscheiden, ob dieses Gerät überhaupt für den
			%    Simulationsdurchlauf gespeichert werden soll oder einfach
			%    ignoriert wird (da es keinen Beitrag zum Gesamtergebnis
			%    liefert).

			if (numel(obj.Start_Probability) == 1)
				% Wenn EIN Wert für die Startwahrscheinlichkeit angegeben wurde,
				% zufällig ermitteln, ob Gerät überhaupt in Einsatz genommen wird:
				if obj.Start_Probability/100 >= rand()
					obj.Activity = 1;
				else
					obj.Activity = 0;
				end
			elseif isempty(obj.Start_Probability)
				% Wurde keine Startwahrscheinlickeit angegeben, diese auf eins
				% setzen (Gerät sicher aktiv):
				obj.Activity = 1;
			end
		end
		
		function obj = adapt_for_simulation(obj, varargin)
			%ADAPT_FOR_SIMULATION    bereitet Klasse für Simulation vor
			%    OBJ = ADAPT_SCHEDULE(OBJ, VARARGIN) sorgt dafür,
			%    dass die aktuelle Geräteklasse für einen Simulationsdurchlauf
			%    vorbereitet wird.
			%    Diese Funktion muss einmal zu Beginn der Simulation für jede
			%    Geräteinstanz aufgerufen werden.
			%    Diese Funktion wird in den jeweiligen Subklassen genauer
			%    definiert!
		end
		
		function obj = next_step(obj, varargin)
			% NEXT_STEP ermittelt die Reaktion des Gerätes
			%    OBJ = NEXT_STEP(OBJ, TIME) ermittelt die Reaktion der Geräte-
			%    instanz zum Zeitpunkt TIME. Die Reaktion besteht vordergründig
			%    in der aufgenommen Leistung zu diesem Zeitpunkt.
			%    Diese Funktion wird in den jeweiligen Subklassen genauer
			%    definiert!
		end		
	end
	
	methods (Static)
		
		function out = clocktime_to_min (timelist)
			%CLOCKTIME_TO_MIN    konvergiert Uhrzeitstring in laufende Minuten
			%    OUT = CLOCKTIME_TO_MIN (TIMELIST) rechnet den Uhrzeitstrings
			%    'HH:MM' im Vektor TIEMLIST in laufende Minutenzeit (0-1440min
			%    entspricht 0-24h) um.
			
			t = datevec(datenum(timelist));
			out = t(:,4)*60 + t(:,5);
		end
	end
end
