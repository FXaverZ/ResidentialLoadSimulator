% Zusammenf�hrungsscript
% Neue Ger�teprofile in bestehende Haushaltsdateien einf�gen

% Speicherort der der neuen Haushaltsdateien mit den neuen Ger�teprofilen
path_profils_new = 'D:\Projekte\aDSM\6_Lastprofile_bearbeiten\aDSM_HH_Daten_aufbereitet_4\'; 
% Speicherort der "alten" Profile, die ugedated werden sollen:
path_profils_old = 'D:\Projekte\aDSM\6_Lastprofile_bearbeiten\aDSM_HH_Daten_aufbereitet_3\'; 
% Speicherort der neuen, upgedatedten Profildateien:
path_profils_merged = 'D:\Projekte\aDSM\6_Lastprofile_bearbeiten\aDSM_HH_Daten_aufbereitet_131021_neue_Austattung\';

% Inhalt des Ordners mit den neuen Profilen auslesen:
hh_names = dir(path_profils_new);
hh_names = struct2cell(hh_names);
hh_names = hh_names(1,3:end);

% Liste mit Ger�ten, die ge�ndert wurden:
changed_devices = {...
	'cir_pu',...
	'wa_boi',...
	'hea_wp',...
	'wa_hea',...
	'hea_ra',...
	};

% Log-File schreiben
diary([pwd,filesep,datestr(now,'yyyy_mm_dd_HH_MM_SS'),'_Log.txt']);

fprintf('Beginne mit Zusammenf�hren der Daten...\n');
for i=1:numel(hh_names)
	fprintf(['\tLade Haushaltsdaten f�r ',hh_names{i},'...\n']);
	% neue profildaten laden:
	load([path_profils_new,hh_names{i}]);
	assignin('base','hh_data_new',eval(hh_names{i}(1:end-4)));
	clear(hh_names{i}(1:end-4));
	% alte profildaten laden:
	load([path_profils_old,hh_names{i}]);
	assignin('base','hh_data_old',eval(hh_names{i}(1:end-4)));
	clear(hh_names{i}(1:end-4));
	
	% Ge�nderte Ger�te aus den bisherigen Datensatz l�schen:
	printed_first_line = 0;
	for j=1:numel(changed_devices)
		idx = strcmp(hh_data_old.Device_Names, changed_devices{j});
		if ~isempty(find(idx,1))
			if ~printed_first_line
				fprintf('\t\tEntferne Ger�te: ');
				printed_first_line = 1;
			end
			fprintf([changed_devices{j},'; ']);
			% L�schen der jeweiligen Daten:
			hh_data_old.Time_Data(idx,:,:) = [];
			hh_data_old.Device_Names(idx) = [];
		end
	end
	if printed_first_line
		fprintf('\n');
	end
	
	% die einzelnen Ger�te durchgehen:
	printed_first_line = 0;
	for j=1:numel(hh_data_new.Device_Names)
		% Suchen nach Ger�t in alter Datenstruktur
		idx = strcmp(hh_data_old.Device_Names, hh_data_new.Device_Names{j});
		if ~isempty(find(idx,1))
			% falls Ger�t vorhanden, Zeitverlauf + Aktivit�tsmatrix ersetzen
			hh_data_old.Time_Data(idx,:,:) = hh_data_new.Time_Data(j,:,:);
		else
			if ~printed_first_line
				fprintf('\t\tF�ge Ger�te hinzu: ');
				printed_first_line = 1;
			end
			fprintf([hh_data_new.Device_Names{j},'; ']);
			% falls Ger�t nicht vorhanden
			hh_data_old.Device_Names{end+1} = hh_data_new.Device_Names{j};
			hh_data_old.Time_Data(end+1,:,:) = hh_data_new.Time_Data(j,:,:);
		end
	
	end
	if printed_first_line
		fprintf('\n');
	end
	fprintf(['\tSpeichere neue Haushaltsdaten f�r ',hh_names{i},'...\n']);
	% Save Data:
	eval([hh_names{i}(1:end-4),'=hh_data_old;']);
	save([path_profils_merged,hh_names{i}],hh_names{i}(1:end-4));
	clear(hh_names{i}(1:end-4));
	fprintf('\t\tabgeschlossen!\n\n');
end

diary off