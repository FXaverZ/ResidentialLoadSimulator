function Households = pick_devices_households (Households, Devices)
%PICK_DEVICES_HOUSEHOLDS    erstellt Zuordnung der Ger�te zu den Haushalten.
%    HOUSEHOLDS = PICK_DEVICES_HOUSEHOLDS (HOUSEHOLDS, DEVICES) f�gt der
%    Datenstruktur HOUSEHOLDS ein Feld DEVICES hinzu, das f�r die jeweilige
%    Haushaltskategorie die Zuordnung der einzelnen Ger�te der DEVICES-Struktur zu
%    den einzelnen Haushalten enth�lt. Dies erfolgt in Form eines Arrays.
%
%    Z.B. f�r den Haushaltstyp 'Haushalt_1' kann dieses Array folgenderma�en
%    ausgelesen werden:
%
%        hh_devices = Households.Devices.Haushalt_1;
%
%    Das Array hh_devices hat drei Dimensionen:
%        1. Dimension: die unterschiedlichen Ger�tetypen
%        2. Dimension: die einzelnen Haushalte
%        3. Dimension: die einzelnen Ger�te
%
%     Wenn z.B. ein Haushalt (Nr. 10) zwei K�hlschr�nke hat (IDs 15 und 17) und
%     hierbei K�hlschr�nke die Ger�teklasse mit der Nr. 3 sind (also das 3. Ger�t das
%     bearbeitet wurde) erh�lt man aus den Ergebnisarray durch
%
%         hh_devices (3, 10, :)
%
%            ans(:,:,1) =
%                 15
%            ans(:,:,2) =
%                 17
%
%    die Ger�teindizes. So lassen sich dann die einzelnen Profile (welche ja
%    gemeinsam in einem Array erzeugt werden) den jeweiligen Haushalten zuordnen! Um
%    ein Gesamtprofil zu erstellen wird �ber alle Ger�tetypen und Haushaltsnummern
%    iteriert, die Ger�teindizes ausgelesen, deren Profile ausgelesen und zum
%    Haushaltsprofil hinzugef�gt.

% Erstellt von:            Franz Zeilinger - 05.12.2011
% Letzte �nderung durch:   Franz Zeilinger - 29.11.2012

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;
Number_Devices = Devices.Number_created_Known;

% Nun ein Array erstellen, dass die Zuordnung der einzelnen Ger�te (mit ihrer
% jweiligen ID) zu den Haushalten enth�lt:
hh_devices = [];

% die bekannten Ger�te durchgehen und diese gem. den zuvor ermittelten
% Ger�teanzahlen dem jeweiligen Haushalt zuordnen:
dev_idx = Devices.Index_created_Known;
for i = 1:numel(Devices.Elements_Varna_Known)
	idx = strcmpi(Devices.Elements_Varna, Devices.Elements_Varna_Known(i));
	run_idx = 1;
	for j = 1:Households.Statistics.(typ).Number
		num_dev = Number_Devices(i,j);
		count_d = 1;
		% Nullwert einf�gen, damit dieses Array auch wirklich Eintr�ge f�r jeden
		% Haushalt enth�lt:
		hh_devices(idx,j,count_d) = 0; %#ok<AGROW>
		while num_dev > 0
			hh_devices(idx,j,count_d) = dev_idx(i,run_idx); %#ok<AGROW>
			run_idx = run_idx + 1;
			count_d = count_d + 1;
			num_dev = num_dev - 1;
		end
	end
end

% nun auch die unbekannten Ger�te, die mit Hilfe der Parameter eines gro�en
% Kollektivs ermittelt wurden, auf die einzelnen Haushalte aufteilen:
for i = 1:numel(Devices.Elements_Varna_Unknown)
	idx = strcmpi(Devices.Elements_Varna, Devices.Elements_Varna_Unknown(i));
	run_idx = 1;
	num_dev_total = Devices.Number_Dev(idx);
	% Ger�teausstattung pro Person ermitteln:
	level_equ = num_dev_total/Households.Statistics.(typ).Number_Per_Tot;
	% Index des aktuellen Haushaltes:
	hh_idx = 1;
	while_counter = 0;
	while num_dev_total > 0
		while_counter = while_counter + 1;
		% Anpassung an die Anzahl an Personen im Haushalt durchf�hren:
		level_equ_hh = level_equ * Households.Statistics.(typ).Number_Persons(hh_idx);
		% Diesen Wert zuf�llig um den Mittelwert variieren:
		level_equ_hh = vary_parameter(level_equ_hh,30);
		% sichere Anzahl an Ger�ten (entspricht Anzahl an 100% in Ausstattung):
		sure_num_dev = floor(level_equ_hh);
		% der Rest der Ausstattung (ohne sicher vorhandene Ger�te):
		level_equ_hh = level_equ_hh - sure_num_dev;
		% Anzahl der weiteren Ger�te ermitteln:
		num_dev = sure_num_dev + (rand() < level_equ_hh);
		% �berpr�fen, ob die ermittelte Anzahl an Ger�ten nicht die noch vorhandene
		% Anzahl an Ger�ten �bersteigt:
		if num_dev > num_dev_total
			% Falls dies zutrifft, k�nnen nur mehr die verbleibenden Ger�te dem
			% Haushalt zugeteilt werden:
			num_dev = num_dev_total;
		end
		if num_dev > 0
			count_d = 1;
			while num_dev > 0
				while_counter = while_counter + 1;
				% Zuerst nachsehen, ob noch ein "leerer" Platz f�r das Ger�te zur
				% Verf�gung steht (Bei vorhergehenden Durchl�ufen k�nnte ja kein
				% Ger�t zugewiesen worden sein). Dazu zuerst �berpr�fen, ob das
				% Ergebnis-Array hh_devices bereits so gro� ist:
				if find(idx) <= size(hh_devices,1) &&...     % Ger�tezeile vorh.?
						hh_idx <= size(hh_devices,2) && ...  % Haush.spalte vorh.?
						count_d <= size(hh_devices,3)        % Ger�tedim. vorh.?
					% Ist kein Ger�t vorhanden?
					if hh_devices(idx,hh_idx,count_d) == 0
						% Wenn ja, das aktuelle Ger�t an diese Stelle setzen:
						hh_devices(idx,hh_idx,count_d) = run_idx; %#ok<AGROW>
						count_d = count_d + 1;
						num_dev = num_dev - 1;
						num_dev_total = num_dev_total - 1;
						run_idx = run_idx + 1;
					else
						% Wenn nein, springen zur n�chsten "Ebene" (in die 3.
						% Dimension der Zurodnungsmatrix:
						count_d = count_d + 1;
					end
				else
					% Falls Array an dieser Stelle noch nicht existent, kann Ger�t
					% eingef�gt werden:
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

% Speichern der Ger�tezurodnung:
Households.Devices.(typ).Allocation = hh_devices;
% Speichern der akutellen Ger�teinstanzen zur Haushaltskategorie:
Households.Devices.(typ).Devices = Devices;