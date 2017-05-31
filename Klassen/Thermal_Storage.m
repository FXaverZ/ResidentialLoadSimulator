classdef Thermal_Storage < Device
	%THERMAL_STORAGE    Klasse aller Verbraucher mit thermischen "Speicher"
	%    THERMAL_STORAGE repr�sentiert Verbraucher, deren Verhalten mit Hilfe eines
	%    Thermischen Modells modelliert wird (z.B. K�hlschr�nke, Gefrierger�te,
	%    Heizungen, Boiler, ...)
	%
	%    Argumenten�bergabe erfolgt gleich wie bei Superklasse DEVICE (n�here
	%    Infos dort):
	%
	%    Parameter (werden in Parameterliste �bergeben):
	%        'Power_Nominal'
	%            Anschlussleistung des Ger�ts
	%        'Start_Probability'
	%            Wahrscheinlichkeit, dass Ger�t �berhaupt verwendet wird.
	%        'Dir_therm_Flow'
	%            Richtung des Flusses der thermischen Energie in den Speicher
	%            bei normalere "Aufladefunktion":
	%                +1 = "Aufheizen" (z.B. Boiler, Raumheizung, ...)
	%                -1 = "Abk�hlen"  (z.B. K�hlschrank, Klimaanlage, ...)
	%  	     'Efficency'
	%  	         Wirkungsgrad der Umwandlung von elektrischer in thermische Energie
	%            in %
	%        'Switch_Point'
	%            Schaltpunkt um Solltemperatur in �C (Thermostatregelung)
	%        'Heat_Capacity'
	%            W�rmekapazit�t in J/K, bezogen auf die elektrische Einspeisung
	%        'Thermal_Res'
	%            thermischer Widerstand Isolierung in K/W, bezogen auf die
	%            elektrische Einspeisung
	%        'Temp_Set'
	%  	         Solltemperatur in �C
	%        'Temp_Ambiance'
	%  	         Umgebungstemperatur in �C
	%        'Operat_Sim_Start'
	%  	         Wahrscheinlichkeit, dass Ger�t zu Beginn der Simulation aktiv
	%  	         ist.
	%
	%    Eigenschaften (Properties der Klasse):
	%	     'Phase_Index'
	%            Index der Phase, an der das Ger�t angeschlossen ist
	%        'Activity'
	%            Ist das Ger�t irgendwann im Einsatz? (Nach Erzeugen der
	%            Ger�teinstanzen k�nne so alle nichtaktiven Ger�te aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	%        'DSM'
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
	%	     'Operating'               
	%            gibt an ob die K�hl- bzw. Heizeinrichtung gerade aktiv ist.
	%		 'Temp'                    
	%            aktuelle Temperatur in �C
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt. Ist ein [3,1]
	%            Array, wobei jede Zeile die aufgenommene Leistung einer Phase
	%            darstellt.
	
	%    Franz Zeilinger - 18.11.2011
	
	properties
		Factor_Inrush
		Time_Inrush_Decay
		Dir_therm_Flow
	%            Richtung des Flusses der thermischen Energie in den Speicher
	%            bei normaler "Aufladefunktion" des Speichers:
	%                +1 = "Aufheizen" (z.B. Boiler, Raumheizung, ...)
	%                -1 = "Abk�hlen"  (z.B. K�hlschrank, Klimaanlage, ...)
		Efficency				
	%  	         Wirkungsgrad der Umwandlung von elektrischer in thermische Energie
	%            in % (thermische Energie bezogen auf die elektrische
	%            Einspeisung, d.h. ohne Ber�cksichtigung einer etwaigen
	%            Leistungszahl einer beteiligten W�rmepumpe!)
		Switch_Point			
	%            Schaltpunkt um Solltemperatur in �C (Thermostatregelung)
		Heat_Capacity			
	%            W�rmekapazit�t in J/K, bezogen auf die elektrische Einspeisung
	%            d.h. ohne Ber�cksichtigung einer etwaigen Leistungszahl einer
	%            beteiligten W�rmepumpe!
		Thermal_Res				
	%            thermischer Widerstand Isolierung in K/W, bezogen auf die
	%            elektrische Einspeisung d.h. ohne Ber�cksichtigung einer
	%            etwaigen Leistungszahl einer beteiligten W�rmepumpe!
		Temp_Set			
	%            Solltemperatur
		Temp_Ambiance			
	%            Umgebungstemperatur
		Operat_Sim_Start        
	%  	         Wahrscheinlichkeit, dass Ger�t zu Beginn der Simulation aktiv
	%  	         ist.	
	end
	
	properties (Hidden)
		Temp                    
	%            aktuelle Temperatur in �C
	    Time_Start_Operation = 0
	%            Zeitpunkt, an dem das Ger�t die aktuelle Aktivit�tszeit gestartet
	%            hat (f�r Einschaltleistungspitze)
	end
	
	methods
		
		function obj = Thermal_Storage(varargin)
			%THERMAL_STORAGE    Konstruktor der Klasse THERMAL_STORAGE
			%    Verwendet den Konstruktor der Superklasse DEVICE zur
			%    Parametervariierung. Die Startwerte werden zuf�llig ermittelt,
			%    um keine Unstetigkeiten im Verlauf zu Beginn der Simulation zu
			%    erhalten.
			
			% Erzeugen der Parameterwerte:
			obj = obj@Device(varargin{:});
			
			% Dir_therm_Flow anpassen (bei normaler Parametervariierung von
			% DEVICE wurde der Wert -1 auf Null gesetzt, dies wieder r�ckg�ngig
			% machen:
			if obj.Dir_therm_Flow == 0
				obj.Dir_therm_Flow = -1;
			end
			
			% Temperatur im Ger�t zu Beginn der Simulation zuf�llig
			% ermitteln (in der N�he der Soll-Temperatur):
			obj.Temp = obj.Temp_Set + (obj.Switch_Point*(rand-0.5));
			% zuf�llig ermitteln, ob Ger�t zu Beginn aktiv ist:
			if rand <= (obj.Operat_Sim_Start/100)
				obj.Operating = 1;
			else
				obj.Operating = 0;
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
			
			if ~isempty(obj.Temp_Set) 
				%Aktivit�ts�berpr�fung der Superklasse verwenden:
				obj = check_activity@Device(obj);
			else
				% Falls keine Solltemperatur angegeben wurde, kann Ger�t nicht
				% aktiv werden:
				obj.Activity = 0;
			end
		end
		
		function obj = next_step (obj, time, delta_t, varargin)
			% NEXT_STEP    ermittelt die Reaktion des Ger�tes
			%    OBJ = NEXT_STEP(OBJ, ~, DELTA_T, VARARGIN) ermittelt die
			%    Reaktion des Ger�ts auf die aktuelle Situation. Es liegt
			%    dieser Funktion ein thermisches Modell des Speichers
			%    zu Grunde. DELTA_T gibt den Simulationsschritt in Sekunden an.
			%    Ist dieser gr��er als eine Minute, werden Zwischenschritte
			%    eingef�gt, damit das thermische Modell akurat bleibt.
			
			% thermisches Modell ablaufen lassen:
			d_t = 60;
			if delta_t>d_t
				for i=(delta_t/d_t):-1:1
					% Ermitteln der aktuellen Temperatur:
					obj = update_temperature(obj, d_t);
					% Ermitteln, ob Ger�t l�uft (Thermostat):
					obj = upate_operation(obj, time - i*d_t/86400, d_t);
				end
			else
				% Ermitteln der aktuellen Temperatur:
				obj = update_temperature(obj, delta_t);
				% Ermitteln, ob Ger�t l�uft (Thermostat):
				obj = upate_operation(obj, time, delta_t);
			end
			
			% Zeitraum zwischen Start der Aktivit�t und aktuellen Zeitpunkt
			% ermitteln:
			d_t = (time - obj.Time_Start_Operation)*86400;
			
			% Ausgabe der Leistung f�r aktuellen Schritt:
			obj.Power_Input(obj.Phase_Index) = obj.Operating * obj.Power_Nominal * ...
				(1+(1+obj.Factor_Inrush/100)*exp(-d_t/obj.Time_Inrush_Decay));
			obj.Power_Input_Reactive = obj.Power_Input*tan(acos(obj.Cos_Phi_Nominal));
			
		end
		
		function obj = update_temperature(obj, delta_t)
			%UPDATE_TEMPERATURE    aktualisiert die Temperatur im Ger�t
			%    OBJ = UPDATE_TEMPERATURE(OBJ, DELTA_T) f�hrt jene
			%    Berechnungsschritte aus um die innere Temperatur des thermischen
			%    Speichers zu aktualisieren.
			%    Dazu wird die Temperatur�nderung �ber die Zeitspanne DELTA_T
			%    berechnet und diese zu der aktuellen Termparatur addiert. Die
			%    Berechnung erfolgt nicht exakt, sondern linearisiert (was bei
			%    thermischen Speichern aufgrund der gro�en Zeitkonstanten meist
			%    zu keinen gro�en Abweichungen f�hrt, sofern DELTA_T klein genug
			%    gegen�ber dieser Zeitkonste ist!)
			
			% Ermitteln der Verluste:
			loss = 1/obj.Thermal_Res * (obj.Temp_Ambiance - obj.Temp);
			% Ermitteln der eingespeisten thermischen Energie:
			input = obj.Operating * obj.Efficency/100 * obj.Power_Nominal * ...
				obj.Dir_therm_Flow;
			% Temperaturdifferenz�nderung (d_temp ~ dTemp/dt)
			d_temp = (loss + input) * 1/obj.Heat_Capacity;
			obj.Temp = obj.Temp + d_temp * delta_t;
		end
		
		function obj = upate_operation(obj, time, delta_t)
			%UPATE_OPERATION    aktualisiert den Betriebzustand des Ger�tes
			%    OBJ = UPATE_OPERATION(OBJ) ermittelt aus den aktuell
			%    vorliegenden Zust�nden, ob das Ger�t seinen Betriebszustand
			%    (Speicher f�llen bzw. kein Betrieb) �ndert.
			%    In der vorliegenden Funktion ist dies im Sinne einer
			%    Zwei-Punkt-Regelung (Thermostat) realisert.
			
			% speichern des vorhergehenden Zustandes:
			operating = obj.Operating;
			
			% Thermostatabfrage:
			if (obj.Temp_Set + (obj.Switch_Point/2) - obj.Temp) < 0
				obj.Operating = 1 - obj.Dir_therm_Flow;
				obj.Operating = logical(obj.Operating);
			elseif (obj.Temp_Set - (obj.Switch_Point/2) - obj.Temp) > 0
				obj.Operating = 1 + obj.Dir_therm_Flow;
				obj.Operating = logical(obj.Operating);
			end
			
			% Zeitpunkt ermitteln, zu dem ein Einschalten erfolgt ist (wenn vorher
			% Ger�t nicht aktiv war und nach der vorherigen Berechnung aktiv ist,
			% liegt der Einschaltzeitpunkt vor!)
			if ~operating && obj.Operating
				% diesen Zeitpunkt noch innerhalb des Zeitraums, der durch delta_t
				% definiert ist, streuen:
				d_t = vary_parameter(delta_t, 'Uniform_Distr');
				obj.Time_Start_Operation = time - d_t / 86400;
			end
		end
	end
end

