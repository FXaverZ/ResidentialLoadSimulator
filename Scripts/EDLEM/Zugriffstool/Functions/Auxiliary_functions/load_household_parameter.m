function Households = load_household_parameter() 
%LOAD_HOUSEHOLD_PARAMETER   generiert Haushaltsparameter 
%    HOUSEHOLDS = LOAD_HOUSEHOLD_PARAMETER() erzeugt eine Struktur HOUSEHOLDS in der
%    s�mtliche Parameter, betreffend die Haushalte, zusammengefasst sind. Diese
%    Funktion entspricht einer Definitionsdatei, innerhalb der die
%    Haushaltszusammensetzung sowie die Ger�teausstattung definiert werden. Die hier
%    eingetragenen Daten stammen aus dem Projekt ADRES bzw. aus weiteren Umfragen
%    (detaillierter Aufteilung von "Audio-Video-Ger�te" und "B�roger�te").
%    
%    N�here Informationen gibt der Endbericht des Projekts EDLEM.

% Franz Zeilinger - 30.11.2011

% Definition der Haushalte sowie deren Personenanzahl
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
	'fami_rt', 3, 6, 'Familie mit Pensionist(en)';...
	};

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
% Zusatzger�ten geschlossen. Daten zu der Aufteiling: siehe DA Zeilinger 2010 bzw.
% Endbericht EDLEM:
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

for k = 1:size(Households.Types,1)
	typ = Households.Types{k,1};
	% Auslesen der bekannten Ausstattungsgrade:
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
end
end

