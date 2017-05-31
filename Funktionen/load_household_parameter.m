function Households = load_household_parameter(Path, Name, Model) %#ok<INUSL>
%LOAD_HOUSEHOLD_PARAMETER   Kurzbeschreibung fehlt.
%    Ausf�hrliche Beschreibung fehlt!

% Franz Zeilinger - 14.09.2011

% { Variablenname, minimale Anzahl Personen, maximale Anzahl Personen, Genaue
% Bezeichnung };
Households.Types = {...
	'sing_vt', 1, 1, 'Single Vollzeit';...
	'coup_vt', 2, 2, 'Paar Vollzeit';...
	'sing_pt', 1, 1, 'Single Teilzeit';...
	'coup_pt', 2, 2, 'Paar Teilzeit';...
	'sing_rt', 1, 1, 'Single Pension';...
	'coup_rt', 2, 2, 'Paar Pension';...
% 	'fami_2v', 3, 6, 'Familie, 2 Mitglieder Vollzeit';...
% 	'fami_1v', 3, 6, 'Familie, 1 Mitglied Vollzeit';...
% 	'fami_rt', 3, 7, 'Familie mit Pensionist(en)';...
	};

% Anzahl der Haushalte:
for i = 1:size(Households.Types,1)
	Households.Number.(Households.Types{i,1}) = 5;
end

% { Ger�tename, Ausstattung in %, Standardabweichung der Ausstattung in % vom 
%   Mittelwert, maximale Anzahl an Ger�ten }
Households.Device_Distribution.sing_vt = {...
	'K�hlschr�nke',   100.0, 30, 2;...
	'Gefrierger�te',   36.4, 30, 2;...
	'Geschirrsp�ler',  64.2, 30, 2;...
	'Waschmaschinen',  86.6, 30, 2;...
	'W�schetrockner',  14.9, 30, 2;...
	'Fernseher',      118.0, 30, 3;...
	'Desktop PCs',     89.8, 30, 3;...
	};
Households.Device_Distribution.coup_vt = {...
	'K�hlschr�nke',   102.0, 30, 2;...
	'Gefrierger�te',   67.3, 30, 2;...
	'Geschirrsp�ler',  82.9, 30, 2;...
	'Waschmaschinen',  96.1, 30, 2;...
	'W�schetrockner',  35.4, 30, 2;...
	'Fernseher',      169.0, 30, 3;...
	'Desktop PCs',    136.0, 30, 3;...
	};
Households.Device_Distribution.sing_pt = {...
	'K�hlschr�nke',    81.8, 30, 2;...
	'Gefrierger�te',   36.4, 30, 2;...
	'Geschirrsp�ler',  39.4, 30, 2;...
	'Waschmaschinen',  78.8, 30, 2;...
	'W�schetrockner',  12.1, 30, 2;...
	'Fernseher',       90.9, 30, 3;...
	'Desktop PCs',     84.8, 30, 3;...
	};
Households.Device_Distribution.coup_pt = {...
	'K�hlschr�nke',   109.0, 30, 2;...
	'Gefrierger�te',   90.9, 30, 2;...
	'Geschirrsp�ler',  72.7, 30, 2;...
	'Waschmaschinen',  90.9, 30, 2;...
	'W�schetrockner',  18.2, 30, 2;...
	'Fernseher',      182.0, 30, 3;...
	'Desktop PCs',    127.0, 30, 3;...
	};
Households.Device_Distribution.sing_rt = {...
	'K�hlschr�nke',    94.5, 30, 2;...
	'Gefrierger�te',   52.5, 30, 2;...
	'Geschirrsp�ler',  47.8, 30, 2;...
	'Waschmaschinen',  91.7, 30, 2;...
	'W�schetrockner',  14.2, 30, 2;...
	'Fernseher',      133.0, 30, 3;...
	'Desktop PCs',     34.6, 30, 3;...
	};
Households.Device_Distribution.coup_rt = {...
	'K�hlschr�nke',   121.0, 30, 2;...
	'Gefrierger�te',  103.0, 30, 2;...
	'Geschirrsp�ler',  75.7, 30, 2;...
	'Waschmaschinen',  94.5, 30, 2;...
	'W�schetrockner',  32.5, 30, 2;...
	'Fernseher',      182.0, 30, 3;...
	'Desktop PCs',     75.3, 30, 3;...
	};
Households.Device_Distribution.fami_2v = {...
	'K�hlschr�nke',   137.0, 30, 2;...
	'Gefrierger�te',  111.0, 30, 2;...
	'Geschirrsp�ler',  87.7, 30, 2;...
	'Waschmaschinen',  95.6, 30, 2;...
	'W�schetrockner',  51.7, 30, 2;...
	'Fernseher',      253.0, 30, 3;...
	'Desktop PCs',    227.0, 30, 3;...
	};
Households.Device_Distribution.fami_1v = {...
	'K�hlschr�nke',   121.0, 30, 2;...
	'Gefrierger�te',   92.6, 30, 2;...
	'Geschirrsp�ler',  88.7, 30, 2;...
	'Waschmaschinen',  96.3, 30, 2;...
	'W�schetrockner',  44.3, 30, 2;...
	'Fernseher',      189.0, 30, 3;...
	'Desktop PCs',    159.0, 30, 3;...
	};
Households.Device_Distribution.fami_rt = {...
	'K�hlschr�nke',   142.0, 30, 2;...
	'Gefrierger�te',  124.0, 30, 2;...
	'Geschirrsp�ler',  76.1, 30, 2;...
	'Waschmaschinen',  94.8, 30, 2;...
	'W�schetrockner',  46.2, 30, 2;...
	'Fernseher',      249.0, 30, 3;...
	'Desktop PCs',    139.0, 30, 3;...
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
	% auslesen der bekannten Ausstattungsgrade:
	degr_tv_set = Households.Device_Distribution.(typ){6,2};
	degr_PC_NBs = Households.Device_Distribution.(typ){7,2};
	% Ausstattungsfaktor anhand der Ausstattung mit Fernsehger�ten bzw. PCs ermitteln:
	fact_av_dev = degr_tv_set / equ_degr_a_v{1,2};
	fact_office = degr_PC_NBs / (equ_degr_office{1,2} + equ_degr_office{2,2});
	% Nun die Ger�te entsprechend anpassen, und der Haushaltsausstattung hinzuf�gen:
	Households.Device_Distribution.(typ)(end-1:end,:) = [];
	for i = 1:size(equ_degr_a_v,1)
		equ_degr_a_v{i,2} = equ_degr_a_v{i,2} * fact_av_dev;
		Households.Device_Distribution.(typ)(end+1,:) = ...
			{equ_degr_a_v{i,:}, 30, 3};
	end
	for i = 1:size(equ_degr_office,1)
		equ_degr_office{i,2} = equ_degr_office{i,2} * fact_office;
		Households.Device_Distribution.(typ)(end+1,:) = ...
			{equ_degr_office{i,:}, 30, 3};
	end
	
	% aus den angegebenen Ger�ten der Haushaltstypen die bekannten Ger�tetypen
	% ermitteln:
	for i=1:size(Households.Device_Distribution.(typ),1)
		% �berpr�fen, ob Array leer ist:
		if ~isempty(Known_Devices)
			% Falls nicht, �berpr�fen, ob es das Ger�t bereits gibt:
			idx = find(strcmpi(Known_Devices(:,2),...
				Households.Device_Distribution.(typ)(i,1)), 1);
			if ~isempty(idx)
				% Falls ja, n�chstes Ger�t heranziehen:
				continue;
			end
		end
		% Falls Array leer, oder das Ger�t noch nicht vorhanden, dieses zu den bekannten
		% Ger�ten hinzuf�gen:
		Known_Devices(end+1,:) = Model.Devices_Pool(strcmpi(...
			Model.Devices_Pool(:,2),Households.Device_Distribution.(typ)(i,1)),:); %#ok<AGROW>
	end
	
	% Die Ausstattung der Haushalte ermitteln:
	Number_Devices = zeros(size(Known_Devices,1),Households.Number.(typ));
	Number_Persons = zeros(1,Households.Number.(typ));
	for i=1:size(Households.Device_Distribution.(typ),1)
		% Index ermitteln, zu welchem bekannten Ger�tetyp das aktuelle Ger�t geh�rt, um
		% damit das Ergebnis-Array korrekt aufzubauen:
		name = Households.Device_Distribution.(typ){i,1};
		idx = strcmpi(Known_Devices(:,2),name);
		for j=1:Households.Number.(typ)
			% Ausstattung mit diesem Ger�t:
			level_equ = Households.Device_Distribution.(typ){i,2}/100;
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
			% Mit der Anzahl an im Haushalt lebenden Personen multiplizieren (da
			% s�mtliche Lastg�nge definiert sind durch Ger�teeinsatzwahrscheinlichkeit
			% pro Person, muss sich auch dies in der Anzahl der Ger�te wiederspieglen -
			% So ist in einem Zwei-Personenhaushalt die Wahrscheinlichkeit f�r ein
			% aktives Ger�te doppelt so hoch wie in einem Ein-Personenhaushalt. Durch die
			% doppelte Anzahl an Ger�teerzeugungen wird der Ger�teeinsatz doppelt
			% wahrscheinlich):
			num_dev = num_dev * num_per;
			% Im Ergebnis-Array speichern:
			Number_Devices(idx,j) = num_dev;
		end
	end
	% Ergebnisse in die Ausgabestruktur speichern:
	Households.Number_Devices.(typ) = Number_Devices;
	Households.Number_Dev_Tot.(typ) = sum(Number_Devices,2);
	Households.Number_Persons.(typ) = Number_Persons;
	Households.Number_Per_Tot.(typ) = sum(Number_Persons);
end
Households.Known_Devices_Pool = Known_Devices;
end

