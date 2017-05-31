function Power_parallel = simulate_devices_for_load_profiles_parallel(Devices, Time)
%SIMULATE_DEVICES_FOR_LOAD_PROFILES_PARALLEL   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

%    Franz Zeilinger - 18.11.2011

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Ger�tearten
% - 2. Dimension: Phasen 1 bis 3 jeweils P & Q (insges. 6)
% - 3. Dimension: Ger�teinstanz
% - 4. Dimension: Zeitpunkte
% Power_parallel = zeros([size(Devices.Elements_Varna,2), 6, max(Devices.Number_Dev),...
% 	(Time.Number_Steps)]);

% F�r paralle Bearbeitung verschieden Daten in eigenen Variblen speichern, um
% Kommunikationsaufwand zu reduzieren:
number_steps = Time.Number_Steps;
date_start = Time.Date_Start;
base = Time.Base;
num_devices = max(Devices.Number_Dev);
% Ein Ergebnis Cell-Array erstellen, dass in der parfor-Schleife bearbeitet werden
% kann (anscheinend kann ein 4D-Array nicht verabeitet werden, ein 3D-Array schon!
% Siehe z.B. SIMULATE_DEVICES_PARALLEL):
pow = cell(size(Devices.Elements_Varna,2),1);
% Ersten Zeitpunkt simulieren und dabei alle Ger�te-Einsatzpl�ne auf laufende
% Matlabzeit umrechnen:
device = cell(1,size(Devices.Elements_Varna,2));
step = 1;
time = Time.Date_Start;
for i = 1:size(Devices.Elements_Varna,2)
	% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen, arbeitet die
	% einzelnen Ger�teklassen ab):
	% Leeres Zwischenergebnisarray erstellen:
	% - 1. Dimension: Phasen 1 bis 3 jeweils P & Q (insges. 6)
	% - 2. Dimension: Ger�teinstanzen (maximal m�gliche Anzahl an Ger�ten)
	% - 3. Dimension: Zeitpunkte
	btw_result = zeros([6, num_devices, number_steps]);
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% F�r Ger�te mit schneller Berechnungsm�glichkeit sind nun alle
		% Vorbereitungen abgeschlossen. F�r Ger�te mit normaler Simulation wird nun
		% der erste Zeitschritt berechnet:
		if ~dev.Fast_computing_at_no_dsm
			% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
			% berechnet wird!
			dev = dev.next_step(time, 0);
			btw_result(1:3,j,step) = dev.Power_Input;
			btw_result(4:6,j,step) = dev.Power_Input_Reactive;
		end
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
	% F�r parallele Bearbeitung die DEVICES-Struktur in ein Cell-Array umwandeln,
	% damit diese in der parfor-Schleife verarbeitet werden kann: 
	device{i} = Devices.(Devices.Elements_Varna{i});
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	pow{i} = btw_result; 
end

% Messen der Zeit, die ben�tigt wird - Start:
waitbar_start;
% Zeitvektor erstellen:
time_vec = Time.Date_Start:Time.Base/Time.day_to_sec:Time.Date_End;

% Berechnen der Reaktionen der Verbraucher f�r die restlichen Zeitpunkte:
parfor i = 1:size(Devices.Elements_Varna,2)
	% Zwischenergebnis Array; enth�lt die Leistungsdaten aufgteilt auf die Phasen, 
	% die Einzelger�te und die Zeitschritte f�r eine Ger�tegruppe:
	btw_result = pow{i};
	dev = device{i};
	if ~isempty(dev)
		dev = device{i}(1); % Ein Ger�t der aktuellen Ger�teklasse auslesen, um 
		                    %     die Eignung der Ger�teklasse f�r eine schnelle 
		                    %     Berechnung zu ermitteln
	else
		continue;           % keine Ger�te vorhanden --> zur n�chsten Ger�teart gehen
	end
	if dev.Fast_computing_at_no_dsm
		% Schnelle Berechnung ist m�glich:
		% (In Zukunft k�nnte das ev. von Klasse zu Klasse verschieden sein, daher
		% w�re eine Verlagerung des kommenden Codes in eine eigene Methode von
		% Vorteil. Da im vorliegendnen Fall nur die Ger�te der Klasse
		% "SCHEDULED_OPERATION" behandelt werden und sich auch ein Speichervorteil
		% ergibt, wird davon abgesehen!
		% Reaktion der Verbraucher ermitteln
		for j = 1:size(device{i},2)
			% Ger�teinstanz auslesen
			dev = device{i}(j);
			% Stand-by-Leistung auf alle Zeitpunkte setzen, die Betriebszeitpunkte
			% werden dann mit den jeweiligen Betriebswerten �berschrieben (--> wenn
			% Ger�t nicht in Betrieb dann in Stand-by, im Fall, dass es keinen
			% Stand-by-Verbrauch gibt, ist dieser Null und bleibt null...)
			btw_result(dev.Phase_Index,j,:) = dev.Power_Stand_by;
			btw_result(dev.Phase_Index + 3,j,:) = dev.Power_Stand_by * ...
				tan(acos(dev.Cos_Phi_Stand_by));
			% Nun die einzelnen Eintragungen im Einsatzplan durchgehen und
			% entsprechend die Leistungen eintragen:
			for step = 1:size(dev.Time_Schedule,1)
				% Zeitpunkte finden, in denen das Ger�t aktiv ist:
				idx = time_vec >= dev.Time_Schedule(step,1) & ...
					time_vec < dev.Time_Schedule(step,2);
				% Zu diesen Zeitpunkten aktuelle Leistungsaufnahme entsprechend dem
				% Einsatzplan sezten
				btw_result(dev.Phase_Index,j,idx) = dev.Time_Schedule(step,3);
				% Mit Hilfe des aktuell g�ltigen cos(phi) die Blindleistungsaufnahme
				% ermitteln und entsprechend sezten:
				btw_result(dev.Phase_Index + 3,j,idx) = dev.Time_Schedule(step,3)*...
					tan(acos(dev.Time_Schedule(step,4)));
			end	
		end
	else
		% Herk�mmliche Berechnung mit Hilfe der NEXT_STEP-Methode der jeweiligen
		% Ger�teklasse:
		% F�r jeden Zeitpunkt
		for step = 2:number_steps
			% Aktuellen Zeitpunkt ermitteln:
			time = date_start + (step-1)*base/86400;
			% Reaktion der Verbraucher ermitteln
			for j = 1:size(device{i},2)
				% Ger�teinstanz auslesen
				dev = device{i}(j);
				% N�chsten Zeitschritt des Ger�tes berechnen:
				dev = dev.next_step(time, base);
				% aktuelle Leistungsaufnahme in Zwischenergebnis-Array speichern:
				btw_result(1:3,j,step) = dev.Power_Input;
				btw_result(4:6,j,step) = dev.Power_Input_Reactive;
				% die �nderungen in der Ger�teinstanz in das DEVICES-Array
				% zur�ckschreiben:
				device{i}(j) = dev;
			end
		end
	end
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	pow{i} = btw_result; 
end

% ACHTUNG! Nachfolgend wurde der urspr�ngliche Code ver�ndert, weil eine Permutation
%     einen gewaltigen Speicherbedarf hat, und so immer zum OUT_OF_MEMORY-Fehler
%     f�hrt. Daher verzicht auf Permutation und bilden eines neuen Ergebnis-Arrays,
%     dass dann in weiterer folge gesondert behandelt werden muss!
%     (siehe POSTPROCESS_RESULTS_FOR_LOADPROFILES)

% Nun die einzelnen Zwischenergenisse abarbeiten:
% Power_parallel = zeros([size(Devices.Elements_Varna,2), 6, max(Devices.Number_Dev),...
% 	(Time.Number_Steps)]);
for i = 1:size(Devices.Elements_Varna,2)
	% Zwischenergenis korrekt eintragen:
	Power_parallel(i,:,:,:) = pow{1}; %#ok<AGROW>
	% Zwischengergebnis l�schen, damit Speicher wieder freigegeben wird!
	pow(1) = [];
end
end