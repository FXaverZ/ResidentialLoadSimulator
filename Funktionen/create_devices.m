function Devices = create_devices(hObject, Model)
%CREATE_DEVICES    erzeugt Geräteinstanzen für Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Geräteinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Geräte erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (für Statusanzeige).

% Erstellt von:            Franz Zeilinger - 29.07.2011
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
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Geräteklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Funktionen-Handle auf zuständige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		Devices.(name) = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{end+1} = name;
		Devices.Elements_Names{end+1} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{end+1} = Model.Devices_Pool{i,3};
		% eine zusätzliche Zuordnung mitspeichern: diese beschreibt einen
		% Ausstattungsrad mit einem bestimmten Gerätetyp: bei der Erzeugung der
		% Gerätinstanzen wird auf diesen Wert Rücksicht genommen, d.h. für einen Wert
		% von 50 ergibt sich hier, dass nur 50% der erzeugten Geräte-Instanzen auch
		% für die Simulation übernommen werden. Per Default wird für alle Geräte der
		% Wert 100 (%) eingetragen, sprich, jede erzeugte Instanz wird auch
		% übernommen! 
		Devices.Elements_Eq_Le{end+1} = 100;
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
			if waitbar_update (hObject, 5, i, Model.Number_User*numel(Devices.Elements_Varna))
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
				% Austattungsgrad:
				equ_level = Devices.Elements_Eq_Le{j};
				% solange der Austattungsgrad positiv, Geräte generieren (der
				% Ausstattungsgrad wird in der Schleife bei jedem Durchgang um 100
				% Prozentpunkte reduziert --> z.B. bei einer Austattung von 125% wird
				% sicher ein Gerät erzeugt (da 100% immer kleiner 125%) und mit
				% 25%iger Wahrscheinlichkeit ein weiteres (da beim nächsten
				% Schleifendurchlauf ein Austattungsgrad von   125% - 100% = 25%
				% herangezogen wird):
				while equ_level > 0
					% Geräteinstanz erzeugen:
					dev = dev_handle(Model.Args.(name){:});
					% Überprüfen, ob Gerät überhaupt im Einsatz, sonst verwerfen, dazu
					% eine Zufallszahl zwischen 0 und 100 erzeugen:
					fort = rand()*100;
					if fort <= equ_level
						% überprüfen, ob Gerät überhaupt aktiv
						if dev.Activity
							% Geräteinstanz in jeweiligen Array speichern:
							Devices.(name)(end+1) = dev;
							% Anzahl der erzeugten Geräte aktualisieren:
							Devices.Total_Number_Dev = Devices.Total_Number_Dev + 1;
						end
					end
					% Reduzieren des Ausstattungsgrades:
					equ_level = equ_level - 100;
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
