classdef Cont_Operation < Device
	%CONT_OPERATION    Ger�te, die zeitunabh�ngig konstante Leistung aufnehmen
	%    CONT_OPERATION charakterisiert elektrische Verbraucher im Haushalt
	%    welche im Dauerbetrieb sind (z.B. Stand-by-Verbraucher)
	%
	%    Parameter (werden in Parameterliste �bergeben):
	%        'Power_Nominal'
	%            Anschlussleistung des Ger�ts
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Ger�t aktiv ist. Kann eine zu einer
	%            Startzeitliste geh�rende Liste sein (definert dann f�r jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Ger�t aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit f�r die
	%            generelle Aktivit�t angibt (f�r die gesamte Simulationsdauer).
	%
	%    Eigenschaften (Properties der Klasse):
	%        'Activity'
	%            Ist das Ger�t irgendwann im Einsatz? (Nach Erzeugen der
	%            Ger�teinstanzen k�nne so alle nichtaktiven Ger�te aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	%        'DSM'
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Ger�ts zum aktuellen Zeitpunkt.
	
	%    Franz Zeilinger - 25.05.2010

   methods

		function obj = Cont_Operation(varargin)
			%CONT_OPERATION    Konstruktor der Klasse CONT_OPERATION
			%    Werden keine Parameter �bergeben, wird ein Default-Wert erzeugt.
			%    Verwendet den Konstruktor der Superklasse DEVICE zur
			%    Parametervariierung.
			if nargin ~= 0
				args = varargin;
			else
				args={'Power_Nominal', 50, 25};
			end
			obj = obj@Device(args{:});
		end
		
		function obj = next_step (obj,varargin)
			% NEXT_STEP ermittelt die Reaktion des Ger�tes
			%    OBJ = NEXT_STEP(OBJ, TIME) ermittelt die Reaktion der Ger�te-
			%    instanz zum Zeitpunkt TIME. Die Reaktion besteht vordergr�ndig
			%    in der aufgenommen Leistung zu diesem Zeitpunkt.
			%    Im Fall von CONT_OPERATION wird nur eine konstante Leistung
			%    ausgegeben:
			
			% Ausgabe der konstanten Leistung:
			obj.Power_Input = obj.Power_Nominal;
			obj.Operating = 1;
		end
	end
end 
