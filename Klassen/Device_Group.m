classdef Device_Group
	%DEVICE_GROUP    Klasse der Gerätegruppen
	%   Detailed explanation goes here
	
	% Franz Zeilinger - 11.08.2011
	
	properties
		Name
	%            Variablenname und voller Name der Gerätegruppe
	%                { Variablenname, ausgeschriebener Name }
		Args
	%            Allgemeine Parameter, die für alle Mitglieder der Gerätegruppe
	%                gelten sollen, sofern diese nicht durch eine Definition des
	%                Gerätes selbst überschrieben werden. Besteht aus der dem Feld
	%                "dev", in dem die allgemeinen Geräteparameter enthalten sind,
	%                dem Feld "dsm", in dem die DSM-Einstellungen zu finden sind und
	%                dem Feld "add", in dem die restlichen Daten der Parameterdatei
	%                abgelegt werden, die bis jetzt noch nicht verwendet werden.
	    Members
	%            Cell-Array mit den Mitgliedern der Gerätegruppe (Vergleiche mit 
	%                Model.Devices_Pool:
	%                { Variablenname, ausgeschriebener Name, ...
	%                  Handle auf zuständige Klasse}
	end
	
	methods
		
		function obj = Device_Group(var_name, Model)
			%DEVICE_GROUPS    Konstruktor der Geräteklasse DEVICE_GROUPS.
			%    OBJ = DEVICE (ARG_LIST) durchläuft die Parameterliste ARG_LIST
			
			% Name(n) der Gerätegruppe ermitteln:
			obj.Name = Model.Device_Groups_Pool(strcmp(var_name, ...
				Model.Device_Groups_Pool(:,1)),:);
			% Die Argumentenlisten für diese Gerätegruppe aus der Model-Struktur
			% kopieren:
			obj.Args.dev = Model.Args.(obj.Name{1});
			if isfield(Model.Args, [obj.Name{1},'_dsm'])
				obj.Args.dsm = Model.Args.([obj.Name{1},'_dsm']);
			else
				obj.Args.dsm = {};
			end
			
			% Ermitteln der Mitglieder dieser Gerätegruppe:
			args = obj.Args.dev;
			idx = find(strcmp('Device_Group_Members', args));
			memb = args{idx+1}(:,1);
			obj.Args.add = args{idx+1}(:,2:end);
			% Nachdem die die Daten für die Geräte in der Gruppe aus der
			% Parameterliste entnommen wurden, diesen Eintrag löschen, da er nicht
			% mehr benötigt wird:
			args(idx:idx+2) = [];
			obj.Args.dev = args;
			obj.Members = {};
			% Die einzelnen Mitglieder identifizieren und deren Einträge in die
			% Klasse übernehmen:
			for i=1:numel(memb)
				devi = memb{i};
				idx = strcmp(devi, Model.Devices_Pool(:,2));
				obj.Members(end+1,:) = Model.Devices_Pool(idx,:);
			end
		end
		
		function Model = update_device_parameter (obj, Model)
			
			% Die Geräteparameter für jedes Gerät in der Gruppe mithilfe der
			% Gruppenparameter auf den aktuellsten, bzw. einen vollständigen Stand
			% bringen:
			for i=1:size(obj.Members,1)
				dev_name = obj.Members{i,1};
				% Überprüfen, ob bereits Parameterwerte für diese Klasse existieren:
				if isfield(Model.Args, dev_name)
					% Wenn ja, Parameter zusammenführen:
					Model.Args.(dev_name) = ...
						obj.merge_parameters(Model.Args.(dev_name),	obj.Args.dev);
					% Parameter gemäß der Gruppenaufteilung anpassen:
					Model.Args.(dev_name) = ...
						obj.adapt_parameters(Model.Args.(dev_name), ...
						obj.Args.add(i,:));	
				else
					% Wenn nicht, die Parameterwerte der Gerätegruppe übernehmen:
					Model.Args.(dev_name) = obj.Args.dev;
				end
				% Das gleiche für die DSM-Einstellungen:
				if ~isempty(obj.Args.dsm) && isfield(Model.Args, [dev_name,'_dsm'])
					% Wenn ja, Parameter zusammenführen:
					Model.Args.([dev_name,'_dsm']) = ...
						obj.merge_parameters(Model.Args.([dev_name,'_dsm']),...
						obj.Args.dsm);
					%
				elseif ~isempty(obj.Args.dsm)
					% Wenn nicht, die Parameterwerte der Gerätegruppe übernehmen:
					Model.Args.([dev_name,'_dsm']) = obj.Args.dsm;
				end
			end
		end
		
		function Model = update_device_assembly(obj, Model)
			%UPDATE_DEVICE_ASSEMBLY    Updaten der Gerätezusammenstellung
			
			grp_name = obj.Name{1};
			% Wenn die Gerätegruppe in der Simulation berücksichtigt werden soll,
			% alle Mitglieder der Gerätegruppe für Simulation aktivieren.
			for i=1:size(obj.Members,1)
				dev_name = obj.Members{i,1};
				Model.Device_Assembly_Simulation.(dev_name) = ...
					Model.Device_Assembly.(grp_name);
			end
		end
	end
	
	methods(Static)
		
		function dev_args = adapt_parameters(dev_args, add_group_args)
			if ~isempty(add_group_args)
				% ACHTUNG - Funktion noch nicht vollständig fertig implementiert,
				% befindet sich noch in der Testphase - Es wird angenommen, dass in
				% der zweiten Spalte von ADD_GROUP_ARGS eine Verteilung der einzelnen
				% Geräte innerhalb der Gerätegruppe angegebene wurde. Diese
				% Verteilung wird nun auf die Startwahrscheinlichkeiten
				% aufgeschlagen:
				idx = find(strcmpi('Start_Probability', dev_args));
				dev_args{idx+1} = dev_args{idx+1} * add_group_args{2}/100;
			end
		end
		
		function dev_args = merge_parameters(dev_args, group_args)
			%MERGE_PARAMETERS    zusammeführen der Gruppen- und Geräteparameter
			%    DEV_ARGS = MERGE_PARAMETERS(DEV_ARGS, GROUP_ARGS) sorgt für die 
			%    Zusammmenführung der Parameterlisten DEV_ARGS und GROUP_ARGS. Dazu
			%    werden die einzelnen Parameternamen verglichen. Sind gleiche
			%    Parameter bei der Gruppe und dem Gerät vorhanden, werden die
			%    Parameterwerte des Gerätes übernommen. Fehlende Parameter
			%    werden jeweils in der Geräteliste ergänzt.
			
			% Durchlaufen der Gruppenparameterliste und suchen nach identischen
			% Einträgen in der Geräteparameterliste:
			for i=1:3:numel(group_args)
				par_name = group_args{i};
				if isempty(find(strcmp(par_name, dev_args),1))
					% Paramter noch nicht vorhanden, neu zur Geräteparameterliste
					% hinzufügen:
					dev_args = [dev_args, group_args(i:i+2)];
				end
			end
		end
	end
end

