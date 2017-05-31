function Devices = create_dsm_devices(hObject, Model, Devices)
%CREATE_DSM_DEVICES    f�gt jedem Ger�t eine DSM-Instanz hinzu
%    DEVICES = CREATE_DSM_DEVICES(HOBJECT, MODEL, DEVICES) erzeugt nach den in
%    der MODEL-Struktur vorhandenen Daten Instanzen von DSM-Ger�ten und f�gt
%    diese den jeweiligen Ger�teinstanzen hinzu.
%    HOBJECT liefert Zugriff auf das aufrufende GUI f�r die Ausgabe des
%    Fortschrittes in einem Statusbalken. 

%    Franz Zeilinger - 17.08.2010

% Falls in vorhergehender Funktion ein Fehler aufgetreten ist, Abbruch:
if isempty(Devices)
	Devices = [];
	return;
end

waitbar_start; % Messen der Zeit, die ben�tigt wird - Start
dev_count = 0; % Z�hler f�r Ger�teanzahl (f�r Statusanzeige)

try
	% Durchlaufen aller Ger�teklassen:
	for i=1:numel(Devices.Elements_Varna)
		% Name der aktuellen Ger�teklasse:
		name = Devices.Elements_Varna{i};
		% Durchlaufen aller Ger�teinstanzen der aktuellen Ger�teklasse:
		for j=1:numel(Devices.(name))
			% DSM-Instanz der Ger�teinstanz hinzuf�gen:
			Devices.(name)(j).DSM = DSM_Device(Devices.(name)(j),...
				Model.Args.([name,'_dsm']){:});
			dev_count = dev_count + 1;
		end
		% Fortschrittsbalken updaten & �berpr�fen ob ein Abbruch durch User
		% erfolgt ist:
		if waitbar_update (hObject, 5, dev_count, Devices.Total_Number_Dev)
			% Ger�teerzeugung abbrechen:
			return;
		end
	end
	
	% Anzeigen, dass in Devices-Struktur nun DSM-Instanzen enthalten sind:
	Devices.DSM_included = 1;
	
catch ME
	% Falls Fehler aufgetreten ist, User mitteilen, bei welcher Ger�teklasse
	% dies passiert ist sowie die Fehlermeldung ausgeben:
	error_titl = 'Fehler beim Erzeugen der DSM - Ger�teinstanzen';
	error_text={...
		'Fehler beim Erzeugen der Instanzen f�r';...
		[' - ',Devices.Elements_Names{i}];
		'';
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zur�ckgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen k�nnen:
	Devices = [];
	return;
end
end
