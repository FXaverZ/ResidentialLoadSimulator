function Households = load_household_parameter(Path, Name, Model)
%LOAD_HOUSEHOLD_PARAMETER   Kurzbeschreibung fehlt.
%    Ausführliche Beschreibung fehlt!

% Franz Zeilinger - 23.08.2011

% { Variablenname, minimale Anzahl Personen, maximale Anzahl Personen, Genaue
% Bezeichnung };
Households.Types = {...
	'sing_vt', 1, 1, 'Single Vollzeit';...
	'coup_vt', 2, 2, 'Paar Vollzeit';...
	'sing_pt', 1, 1, 'Single Teilzeit';...
	'coup_pt', 2, 2, 'Paar Teilzeit';...
	'sing_rt', 1, 1, 'Single Pension';...
	'coup_rt', 2, 2, 'Paar Pension';...
	'fami_2v', 3, 6, 'Familie, 2 Mitglieder Vollzeit';...
	'fami_1v', 3, 6, 'Familie, 1 Mitglied Vollzeit';...
	'fami_rt', 3, 7, 'Familie mit Pensionist(en)';...
	};

% ACHTUNG! Debug-Einstellung bzw. für Testzwecke:
typ = Households.Types{1};

% Anzahl der Haushalte:
Households.Number.sing_vt = 50;
% { Gerätename, Ausstattung in %, Standardabweichung der Ausstattung in % vom 
%   Mittelwert, maximale Anzahl an Geräten }
Households.Device_Distribution.sing_vt = {...
	'Kühlschränke',   100.0, 30, 2;...
	'Gefriergeräte',   36.4, 30, 2;...
	'Geschirrspüler',  64.2, 30, 2;...
	'Waschmaschinen',  86.6, 30, 2;...
	'Wäschetrockner',  14.9, 30, 2;...
	'Fernseher',      118.0, 30, 3;...
	'Desktop PCs',     89.8, 30, 3;...
	};

% aus den angegebenen Geräten der Haushaltstypen die bekannten Gerätetypen
% ermitteln:
Known_Devices = {}; %leeres Ergebnis-Array
for i=1:size(Households.Device_Distribution.(typ),1)
	% Überprüfen, ob Array leer ist:
	if ~isempty(Known_Devices)
		% Falls nicht, überprüfen, ob es das Gerät bereits gibt:
		idx = find(strcmpi(Known_Devices(:,2),...
			Households.Device_Distribution.(typ)(i,1)), 1);
		if ~isempty(idx)
			% Falls ja, nächstes Gerät heranziehen:
			continue;
		end
	end
	% Falls Array leer, oder das Gerät noch nicht vorhanden, dieses zu den bekannten
	% Geräten hinzufügen:
	Known_Devices(end+1,:) = Model.Devices_Pool(strcmpi(...
		Model.Devices_Pool(:,2),Households.Device_Distribution.(typ)(i,1)),:); %#ok<AGROW>
end
Households.Known_Devices_Pool = Known_Devices;

% Die Ausstattung der Haushalte ermitteln:
Number_Devices = zeros(size(Known_Devices,1),Households.Number.(typ));
Number_Persons = zeros(1,Households.Number.(typ));
for i=1:size(Households.Device_Distribution.(typ),1)
	% Index ermitteln, zu welchem bekannten Gerätetyp das aktuelle Gerät gehört, um
	% damit das Ergebnis-Array korrekt aufzubauen:
	name = Households.Device_Distribution.(typ){i,1};
	idx = strcmpi(Known_Devices(:,2),name);
	for j=1:Households.Number.(typ)
		% Ausstattung mit diesem Gerät:
		level_equ = Households.Device_Distribution.(typ){i,2}/100;
		% sichere Anzahl an Geräten (entspricht Anzahl an 100% in Ausstattung):
		sure_num_dev = floor(level_equ);
		% der Rest der Ausstattung (ohne sicher vorhandene Geräte):
		level_equ = level_equ - sure_num_dev;
		% Anzahl der weiteren Geräte ermitteln:
		num_dev = sure_num_dev + (rand() < level_equ);
		% Anzahl der Im Haushalt lebenden Personen ermitteln:
		min_per = Households.Types{1,2};
		max_per = Households.Types{1,3};
		if min_per <= max_per
			num_per = min_per;
		else
			num_per = min_per + round(rand()*(max_per - min_per));
		end
		Number_Persons(j) = num_per;
		% Mit der Anzahl an im Haushalt lebenden Personen multiplizieren (da
		% sämtliche Lastgänge definiert sind durch Geräteeinsatzwahrscheinlichkeit
		% pro Person, muss sich auch dies in der Anzahl der Geräte wiederspieglen -
		% So ist in einem Zwei-Personenhaushalt die Wahrscheinlichkeit für ein
		% aktives Geräte doppelt so hoch wie in einem Ein-Personenhaushalt. Durch die
		% doppelte Anzahl an Geräteerzeugungen wird der Geräteeinsatz doppelt
		% wahrscheinlich):
		num_dev = num_dev * num_per;
		% Im Ergebnis-Array speichern:
		Number_Devices(idx,j) = num_dev;
	end
end

% Ergebnisse in die Ausgabestruktur speichern:
Households.Number_Devices.(typ) = Number_Devices;
Households.Number_Devices.Total = sum(Number_Devices,2);
Households.Number_Persons.(typ) = Number_Persons;
Households.Number_Persons.Total = sum(Number_Persons);
end

