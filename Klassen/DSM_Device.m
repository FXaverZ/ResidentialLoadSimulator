classdef DSM_Device
	%DSM_DEVICE    Klasse der DSM-Funktionalitäten 
	%    DSM_DEVICE repräsentiert jene Funktionalitäten, die ein Gerät (Chip)
	%    für die Steuerung eines Verbrauchers mit DSM benötigt
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
	%        'Frequency_Level'				
	%            Frequenzwert, ab dem DSM eingreift
	%        'Check_former_Frequ_Data'    
	%            Sollen zurückliegende Frequenzdaten überprüft werden (Für
	%            genauere zeitliche Auflösung)?
	%	     'Time_Delay_Restore_Op'
	%            Zeit die vergehen soll, wenn von einer Leistungsbeeinflussung
	%            zu der normalen Geräteoperation zurückgekehrt werden kann.
	%        'DSM_Input_Mode'				
	%            Auswahl des zu verwendenden DSM-Algorithmus
	%        'DSM_Output_Mode'				
	%            Aúswahl der Reaktion des Gerätes.
	%        'Controlled_Device'			
	%            Kopie der Instanz des kontrollierten Gerätes. Hier greifen die
	%            Änderungen durch das DSM.
	%        'Power_Input'					
	%            Aufgenommene Leistung des Gerätes nach DSM
	%        'Temp_Set_Variation'			
	%            Um wieviel soll Soll-Temperatur geändert werden?
	%        'Power_Reduction'				
	%            Um wieviel soll aufgenommene Leistung reduziert werden?
	%        'Time_Postpone_Start'			
	%            Um wieviel soll der Startzeitpunkt verschoben werden (in min)?
	%        'Time_Postpone_max'           
	%            Um wieviel Zeit darf Startzeitpunkt maximal verschoben werden
	%            (in min)?
	%        'Prioritys_Number'			
	%            Anzahl an Prioritätsgruppen von Verbrauchern
	%        'Prioritys_Freq_Range'	    
	%            Frequenzbereich der einzelnen Prioritätsgruppen
	%        'Prioritys_Allocation'		
	%            Verteilung der Verbraucher auf die Prioritätsgruppen.
	%
	%    Eigenschaften (Properties der Klasse):
	%        'Output'						
	%            Gibt an, ob vom DSM Algorithmus ein Signal anliegt.
	%        'Warning'	
	%            Warnung durch DSM Algorithmus	
	%        'Time_Output_Start'
	%            Gibt den Zeitpunkt an, zu dem der DSM-Algorithmus aktiv
	%            wurde.
	%        'Time_Output_Stop'   
	%            Gibt den Zeitpunkt an, zu dem der DSM-Algorithmus verlassen
	%            wurde.
	%        'Time_Postpone'   
	%            Um wieviel wurde der Startzeitpunkt bereits verschoben?
	%
	%    Funktionenhandles:
	%        input_algorithm   
	%            Funktionenhandle auf Input-Funktion (Reaktion auf
	%            Frequenzlevel)
	%        output_next_step   
	%            Funktionenhandle auf Output-Funktion (Geräteverhalten bei
	%            Frequenzeinbruch)
	%        find_start_idx
	%            Funktionenhandle auf Suchfunktion nach Startzeiten für
	%            Lastkurven, die innerhalb des betrachteten Zeiraums liegen.
	%        postpone_schedule
	%            Funktionenhandle auf Verschiebefunktion eines Einsatzplanes mit
	%            neuen Startzeiten.
	%
	%    Ausgabe:
	%        'Power_Input'     
	%            Leistungsaufnahme des Geräts zum aktuellen Zeitpunkt nach DSM.
	
	%    Franz Zeilinger - 28.10.2010 - R2008b lauffähig
	
	properties						
		Frequency_Level				
	%            Frequenzwert, ab dem DSM eingreift
		Check_former_Frequ_Data    
	%            Sollen zurückliegende Frequenzdaten überprüft werden (Für
	%            genauere zeitliche Auflösung)?
	    Frequency_Hysteresis
	%            Breite der Hysterese um die Frequenz:
	%                Output = 1 bei Frequenzwert
	%	                 Frequency_Level
	%                Output = 0 bei Frequenzwert
	%	                 Frequency_Level + Frequenzy_Hysteresis
	    Frequ_Filter_Time
	%            Gibt Zeitspanne an, wie weit zurückliegende Frequenzwerte für
	%            die laufende Mittelwertbildung herangezogen werden sollen (in
	%            Minuten)
		Prioritys_Number			
	%            Anzahl an Prioritätsgruppen von Verbrauchern
		Prioritys_Freq_Range	    
	%            Frequenzbereich der einzelnen Prioritätsgruppen
		Prioritys_Allocation		
	%            Verteilung der Verbraucher auf die Prioritätsgruppen.
	    Time_Delay_Restore_Op
	%            Zeit die vergehen soll, wenn von einer Leistungsbeeinflussung
	%            zu der normalen Geräteoperation zurückgekehrt werden kann.
		DSM_Input_Mode				
	%            Auswahl des zu verwendenden DSM-Algorithmus
		DSM_Output_Mode				
	%            Aúswahl der Reaktion des Gerätes.
		Controlled_Device			
	%            Kopie der Instanz des kontrollierten Gerätes. Hier greifen die
	%            Änderungen durch das DSM.
		Temp_Set_Variation			
	%            Um wieviel soll Soll-Temperatur geändert werden?
		Power_Reduction				
	%            Um wieviel soll die aufgenommene Leistung reduziert werden?
		Time_Postpone_Start			
	%            Um wieviel soll der Startzeitpunkt verschoben werden (in min)?
		Time_Postpone_max           
	%            Um wieviel Zeit darf Startzeitpunkt maximal verschoben werden
	%            (in min)?
	    Consider_non_stop_Parts = 1
	%            Sollen unenterbrechbare Teile der Lastkurve berücksichtigt
	%            werden
		Power_Input					
	%            Aufgenommene Leistung des Gerätes nach DSM
	end
	
	properties (Hidden)
		Last_Frequency_Data
	%            Speicherung der letzten Frequenzdaten für laufenden Mittelwert
		Output						
	%            Gibt an, ob vom DSM Algorithmus ein Signal anliegt.
		Warning	
	%            Warnung durch DSM Algorithmus
	    Output_for_Delay
	%            Zwischenergebnis des DSM Algorithmus (nach Frequenzbewertung
	%            z.B.)
		Time_Output_Start
	%            Gibt den Zeitpunkt an, zu dem der DSM-Algorithmus aktiv
	%            wurde.
		Time_Output_Stop   
	%            Gibt den Zeitpunkt an, zu dem der DSM-Algorithmus verlassen
	%            wurde.
	    Time_Delay_Active
	%            Ist die Zeitverschiebung der Wiederaufnahme der normalen
	%            Betriebsweise aktiv?
		Time_Postpone   
	%            Um wieviel wurde der Startzeitpunkt bereits verschoben?
		input_algorithm   
	%            Funktionenhandle auf Input-Funktion (Reaktion auf
	%            Frequenzlevel)
		output_next_step   
	%            Funktionenhandle auf Output-Funktion (Geräteverhalten bei
	%            Frequenzeinbruch)
		find_start_idx
	%            Funktionenhandle auf Suchfunktion nach Startzeiten für
	%            Lastkurven, die innerhalb des betrachteten Zeiraums liegen.
	    postpone_schedule
	%            Funktionenhandle auf Verschiebefunktion eines Einsatzplanes mit
	%            neuen Startzeiten.
	end
	
	methods
		
		function obj = DSM_Device (device, varargin)
			%DSM_DEVICE    Konstruktor der Geräteklasse DSM_DEVICE.
			%    OBJ = DSM_DEVICE (DEVICE, ARGLIST) durchläuft die
			%    Parameterliste ARGLIST und führt diese einer Variation der
			%    gegebenen Parameterwerte gemäß einer Normalverteilung zu.
			%    Daran anschließend werden die passenden Funktionen für Input
			%    und Output ermittelt und die entsprechenden Funktionenhandles
			%    gespeichert.
			
			input = varargin; % Übernehemen der Eingangsvariablen
			num_argin = numel(input);
			% Wenn keine Argumente übergeben wurden, Default-Werte setzen:
			if isempty(input)
				obj.DSM_Input_Mode = ' ';
				obj.DSM_Output_Mode = ' ';
				return;
			end
			
			% Liste mit Eingangsparametern durchgehen:
			if (mod(num_argin,3) == 0)
				% Durchlaufen aller Eingangsparameter (in 3er Schritten):
				for i = 1:3:num_argin
					parameter = input{i};
					if ischar(parameter)
						try
							% Je nach Paramterwert gesonderte Behandlung:
							obj = add_parameter (obj, parameter, input{i+1},...
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
						error('device:paramlist', ['Falscher Eingangsparameter!',...
							' Parameterliste: (''Parameter_Name'',',...
							' Mean_Value, Standard_Deviation)']);
					end
				end
			else
				% Fehler, weil Parameter nicht in Dreiergruppe übergeben wurde:
				error('DSM_Device:paramlist', ['Falsche Anzahl Eingangsparameter',...
					'. Parameterliste: (''Parameter_Name'', Mean_Value,',...
					' Standard_Deviation)']);
			end
			% Je nach Modus für DSM auswählen der entsprechenden
			% Funktionalitäten mit Überprüfung der Machbarkeit:
			obj = get_function_for_input (obj);
			obj = get_function_for_output (obj, device);
		end
		
		function obj = add_parameter (obj, parameter, input_1, input_2)
			% Überprüfung, ob Parameter übergeben wurden, die eine gesonderte
			% Behandlung benötigen, ansonsten normale Parametervariierung:
			switch parameter
				case 'DSM_Input_Mode'
					if iscell(input_1)
						obj.(parameter) = vary_parameter(input_1, input_2,...
							'List');
					elseif ischar(input_1)
						obj.(parameter) = input_1;
					else
						error('DSM_Device:paramlist', ['Ungültige Bezeichnung',...
							' für DSM Modus!']);
					end
				case 'DSM_Output_Mode'
					if iscell(input_1)
						obj.(parameter) = vary_parameter(input_1, input_2,...
							'List');
					elseif ischar(input_1)
						obj.(parameter) = input_1;
					else
						error('DSM_Device:paramlist', ['Ungültige Bezeichnung',...
							' für DSM Modus!']);
					end
				% Parameter, die, falls ein Parameterwert kleiner Null bei
				% der Streuung entsteht, solange gestreut werden, bis ein
				% Wert größer Null erreicht wird.
				% Das soll dazu führen, dass der Wert 0 dieser Parameter
				% nicht bevorzugt wird (da ansonsten, siehe
				% otherwise-Block, alle Werte kleiner Null auf Null gesetzt
				% werden und so mehr Geräte diesen Wert annehmen, als eine
				% Standardverteilung eigentlich zulassen würde)!
				case 'Time_Postpone_Start'
					obj.(parameter) = vary_parameter(...
						input_1,input_2);
					while obj.(parameter) < 0
						obj.(parameter) = vary_parameter(...
							input_1,input_2);
					end
				case 'Time_Delay_Restore_Op'
					obj.(parameter) = vary_parameter(...
						input_1,input_2);
					while obj.(parameter) < 0
						obj.(parameter) = vary_parameter(...
							input_1,input_2);
					end
				% Keine negativen Parameter zulassen:
				otherwise
					obj.(parameter) = vary_parameter(...
						input_1,input_2);
					
					obj.(parameter)(obj.(parameter)<0)=0;
			end
		end
		
		function [obj,frequency] = frequency_filter (obj, frequency)
			
			if size(frequency,2) < 2
				return;
			end
			
			% Filterung der Frequenzdaten
			dt_frequ = frequency(1,2)-frequency(1,1);
			dt_filte = obj.Frequ_Filter_Time/1440;
			% Zeitspanne für Interpolation für den letzten verfügbaren Wert:
			diff = mod(dt_filte,dt_frequ);
			% wieviel Frequenzwerte liegen für Mittelwertbildung vor?
			ind = floor((dt_filte/dt_frequ)+1e-5)+1;
			if isempty(obj.Last_Frequency_Data)
				% vorhergehende Frequenzdaten erzeugen:
				fre_n = zeros(2,ind);
				for k = 1:ind
					fre_n(:,ind+1-k) = [frequency(1,1)-k*dt_frequ; 50];
				end
				obj.Last_Frequency_Data = fre_n;
			end
			% ursprüngliches Frequenzdaten_Array:
			freq = [obj.Last_Frequency_Data, frequency];
			% Linear interpolierte Zwischenwerte:
			freq_int = (freq(2,2:end)-freq(2,1:end-1))*(1-diff/dt_frequ)+...
				freq(2,1:end-1);
			% Aufsummieren aller notwendigen Frequenzwerte für laufende
			% Mittelwertbildung, Beginn die jeweiligen aktuellen + bereits
			% interpolierten Werte:
			sum = freq(2,ind+1:end) + freq_int(1:end-(ind-1));
			for k=1:ind-1
				sum = sum + freq(2,1+k:size(sum,2)+k);
			end
			% Mittelwertbildung:
			freq_fil = sum/(ind+1);
			
			% Die letzten Frequenzwerte für nächsten Schritt speichern:
			obj.Last_Frequency_Data = freq(:,end-ind+1:end);
			% Gefilterte Werte übernehmen:
			frequency(2,:)=freq_fil;
		end
		
		function obj = delay_restore_op(obj, frequency, time, delta_t)
			if (isempty(obj.Output_for_Delay) || ~obj.Output_for_Delay) && ...
					~obj.Output
				return;
			elseif (isempty(obj.Output_for_Delay) || ~obj.Output_for_Delay ||...
					obj.Time_Delay_Active) && ...
				obj.Output
				obj.Output_for_Delay = obj.Output;
				obj.Time_Delay_Active = 0;
			elseif (~isempty(obj.Output_for_Delay) && ...
					obj.Output_for_Delay && ~obj.Output) || ...
					(obj.Output && ~isempty(obj.Time_Output_Stop) &&...
					(obj.Time_Output_Stop < time && ...
					(obj.Time_Output_Stop > time-delta_t/86400 || ...
					abs(obj.Time_Output_Stop - time-delta_t/86400) < 1e-8)))
				% Stopzeit der DSM-Funktion speichern, falls keiner vorhanden
				% ist:
				if isempty(obj.Time_Output_Stop) || obj.Time_Output_Stop == 0
					obj.Time_Output_Stop = time-delta_t/86400;
				end
				% Verzugszeit zur Stopzeit hinzufügen:
				if obj.Time_Delay_Active == 0
					obj.Time_Output_Stop = obj.Time_Output_Stop + ...
						obj.Time_Delay_Restore_Op/1440;
					obj.Time_Delay_Active = 1;
				end
				if obj.Time_Output_Stop < time-delta_t/86400 || ...
						abs(obj.Time_Output_Stop - time-delta_t/86400) < 1e-8
					obj.Output_for_Delay = obj.Output;
				end
			end
			obj.Output = obj.Output_for_Delay;
		end
		
		function obj = algorithm (obj, frequency, varargin)
			% algorithm (OBJ, FREQUENCY, POWER, VARARGIN) simuliert das
			% Verhalten eines DSM-Chips.
			% Ausgegeben wird ein Signal, ob Gerät weiterlaufen darf (OUTPUT)
			
			if ~isempty(obj.Frequ_Filter_Time)
				[obj,frequency] = obj.frequency_filter(frequency);
			end
			obj = obj.input_algorithm(obj, frequency, varargin{:});
			if ~isempty(obj.Time_Delay_Restore_Op) && obj.Time_Delay_Restore_Op > 0
				obj = obj.delay_restore_op(frequency, varargin{:});
			end
		end
		
		function obj = next_step(obj, device, time, delta_t, varargin)
			obj = obj.output_next_step(obj, device, time, delta_t, varargin{:});
		end
		
		function obj = combine_device_with (obj, device)
			% 			if isempty(obj.Controlled_Device)
			obj.Controlled_Device = device;
			% 			end
		end
		
		function obj = get_function_for_input (obj)
			switch obj.DSM_Input_Mode
				case 'Frequency_Response_Simple'
					% Simple Frequenzreaktion des "DSM-Chips":
					obj.Frequency_Level = 50 - obj.Frequency_Level;
					if isempty(obj.Frequency_Hysteresis)
						if obj.Check_former_Frequ_Data
							obj.input_algorithm =@frequency_response_simple_look_back;
						else
							obj.input_algorithm = @frequency_response_simple;
						end
					else
						if obj.Check_former_Frequ_Data
							obj.input_algorithm = ...
								@frequency_response_simple_hysteresis_look_back;
						else
							obj.input_algorithm = ...
								@frequency_response_simple_hysteresis;
						end
					end
				case 'Frequency_Response_Priority'
					% Die Auslösefrequenz des DSM hängt von der jeweiligen
					% Prioritätsklasse des "DSM-Chips" ab:
					if ~isempty(obj.Prioritys_Number) && ...
							~isempty(obj.Prioritys_Freq_Range) && ...
							~isempty(obj.Prioritys_Allocation)
						% Erzeugen einer Liste mit möglichen Prioritäten:
						list = 1:obj.Prioritys_Number;
						% Auswählen einer Priorität aus dieser Liste aufgrund
						% der angegebenen Verteilung der Prioritäten:
						prior = vary_parameter(list,...
							obj.Prioritys_Allocation, 'List');
						% Die zulässige Frequenzabweichung aus der Liste der
						% Frequenzen der jeweiligen Prioritäten ermitteln (je
						% höher die Prioritsnummer desto kleiner der
						% Frequenzwert, bei dem es zu einem Einsetzen der
						% DSM-Funktion kommt:
						frequ = sum(obj.Prioritys_Freq_Range(prior:end),1);
						obj.Frequency_Level = 50 - frequ;
						% Mit dieser Auslösefrequenz wird nun der simple
						% Frequenzalgorithmus verwendet:
						obj.input_algorithm = @frequency_response_simple;
					else
						% Falls nicht alle notwendigen Parameter angegeben
						% wurden --> Fehlermeldung:
						error('DSM_Device:notenoughInputArguments', ...
							['Kann Input-Funktion nicht erstellen, da ',...
							'Parameter fehlen (Inputfunktion ',...
							'''Frequency_Response_Priority)''']);
					end
				otherwise
					obj.input_algorithm = @no_dsm_function_input;
			end
		end
		
		function obj = get_function_for_output (obj, device)
			switch obj.DSM_Output_Mode
				case 'Change_Temp_Set'
					if strcmpi(class(device),'Thermal_Storage')
						if obj.Check_former_Frequ_Data
							obj.output_next_step = @change_temp_set_look_back;
						else
						obj.output_next_step = @change_temp_set;
						end
					else
						error('DSM_Device:wrongDeviceforFunction', ...
							['Kann Output-Funktion nicht mit dieser ',...
							'Geräteklasse anwenden, da diese nicht ',...
							'kompatibel zueinander sind!']);
					end
				case 'Turn_Off'
					% Normale Abschaltfunktion
					obj.output_next_step = @turn_off;
					% Bei Geräten mit thermischen Speicher: erhöhen der
					% Solltemperatur auf Unendlich, damit Funktion in der Zeit
					% der Regelfunktion ausgesetzt wird (der Speicher aber
					% normal weiterläuft...
					if strcmpi(class(device),'Thermal_Storage')
						obj.Temp_Set_Variation = Inf;
						if obj.Check_former_Frequ_Data
							obj.output_next_step = @change_temp_set_look_back;
						else
						obj.output_next_step = @change_temp_set;
						end
					end
					if strcmpi(class(device),'Loadcurve_Operation')
						obj.Consider_non_stop_Parts = 0;
						obj.Time_Postpone_max = Inf;
						obj.Time_Postpone_Start = 1;
						obj.postpone_schedule = @postpone_schedule_simple;
						if obj.Check_former_Frequ_Data
							obj.output_next_step = @pause_programm_look_back;
							obj.find_start_idx = @find_start_idx_look_back;
						else
							obj.output_next_step = @pause_programm;
							obj.find_start_idx = @find_start_idx_simple;
						end
					end
				case 'Turn_Off_Stand_by'
					if ~isempty(device.Power_Stand_by) && device.Power_Stand_by > 0
						obj.output_next_step = @turn_off_stand_by;
					else
						obj.output_next_step = @turn_off;
					end
				case 'Reduce_Input_Power'
					obj.output_next_step = @reduce_input_power;
				case 'Postpone_Start'
					% Falls Verschiebungszeit null, auf Minimalwert
					% (1 min) setzten, da sonst Gefahr für eine
					% Endlosschleife besteht:
					if isempty(obj.Time_Postpone_Start) || ...
							obj.Time_Postpone_Start <= 0
						obj.Time_Postpone_Start = 1;
					end
					% Sollen look_back-Funktionen verwendet werden?
					if obj.Check_former_Frequ_Data
						obj.find_start_idx = @find_start_idx_look_back;
					else
						obj.find_start_idx = @find_start_idx_simple;
					end
					obj.output_next_step = @postpone_start;
					% Wenn Geräteeinsatzplan vorhanden und maximale
					% Verschiebungszeit nicht angegeben bzw. mit 0 angegeben
					% wurde, normale Startzeitverschiebung (ohne Maximalzeit):
					if ~isempty(device.Time_Schedule_Day) && ...
							(isempty(obj.Time_Postpone_max) || ...
							obj.Time_Postpone_max <= 0)
						obj.postpone_schedule = @postpone_schedule_simple;
					% Startzeitverschiebung mit Maximalzeit:	
					elseif ~isempty(device.Time_Schedule_Day) && ...
							~isempty(obj.Time_Postpone_max) && ...
							obj.Time_Postpone_max > 0
						obj.postpone_schedule = @postpone_schedule_with_max_time;
					% nicht alle notwendigen Daten vorhanden: keine
					% Outputfunktion:
					else
						obj.output_next_step = @no_dsm_function_output;
					end
				case 'Pause_Programm'
					% Falls Verschiebungszeit null, auf Minimalwert
					% (1 min) setzten, da sonst Gefahr für eine
					% Endlosschleife besteht:
					if isempty(obj.Time_Postpone_Start) || ...
							obj.Time_Postpone_Start <= 0
						obj.Time_Postpone_Start = 1;
					end
					% Sollen look_back-Funktionen verwendet werden?
					if obj.Check_former_Frequ_Data
						obj.find_start_idx = @find_start_idx_look_back;
						obj.output_next_step = @pause_programm_look_back;
					else
						obj.find_start_idx = @find_start_idx_simple;
						obj.output_next_step = @pause_programm;
					end
					% Einsatzplan vorhanden, keine maximale Startzeit vorhanden:
					% Verschiebung ohne Maximalzeit
					if ~isempty(device.Time_Schedule_Day) && ...
							(isempty(obj.Time_Postpone_max) || ...
							obj.Time_Postpone_max <= 0)
						% maximale Verschiebezeit auf unendlich:
						obj.Time_Postpone_max = Inf;
						obj.postpone_schedule = @postpone_schedule_simple;
					% Verschiebung mit Maximalzeit
					elseif ~isempty(device.Time_Schedule_Day) && ...
							~isempty(obj.Time_Postpone_max) && ...
							obj.Time_Postpone_max > 0
						obj.postpone_schedule = @postpone_schedule_with_max_time;
					% nicht alle notwendigen Daten vorhanden: keine
					% Outputfunktion:
					else
						obj.output_next_step = @no_dsm_function_output;
					end
				otherwise
					obj.output_next_step = @no_dsm_function_output;
			end
		end
		
		function obj = no_dsm_function_input (obj, varargin)
			obj.Output = 0;
		end
		
		function obj = frequency_response_simple (obj, frequency, varargin)
			
			% aktuellen Frequenzwert einlesen (lezter Wert des übergebenen
			% Frequenz-Arrays):
			freq = frequency(2,end);
			% Überprüfen, ob aktueller Frequenzwert Schwellwert überschreitet
			% und dementsprechend den Output ansteuern:
			if freq < obj.Frequency_Level
				obj.Output = 1;
			else
				obj.Output = 0;
			end
		end
		
		function obj = frequency_response_simple_hysteresis (obj, ...
						frequency, varargin)
			
			% aktuellen Frequenzwert einlesen (lezter Wert des übergebenen
			% Frequenz-Arrays):
			freq = frequency(2,end);
			% Überprüfen, ob aktueller Frequenzwert Schwellwert überschreitet
			% und dementsprechend den Output ansteuern:
			if freq < obj.Frequency_Level
				obj.Output = 1;
			elseif freq > obj.Frequency_Level + obj.Frequency_Hysteresis
				obj.Output = 0;
			end
		end
		
		function obj = frequency_response_simple_look_back (obj, frequency, varargin)
			
			% Suchen nach Zeitpunkt, zu dem Frequenzschwelle unterschritten
			% wird:
			idx_l = find(frequency(2,:)<obj.Frequency_Level,1,'last');
			idx_f = find(frequency(2,:)<obj.Frequency_Level,1);
			if isempty(idx_l)
				% Wurde kein Wert gefunden, kein DSM-Einsatz: Abbruch
				obj.Output = 0;
				return;
			end
			% Speichern der Zeitpunkte zu dem es zur Unterschreitung des
			% Frequenzleves kam:
			if ~obj.Output
				obj.Time_Output_Start = frequency(1,idx_f);
			end
			% Speichern des letzten Zeitpunktes, zu dem es zur Unterschreitung
			% des Frequenzleves kam:
			obj.Time_Output_Stop = frequency(1,idx_l);
			% DSM-Output aktivieren:
			obj.Output = 1;			
		end
		
		function obj = frequency_response_simple_hysteresis_look_back (obj,...
				frequency, varargin)
			
			% Suchen nach Zeitpunkt, zu dem Frequenzschwelle unterschritten
			% wird:
			idx_l = find(frequency(2,:)<=obj.Frequency_Level + ...
				obj.Frequency_Hysteresis,1,'last');
			idx_f = find(frequency(2,:)<obj.Frequency_Level,1);
			% Wird ein Frequenzwert + Hysteres überschritten?
			idx_h = find(frequency(2,:)>obj.Frequency_Level + ...
				obj.Frequency_Hysteresis,1);
			if isempty(idx_f) && ~obj.Output
				% Wurde kein Wert gefunden, kein DSM-Einsatz: Abbruch
				obj.Output = 0;
				return;
			end
			if ~isempty(idx_h) && obj.Output
				% Hysterese wurde überschritten
				obj.Output = 0;
				if isempty(idx_l)
					idx_l = idx_h;
				end
				obj.Time_Output_Stop = frequency(1,idx_l);
			end
			% Speichern der Zeitpunkte zu dem es zur Unterschreitung des
			% Frequenzleves kam:
			if ~obj.Output
				obj.Time_Output_Start = frequency(1,idx_f);
			end
			% Speichern des letzten Zeitpunktes, zu dem es zur Unterschreitung
			% des Frequenzleves kam:
			obj.Time_Output_Stop = frequency(1,idx_l);
			% DSM-Output aktivieren:
			obj.Output = 1;			
		end
		
		function obj = change_temp_set (obj, device, time, delta_t, varargin)
			dev = obj.Controlled_Device;
			if obj.Output
				% die Solltemperatur des zu kontrollierenden Gerätes erhöhen
				% (um in Temp_Set_Variation angegebene Temperatur);
				dev.Temp_Set = device.Temp_Set + obj.Temp_Set_Variation;
			else
				% Zurücksetzen der Temperatur:
				dev.Temp_Set = device.Temp_Set;
			end
			dev = dev.next_step(time, delta_t);
			obj.Power_Input = dev.Power_Input;
			obj.Controlled_Device = dev;
		end
		
		function obj = change_temp_set_look_back (obj, device, time, delta_t, varargin)
			dev = obj.Controlled_Device;
			if obj.Output && (obj.Time_Output_Start < time || ...
					abs(obj.Time_Output_Start - time) < 1e-8) && ...
					obj.Time_Output_Start > time-delta_t/86400
				% Im letzen Betrachteten Zeitraum ist ein DSM-Output
				% aufgetreten. Jetzt thermisches Modell normal bis zum Zeitpunkt
				% des Auftretens der DSM-Funktionalität weiterlaufen lassen und
				% ab dann mit geänderter Soll-Temperatur:
				% Ermitteln der restlichen Laufzeit mit normaler Soll-Temperatur:
				delta_t_old = obj.Time_Output_Start-(time-(delta_t/86400));
				% In ganze Minuten umrechnen (da thermisches Modell max. in
				% Minutenschritten reagieren kann) und dann in Sekunden umrechnen:
				delta_t_old = round(delta_t_old*1440)*60;
				% thermisches Model mit alten Daten durchlaufen lassen:
				dev = dev.next_step(time, delta_t_old);
				% Rest der Laufzeit ist neue Laufzeit für kommende Schritte:
				delta_t = delta_t - delta_t_old; 				
				% die Solltemperatur des zu kontrollierenden Gerätes erhöhen
				% (um in Temp_Set_Variation angegebene Temperatur);
				dev.Temp_Set = device.Temp_Set + obj.Temp_Set_Variation;
			elseif obj.Output && obj.Time_Output_Stop < time && ...
					(obj.Time_Output_Stop > time-delta_t/86400 || ...
					abs(obj.Time_Output_Stop - time-delta_t/86400) < 1e-8)
				% Im betrachteten Zeitraum ist DSM-Funktinalität beendet worden.
				% Bis zu dem Zeitpunkt, an dem das passiert ist, thermisches
				% Model mit alten Einstellungen weiterlaufen lassen, danach auf
				% mit neuer Soll-Temperatur fortfahren:
				% Ermitteln der restlichen Laufzeit mit veränderter Soll-Temperatur:
				delta_t_old = obj.Time_Output_Stop-(time-(delta_t/86400));
				% In ganze Minuten umrechnen (da thermisches Modell max. in
				% Minutenschritten reagieren kann) und dann in Sekunden umrechnen:
				delta_t_old = round(delta_t_old*1440)*60;
				% thermisches Model mit alten Daten durchlaufen lassen:
				dev = dev.next_step(time, delta_t_old);
				% Rest der Laufzeit ist neue Laufzeit für kommende Schritte:
				delta_t = delta_t - delta_t_old; 				
				% Zurücksetzen der Temperatur:
				dev.Temp_Set = device.Temp_Set;
			elseif ~obj.Output
				% Zurücksetzen der Temperatur:
				dev.Temp_Set = device.Temp_Set;
			end
			dev = dev.next_step(time, delta_t);
			obj.Power_Input = dev.Power_Input;
			obj.Controlled_Device = dev;
		end
		
		function obj = turn_off (obj, device, varargin)
			if obj.Output
				obj.Power_Input = 0;
			else
				obj.Power_Input = device.Power_Input;
			end
		end
		
		function obj = turn_off_stand_by (obj, device, varargin)
			if obj.Output && ~device.Operating
				obj.Power_Input = 0;
			else
				obj.Power_Input = device.Power_Input;
			end
		end
		
		function obj = reduce_input_power (obj, device, varargin)
			if obj.Output && device.Operating
				obj.Power_Input = device.Power_Input*...
					(1-obj.Power_Reduction/100);
			else
				obj.Power_Input = device.Power_Input;
			end
		end
		
		function idx = find_start_idx_simple (obj, start, time, delta_t)
			% Ermitteln, ob Startzeiten in betrachteten Zeitraum fallen:
			% (ACHTUNG: statt (a <= b) wird (a<b | abs(a-b)<1e-8)
			% verwendet, damit ev. Gleitkommafehler ausgeschlossen
			% werden können!
			idx = start > time-delta_t/86400 & start < time | ...
				abs(start-time)< 1e-8;
		end
		
		function idx = find_start_idx_look_back (obj, start, time, delta_t)
			% Ermitteln, ob Startzeiten in betrachteten Zeitraum fallen:
			% (ACHTUNG: statt (a <= b) wird (a<b | abs(a-b)<1e-8)
			% verwendet, damit ev. Gleitkommafehler ausgeschlossen
			% werden können!
			idx = ...
				start > time-delta_t/86400 & ...
				(start > obj.Time_Output_Start | ...
				abs(start - obj.Time_Output_Start) < 1e-8) & ...
				(start < time | abs(start - time) < 1e-8) & ...
				(start < obj.Time_Output_Stop | ...
				abs(start - obj.Time_Output_Stop) < 1e-8);
		end
		
		function [dev, obj] = postpone_schedule_simple (obj, dev, time, delta_t)
			% Startzeiten auslesen:
			start = dev.Time_Start;
			% Ermitteln, ob Startzeiten in betrachteten Zeitraum fallen:
			% (ACHTUNG: statt (a <= b) wird (a<b | abs(a-b)<1e-8)
			% verwendet, damit ev. Gleitkommafehler ausgeschlossen
			% werden können!
			idx = obj.find_start_idx(obj, start, time, delta_t);
			% Wurde maximale Startzeitverschiebung überschritten?
			if isempty(start(idx))
				% keinen Startindex gefunden, Abbruch!
				return;
			end
			% Verschieben der der weiteren Lastpunkte solange um POST_T, bis
			% diese entweder nicht mehr in den betrachteten Zeitraum fallen:
			post_t = obj.Time_Postpone_Start/1440;
			while ~isempty(start(idx))
				% Startzeiten verschieben:
				start(idx) = start(idx) + post_t;
				% Ermitteln, ob die neuen Startzeiten in betrachteten Zeitraum
				% fallen:
				idx = obj.find_start_idx(obj, start, time, delta_t);
			end
			% Neue Startzeiten übernehmen und Einsatzplan neu berechnen:
			dev.Time_Start = start;
			dev = dev.recalculate_schedule();
		end
		
		function [dev, obj] = postpone_schedule_with_max_time (obj, dev, time, delta_t)
			% Zeiten in Tage umrechnen:
			post_max = obj.Time_Postpone_max/1440;
			if obj.Time_Postpone >= post_max && ...
					~isempty(find(dev.Time_Stop < time & ...
					(dev.Time_Stop > time-delta_t/86400 | ...
					abs(dev.Time_Stop - (time-delta_t/86400)) < 1e-8), 1))
				% Falls eine Lastkurve abgearbeitet wurde, maximale
				% Verschiebungszeit auf Null setzen (max. Verschiebungszeit nur
				% für einen Lastgang):
				obj.Time_Postpone = 0;
			end
			% Startzeiten auslesen:
			start = dev.Time_Start;
			% Ermitteln, ob Startzeiten in betrachteten Zeitraum fallen:
			% (ACHTUNG: statt (a <= b) wird (a<b | abs(a-b)<1e-8)
			% verwendet, damit ev. Gleitkommafehler ausgeschlossen
			% werden können!
			idx = obj.find_start_idx(obj, start, time, delta_t);
			% Wurde maximale Startzeitverschiebung überschritten?
			if isempty(start(idx))
				% keinen Startindex gefunden, Abbruch!
				return;
			end
			% Verschieben der der weiteren Lastpunkte solange um POST_T, bis
			% diese entweder nicht mehr in den betrachteten Zeitraum fallen oder
			% die maximale Verschiebungszeit POST_MAX erreicht wurde:
			post_t = obj.Time_Postpone_Start/1440;
			while ~isempty(start(idx)) && obj.Time_Postpone < post_max
				% Startzeitverschiebung aufsummieren:
				obj.Time_Postpone = obj.Time_Postpone + post_t;
				% Wird maximale Verschiebungszeit überschritten?
				if obj.Time_Postpone > post_max
					% Wenn ja, Zeitverschiebung an maximale Zeit anpassen:
					rem = obj.Time_Postpone - post_max;
					% Zeiten nur soviel verschieben, dass post_max erreicht
					% wird:
					post_t = post_t - rem;
					start(idx) = start(idx) + post_t;
					obj.Time_Postpone = post_max;
				else
					% Ansonsten Startzeiten verschieben:
					start(idx) = start(idx) + post_t;
				end
				% Ermitteln, ob die neuen Startzeiten in betrachteten Zeitraum
				% fallen:
				idx = obj.find_start_idx(obj, start, time, delta_t);
			end
			% Neue Startzeiten übernehmen und Einsatzplan neu berechnen:
			dev.Time_Start = start;
			dev = dev.recalculate_schedule();
		end
		
		function obj = postpone_start (obj, device, time, delta_t, varargin)
			dev = obj.Controlled_Device;
			if obj.Output
				% Anpassen des Einsatzplanes mit Verschiebung:
				[dev, obj] = obj.postpone_schedule(obj, dev, time, delta_t);
			else
				% Verschiebungszeit auf Null setzen (da DSM-Output weg ist):
				obj.Time_Postpone = 0;
			end
			% Durchführen der Berechnungen des aktuellen Zeitschrittes:
			dev = dev.next_step(time, delta_t);
			obj.Power_Input = dev.Power_Input;
			obj.Controlled_Device = dev;
		end
		
		function obj = pause_programm (obj, device, time, delta_t, varargin)
			dev = obj.Controlled_Device;
			if obj.Output
				% Anpassen des Einsatzplanes mit Verschiebung:
				[dev, obj] = obj.postpone_schedule(obj, dev, time, delta_t);
				% Überprüfen, ob gerade ein Lastgang aktiv ist (d.h. Zeitpunkt
				% time fällt zwischen Time_Start und Time_Stop):
				post_max = obj.Time_Postpone_max/1440;
				if ~isempty(dev.Time_Start(time > dev.Time_Start &...
						time < dev.Time_Stop)) && (obj.Time_Postpone < post_max);
					% aktive Lastkurve teilen, neue Startzeiten werden erstellt:
					dev = dev.split_loadcurve(time,obj.Consider_non_stop_Parts);
					% Anpassen des Einsatzplanes mit Verschiebung:
					[dev, obj] = obj.postpone_schedule(obj, dev, time, delta_t);
				end
			else
				% Verschiebungszeit auf Null setzen (da DSM-Output weg ist):
				obj.Time_Postpone = 0;
			end
			% Durchführen der Berechnungen des aktuellen Zeitschrittes:
			dev = dev.next_step(time, delta_t);
			obj.Power_Input = dev.Power_Input;
			obj.Controlled_Device = dev;
		end
		
		function obj = pause_programm_look_back(obj, device, time, delta_t, varargin)
			dev = obj.Controlled_Device;
			if obj.Output
				if (obj.Time_Output_Start > time-delta_t/86400) && ...
						(obj.Time_Output_Start < time || ...
						abs(obj.Time_Output_Start - time)<1e-8)
					t = obj.Time_Output_Start;
				else
					t = time;
				end
				% Anpassen des Einsatzplanes mit Verschiebung:
				[dev, obj] = obj.postpone_schedule(obj, dev, time, delta_t);
				% Überprüfen, ob gerade ein Lastgang aktiv ist (d.h. Zeitpunkt
				% des DSM_outputs fällt zwischen Time_Start und Time_Stop):
				post_max = obj.Time_Postpone_max/1440;
				try
					if ~isempty(dev.Time_Start(t > dev.Time_Start &...
							t < dev.Time_Stop)) && (obj.Time_Postpone < post_max);
						dev = dev.split_loadcurve(t, obj.Consider_non_stop_Parts);
						% Anpassen des Einsatzplanes mit Verschiebung:
						[dev, obj] = obj.postpone_schedule(obj, dev, time, delta_t);
					end
				catch ME
					% Eventuell Fehler aufgetreten bei
					% Einsatzplanerzeugung, wiederholen:
					dev = dev.recalculate_schedule();
					if ~isempty(dev.Time_Start(t > dev.Time_Start &...
							t < dev.Time_Stop)) && (obj.Time_Postpone < post_max);
						dev = dev.split_loadcurve(t, obj.Consider_non_stop_Parts);
						% Anpassen des Einsatzplanes mit Verschiebung:
						[dev, obj] = obj.postpone_schedule(obj, dev, time, delta_t);
					end
				end
			else
				% Verschiebungszeit auf Null setzen (da DSM-Output weg ist):
				obj.Time_Postpone = 0;
			end
			% Durchführen der Berechnungen des aktuellen Zeitschrittes:
			dev = dev.next_step(time, delta_t);
			obj.Power_Input = dev.Power_Input;
			obj.Controlled_Device = dev;
		end
		
		function obj = no_dsm_function_output (obj, device, varargin)
			obj.Power_Input = device.Power_Input;
		end
	end
end