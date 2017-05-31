function Result = simulate_devices_parallel(hObject, Devices, Time)
%SIMULATE_DEVICES    führt die eigentliche Simulation durch
%    RESULT = SIMULATE_DEVICES(HOBJECT, DEVICES, TIME) führt die eigentliche
%    Simulation aus. Dazu wird über jeden Zeitschritt (gemäß TIME) und jedes
%    Gerät (DEVICES) itteriert und deren aktuelle Leistung ermittelt und in die
%    RESULT-Struktur gespeichert. Weiters erfolgt eine Ausgabe des Fortschritts
%    in der Konsole. HOBJECT liefert den Zugriff auf das aufrufende GUI-Fenster
%    (für Statusanzeige).

% Erstellt von:            Franz Zeilinger - 10.08.2011
% Letzte Änderung durch:   Franz Zeilinger - 04.12.2012

number_steps = Time.Number_Steps;

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: Gerätearten
% - 3. Dimension: Zeitpunkte
Power = zeros([3 size(Devices.Elements_Varna,2) (Time.Number_Steps)]);
Power_Reactive = Power;
% Ein Ergebnis Cell-Array erstellen, dass in der parfor-Schleife bearbeitet werden
% kann
pow = cell(size(Devices.Elements_Varna,2),1);
% Ersten Zeitpnkt simulieren und dabei alle Geräte-Einsatzpläne auf laufende
% Matlabzeit umrechnen:
device = cell(1,size(Devices.Elements_Varna,2));
step = 1;
time = Time.Date_Start;
for i = 1:size(Devices.Elements_Varna,2)
	% Für jedes Element im Cell-Array Elements_Varna (Variablennamen, arbeitet die
	% einzelnen Geräteklassen ab):
	% Leeres Zwischenergebnisarray erstellen:
	% - 1. Dimension: Phasen 1 bis 3 jeweils P & Q (insges. 6)
	% - 2. Dimension: Geräteinstanzen (maximal mögliche Anzahl an Geräten)
	% - 3. Dimension: Zeitpunkte
	btw_result = zeros([6, number_steps]);
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% Für Geräte mit schneller Berechnungsmöglichkeit sind nun alle
		% Vorbereitungen abgeschlossen. Für Geräte mit normaler Simulation wird nun
		% der erste Zeitschritt berechnet:
		if ~dev.Fast_computing_at_no_dsm
			% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
			% berechnet wird!
			dev = dev.next_step(time, 0);
			btw_result(1:3,step) = btw_result(1:3,step) + dev.Power_Input;
			btw_result(4:6,step) = btw_result(4:6,step) + dev.Power_Input_Reactive;
		end
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
	% Für parallele Bearbeitung die DEVICES-Struktur in ein Cell-Array umwandeln,
	% damit diese in der parfor-Schleife verarbeitet werden kann: 
	device{i} = Devices.(Devices.Elements_Varna{i});
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	pow{i} = btw_result; 
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start
time_vec = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;

date_start = Time.Date_Start;
base = Time.Base;
% Berechnen der Reaktionen der Verbraucher für die restlichen Zeitpunkte:
parfor i = 1:size(Devices.Elements_Varna,2)
	% Zwischenergebnis Array; enthält die Leistungsdaten aufgteilt auf die Phasen, 
	% und die Zeitschritte für eine Gerätegruppe:
	btw_result = pow{i};
	dev = device{i};
	if ~isempty(dev)
		dev = device{i}(1); % Ein Gerät der aktuellen Geräteklasse auslesen, um 
		                    %     die Eignung der Geräteklasse für eine schnelle 
		                    %     Berechnung zu ermitteln
	else
		continue;           % keine Geräte vorhanden --> zur nächsten Geräteart gehen
	end
	if dev.Fast_computing_at_no_dsm
		% Schnelle Berechnung ist möglich:
		% (In Zukunft könnte das ev. von Klasse zu Klasse verschieden sein, daher
		% wäre eine Verlagerung des kommenden Codes in eine eigene Methode von
		% Vorteil. Da im vorliegendnen Fall nur die Geräte der Klasse
		% "SCHEDULED_OPERATION" behandelt werden und sich auch ein Speichervorteil
		% ergibt, wird davon abgesehen!
		% Reaktion der Verbraucher ermitteln
		for j = 1:size(device{i},2)
			% Geräteinstanz auslesen
			dev = device{i}(j);
			% Ein Hilfsarray erstellen, das die Geräteleistungsaufnahme darstellen
			% soll, dazu die Stand-by-Leistung zu allen Zeitpunkte setzen, die
			% Betriebszeitpunkte werden dann mit den jeweiligen Betriebswerten
			% überschrieben (--> wenn Gerät nicht in Betrieb dann in Stand-by, im
			% Fall, dass es keinen Stand-by-Verbrauch gibt, ist dieser Null und
			% bleibt null...) 
			btw_dev = zeros(6,number_steps);
			btw_dev(dev.Phase_Index,:) = dev.Power_Stand_by;
			btw_dev(dev.Phase_Index + 3,:) = dev.Power_Stand_by * ...
				tan(acos(dev.Cos_Phi_Stand_by));
			% Nun die einzelnen Eintragungen im Einsatzplan durchgehen und
			% entsprechend die Leistungen eintragen:
			for step = 1:size(dev.Time_Schedule,1)
				% Zeitpunkte finden, in denen das Gerät aktiv ist:
				idx = time_vec >= dev.Time_Schedule(step,1) & ...
					time_vec < dev.Time_Schedule(step,2);
				% Zu diesen Zeitpunkten aktuelle Leistungsaufnahme entsprechend dem
				% Einsatzplan sezten
				btw_dev(dev.Phase_Index,idx) = dev.Time_Schedule(step,3);
				% Mit Hilfe des aktuell gültigen cos(phi) die Blindleistungsaufnahme
				% ermitteln und entsprechend sezten:
				btw_dev(dev.Phase_Index + 3,idx) = dev.Time_Schedule(step,3)*...
					tan(acos(dev.Time_Schedule(step,4)));
			end
			% die ermittelte Leistung der bisher ermittelten hinzufügen:
			btw_result = btw_result + btw_dev;
		end
	else
		% Herkömmliche Berechnung mit Hilfe der NEXT_STEP-Methode der jeweiligen
		% Geräteklasse:
		% Für jeden Zeitpunkt
		for step = 2:number_steps
			% Aktuellen Zeitpunkt ermitteln:
			time = date_start + (step-1)*base/86400;
			% Reaktion der Verbraucher ermitteln
			for j = 1:size(device{i},2)
				dev = device{i}(j);
				dev = dev.next_step(time, base);
				btw_result(1:3,step) = btw_result(1:3,step) + dev.Power_Input;
				btw_result(4:6,step) = btw_result(4:6,step) + dev.Power_Input_Reactive;
				device{i}(j) = dev;
			end
		end
	end
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	pow{i} = btw_result; 
end

% Nun die gewünschten Ergebnis-Arrays wiederherstellen:
for i=1:size(Devices.Elements_Varna,2)
	btw_result = pow{i};
	Power(:,i,:) = btw_result(1:3,:);
	Power_Reactive(:,i,:) = btw_result(4:6,:);
end
	
Result.Raw_Data.Power = Power;
Result.Raw_Data.Power_Reactive = Power_Reactive;

end