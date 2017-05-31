function Devices = create_dsm_devices(hObject, Model, Devices)
%CREATE_DSM_DEVICES    fügt jedem Gerät eine DSM-Instanz hinzu
%    DEVICES = CREATE_DSM_DEVICES(HOBJECT, MODEL, DEVICES) erzeugt nach den in
%    der MODEL-Struktur vorhandenen Daten Instanzen von DSM-Geräten und fügt
%    diese den jeweiligen Geräteinstanzen hinzu.
%    HOBJECT liefert Zugriff auf das aufrufende GUI für die Ausgabe des
%    Fortschrittes in einem Statusbalken. 

%    Franz Zeilinger - 17.08.2010

% Falls in vorhergehender Funktion ein Fehler aufgetreten ist, Abbruch:
if isempty(Devices)
	Devices = [];
	return;
end

waitbar_start; % Messen der Zeit, die benötigt wird - Start
dev_count = 0; % Zähler für Geräteanzahl (für Statusanzeige)

try
	% Durchlaufen aller Geräteklassen:
	for i=1:numel(Devices.Elements_Varna)
		% Name der aktuellen Geräteklasse:
		name = Devices.Elements_Varna{i};
		% Durchlaufen aller Geräteinstanzen der aktuellen Geräteklasse:
		for j=1:numel(Devices.(name))
			% DSM-Instanz der Geräteinstanz hinzufügen:
			Devices.(name)(j).DSM = DSM_Device(Devices.(name)(j),...
				Model.Args.([name,'_dsm']){:});
			dev_count = dev_count + 1;
		end
		% Fortschrittsbalken updaten & überprüfen ob ein Abbruch durch User
		% erfolgt ist:
		if waitbar_update (hObject, 5, dev_count, Devices.Total_Number_Dev)
			% Geräteerzeugung abbrechen:
			return;
		end
	end
	
	% Anzeigen, dass in Devices-Struktur nun DSM-Instanzen enthalten sind:
	Devices.DSM_included = 1;
	
catch ME
	% Falls Fehler aufgetreten ist, User mitteilen, bei welcher Geräteklasse
	% dies passiert ist sowie die Fehlermeldung ausgeben:
	error_titl = 'Fehler beim Erzeugen der DSM - Geräteinstanzen';
	error_text={...
		'Fehler beim Erzeugen der Instanzen für';...
		[' - ',Devices.Elements_Names{i}];
		'';
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen können:
	Devices = [];
	return;
end
end
