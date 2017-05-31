function Power_parallel = simulate_devices_for_load_profiles_new(Devices, Time)
%SIMULATE_DEVICES_FOR_LOAD_PROFILES_PARALLEL   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 18.11.2011
% Letzte �nderung durch:   Franz Zeilinger - 29.01.2015

% F�r paralle Bearbeitung verschieden Daten in eigenen Variblen speichern, um
% Kommunikationsaufwand zu reduzieren:
number_steps = Time.Number_Steps;
date_start = Time.Date_Start;
base = Time.Base;
num_devices = max(Devices.Number_Dev);
% Aufbereiten der Ger�te f�r unterschiedliche paralle Simulation:
fast_computing_devs = {};
% fast_computing_devs_num = [];
slow_computing_devs = {};
% slow_computing_devs_num = [];

for i = 1:size(Devices.Elements_Varna,2)
	if isempty(Devices.(Devices.Elements_Varna{i}))
		continue;
	end
	dev = Devices.(Devices.Elements_Varna{i})(1);
	if ~dev.Fast_computing_at_no_dsm
		slow_computing_devs{end+1} = Devices.Elements_Varna{i}; %#ok<AGROW>
% 		slow_computing_devs_num(end+1) = Devices.Number_Dev(i); %#ok<AGROW>
	else
		% Schnelle Berechnung ist m�glich!
		fast_computing_devs{end+1} = Devices.Elements_Varna{i}; %#ok<AGROW>
% 		fast_computing_devs_num(end+1) = Devices.Number_Dev(i); %#ok<AGROW>
	end
end
% Ein Ergebnis Cell-Array erstellen, dass in der parfor-Schleife bearbeitet werden
% kann (anscheinend kann ein 4D-Array nicht verabeitet werden, ein 3D-Array schon!
% Siehe z.B. SIMULATE_DEVICES_PARALLEL):
fast_pow = cell(numel(fast_computing_devs),1);
slow_pow = cell(numel(slow_computing_devs),1);
fast_device = cell(1,numel(fast_computing_devs));
slow_device = cell(1,numel(slow_computing_devs));

step = 1;
time = Time.Date_Start;
% Ersten Zeitpunkt simulieren und dabei alle Ger�te-Einsatzpl�ne auf laufende
% Matlabzeit umrechnen:
for i = 1:numel(fast_computing_devs)
	% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen, arbeitet die
	% einzelnen Ger�teklassen ab):
	% Leeres Zwischenergebnisarray erstellen:
	% - 1. Dimension: Phasen 1 bis 3 jeweils P & Q (insges. 6)
	% - 2. Dimension: Ger�teinstanzen (maximal m�gliche Anzahl an Ger�ten)
	% - 3. Dimension: Zeitpunkte
	btw_result = zeros([6, num_devices, number_steps]);
	for j = 1:size(Devices.(fast_computing_devs{i}),2)
		dev = Devices.(fast_computing_devs{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% F�r Ger�te mit schneller Berechnungsm�glichkeit sind nun alle
		% Vorbereitungen abgeschlossen.
		Devices.(fast_computing_devs{i})(j) = dev;
	end
	% F�r parallele Bearbeitung die DEVICES-Struktur in ein Cell-Array umwandeln,
	% damit diese in der parfor-Schleife verarbeitet werden kann:
	fast_device{i} = Devices.(fast_computing_devs{i});
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	fast_pow{i} = btw_result;
end
for i = 1:numel(slow_computing_devs)
	% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen, arbeitet die
	% einzelnen Ger�teklassen ab):
	% Leeres Zwischenergebnisarray erstellen:
	% - 1. Dimension: Ger�teinstanzen (maximal m�gliche Anzahl an Ger�ten)
	% - 2. Dimension: Phasen 1 bis 3 jeweils P & Q (insges. 6)
	% - 3. Dimension: Zeitpunkte
	btw_result = zeros([num_devices, 6, number_steps]);
	for j = 1:size(Devices.(slow_computing_devs{i}),2)
		dev = Devices.(slow_computing_devs{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% F�r Ger�te mit schneller Berechnungsm�glichkeit sind nun alle
		% Vorbereitungen abgeschlossen. F�r Ger�te mit normaler Simulation wird nun
		% der erste Zeitschritt berechnet:
		if ~dev.Fast_computing_at_no_dsm
			% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
			% berechnet wird!
			dev = dev.next_step(time, 0);
			btw_result(j,1:3,step) = dev.Power_Input*dev.Phase_Power_Distribution_Factor;
			btw_result(j,4:6,step) = dev.Power_Input_Reactive *devPhase_Power_Distribution_Factor;
		end
		Devices.(slow_computing_devs{i})(j) = dev;
	end
	% F�r parallele Bearbeitung die DEVICES-Struktur in ein Cell-Array umwandeln,
	% damit diese in der parfor-Schleife verarbeitet werden kann:
	slow_device{i} = Devices.(slow_computing_devs{i});
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	slow_pow{i} = btw_result;
end

% Messen der Zeit, die ben�tigt wird - Start:
waitbar_start;
% Zeitvektor erstellen:
time_vec = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;

% Berechnen der Reaktionen der Verbraucher f�r die restlichen Zeitpunkte, zun�chst
% die schnell rechenbaren Ger�te (aufgeteilt auf die aktiven Worker):
for i = 1:numel(fast_computing_devs)
	btw_result = fast_pow{i};
	dev = fast_device{i};
	if isempty(dev)
		 % keine Ger�te vorhanden --> zur n�chsten Ger�teart gehen
		continue;
	end
	
	% Schnelle Berechnung ist m�glich:
	% (In Zukunft k�nnte das ev. von Klasse zu Klasse verschieden sein, daher
	% w�re eine Verlagerung des kommenden Codes in eine eigene Methode von
	% Vorteil. Da im vorliegendnen Fall nur die Ger�te der Klasse
	% "SCHEDULED_OPERATION" behandelt werden und sich auch ein Speichervorteil
	% ergibt, wird davon abgesehen!
	% Reaktion der Verbraucher ermitteln
	for j = 1:size(fast_device{i},2)
		% Ger�teinstanz auslesen
		dev = fast_device{i}(j);
		% Stand-by-Leistung auf alle Zeitpunkte setzen, die Betriebszeit-
		% punkte werden dann mit den jeweiligen Betriebswerten �berschrieben
		% (--> wenn Ger�t nicht in Betrieb dann in Stand-by, im Fall, dass es
		% keinen Stand-by-Verbrauch gibt, ist dieser Null und bleibt null...)
		btw_result(dev.Phase_Index,j,:) = dev.Power_Stand_by*dev.Phase_Power_Distribution_Factor;
		btw_result(dev.Phase_Index + 3,j,:) = dev.Power_Stand_by * ...
			tan(acos(dev.Cos_Phi_Stand_by))*dev.Phase_Power_Distribution_Factor;
		% Nun die einzelnen Eintragungen im Einsatzplan durchgehen und
		% entsprechend die Leistungen eintragen:
		for step = 1:size(dev.Time_Schedule,1)
			% Zeitpunkte finden, in denen das Ger�t aktiv ist:
			idx = time_vec >= dev.Time_Schedule(step,1) & ...
				time_vec < dev.Time_Schedule(step,2);
			% Zu diesen Zeitpunkten aktuelle Leistungsaufnahme entsprechend
			% dem Einsatzplan sezten
			btw_result(dev.Phase_Index,j,idx) = dev.Time_Schedule(step,3)*dev.Phase_Power_Distribution_Factor;
			% Mit Hilfe des aktuell g�ltigen cos(phi) die Blindleistungs-
			% aufnahme ermitteln und entsprechend sezten:
			btw_result(dev.Phase_Index + 3,j,idx) = ...
				dev.Time_Schedule(step,3)*tan(acos(dev.Time_Schedule(step,4)))*dev.Phase_Power_Distribution_Factor;
		end
	end
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	fast_pow{i} = btw_result;
end
clear btw_result fast_device

for i = 1:numel(slow_computing_devs)
	btw_result = slow_pow{i};
	dev = slow_device{i};
	if isempty(dev)
		% keine Ger�te vorhanden --> zur n�chsten Ger�teart gehen
		continue;
	end
	% Herk�mmliche Berechnung mit Hilfe der NEXT_STEP-Methode der jeweiligen
	% Ger�teklasse:
	% F�r jeden Zeitpunkt
	device = slow_device{i};
	for j = 1:size(device,2)
		% Reaktion der Verbraucher ermitteln
		for step = 2:number_steps
			% Aktuellen Zeitpunkt ermitteln:
			time = date_start + (step-1)*base/86400;
			% Ger�teinstanz auslesen
			dev = device(j);
			% N�chsten Zeitschritt des Ger�tes berechnen:
			dev = dev.next_step(time, base);
			% aktuelle Leistungsaufnahme in Zwischenergebnis-Array speichern:
			btw_result(j,:,step) = [dev.Power_Input; dev.Power_Input_Reactive] * dev.Phase_Power_Distribution_Factor;
			% die �nderungen in der Ger�teinstanz in das DEVICES-Array
			% zur�ckschreiben:
			device(j) = dev;
		end
	end
	slow_device{i} = device;
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	slow_pow{i} = btw_result;
end
clear btw_result slow_device;

% ACHTUNG! Nachfolgend wurde der urspr�ngliche Code ver�ndert, weil eine Permutation
%     einen gewaltigen Speicherbedarf hat, und so immer zum OUT_OF_MEMORY-Fehler
%     f�hrt. Daher verzicht auf Permutation und bilden eines neuen Ergebnis-Arrays,
%     dass dann in weiterer folge gesondert behandelt werden muss!
%     (siehe POSTPROCESS_RESULTS_FOR_LOADPROFILES)

% Nun die einzelnen Zwischenergenisse abarbeiten und zu einem Gesamtarray
% zusammenfassen: Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Ger�tearten
% - 2. Dimension: Phasen 1 bis 3 jeweils P & Q (insges. 6)
% - 3. Dimension: Ger�teinstanz
% - 4. Dimension: Zeitpunkte
for i = 1:size(Devices.Elements_Varna,2)
	% Zwischenergenis korrekt eintragen:
	idx = find(strcmp(Devices.Elements_Varna{i},fast_computing_devs));
	if ~isempty(idx)
		Power_parallel(i,:,:,:) = fast_pow{idx}; %#ok<AGROW>
		fast_pow{idx} = [];
	end
	idx = find(strcmp(Devices.Elements_Varna{i},slow_computing_devs));
	if ~isempty(idx)
		Power_parallel(i,:,:,:) = permute(slow_pow{idx},[2,1,3]); %#ok<AGROW>
		slow_pow{idx} = [];
	end
end
end