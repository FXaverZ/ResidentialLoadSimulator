function Result = simulate_devices_for_load_profiles_parallel(hObject, Devices, ...
	Households,	Time)
%SIMULATE_DEVICES_FOR_LOAD_PROFILES_PARALLEL   Kurzbeschreibung fehlt!
%    Ausführliche Beschreibung fehlt!

%    Franz Zeilinger - 16.09.2011

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Gerätearten
% - 2. Dimension: Phasen 1 bis 3
% - 3. Dimension: Geräteinstanz
% - 4. Dimension: Zeitpunkte
Power_parallel = zeros([size(Devices.Elements_Varna,2), 3, max(Devices.Number_Dev),...
	(Time.Number_Steps)]);

% Ersten Zeitpunkt simulieren und dabei alle Geräte-Einsatzpläne auf laufende
% Matlabzeit umrechnen:
device = cell(1,size(Devices.Elements_Varna,2));
step = 1;
time = Time.Date_Start;
for i = 1:size(Devices.Elements_Varna,2)
	% Für jedes Element im Cell-Array Elements_Varna (Variablennamen)
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
		% berechnet wird!
		dev = dev.next_step(time, 0);
		Power_parallel(i,:,dev.ID_Index,step) = dev.Power_Input;
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
	% Für parallele Bearbeitung die DEVICES-Struktur in ein Cell-Array umwandeln,
	% damit diese in der parfor-Schleife verarbeitet werden kann: 
	device{i} = Devices.(Devices.Elements_Varna{i});
end

% Messen der Zeit, die benötigt wird - Start:
waitbar_start;
% Für paralle Bearbeitung verschieden Daten in eigenen Variblen speichern, um
% Kommunikationsaufwand zu reduzieren:
number_steps = Time.Number_Steps;
date_start = Time.Date_Start;
base = Time.Base;
num_devices = max(Devices.Number_Dev);
% Ein Ergebnis Cell-Array erstellen, dass in der parfor-Schleife bearbeitet werden
% kann (anscheinend kann ein 4D-Array nicht verabeitet werden, ein 3D-Array schon!
% Siehe z.B. SIMULATE_DEVICES_PARALLEL):
pow = cell(size(Devices.Elements_Varna,2),1);
% Berechnen der Reaktionen der Verbraucher für die restlichen Zeitpunkte:
parfor i = 1:size(Devices.Elements_Varna,2)
	% Zwischenergebnis Array; enthält die Leistugsdaten aufgteilt auf die Phasen, die
	% Einzelgeräte und die Zeitschritte für eine Gerätegruppe:
	btw_result = zeros([3, num_devices, number_steps]);
	for step = 2:number_steps
		% Aktuellen Zeitpunkt ermitteln:
		time = date_start + (step-1)*base/86400;
		% Reaktion der Verbraucher ermitteln
		for j = 1:size(device{i},2)
			% Geräteinstanz auslesen
			dev = device{i}(j);
			% Nächsten Zeitschritt des Gerätes berechnen:
			dev = dev.next_step(time, base);
			% aktuelle Leistungsaufnahme in Zwischenergebnis-Array speichern:
			btw_result(:,j,step) = dev.Power_Input;
			% die Änderungen in der Geräteinstanz in das DEVICES-Array
			% zurückschreiben:
			device{i}(j) = dev;
		end
	end
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	pow{i} = btw_result;
end

% ACHTUNG! Nachfolgend wurde der ursprüngliche Code verändert, weil eine Permutation
%     einen gewaltigen Speicherbedarf hat, und so immer zum OUT_OF_MEMORY-Fehler
%     führt. Daher verzicht auf Permutation und bilden eines neuen Ergebnis-Arrays,
%     dass dann in weiterer folge gesondert behandelt werden muss!
%     (siehe POSTPROCESS_RESULTS_FOR_LOADPROFILES)

% Nun die einzelnen Zwischenergenisse abarbeiten:
for i = 1:size(Devices.Elements_Varna,2)
	% ersten Zeitpunkt aus erster Schleife übernehmen:
	pow{i}(:,:,1) = squeeze(Power_parallel(i,:,:,1));
	% Zwischenergenis korrekt eintragen:
	Power_parallel(i,:,:,:) = pow{i};
end

% Das Endergebnis in der Result-Struktur speichern:
Result.Raw_Data.Households_Power_parallel = Power_parallel;
end