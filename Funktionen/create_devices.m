function Devices = create_devices(hObject, Model)
%CREATE_DEVICES    erzeugt Ger�teinstanzen f�r Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Ger�teinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Ger�te erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (f�r Statusanzeige).

%    Franz Zeilinger - 17.08.2010

% F�r sp�tere �berpr�fung, ob Ger�teinstanzen f�r eine weitere Verwendung
% gebraucht werden k�nnen, die Anzahl der Personen in der Ger�te-Struktur
% speichern:
Devices.Number_User = Model.Number_User;  

%Auflistung der verwendeten Ger�te im Modell:
Devices.Elements_Varna = {};  % Variablenname f�r automatisches Abarbeiten
Devices.Elements_Names = {};  % Volle Namen f�r Legendenbeschriftung
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Ger�te
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?
waitbar_start;                % Messen der Zeit, die ben�tigt wird - Start

% Vorbereiten der Arrays f�r die Ger�te-Instanzen der Ger�testruktur:
for i=1:size(Model.Elements_Pool,1)
	% Variablenname der aktuellen Ger�teklasse:
	name = Model.Elements_Pool{i,1};
	if Model.Device_Assembly.(name)
		% Funktionen-Handle auf zust�ndige Klasse auslesen
		dev_handle = Model.Elements_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		Devices.(name) = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{end+1} = name;
		Devices.Elements_Names{end+1} = Model.Elements_Pool{i,2};
		Devices.Elements_Funha{end+1} = Model.Elements_Pool{i,3};
	end
end

try
	% Erzeugen der jeweiligen Ger�teinstanzen:
	if Model.Number_User == 1
		% Wenn Anzahl Personen = 1 eingegeben wurde zeigt das einen
		% Sonderfall an: Es wird f�r jede Ger�teklasse zumindest ein
		% aktives Ger�t ermittelt!
		for j=1:numel(Devices.Elements_Varna)
			% Variablenname der aktuellen Ger�teklasse:
			name = Devices.Elements_Varna{j};
			% Funktionen-Handle auf zust�ndige Klasse auslesen
			dev_handle = Devices.Elements_Funha{j};
			% Ger�teinstanz erzeugen:
			dev = dev_handle(Model.Args.(name){:});
			while ~dev.Activity
				% Solange Ger�teinstanz erzeugen, bis ein aktives Ger�t
				% erzeugt wird:
				dev = dev_handle(Model.Args.(name){:});
			end
			% Ger�teinstanz in jeweiligen Array speichern:
			Devices.(name)(1) = dev;
			% Anzahl der erzeugten Ger�te aktualisieren:
			Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
		end
	else
		for i=1:Model.Number_User
			% Fortschrittsbalken updaten & �berpr�fen ob ein Abbruch durch User
			% erfolgt ist:
			if waitbar_update (hObject, 5, i, Model.Number_User)
				% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
				% aufgetretenen Fehler erkennen k�nnen:
				Devices = [];
				% Ger�teerzeugung abbrechen:
				return;
			end
			for j=1:numel(Devices.Elements_Varna)
				% Variablenname der aktuellen Ger�teklasse:
				name = Devices.Elements_Varna{j};
				% Funktionen-Handle auf zust�ndige Klasse auslesen
				dev_handle = Devices.Elements_Funha{j};
				% Ger�teinstanz erzeugen:
				dev = dev_handle(Model.Args.(name){:});
				% �berpr�fen, ob Ger�t �berhaupt im Einsatz, sonst verwerfen:
				if dev.Activity
					% Ger�teinstanz in jeweiligen Array speichern:
					Devices.(name)(end+1) = dev;
					% Anzahl der erzeugten Ger�te aktualisieren:
					Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
				end
			end
		end
	end
catch ME
	% Falls Fehler aufgetreten ist, User mitteilen, bei welcher Ger�teklasse
	% dies passiert ist sowie die Fehlermeldung ausgeben:
	error_titl = 'Fehler beim Erzeugen der Ger�teinstanzen';
	error_text={...
		'Fehler beim Erzeugen der Ger�teinstanzen f�r';...
		'';...
		[' - ',Devices.Elements_Names{j}];
		'';
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen k�nnen:
	Devices = [];
	return;
end
end
