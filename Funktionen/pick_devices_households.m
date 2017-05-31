function Households = pick_devices_households (Households, Devices)
%PICK_DEVICES_HOUSEHOLDS    erstellt Zuordnung der Geräte zu den Haushalten.
%    HOUSEHOLDS = PICK_DEVICES_HOUSEHOLDS (HOUSEHOLDS, DEVICES) fügt der
%    Datenstruktur HOUSEHOLDS ein Feld DEVICES hinzu, das für die jeweilige
%    Haushaltskategorie die Zuordnung der einzelnen Geräte der DEVICES-Struktur zu
%    den einzelnen Haushalten enthält. Dies erfolgt in Form eines Arrays.
%
%    Z.B. für den Haushaltstyp 'Haushalt_1' kann dieses Array folgendermaßen
%    ausgelesen werden:
%
%        hh_devices = Households.Devices.Haushalt_1;
%
%    Das Array hh_devices hat drei Dimensionen:
%        1. Dimension: die unterschiedlichen Gerätetypen
%        2. Dimension: die einzelnen Haushalte
%        3. Dimension: die einzelnen Geräte
%
%     Wenn z.B. ein Haushalt (Nr. 10) zwei Kühlschränke hat (IDs 15 und 17) und
%     hierbei Kühlschränke die Geräteklasse mit der Nr. 3 sind (also das 3. Gerät das
%     bearbeitet wurde) erhält man aus den Ergebnisarray durch
%
%         hh_devices (3, 10, :)
%
%            ans(:,:,1) =
%                 15
%            ans(:,:,2) =
%                 17
%
%    die Geräteindizes. So lassen sich dann die einzelnen Profile (welche ja
%    gemeinsam in einem Array erzeugt werden) den jeweiligen Haushalten zuordnen! Um
%    ein Gesamtprofil zu erstellen wird über alle Gerätetypen und Haushaltsnummern
%    iteriert, die Geräteindizes ausgelesen, deren Profile ausgelesen und zum
%    Haushaltsprofil hinzugefügt.

% Erstellt von:            Franz Zeilinger - 05.12.2011
% Letzte Änderung durch:   Franz Zeilinger - 29.11.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;
Number_Devices = Devices.Number_created_Known;

% Nun ein Array erstellen, dass die Zuordnung der einzelnen Geräte (mit ihrer
% jweiligen ID) zu den Haushalten enthält:
hh_devices = [];

% die bekannten Geräte durchgehen und diese gem. den zuvor ermittelten
% Geräteanzahlen dem jeweiligen Haushalt zuordnen:
dev_idx = Devices.Index_created_Known;
for i = 1:numel(Devices.Elements_Varna_Known)
	idx = strcmpi(Devices.Elements_Varna, Devices.Elements_Varna_Known(i));
	run_idx = 1;
	for j = 1:Households.Statistics.(typ).Number
		num_dev = Number_Devices(i,j);
		count_d = 1;
		% Nullwert einfügen, damit dieses Array auch wirklich Einträge für jeden
		% Haushalt enthält:
		hh_devices(idx,j,count_d) = 0; %#ok<AGROW>
		while num_dev > 0
			hh_devices(idx,j,count_d) = dev_idx(i,run_idx); %#ok<AGROW>
			run_idx = run_idx + 1;
			count_d = count_d + 1;
			num_dev = num_dev - 1;
		end
	end
end

% nun auch die unbekannten Geräte, die mit Hilfe der Parameter eines großen
% Kollektivs ermittelt wurden, auf die einzelnen Haushalte aufteilen:
for i = 1:numel(Devices.Elements_Varna_Unknown)
	idx = strcmpi(Devices.Elements_Varna, Devices.Elements_Varna_Unknown(i));
	run_idx = 1;
	num_dev_total = Devices.Number_Dev(idx);
	% Geräteausstattung pro Person ermitteln:
	level_equ = num_dev_total/Households.Statistics.(typ).Number_Per_Tot;
	% Index des aktuellen Haushaltes:
	hh_idx = 1;
	while_counter = 0;
	while num_dev_total > 0
		while_counter = while_counter + 1;
		% Anpassung an die Anzahl an Personen im Haushalt durchführen:
		level_equ_hh = level_equ * Households.Statistics.(typ).Number_Persons(hh_idx);
		% Diesen Wert zufällig um den Mittelwert variieren:
		level_equ_hh = vary_parameter(level_equ_hh,30);
		% sichere Anzahl an Geräten (entspricht Anzahl an 100% in Ausstattung):
		sure_num_dev = floor(level_equ_hh);
		% der Rest der Ausstattung (ohne sicher vorhandene Geräte):
		level_equ_hh = level_equ_hh - sure_num_dev;
		% Anzahl der weiteren Geräte ermitteln:
		num_dev = sure_num_dev + (rand() < level_equ_hh);
		% Überprüfen, ob die ermittelte Anzahl an Geräten nicht die noch vorhandene
		% Anzahl an Geräten übersteigt:
		if num_dev > num_dev_total
			% Falls dies zutrifft, können nur mehr die verbleibenden Geräte dem
			% Haushalt zugeteilt werden:
			num_dev = num_dev_total;
		end
		if num_dev > 0
			count_d = 1;
			while num_dev > 0
				while_counter = while_counter + 1;
				% Zuerst nachsehen, ob noch ein "leerer" Platz für das Geräte zur
				% Verfügung steht (Bei vorhergehenden Durchläufen könnte ja kein
				% Gerät zugewiesen worden sein). Dazu zuerst überprüfen, ob das
				% Ergebnis-Array hh_devices bereits so groß ist:
				if find(idx) <= size(hh_devices,1) &&...     % Gerätezeile vorh.?
						hh_idx <= size(hh_devices,2) && ...  % Haush.spalte vorh.?
						count_d <= size(hh_devices,3)        % Gerätedim. vorh.?
					% Ist kein Gerät vorhanden?
					if hh_devices(idx,hh_idx,count_d) == 0
						% Wenn ja, das aktuelle Gerät an diese Stelle setzen:
						hh_devices(idx,hh_idx,count_d) = run_idx; %#ok<AGROW>
						count_d = count_d + 1;
						num_dev = num_dev - 1;
						num_dev_total = num_dev_total - 1;
						run_idx = run_idx + 1;
					else
						% Wenn nein, springen zur nächsten "Ebene" (in die 3.
						% Dimension der Zurodnungsmatrix:
						count_d = count_d + 1;
					end
				else
					% Falls Array an dieser Stelle noch nicht existent, kann Gerät
					% eingefügt werden:
					hh_devices(idx,hh_idx,count_d) = run_idx; %#ok<AGROW>
					count_d = count_d + 1;
					num_dev = num_dev - 1;
					num_dev_total = num_dev_total - 1;
					run_idx = run_idx + 1;
				end
			end
		end
		% Index des aktuellen Haushalts anpassen:
		hh_idx = hh_idx + 1;
		if hh_idx > Households.Statistics.(typ).Number
			hh_idx = 1;
		end
		if while_counter > 1000000
			error('pick_devices:endless_loop',...
				'Kein Schleifenabbruch in pick_devices_households!');
		end
	end
end

% Speichern der Gerätezurodnung:
Households.Devices.(typ).Allocation = hh_devices;
% Speichern der akutellen Geräteinstanzen zur Haushaltskategorie:
Households.Devices.(typ).Devices = Devices;