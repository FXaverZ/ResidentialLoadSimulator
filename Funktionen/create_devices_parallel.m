function Devices = create_devices_parallel(hObject, Model)
%CREATE_DEVICES    erzeugt Geräteinstanzen für Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Geräteinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Geräte erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (für Statusanzeige).

%    Franz Zeilinger - 10.08.2011

% Für spätere Überprüfung, ob Geräteinstanzen für eine weitere Verwendung
% gebraucht werden können, die Anzahl der Personen in der Geräte-Struktur
% speichern:
Devices.Number_User = Model.Number_User;  

%Auflistung der verwendeten Geräte im Modell:
Devices.Elements_Varna = {};  % Variablennamen für automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollständige Namen der jeweiligen Geräte 
                              %     z.B. für Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Geräte
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?
waitbar_start;                % Messen der Zeit, die benötigt wird - Start

% Vorbereiten der Arrays für die Geräte-Instanzen der Gerätestruktur:
device = cell(size(Model.Devices_Pool,1),1);
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Geräteklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Funktionen-Handle auf zuständige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		device{i} = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{end+1} = name;
		Devices.Elements_Names{end+1} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{end+1} = Model.Devices_Pool{i,3};
	end
end

try
	% Erzeugen der jeweiligen Geräteinstanzen:
		names = Devices.Elements_Varna;
		dev_handles = Devices.Elements_Funha;
		total_number_dev = 0;
		num_user = Model.Number_User;
		args = Model.Args;
		parfor j=1:numel(names)
			for i=1:num_user
				% Variablenname der aktuellen Geräteklasse:
				name = names{j};
				% Funktionen-Handle auf zuständige Klasse auslesen
				dev_handle = dev_handles{j};
				% Geräteinstanz erzeugen:
				dev = dev_handle(args.(name){:});
				% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen:
				if dev.Activity
					% Geräteinstanz in jeweiligen Array speichern:
					device{j}(end+1) = dev;
					% Anzahl der erzeugten Geräte aktualisieren:
					total_number_dev = total_number_dev + 1;
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
		'';
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen können:
	Devices = [];
	return;
end

for i = 1:size(Devices.Elements_Varna,2)
	Devices.(Devices.Elements_Varna{i}) = device{i};
	Devices.Total_Number_Dev = total_number_dev;
end
end
