function New_Devices = pick_devices (Model, Devices)
%PICK_DEVICES    w�hlt aus vorhandenen Ger�teinstanzen die f�r Simulation n�tigen aus
%    NEW_DEVICES = PICK_DEVICES (MODEL, DEVICES) erzeugt aus der bereits
%    vorhandenen Ger�testruktur DEVICES eine neue Ger�testruktur NEW_DEVICES,
%    die nur jene Ger�te enth�lt, die f�r die Simulation, die in MODEL definiert
%    ist, notwendig sind. 
%    
%    Es empfiehlt sich, die urspr�ngliche Ger�testruktur f�r die Dauer der
%    Simulation zu speichern und nach der Simulation die neue Struktur mit der
%    alten zu �berschreiben, da diese Funktion immer eine Untermenge der
%    verf�gbaren Ger�te zur�ckgibt, f�r zuk�nftige Simulationen aber eventuell
%    die anderen Ger�teklassen ben�tigt werden!

%    Franz Zeilinger - 17.08.2010

% Falls in vorhergehender Funktion Fehler aufgetreten ist:
if isempty (Devices)
	New_Devices = [];
	return;
end

% Zur�cksetzen aller zu ver�ndernden Felder:
New_Devices.Elements_Varna = {}; %Variablenname f�r automatisches Abarbeiten
New_Devices.Elements_Names = {}; %F�r Legendenbeschriftung
New_Devices.Elements_Funha = {}; %Handles auf Klassenfunktionen 
New_Devices.Total_Number_Dev = 0; %Gesamtanzahl aller beteiligten Ger�te
% Kopieren sonstiger wichtiger Parameter:
New_Devices.DSM_included = Devices.DSM_included;
New_Devices.Number_User = Devices.Number_User;

% �bernehmen der notwendigen Ger�teklassen:
for i=1:size(Model.Elements_Pool,1)
	name = Model.Elements_Pool{i,1};
	if Model.Device_Assembly.(name)
		New_Devices.(name) = Devices.(name);
		New_Devices.Elements_Varna{end+1} = name;
		New_Devices.Elements_Names{end+1} = Model.Elements_Pool{i,2};
		New_Devices.Elements_Funha{end+1} = Model.Elements_Pool{i,3};
		New_Devices.Total_Number_Dev = New_Devices.Total_Number_Dev + ...
			numel(Devices.(name));
	end
end