function Households = pick_devices_households (Households, Devices)
%PICK_DEVICES_HOUSEHOLDS   Kurzbeschreibung fehlt.
%    Ausf�hrliche Beschreibung fehlt!

%    Franz Zeilinger - 05.12.2011

% Auslesen der Haushaltskategorie, die berechnet wird:
typ = Households.Act_Type;
Number_Devices = Devices.Number_created_Known;

hh_devices = [];
% die bekannten Ger�te durchgehen und diese gem. den zuvor ermittelten Ger�teanzahlen
% dem jeweiligen Haushalt zuordnen:
dev_idx = Devices.Index_created_Known;
for i = 1:numel(Devices.Elements_Varna_Known)
	idx = strcmpi(Devices.Elements_Varna, Devices.Elements_Varna_Known(i));
	run_idx = 1;
	for j = 1:Households.Number.(typ)
		num_dev = Number_Devices(i,j);
		count_d = 1;
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
	level_equ = num_dev_total/Households.Number_Per_Tot.(typ);
	% Index des aktuellen Haushaltes:
	hh_idx = 1;
	while_counter = 0;
	while num_dev_total > 0
		while_counter = while_counter + 1;
		% Anpassung an die Anzahl an Personen im Haushalt durchf�hren:
		level_equ = level_equ * Households.Number_Persons.(typ)(hh_idx);
		% Diesen Wert zuf�llig um den Mittelwert variieren:
		level_equ = vary_parameter(level_equ,30);
		% sichere Anzahl an Ger�ten (entspricht Anzahl an 100% in Ausstattung):
		sure_num_dev = floor(level_equ);
		% der Rest der Ausstattung (ohne sicher vorhandene Ger�te):
		level_equ = level_equ - sure_num_dev;
		% Anzahl der weiteren Ger�te ermitteln:
		num_dev = sure_num_dev + (rand() < level_equ);
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
				hh_devices(idx,hh_idx,count_d) = run_idx; %#ok<AGROW>
				count_d = count_d + 1;
				num_dev = num_dev - 1;
				num_dev_total = num_dev_total - 1;
				run_idx = run_idx + 1;
			end
		end
		% Index des aktuellen Haushalts anpassen:
		hh_idx = hh_idx + 1;
		if hh_idx > Households.Number.(typ)
			hh_idx = 1;
		end
		if while_counter > 1000000
			error('pick_devices:endless_loop',...
				'Kein Schleifenabbruch in pick_devices_households!');
		end
	end
end
% Speichern der Ger�tezurodnung:
Households.Devices.(typ) = hh_devices;