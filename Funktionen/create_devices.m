function Devices = create_devices(hObject, Model)
%CREATE_DEVICES    erzeugt Geräteinstanzen für Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Geräteinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Geräte erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (für Statusanzeige).

%    Franz Zeilinger - 17.08.2010

% Für spätere Überprüfung, ob Geräteinstanzen für eine weitere Verwendung
% gebraucht werden können, die Anzahl der Personen in der Geräte-Struktur
% speichern:
Devices.Number_User = Model.Number_User;  

%Auflistung der verwendeten Geräte im Modell:
Devices.Elements_Varna = {};  % Variablenname für automatisches Abarbeiten
Devices.Elements_Names = {};  % Volle Namen für Legendenbeschriftung
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Geräte
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?
waitbar_start;                % Messen der Zeit, die benötigt wird - Start

% Vorbereiten der Arrays für die Geräte-Instanzen der Gerätestruktur:
for i=1:size(Model.Elements_Pool,1)
	% Variablenname der aktuellen Geräteklasse:
	name = Model.Elements_Pool{i,1};
	if Model.Device_Assembly.(name)
		% Funktionen-Handle auf zuständige Klasse auslesen
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
	% Erzeugen der jeweiligen Geräteinstanzen:
	if Model.Number_User == 1
		% Wenn Anzahl Personen = 1 eingegeben wurde zeigt das einen
		% Sonderfall an: Es wird für jede Geräteklasse zumindest ein
		% aktives Gerät ermittelt!
		for j=1:numel(Devices.Elements_Varna)
			% Variablenname der aktuellen Geräteklasse:
			name = Devices.Elements_Varna{j};
			% Funktionen-Handle auf zuständige Klasse auslesen
			dev_handle = Devices.Elements_Funha{j};
			% Geräteinstanz erzeugen:
			dev = dev_handle(Model.Args.(name){:});
			while ~dev.Activity
				% Solange Geräteinstanz erzeugen, bis ein aktives Gerät
				% erzeugt wird:
				dev = dev_handle(Model.Args.(name){:});
			end
			% Geräteinstanz in jeweiligen Array speichern:
			Devices.(name)(1) = dev;
			% Anzahl der erzeugten Geräte aktualisieren:
			Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
		end
	else
		for i=1:Model.Number_User
			% Fortschrittsbalken updaten & überprüfen ob ein Abbruch durch User
			% erfolgt ist:
			if waitbar_update (hObject, 5, i, Model.Number_User)
				% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
				% aufgetretenen Fehler erkennen können:
				Devices = [];
				% Geräteerzeugung abbrechen:
				return;
			end
			for j=1:numel(Devices.Elements_Varna)
				% Variablenname der aktuellen Geräteklasse:
				name = Devices.Elements_Varna{j};
				% Funktionen-Handle auf zuständige Klasse auslesen
				dev_handle = Devices.Elements_Funha{j};
				% Geräteinstanz erzeugen:
				dev = dev_handle(Model.Args.(name){:});
				% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen:
				if dev.Activity
					% Geräteinstanz in jeweiligen Array speichern:
					Devices.(name)(end+1) = dev;
					% Anzahl der erzeugten Geräte aktualisieren:
					Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
				end
			end
		end
	end
catch ME
	% Falls Fehler aufgetreten ist, User mitteilen, bei welcher Geräteklasse
	% dies passiert ist sowie die Fehlermeldung ausgeben:
	error_titl = 'Fehler beim Erzeugen der Geräteinstanzen';
	error_text={...
		'Fehler beim Erzeugen der Geräteinstanzen für';...
		'';...
		[' - ',Devices.Elements_Names{j}];
		'';
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen können:
	Devices = [];
	return;
end
end
