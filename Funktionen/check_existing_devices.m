function reply = check_existing_devices (Model, Devices, Configuration)
%CHECK_EXISTING_DEVICES    überprüfen, ob vorhandene Geräte wiederverwendbar sind
%    REPLY = CHECK_EXISTING_DEVICES(MODEL, DEVICES) überprüft, ob die
%    Geräteinstanzen in DEVICES zu den Simulationseinstellungen, die in MODEL
%    angegeben wurden, passen. Trifft dies zu, wird der User gefragt, ob er ein
%    Wiederverwenden wünscht.
%    REPLY enthält die Informationen über die weitere Vorgehensweise: 
%        'j'   - Geräteinstanzen so wie sie sind weiterverwenden
%        'dsm' - Geräteinstanzen erhalten, nur die DSM-Instanzen neu erzeugen
%        'n'   - die Geräteinstanzen verwerfen und neue ermitteln
%
%    REPLY = CHECK_EXISTING_DEVICES(MODEL, DEVICES, CONFIGURATION) führt die
%    gleiche Überprüfung durch, nur erfolgt keine Userabfrage sondern durch die
%    Optionen 'use_same_devices' und 'use_same_dsm' in CONFIGURATION.OPTIONS wird
%    definiert, wie die passende Weiterverarbeitung aussieht:
%        use_same_devices = 1 : wenn möglich, Geräteinstanzen weiterverwenden
%        use_same_devices = 0 : Geräteinstanzen immer neu erzeugen
%                               (daraus folgt automatisch use_same_dsm = 0)
%        use_same_dsm     = 1 : wenn möglich, DSM-Instanzen weiterverwenden
%                               (daraus folgt automatisch use_same_devices = 1)
%        use_same_dsm     = 0 : DSM-Instanzen immer neu erzeugen

%    Franz Zeilinger - 16.06.2010

reply = 'n';

% Grundvoraussetzung: Devices existieren:
if isempty(Devices)
	% Wenn nicht, sofortiger Abbruch
	return;
end
% Grundvoraussetzung: Gleiche Anzahl von Usern: 
if (Model.Number_User ~= Devices.Number_User)
	% Wenn nicht, sofortiger Abbruch
	return;
end

% Überprüfen ob alle notwendigen Geräteklassen in Devices vorhanden sind:
nec_dev = Model.Elements_Pool(logical(struct2array(Model.Device_Assembly)),1)';
count = 0;
for i = 1:numel(nec_dev)
	count = count + sum(strcmp(nec_dev{i},Devices.Elements_Varna));
end
if numel(nec_dev) ~= count
	% nicht alle Geräteklassen vertreten, Abbruch!
	return;
end

% ab jetzt gilt: numel(nec_dev) = count, d.h. Geräteinstanzen können
% wiederverwendet werden:
fprintf(['\n\t\tSollen die vorhandenen Geräteinstanzen',...
	' herangezogen werden?']);
if nargin == 2
	% Frage an User stellen:
	ask_text = ['Sollen die aktuell vorhandenen',...
		' Geräteinstanzen für die Simulation herangezogen werden?'];
	title_text = 'Geräteinstanzen?';
	if Model.Use_DSM && Devices.DSM_included
		user_response = questdlg(ask_text,...
			title_text,'Ja', 'ohne DSM', 'Nein','Nein');
	else
		user_response = questdlg(ask_text,...
			title_text,'Ja', 'Nein', 'Nein');
	end
	
	switch lower(user_response)
		case 'ja'
			if Model.Use_DSM && ~Devices.DSM_included
				reply = 'dsm';
				fprintf(' DSM-Instanzen neu');
			else
				reply = 'j';
				fprintf(' J');
			end
		case 'ohne dsm'
			reply = 'dsm';
			fprintf(' DSM-Instanzen neu');
		otherwise
			reply = 'n';
			fprintf(' N');
	end
elseif nargin == 3
	% Je nach Angabe in Options wird die Weiterverwendung entschieden:
	opt = Configuration.Options;
	if opt.use_same_devices && opt.use_same_dsm
		if Model.Use_DSM && ~Devices.DSM_included
			reply = 'dsm';
			fprintf(' DSM-Instanzen neu');
		else
			reply = 'j';
			fprintf(' J');
		end
	elseif opt.use_same_devices && ~opt.use_same_dsm
			reply = 'dsm';
			fprintf(' DSM-Instanzen neu');
	end
end

drawnow;
end