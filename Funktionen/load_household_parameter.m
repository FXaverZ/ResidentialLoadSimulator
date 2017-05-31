function Households = load_household_parameter(~, ~, Model) 
%LOAD_HOUSEHOLD_PARAMETER   Kurzbeschreibung fehlt.
%    HOUSEHOLDS = LOAD_HOUSEHOLD_PARAMETER(PATH, NAME, MODEL)
%    Funtion ist vorbereitet, �ber die Parameter PATH und NAME auf eine Datei
%    zugreifen zu k�nnen, aus der die Konfiguration der Haushalte geladen werden
%    kann. Muss aber noch bei Bedarf implementiert werden!
%    Ausf�hrliche Beschreibung fehlt!

% Erstellt von:            Franz Zeilinger - 14.09.2011
% Letzte �nderung durch:   Franz Zeilinger - 08.03.2013

% { Variablenname, minimale Anzahl Personen, maximale Anzahl Personen, Genaue
% Bezeichnung };
Households.Types = Model.Households;

% Anzahl der Haushalte:
for i = 1:size(Households.Types,1)
	Households.Statistics.(Households.Types{i,1}).Number = Households.Types{i,5};
end

% { Ger�tename, Ausstattung in %, Standardabweichung der Ausstattung in % vom 
%   Mittelwert, maximale Anzahl an Ger�ten }
Households.Devices.home_1.Distribution = {...
	'K�hlschr�nke',     105.8, 30, 3;...
	'Gefrierger�te',     59.9, 30, 3;...
	'Waschmaschinen',    91.2, 30, 2;...
	'W�schetrockner',    11.8, 30, 2;...
	'Geschirrsp�ler',    49.6, 30, 2;...
	'Fernseher',        161.8, 30, 3;...
	'Desktop PCs',       48.2, 30, 3;...
	'W�rmepumpe'         75.0, 20, 1;...
% 	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',        12.5, 30, 2;...
	'Umw�lzpumpen',     100.0, 20, 2;...
% 	'Umw�lzpumpen',      69.2, 30, 2;...
	'Warmwasserboiler',  75.0, 20, 3;...
% 	'Warmwasserboiler',  29.2, 30, 3;...
	'Durchlauferhitzer',  8.3, 30, 1;...
	};
Households.Devices.home_2.Distribution = {...
	'K�hlschr�nke',     157.8, 30, 3;...
	'Gefrierger�te',     97.4, 30, 3;...
	'Waschmaschinen',    93.8, 30, 3;...
	'W�schetrockner',    35.8, 30, 3;...
	'Geschirrsp�ler',    80.7, 30, 3;...
	'Fernseher',        200.1, 30, 4;...
	'Desktop PCs',       84.9, 30, 3;...
	'W�rmepumpe'         75.0, 20, 1;...
% 	'W�rmepumpe'          5.1, 30, 1;...
	'Heizk�rper',         2.6, 30, 2;...
	'Umw�lzpumpen',     100.0, 20, 2;...
% 	'Umw�lzpumpen',      85.7, 30, 2;...
	'Warmwasserboiler',  75.0, 20, 3;...
% 	'Warmwasserboiler',  22.2, 30, 3;...
	'Durchlauferhitzer',  2.8, 30, 1;...
	};
Households.Devices.home_3.Distribution = {...
	'K�hlschr�nke',     183.4, 30, 4;...
	'Gefrierger�te',    111.2, 30, 3;...
	'Waschmaschinen',    92.3, 30, 3;...
	'W�schetrockner',    42.4, 30, 3;...
	'Geschirrsp�ler',    81.4, 30, 3;...
	'Fernseher',        282.1, 30, 5;...
	'Desktop PCs',      161.6, 30, 4;...
	'W�rmepumpe'         75.0, 20, 1;...
% 	'W�rmepumpe'          4.8, 30, 1;...
	'Heizk�rper',        14.3, 30, 2;...
	'Umw�lzpumpen',     100.0, 20, 2;...
% 	'Umw�lzpumpen',      72.0, 30, 2;...
	'Warmwasserboiler',  75.0, 20, 3;...
% 	'Warmwasserboiler',  43.5, 30, 3;...
	'Durchlauferhitzer',  4.3, 30, 1;...
	};
Households.Devices.hom_4p.Distribution = {...
	'K�hlschr�nke',     186.7, 30, 4;...
	'Gefrierger�te',    119.8, 30, 3;...
	'Waschmaschinen',    91.3, 30, 3;...
	'W�schetrockner',    44.1, 30, 3;...
	'Geschirrsp�ler',    86.8, 30, 3;...
	'Fernseher',        262.3, 30, 5;...
	'Desktop PCs',      212.7, 30, 5;...
	'W�rmepumpe'         75.0, 20, 1;...
% 	'W�rmepumpe'          9.3, 30, 1;...
	'Heizk�rper',         4.7, 30, 2;...
	'Umw�lzpumpen',     100.0, 20, 2;...
% 	'Umw�lzpumpen',      85.1, 30, 2;...
	'Warmwasserboiler',  75.0, 20, 3;...
% 	'Warmwasserboiler',  30.0, 30, 3;...
	'Durchlauferhitzer',  3.3, 30, 1;...
	};
Households.Devices.flat_1.Distribution = {...
	'K�hlschr�nke',     108.6, 30, 3;...
	'Gefrierger�te',     26.3, 30, 2;...
	'Waschmaschinen',    82.5, 30, 2;...
	'W�schetrockner',     9.0, 30, 2;...
	'Geschirrsp�ler',    50.3, 30, 2;...
	'Fernseher',        112.4, 30, 3;...
	'Desktop PCs',       70.0, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',        13.2, 30, 2;...
	'Umw�lzpumpen',      19.6, 30, 2;...
	'Warmwasserboiler',  45.8, 30, 3;...
	'Durchlauferhitzer',  8.3, 30, 1;...
	};
Households.Devices.flat_2.Distribution = {...
	'K�hlschr�nke',     124.8, 30, 3;...
	'Gefrierger�te',     53.7, 30, 3;...
	'Waschmaschinen',    86.2, 30, 3;...
	'W�schetrockner',    12.5, 30, 3;...
	'Geschirrsp�ler',    69.3, 30, 3;...
	'Fernseher',        155.4, 30, 4;...
	'Desktop PCs',      116.5, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',         8.1, 30, 2;...
	'Umw�lzpumpen',      39.5, 30, 2;...
	'Warmwasserboiler',  41.2, 30, 3;...
	'Durchlauferhitzer',  2.9, 30, 1;...
	};
Households.Devices.flat_3.Distribution = {...
	'K�hlschr�nke',     123.1, 30, 4;...
	'Gefrierger�te',     47.8, 30, 3;...
	'Waschmaschinen',    90.5, 30, 3;...
	'W�schetrockner',    19.8, 30, 3;...
	'Geschirrsp�ler',    77.7, 30, 3;...
	'Fernseher',        188.2, 30, 5;...
	'Desktop PCs',      176.5, 30, 4;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',         0.0, 30, 2;...
	'Umw�lzpumpen',      37.5, 30, 2;...
	'Warmwasserboiler',  43.8, 30, 3;...
	'Durchlauferhitzer',  0.0, 30, 1;...
	};
Households.Devices.fla_4p.Distribution = {...
	'K�hlschr�nke',     135.3, 30, 4;...
	'Gefrierger�te',     56.4, 30, 3;...
	'Waschmaschinen',    86.9, 30, 3;...
	'W�schetrockner',    26.5, 30, 3;...
	'Geschirrsp�ler',    76.9, 30, 3;...
	'Fernseher',        206.2, 30, 5;...
	'Desktop PCs',      206.0, 30, 5;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',         0.0, 30, 2;...
	'Umw�lzpumpen',      21.4, 30, 2;...
	'Warmwasserboiler',  66.7, 30, 3;...
	'Durchlauferhitzer',  6.7, 30, 1;...
	};

% --- Ausstattung f�r EDLEM ---
Households.Devices.sing_vt.Distribution = {...
	'K�hlschr�nke',     100.0, 30, 2;...
	'Gefrierger�te',     36.4, 30, 2;...
	'Geschirrsp�ler',    64.2, 30, 2;...
	'Waschmaschinen',    86.6, 30, 2;...
	'W�schetrockner',    14.9, 30, 2;...
	'Fernseher',        118.0, 30, 3;...
	'Desktop PCs',       89.8, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',        12.5, 30, 2;...
	'Umw�lzpumpen',      69.2, 30, 2;...
	'Warmwasserboiler',  29.2, 30, 3;...
	'Durchlauferhitzer',  8.3, 30, 1;...
	};
Households.Devices.coup_vt.Distribution = {...
	'K�hlschr�nke',     102.0, 30, 2;...
	'Gefrierger�te',     67.3, 30, 2;...
	'Geschirrsp�ler',    82.9, 30, 2;...
	'Waschmaschinen',    96.1, 30, 2;...
	'W�schetrockner',    35.4, 30, 2;...
	'Fernseher',        169.0, 30, 3;...
	'Desktop PCs',      136.0, 30, 3;...
	'W�rmepumpe'          5.1, 30, 1;...
	'Heizk�rper',         2.6, 30, 2;...
	'Umw�lzpumpen',      85.7, 30, 2;...
	'Warmwasserboiler',  22.2, 30, 3;...
	'Durchlauferhitzer',  2.8, 30, 1;...
	};
Households.Devices.sing_pt.Distribution = {...
	'K�hlschr�nke',      81.8, 30, 2;...
	'Gefrierger�te',     36.4, 30, 2;...
	'Geschirrsp�ler',    39.4, 30, 2;...
	'Waschmaschinen',    78.8, 30, 2;...
	'W�schetrockner',    12.1, 30, 2;...
	'Fernseher',         90.9, 30, 3;...
	'Desktop PCs',       84.8, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',        13.2, 30, 2;...
	'Umw�lzpumpen',      19.6, 30, 2;...
	'Warmwasserboiler',  45.8, 30, 3;...
	'Durchlauferhitzer',  8.3, 30, 1;...
	};
Households.Devices.coup_pt.Distribution = {...
	'K�hlschr�nke',     109.0, 30, 2;...
	'Gefrierger�te',     90.9, 30, 2;...
	'Geschirrsp�ler',    72.7, 30, 2;...
	'Waschmaschinen',    90.9, 30, 2;...
	'W�schetrockner',    18.2, 30, 2;...
	'Fernseher',        182.0, 30, 3;...
	'Desktop PCs',      127.0, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',         8.1, 30, 2;...
	'Umw�lzpumpen',      39.5, 30, 2;...
	'Warmwasserboiler',  41.2, 30, 3;...
	'Durchlauferhitzer',  2.9, 30, 1;...
	};
Households.Devices.sing_rt.Distribution = {...
	'K�hlschr�nke',      94.5, 30, 2;...
	'Gefrierger�te',     52.5, 30, 2;...
	'Geschirrsp�ler',    47.8, 30, 2;...
	'Waschmaschinen',    91.7, 30, 2;...
	'W�schetrockner',    14.2, 30, 2;...
	'Fernseher',        133.0, 30, 3;...
	'Desktop PCs',       34.6, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',        13.2, 30, 2;...
	'Umw�lzpumpen',      19.6, 30, 2;...
	'Warmwasserboiler',  45.8, 30, 3;...
	'Durchlauferhitzer',  8.3, 30, 1;...
	};
Households.Devices.coup_rt.Distribution = {...
	'K�hlschr�nke',     121.0, 30, 2;...
	'Gefrierger�te',    103.0, 30, 2;...
	'Geschirrsp�ler',    75.7, 30, 2;...
	'Waschmaschinen',    94.5, 30, 2;...
	'W�schetrockner',    32.5, 30, 2;...
	'Fernseher',        182.0, 30, 3;...
	'Desktop PCs',       75.3, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',         8.1, 30, 2;...
	'Umw�lzpumpen',      39.5, 30, 2;...
	'Warmwasserboiler',  41.2, 30, 3;...
	'Durchlauferhitzer',  2.9, 30, 1;...
	};
Households.Devices.fami_2v.Distribution = {...
	'K�hlschr�nke',     137.0, 30, 2;...
	'Gefrierger�te',    111.0, 30, 2;...
	'Geschirrsp�ler',    87.7, 30, 2;...
	'Waschmaschinen',    95.6, 30, 2;...
	'W�schetrockner',    51.7, 30, 2;...
	'Fernseher',        253.0, 30, 3;...
	'Desktop PCs',      227.0, 30, 3;...
	'W�rmepumpe'          4.8, 30, 1;...
	'Heizk�rper',        14.3, 30, 2;...
	'Umw�lzpumpen',      72.0, 30, 2;...
	'Warmwasserboiler',  43.5, 30, 3;...
	'Durchlauferhitzer',  4.3, 30, 1;...
	};
Households.Devices.fami_1v.Distribution = {...
	'K�hlschr�nke',     121.0, 30, 2;...
	'Gefrierger�te',     92.6, 30, 2;...
	'Geschirrsp�ler',    88.7, 30, 2;...
	'Waschmaschinen',    96.3, 30, 2;...
	'W�schetrockner',    44.3, 30, 2;...
	'Fernseher',        189.0, 30, 3;...
	'Desktop PCs',      159.0, 30, 3;...
	'W�rmepumpe'          0.0, 30, 1;...
	'Heizk�rper',         0.0, 30, 2;...
	'Umw�lzpumpen',      37.5, 30, 2;...
	'Warmwasserboiler',  43.8, 30, 3;...
	'Durchlauferhitzer',  0.0, 30, 1;...
	};
Households.Devices.fami_rt.Distribution = {...
	'K�hlschr�nke',     142.0, 30, 2;...
	'Gefrierger�te',    124.0, 30, 2;...
	'Geschirrsp�ler',    76.1, 30, 2;...
	'Waschmaschinen',    94.8, 30, 2;...
	'W�schetrockner',    46.2, 30, 2;...
	'Fernseher',        249.0, 30, 3;...
	'Desktop PCs',      139.0, 30, 3;...
	'W�rmepumpe'          9.3, 30, 1;...
	'Heizk�rper',         4.7, 30, 2;...
	'Umw�lzpumpen',      85.1, 30, 2;...
	'Warmwasserboiler',  30.0, 30, 3;...
	'Durchlauferhitzer',  3.3, 30, 1;...
	};
% die oberen Listen anhand der bekannten Aufteilungen um weitere Ger�te erweitern.
% Hier wird insbesondere mit dem Ausstattungsgrad von Fernsehern und Desktop PCs (die
% in der Statistik als Notebook + PCs angef�hrt sind) auf die Ausstattung mit den
% Zusatzger�ten geschlossen. Daten zu der Aufteiling: siehe DA Zeilinger 2010.
equ_degr_a_v = {...
	'Fernseher',           22.27;...
	'Set-Top-Boxen',       15.97;...
	'Video-Equipment',     17.23;...
	'Game-Konsolen',       14.71;...
	'Hi-Fi-Ger�te',         9.24;...
	'Radios',              20.59;...
	};
equ_degr_office = {...
	'Desktop PCs',		   12.45;...
	'Notebooks',		   26.62;...
	'Monitore (PCs)',	   30.44;...	
	'Laserdrucker',		   17.51;...	
	'Tintenstrahldrucker', 23.21;...	
	'Diverse B�roger�te',   2.18;...
	};

Known_Devices = {}; %leeres Ergebnis-Array
for k = 1:size(Households.Types,1)
	typ = Households.Types{k,1};
	% wo befinden sich die Angaben f�r Fernseher?
	idx_tv_set = strcmpi(Households.Devices.(typ).Distribution(:,1),'fernseher');
	% auslesen der bekannten Ausstattungsgrade f�r Fernseher + sonstige
	% Einstellungen: 
	degr_tv_set = Households.Devices.(typ).Distribution(idx_tv_set,2:end);
	% L�schen der entsprechenden Zeile:
	Households.Devices.(typ).Distribution(idx_tv_set,:) = [];
	% Das gleiche f�r die PCs + Notebooks:
	idx_pc_des = strcmpi(Households.Devices.(typ).Distribution(:,1),'desktop pcs');
	degr_PC_NBs = Households.Devices.(typ).Distribution(idx_pc_des,2:end);
	Households.Devices.(typ).Distribution(idx_pc_des,:) = [];
	% Ausstattungsfaktor anhand der Ausstattung mit Fernsehger�ten bzw. PCs+Notebooks
	% ermitteln: 
	fact_av_dev = degr_tv_set{1} / equ_degr_a_v{1,2};
	fact_office = degr_PC_NBs{1} / equ_degr_office{1,2};
	% Nun die Ger�te entsprechend anpassen, und der Haushaltsausstattung hinzuf�gen:
	for i = 1:size(equ_degr_a_v,1)
		equ_degr_a_v{i,2} = equ_degr_a_v{i,2} * fact_av_dev;
		Households.Devices.(typ).Distribution(end+1,:) = ...
			{equ_degr_a_v{i,:}, degr_tv_set{2}, degr_tv_set{3}}; 
	end
	for i = 1:size(equ_degr_office,1)
		equ_degr_office{i,2} = equ_degr_office{i,2} * fact_office;
		Households.Devices.(typ).Distribution(end+1,:) = ...
			{equ_degr_office{i,:}, degr_PC_NBs{2}, degr_PC_NBs{3}};
	end
	
	% aus den angegebenen Ger�ten der Haushaltstypen die bekannten Ger�tetypen
	% ermitteln:
	for i=1:size(Households.Devices.(typ).Distribution,1)
		% �berpr�fen, ob Array leer ist:
		if ~isempty(Known_Devices)
			% Falls nicht, �berpr�fen, ob es das Ger�t bereits gibt:
			idx = find(strcmpi(Known_Devices(:,2),...
				Households.Devices.(typ).Distribution(i,1)), 1);
			if ~isempty(idx)
				% Falls ja, n�chstes Ger�t heranziehen:
				continue;
			end
		end
		% Falls Array leer, oder das Ger�t noch nicht vorhanden, dieses zu den bekannten
		% Ger�ten hinzuf�gen:
		Known_Devices(end+1,:) = Model.Devices_Pool(strcmpi(...
			Model.Devices_Pool(:,2),Households.Devices.(typ).Distribution(i,1)),:); %#ok<AGROW>
	end
	
	% Die Ausstattung der Haushalte ermitteln:
	Number_Devices = zeros(size(Known_Devices,1),Households.Statistics.(typ).Number);
	Number_Persons = zeros(1,Households.Statistics.(typ).Number);
	for i=1:size(Households.Devices.(typ).Distribution,1)
		% Index ermitteln, zu welchem bekannten Ger�tetyp das aktuelle Ger�t geh�rt,
		% um damit das Ergebnis-Array korrekt aufzubauen:
		name = Households.Devices.(typ).Distribution{i,1};
		idx = strcmpi(Known_Devices(:,2),name);
		for j=1:Households.Statistics.(typ).Number
			% Ausstattung mit diesem Ger�t:
			level_equ = Households.Devices.(typ).Distribution{i,2}/100;
			% sichere Anzahl an Ger�ten (entspricht Anzahl an 100% in Ausstattung):
			sure_num_dev = floor(level_equ);
			% der Rest der Ausstattung (ohne sicher vorhandene Ger�te):
			level_equ = level_equ - sure_num_dev;
			% Anzahl der weiteren Ger�te ermitteln:
			num_dev = sure_num_dev + (rand() < level_equ);
			% Anzahl der Im Haushalt lebenden Personen ermitteln:
			idx_2 = find(strcmp(Households.Types(:,1),typ));
			min_per = Households.Types{idx_2,2};
			max_per = Households.Types{idx_2,3};
			if min_per >= max_per
				num_per = min_per;
			else
				num_per = min_per + round(rand()*(max_per - min_per));
			end
			Number_Persons(j) = num_per;
			% Im Ergebnis-Array speichern:
			Number_Devices(idx,j) = num_dev;
		end
	end
	% Ergebnisse in die Ausgabestruktur speichern:
	Households.Devices.(typ).Number_Known = Number_Devices;
	Households.Devices.(typ).Number_Known_Tot = sum(Number_Devices,2);
	Households.Statistics.(typ).Number_Persons = Number_Persons;
	Households.Statistics.(typ).Number_Per_Tot = sum(Number_Persons);
end
Households.Devices.Pool_Known = Known_Devices;
end

