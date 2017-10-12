classdef Cont_Operation < Device
	%CONT_OPERATION    Geräte, die zeitunabhängig konstante Leistung aufnehmen
	%    CONT_OPERATION charakterisiert elektrische Verbraucher im Haushalt
	%    welche im Dauerbetrieb sind (z.B. Stand-by-Verbraucher)
	%
	%    Parameter (werden in Parameterliste übergeben):
	%        'Power_Nominal'
	%            Anschlussleistung des Geräts
	%        'Start_Probability'       
	%            Wahrscheinlichkeit, dass Gerät aktiv ist. Kann eine zu einer
	%            Startzeitliste gehörende Liste sein (definert dann für jeden
	%            Startzeitpunkt die Wahrscheinlichkeit, ob Gerät aktiv wird)
	%            oder auch ein Wert, der die Wahrscheinlichkeit für die
	%            generelle Aktivität angibt (für die gesamte Simulationsdauer).
	%
	%    Eigenschaften (Properties der Klasse):
	%        'Activity'
	%            Ist das Gerät irgendwann im Einsatz? (Nach Erzeugen der
	%            Geräteinstanzen könne so alle nichtaktiven Geräte aussortiert
	%            werden. Daher sollte immer ACTIVITY = 1 sein!)
	%        'DSM'
	%            Instanz der Klasse 'DSM_Device', welche das DSM-Verhalten des
	%            Verbrauchers beinhaltet und steuert.
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt.
	
	%    Franz Zeilinger - 25.05.2010

   methods

		function obj = Cont_Operation(varargin)
			%CONT_OPERATION    Konstruktor der Klasse CONT_OPERATION
			%    Werden keine Parameter übergeben, wird ein Default-Wert erzeugt.
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
			% NEXT_STEP ermittelt die Reaktion des Gerätes
			%    OBJ = NEXT_STEP(OBJ, TIME) ermittelt die Reaktion der Geräte-
			%    instanz zum Zeitpunkt TIME. Die Reaktion besteht vordergründig
			%    in der aufgenommen Leistung zu diesem Zeitpunkt.
			%    Im Fall von CONT_OPERATION wird nur eine konstante Leistung
			%    ausgegeben:
			
			% Ausgabe der konstanten Leistung:
			obj.Power_Input = obj.Power_Nominal;
			obj.Operating = 1;
		end
	end
end 
