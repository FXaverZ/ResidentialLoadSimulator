classdef Device
	%DEVICE    Superklasse aller Elektroger�te
	%    DEVICE fasst alle Eigenschaften, die Elektroger�te gemeinsam haben,
	%    zusammen.
	%
	%    Argumente werden in Dreiergruppen �bergeben:
	%         - 1. Argument:   Name des Parameters (z.B. 'Power_Nominal')
	%         - 2. Argument:   Mittelwert(e) des oder der Parameter
	%         - 3. Argument:   Standardabweichung(en) (in % des Mittelwerts)
	%    Die Parameter werden bei der Objekterzeugung normalverteilt variiert
	%    gem. der angegebenen Standardabweichung. Die Parameter k�nnen, m�ssen
	%    aber keine Standardabweichung haben. Falls keine Standardabweichung
	%    gew�nscht ist, den Wert '0' als drittes Argument einf�gen (z.B. bei
	%    Verteilungsfunktionen)
	%
	%    Parameter (werden in Parameterliste �bergeben):
	%        'Power_Nominal'
	%            Anschlussleistung des Ger�ts.
	%	     'Cos_Phi_Nominal'
	%            Leistungsfaktor bei Normalbetrieb
	%        'Start_Probability'
	%            Wahrscheinlichkeit, dass Ger�t aktiv ist. Kann eine zu einer
	%            Startzeitliste geh�rende Liste sein (definert dann f�r jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Ger�t aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit f�r die
	%            generelle Aktivit�t angibt (f�r die gesamte Simulationsdauer).
	%
	%    Eigenschaften (Properties der Klasse):
	%	     'Phase_Index'
	%            Index der Phase, an der das Ger�t angeschlossen ist
	%		 'Phase_Power_Distribution_Factor'
	%            gibt an, wie sich die Leistung auf die einzelnen Phasen
	%            aufteilt. Bei einphasigen Ger�ten ist der Faktor gleich 1, bei
	%            dreiphasigen 1/3.
	%        'Activity'
	%            Ist das Ger�t irgendwann im Einsatz? (Nach Erzeugen der
	%            Ger�teinstanzen k�nne so alle nichtaktiven Ger�te aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	%	     'Operating'
	%            gibt an, ob das Ger�t gerade aktiv ist (d.h. eingeschaltet).
	%        'DSM'
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
	%
	%    Ausgabe:
	%        'Power_Input'
	%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	%		 'Power_Input_Reactive'
	%            Blindleistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt.
	
	% Erstellt von:            Franz Zeilinger - 21.09.2011
	% Letzte �nderung durch:   Franz Zeilinger - 19.08.2016
	
	properties
		Phase_Index
		%            Index der Phase, an der das Ger�t angeschlossen ist
		Three_Phase_Device = false
		%            handelt es sich um ein dreiphasiges Ger�t?
		Phase_Power_Distribution_Factor = 1
		%            gibt an, wie sich die Leistung auf die einzelnen Phasen
		%            aufteilt. Bei einphasigen Ger�ten ist der Faktor gleich 1, bei
		%            dreiphasigen 1/3.
		Power_Nominal
		%            Anschlussleistung des Ger�ts
		Cos_Phi_Nominal = 1
		%            Leistungsfaktor bei Normalbetrieb
		Start_Probability
		%            Wahrscheinlichkeit, dass Ger�t aktiv ist. Kann eine zu einer
		%            Startzeitliste geh�rende Liste sein (definert dann f�r jeden
		%            Startzeitpunkt die Wahrscheinlichkeit, ob Ger�t aktiv wird)
		%            oder auch ein Wert, der die Wahrscheinlichkeit f�r die
		%            generelle Aktivit�t angibt (f�r die gesamte Simulationsdauer).
		Power_Input = zeros(3,1)
		%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt. Ist ein [3,1]
		%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
		%            darstellt.
		Power_Input_Reactive = zeros(3,1)
		%            Blindleistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt.
	end
	
	properties (Hidden)
		Activity
		%            Ist das Ger�t irgendwann im Einsatz? (Nach Erzeugen der
		%            Ger�teinstanzen k�nne so alle nichtaktiven Ger�te aussortiert
		%            werden. Daher sollte immer ACTIVITY = 1 sein!)
		Operating
		%            gibt an, ob das Ger�t gerade aktiv ist (d.h. eingeschaltet).
		DSM
		%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
		%            Verbrauchers beinhaltet und steuert.
		Fast_computing_at_no_dsm = 0
		%            diese Option zeigt an, ob im Fall, wenn kein DSM simuliert werden
		%            muss, eine schnellere Berechnung durchgef�hrt werden kann (d.h.
		%            nicht jeder Zeitschritt extra). Diese Option ist generell
		%            deaktiviert und muss in den entsprechnenden Ge�rteklassen auf Eins
		%            gesetzt werden!
	end
	
	methods
		
		function obj = Device(varargin)
			%DEVICE    Konstruktor der Ger�teklasse DEVICE.
			%    OBJ = DEVICE (ARGLIST) durchl�uft die Parameterliste ARGLIST
			%    und f�hrt diese einer Variation der gegebenen Parameterwerte
			%    gem�� einer Normalverteilung zu.
			
			% Sind die Argumente Dreiergruppen --> wenn nicht --> Fehler:
			if (mod(nargin,3) == 0)
				% Durchlaufen aller Eingangsparameter (in 3er Schritten):
				for i = 1:3:nargin
					% Erster Teil: Parametername, ist dieser ein String -->
					% wenn nicht --> Fehler:
					if ischar(varargin{i})
						try
							obj = add_parameter(obj, varargin{i}, varargin{i+1}, ...
								varargin{i+2});
						catch ME
							error('device:paramlist',...
								['Fehler beim Bearbeiten des Parameters ''',...
								varargin{i},''' ist folgender Fehler aufgetreten: ',...
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
			else
				% Fehler, weil Parameter nicht in Dreiergruppe �bergeben wurde:
				error('device:paramlist', ['Wrong number of inputarguments',...
					'. Input looks like (''Parameter_Name'', Mean_Value,',...
					' Standard_Deviation)']);
			end
			
			% Phasenzuordnung ermitteln (gleich verteilt �ber alle drei Phasen):
			if obj.Three_Phase_Device
				obj.Phase_Index = 1:3;
				obj.Phase_Power_Distribution_Factor = 1/3;
			else
				obj.Phase_Index = vary_parameter([1;2;3], ones(3,1)*100/3, 'List');
				obj.Phase_Power_Distribution_Factor = 1;
			end
			
			% Anhand der nun vorhandenen Parameter, Aktivit�tscheck durchf�hren (wird
			% ev. in den Subklassen nochmal durchgef�hrt, nachdem die
			% Klassenspezifischen Vorbereitungen durchgef�hrt wurden):
			obj = check_activity(obj);
			
		end
		
		function obj = add_parameter(obj, parameter, input_1, input_2)
			% �berpr�fung, ob Parameter �bergeben wurden, die eine gesonderte
			% Behandlung ben�tigen, ansonsten normale Parametervariierung:
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
					% Keine Cos_Phi gr��er 1 zulassen:
					value(value>1)=1;
					obj.(parameter) = value;
				case 'Cos_Phi_Stand_by'
					value = vary_parameter(...
						input_1,input_2);
					% Keine Cos_Phi gr��er 1 zulassen:
					value(value>1)=1;
					obj.(parameter) = value;
				case 'Power_Loadcurve'
					% Noramle Parametervariation:
					value = vary_parameter(...
						input_1,input_2);
					% Keine Cos_Phi gr��er 1 zulassen:
					cos = value(:,3:3:end);
					cos(cos>1)=1;
					value(:,3:3:end) = cos;
					obj.(parameter)=value;
				case 'Three_Phase_Device'
					% Ist der Wert 1 --> dreiphasiges Ger�t
					if input_1 >= 0.9
						obj.(parameter) = true;
					else
						obj.(parameter) = false;
					end
				otherwise
					% Noramle Parametervariation:
					obj.(parameter) = vary_parameter(...
						input_1,input_2);
					% Keine negativen Parameter zulassen:
					obj.(parameter)(obj.(parameter)<0)=0;
			end
		end
		
		function obj = check_activity(obj)
			%CHECK_ACTIVITY    �berpr�fen ob Ger�t zum Einsatz kommt.
			%    OBJ = CHECK_ACTIVITY(OBJ) �berpr�ft, ob Ger�t �berhaupt f�r
			%    Simulation als aktiv gilt und setzt dementsprechend
			%    OBJ.ACTIVITY. Dieser Wert hilft der das Ger�t verwendenden
			%    Funktion zu entscheiden, ob dieses Ger�t �berhaupt f�r den
			%    Simulationsdurchlauf gespeichert werden soll oder einfach
			%    ignoriert wird (da es keinen Beitrag zum Gesamtergebnis
			%    liefert).
			
			if (numel(obj.Start_Probability) == 1)
				% Wenn EIN Wert f�r die Startwahrscheinlichkeit angegeben wurde,
				% zuf�llig ermitteln, ob Ger�t �berhaupt in Einsatz genommen wird:
				if obj.Start_Probability/100 >= rand()
					obj.Activity = 1;
				else
					obj.Activity = 0;
				end
			elseif isempty(obj.Start_Probability)
				% Wurde keine Startwahrscheinlickeit angegeben, diese auf eins
				% setzen (Ger�t sicher aktiv):
				obj.Activity = 1;
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
			%    Z.B. werden die Einsatzzeiten �ber Startwahrscheinlichkeit &
			%    Startzeiten & typische Laufzeiten definiert, daher werden auch nur
			%    diese Parameter von dieser Funktion ge�ndert. z.B. die Nennleistung
			%    wird nicht ge�ndert.
			
			% Liste mit Parameterwerten, die ge�ndert werden k�nnen, alle anderen
			% werden einfach ignoriert:
			args_list = {...
% 				'Temp_Ambiance';...
				'Time_Period';...
				'Time_typ_Run';...
				'Time_Start';...
				'Start_Probability';...
				'Time_Starts_per_Hour';...
				'Time_run_Duty_Cycle';...
				'Time_min_Run';...
				};
			
			% Sind die Argumente Dreiergruppen --> wenn nicht --> Fehler:
			if (mod(numel(varargin),3) == 0)
				% Durchlaufen aller Eingangsparameter (in 3er Schritten):
				for i = 1:3:numel(varargin)
					% Erster Teil: Parametername, ist dieser ein String -->
					% wenn nicht --> Fehler:
					if ischar(varargin{i})
						try
							% nun �berpr�fen, ob dieser Parameter �berhaupt ge�ndert
							% werden muss:
							if ~isempty(find(strcmp(varargin{i},args_list), 1))
								% Falls Parameter in dieser Liste steht, Parameter
								% anpassen:
								obj = add_parameter(obj, varargin{i}, varargin{i+1},...
									varargin{i+2});
							end		
						catch ME
							error('device:paramlist',...
								['Fehler beim Bearbeiten des Parameters ''',...
								varargin{i},''' ist folgender Fehler aufgetreten: ',...
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
				% Fehler, weil Parameter nicht in Dreiergruppe �bergeben wurde:
				error('device:paramlist', ['Wrong number of inputarguments',...
					'. Input looks like (''Parameter_Name'', Mean_Value,',...
					' Standard_Deviation)']);
			end
			
		end
		
		function obj = adapt_for_simulation(obj, varargin)
			%ADAPT_FOR_SIMULATION    bereitet Klasse f�r Simulation vor
			%    OBJ = ADAPT_SCHEDULE(OBJ, VARARGIN) sorgt daf�r, dass die aktuelle
			%    Ger�teklasse f�r einen Simulationsdurchlauf vorbereitet wird.
			%    Diese Funktion muss einmal zu Beginn der Simulation f�r jede
			%    Ger�teinstanz aufgerufen werden. Diese Funktion wird in den
			%    jeweiligen Subklassen genauer definiert!
		end
		
		function obj = next_step(obj, varargin)
			% NEXT_STEP ermittelt die Reaktion des Ger�tes
			%    OBJ = NEXT_STEP(OBJ, TIME) ermittelt die Reaktion der Ger�te-
			%    instanz zum Zeitpunkt TIME. Die Reaktion besteht vordergr�ndig
			%    in der aufgenommen Leistung zu diesem Zeitpunkt.
			%    Diese Funktion wird in den jeweiligen Subklassen genauer
			%    definiert!
		end
	end
	
	methods (Static)
		
		function out = clocktime_to_min (timelist)
			%CLOCKTIME_TO_MIN    konvergiert Uhrzeitstring in laufende Minuten
			%    OUT = CLOCKTIME_TO_MIN (TIMELIST) rechnet den Uhrzeitstrings
			%    'HH:MM' im Vektor TIMELIST in laufende Minutenzeit (0-1440min
			%    entspricht 0-24h) um.
			
			t = datevec(datenum(timelist));
			out = t(:,4)*60 + t(:,5);
		end
	end
end
