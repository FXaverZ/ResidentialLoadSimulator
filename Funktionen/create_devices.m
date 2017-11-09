function Devices = create_devices(hObject, Model)
%CREATE_DEVICES    erzeugt Ger�teinstanzen f�r Simulation
%    DEVICES = CREATE_DEVICES(HOBJECT, MODEL) erzeugt aus den in der
%    MODEL-Struktur angegebenen Daten ein Array von Ger�teinstanzen in der
%    DEVICES-Struktur. Weiters werden Informationen zum Umfang der enthaltenen
%    Ger�te erzeugt und in die DEVICES-Struktur gespeichert sowie eine
%    Statusanzeige des Fortschritts in der Konsole ausgegeben. HOBJECT liefert
%    den Zugriff auf das aufrufende GUI-Fenster (f�r Statusanzeige).

% Erstellt von:            Franz Zeilinger - 29.07.2011
% Letzte �nderung durch:   Franz Zeilinger - 12.12.2012

% F�r sp�tere �berpr�fung, ob Ger�teinstanzen f�r eine weitere Verwendung
% gebraucht werden k�nnen, die Anzahl der Personen in der Ger�te-Struktur
% speichern:
Devices.Number_User = Model.Number_User;  

%Auflistung der verwendeten Ger�te im Modell:
Devices.Elements_Varna = {};  % Variablennamen f�r automatisches Abarbeiten
Devices.Elements_Names = {};  % Vollst�ndige Namen der jeweiligen Ger�te 
                              %     z.B. f�r Legendenbeschriftung)
Devices.Elements_Funha = {};  % Handles auf Klassenfunktionen
Devices.Elements_Eq_Le = {};  % Ausstattungsgrad mit diesem Ger�t
Devices.Total_Number_Dev = 0; % Gesamtanzahl aller beteiligten Ger�te
Devices.DSM_included = 0;     % Sind DSM-Instanzen vorhanden?
waitbar_start;                % Messen der Zeit, die ben�tigt wird - Start

% Vorbereiten der Arrays f�r die Ger�te-Instanzen der Ger�testruktur:
for i=1:size(Model.Devices_Pool,1)
	% Variablenname der aktuellen Ger�teklasse:
	name = Model.Devices_Pool{i,1};
	if Model.Device_Assembly_Simulation.(name)
		% Funktionen-Handle auf zust�ndige Klasse auslesen
		dev_handle = Model.Devices_Pool{i,3};
		% eine Instanz der Klasse erzeugen
		dev = dev_handle();
		% leeres Array mit Klasseninstanzen erzeugen:
		Devices.(name) = dev.empty(0,0);
		% die jeweilingen Namen anspeichern:
		Devices.Elements_Varna{end+1} = name;
		Devices.Elements_Names{end+1} = Model.Devices_Pool{i,2};
		Devices.Elements_Funha{end+1} = Model.Devices_Pool{i,3};
		% eine zus�tzliche Zuordnung mitspeichern: diese beschreibt einen
		% Ausstattungsrad mit einem bestimmten Ger�tetyp: bei der Erzeugung der
		% Ger�tinstanzen wird auf diesen Wert R�cksicht genommen, d.h. f�r einen Wert
		% von 50 ergibt sich hier, dass nur 50% der erzeugten Ger�te-Instanzen auch
		% f�r die Simulation �bernommen werden. Per Default wird f�r alle Ger�te der
		% Wert 100 (%) eingetragen, sprich, jede erzeugte Instanz wird auch
		% �bernommen! 
		Devices.Elements_Eq_Le{end+1} = 100;
	end
end

% Falls Ger�tegruppen vorhanden sind, den Austattungsgrad der einzelnen Elemente
% �bernehmen:
if Model.Device_Groups.Present
	% �ber die m�glichen Ger�tegruppen iterieren:
	for i=1:size(Model.Device_Groups_Pool,1)
		% gibt es diese Ger�tegruppe �berhaupt?
		if ~isfield(Model.Device_Groups, Model.Device_Groups_Pool{i,1})
			continue;
		end
		% Mitglieder dieser Gruppe auslesen:
		member = Model.Device_Groups.(Model.Device_Groups_Pool{i,1}).Members;
		% �ber die Mitglieder iterieren:
		for j=1:size(member,1)
			% Zuordnung des Ger�tetyps in den vorhandenen Ger�ten finden:
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
			if waitbar_update (hObject, 5, i, Model.Number_User*numel(Devices.Elements_Varna))
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
				% Austattungsgrad:
				equ_level = Devices.Elements_Eq_Le{j};
				% solange der Austattungsgrad positiv, Ger�te generieren (der
				% Ausstattungsgrad wird in der Schleife bei jedem Durchgang um 100
				% Prozentpunkte reduziert --> z.B. bei einer Austattung von 125% wird
				% sicher ein Ger�t erzeugt (da 100% immer kleiner 125%) und mit
				% 25%iger Wahrscheinlichkeit ein weiteres (da beim n�chsten
				% Schleifendurchlauf ein Austattungsgrad von   125% - 100% = 25%
				% herangezogen wird):
				while equ_level > 0
					% Ger�teinstanz erzeugen:
					dev = dev_handle(Model.Args.(name){:});
					% �berpr�fen, ob Ger�t �berhaupt im Einsatz, sonst verwerfen, dazu
					% eine Zufallszahl zwischen 0 und 100 erzeugen:
					fort = rand()*100;
					if fort <= equ_level
						% �berpr�fen, ob Ger�t �berhaupt aktiv
						if dev.Activity
							% Ger�teinstanz in jeweiligen Array speichern:
							Devices.(name)(end+1) = dev;
							% Anzahl der erzeugten Ger�te aktualisieren:
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
