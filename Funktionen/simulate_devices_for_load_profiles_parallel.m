function Result = simulate_devices_for_load_profiles_parallel(hObject, Devices, ...
	Households,	Time)
%SIMULATE_DEVICES_FOR_LOAD_PROFILES_PARALLEL   Kurzbeschreibung fehlt!
%    Ausf�hrliche Beschreibung fehlt!

%    Franz Zeilinger - 22.08.2011

% ACHTUNG! Debug-Einstellung bzw. f�r Testzwecke:
typ = Households.Types{1};

% Erstellen eines Arrays mit den Leistungsdaten:
% - 1. Dimension: Phasen 1 bis 3
% - 2. Dimension: Ger�tearten
% - 3. Dimension: Ger�teinstanz
% - 4. Dimension: Zeitpunkte
Power = zeros([3 size(Devices.Elements_Varna,2) max(Devices.Number_Dev)...
	(Time.Number_Steps)]);

% Ersten Zeitpunkt simulieren und dabei alle Ger�te-Einsatzpl�ne auf laufende
% Matlabzeit umrechnen:
device = cell(1,size(Devices.Elements_Varna,2));
step = 1;
time = Time.Date_Start;
for i = 1:size(Devices.Elements_Varna,2)
	% F�r jedes Element im Cell-Array Elements_Varna (Variablennamen)
	for j = 1:size(Devices.(Devices.Elements_Varna{i}),2)
		dev = Devices.(Devices.Elements_Varna{i})(j);
		dev = dev.adapt_for_simulation(Time.Date_Start, Time.Date_End, Time.Base);
		% delta_t = 0, da hier nur der erste Zeitpunkt (nicht Zeitraum)
		% berechnet wird!
		dev = dev.next_step(time, 0);
		Power(:,i,dev.ID_Index,step) = dev.Power_Input;
		Devices.(Devices.Elements_Varna{i})(j) = dev;
	end
	% F�r parallele Bearbeitung die DEVICES-Struktur in ein Cell-Array umwandeln,
	% damit diese in der parfor-Schleife verarbeitet werden kann: 
	device{i} = Devices.(Devices.Elements_Varna{i});
end

% Messen der Zeit, die ben�tigt wird - Start:
waitbar_start;
% F�r paralle Bearbeitung verschieden Daten in eigenen Variblen speichern, um
% Kommunikationsaufwand zu reduzieren:
number_steps = Time.Number_Steps;
date_start = Time.Date_Start;
base = Time.Base;
num_devices = max(Devices.Number_Dev);
% Ein Ergebnis Cell-Array erstellen, dass in der parfor-Schleife bearbeitet werden
% kann (anscheinend kann ein 4D-Array nicht verabeitet werden, ein 3D-Array schon!
% Siehe z.B. SIMULATE_DEVICES_PARALLEL):
pow = cell(size(Devices.Elements_Varna,2),2);
% Berechnen der Reaktionen der Verbraucher f�r die restlichen Zeitpunkte:
parfor i = 1:size(Devices.Elements_Varna,2)
	% Zwischenergebnis Array; enth�lt die Leistugsdaten aufgteilt auf die Phasen, die
	% Einzelger�te und die Zeitschritte f�r eine Ger�tegruppe:
	btw_result = zeros([3, num_devices, number_steps]);
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
			btw_result(:,j,step) = dev.Power_Input;
			% die �nderungen in der Ger�teinstanz in das DEVICES-Array
			% zur�ckschreiben:
			device{i}(j) = dev;
		end
	end
	% Das Zwischenergebnis in das Ergebnis-Cell-Array speichern:
	pow{i} = btw_result;
end

% Nach der Berechnung aus dem Ergebnis-Cell-Array das gew�nschte 4D-Ergebnis-Array
% erstellen. Zuerst die bisherige Ergebnismatrixdimensionen permutieren, damit diese
% eine f�r die n�chsten Schritte korrekt zu verarbeitende Form bekommt:
Power = permute(Power, [2 1 3 4]);
% Nun die einzelnen Zwischenergenisse abarbeiten:
for i = 1:size(Devices.Elements_Varna,2)
	btw_result = pow{i};
	% ersten Zeitpunkt aus erster Schleife �bernehmen:
	btw_result(:,:,1) = squeeze(Power(i,:,:,1));
	% Zwischenergenis korrekt eintragen:
	Power(i,:,:,:) = btw_result;
end
% Nun die vorherige Permutation r�ckg�ngig machen, damit wieder das urspr�ngliche
% Ergebnis-Array f�r die nachflogenden Funktionen zur Verf�gung steht:
Power = permute(Power, [2 1 3 4]);

% Das Endergebnis in der Result-Struktur speichern:
Result.Raw_Data.Households_Power = Power;
end