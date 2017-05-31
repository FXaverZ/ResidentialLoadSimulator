function Devices = create_devices_parallel(hObject, Model)
%CREATE_DEVICES    erzeugt Geräteinstanzen für Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Geräteinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Geräte erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (für Statusanzeige).

% Erstellt von:            Franz Zeilinger - 10.08.2011
% Letzte Änderung durch:   Franz Zeilinger - 12.12.2012

% Für spätere Überprüfung, ob Geräteinstanzen für eine weitere Verwendung
% gebraucht werden können, die Anzahl der Personen in der Geräte-Struktur
% speichern:
Devices.Number_User = Model.Number_User;

%Auflistung der verwendeten Geräte im Modell:
Devices.Elements_Varna = {};  % Variablennamen für automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollständige Namen der jeweiligen Geräte
%     z.B. für Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Elements_Eq_Le = {};  % Ausstattungsgrad mit diesem Gerät
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Geräte
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?
waitbar_start;                % Messen der Zeit, die benötigt wird - Start

% Vorbereiten der Arrays für die Geräte-Instanzen der Gerätestruktur:
% Wieviele Geräteklassen werden simuliert? Antwort gibt Device_Assembly_Simulation,
% hier ist eine eins für jede aktive Geräteklasse eingetragen, daher diese Struktur
% in ein Array umwandeln (zuerst Struktur in Zellenarray, dann Zellenarray in Matrix)
% und dann alles aufaddieren:
dev_num = sum(cell2mat(struct2cell(Model.Device_Assembly_Simulation)));
device = cell(dev_num,1);
args = cell(dev_num,1);
% Einen Zähler initialisieren, der den laufenden Geräteklassenindex entspricht (wenn
% nicht alle Geräte ausgewählt, entspricht dieser NICHT dem Schleifenindex!)
dev_num = 0;
% Nun über alle möglichen Geräteklassen iterieren:
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Geräteklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Geräteklassenindex erhöhen:
		dev_num = dev_num + 1;
		% Funktionen-Handle auf zuständige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		device{dev_num} = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{dev_num} = name;
		Devices.Elements_Names{dev_num} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{dev_num} = Model.Devices_Pool{i,3};
		% eine zusätzliche Zuordnung mitspeichern: diese beschreibt einen
		% Ausstattungsrad mit einem bestimmten Gerätetyp: bei der Erzeugung der
		% Gerätinstanzen wird auf diesen Wert Rücksicht genommen, d.h. für einen Wert
		% von 50 ergibt sich hier, dass nur 50% der erzeugten Geräte-Instanzen auch
		% für die Simulation übernommen werden. Per Default wird für alle Geräte der
		% Wert 100 (%) eingetragen, sprich, jede erzeugte Instanz wird auch
		% übernommen! 
		Devices.Elements_Eq_Le{end+1} = 100;
		% Ein eigenes Argumenten-Array aufbauen für parfor-Schleife:
		args{dev_num} = Model.Args.(name);
	end
end

% Falls Gerätegruppen vorhanden sind, den Austattungsgrad der einzelnen Elemente
% übernehmen:
if Model.Device_Groups.Present
	% über die möglichen Gerätegruppen iterieren:
	for i=1:size(Model.Device_Groups_Pool,1)
		% gibt es diese Gerätegruppe überhaupt?
		if ~isfield(Model.Device_Groups, Model.Device_Groups_Pool{i,1})
			continue;
		end
		% Mitglieder dieser Gruppe auslesen:
		member = Model.Device_Groups.(Model.Device_Groups_Pool{i,1}).Members;
		% über die Mitglieder iterieren:
		for j=1:size(member,1)
			% Zuordnung des Gerätetyps in den vorhandenen Geräten finden:
			idx = find(strcmp(Devices.Elements_Varna, member{j,1}));
			if isempty(idx)
				continue;
			end
			% Austattung entsprechend abspeichern:
			Devices.Elements_Eq_Le{idx} = member{j,end};
		end
	end
end

try
	% Erzeugen der jeweiligen Geräteinstanzen:
	dev_handles = Devices.Elements_Funha;
	total_number_dev = 0;
	num_user = Model.Number_User;
	equ_level = Devices.Elements_Eq_Le;
	parfor j=1:numel(Devices.Elements_Varna)
		% Funktionen-Handle auf zuständige Klasse auslesen
		dev_handle = dev_handles{j};
		for i=1:num_user
			% Austattungsgrad:
			equ_l = equ_level{j};
			% solange der Austattungsgrad positiv, Geräte generieren:
			while equ_l > 0
				% Geräteinstanz erzeugen:
				dev = dev_handle(args{j}{:});
				% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen, dazu
				% eine Zufallszahl zwischen 0 und 100 erzeugen:
				fort = rand()*100;
				if fort <= equ_l;
					% Geräteinstanz in jeweiligen Array speichern:
					device{j}(end+1) = dev;
					% Anzahl der erzeugten Geräte aktualisieren:
					total_number_dev = total_number_dev + 1;
				end
				% Reduzieren des Ausstattungsgrades:
				equ_l = equ_l - 100;
			end
		end
	end
catch ME
	% Falls Fehler aufgetreten ist, dies dem User mitteilen, sowie die Fehlermeldung
	% ausgeben: 
	error_titl = 'Fehler beim Erzeugen der Geräteinstanzen';
	error_text={...
		'Fehler beim Erzeugen der Geräteinstanzen für';...
		'';...
		ME.message};
	errordlg(error_text, error_titl);
	% Leere Matrix zurückgeben, damit nachfolgende Programmteile den
	% aufgetretenen Fehler erkennen können:
	Devices = [];
	return;
end

% Die erzeugten Geräteinstanzen im ursprünglichen Format in die Devices-Strukutr
% übernehmen:
for i = 1:size(Devices.Elements_Varna,2)
	Devices.(Devices.Elements_Varna{i}) = device{i};
	Devices.Total_Number_Dev = total_number_dev;
end
end
