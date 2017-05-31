classdef Device_Group
	%DEVICE_GROUP    Klasse der Ger�tegruppen
	%   Detailed explanation goes here
	
	% Franz Zeilinger - 11.08.2011
	
	properties
		Name
	%            Variablenname und voller Name der Ger�tegruppe
	%                { Variablenname, ausgeschriebener Name }
		Args
	%            Allgemeine Parameter, die f�r alle Mitglieder der Ger�tegruppe
	%                gelten sollen, sofern diese nicht durch eine Definition des
	%                Ger�tes selbst �berschrieben werden. Besteht aus der dem Feld
	%                "dev", in dem die allgemeinen Ger�teparameter enthalten sind,
	%                dem Feld "dsm", in dem die DSM-Einstellungen zu finden sind und
	%                dem Feld "add", in dem die restlichen Daten der Parameterdatei
	%                abgelegt werden, die bis jetzt noch nicht verwendet werden.
	    Members
	%            Cell-Array mit den Mitgliedern der Ger�tegruppe (Vergleiche mit 
	%                Model.Devices_Pool:
	%                { Variablenname, ausgeschriebener Name, ...
	%                  Handle auf zust�ndige Klasse}
	end
	
	methods
		
		function obj = Device_Group(var_name, Model)
			%DEVICE_GROUPS    Konstruktor der Ger�teklasse DEVICE_GROUPS.
			%    OBJ = DEVICE (ARG_LIST) durchl�uft die Parameterliste ARG_LIST
			
			% Name(n) der Ger�tegruppe ermitteln:
			obj.Name = Model.Device_Groups_Pool(strcmp(var_name, ...
				Model.Device_Groups_Pool(:,1)),:);
			% Die Argumentenlisten f�r diese Ger�tegruppe aus der Model-Struktur
			% kopieren:
			obj.Args.dev = Model.Args.(obj.Name{1});
			if isfield(Model.Args, [obj.Name{1},'_dsm'])
				obj.Args.dsm = Model.Args.([obj.Name{1},'_dsm']);
			else
				obj.Args.dsm = {};
			end
			
			% Ermitteln der Mitglieder dieser Ger�tegruppe:
			args = obj.Args.dev;
			idx = find(strcmp('Device_Group_Members', args));
			memb = args{idx+1}(:,1);
			obj.Args.add = args{idx+1}(:,2:end);
			% Nachdem die die Daten f�r die Ger�te in der Gruppe aus der
			% Parameterliste entnommen wurden, diesen Eintrag l�schen, da er nicht
			% mehr ben�tigt wird:
			args(idx:idx+2) = [];
			obj.Args.dev = args;
			obj.Members = {};
			% Die einzelnen Mitglieder identifizieren und deren Eintr�ge in die
			% Klasse �bernehmen:
			for i=1:numel(memb)
				devi = memb{i};
				idx = strcmp(devi, Model.Devices_Pool(:,2));
				obj.Members(end+1,:) = Model.Devices_Pool(idx,:);
			end
		end
		
		function Model = update_device_parameter (obj, Model)
			
			% Die Ger�teparameter f�r jedes Ger�t in der Gruppe mithilfe der
			% Gruppenparameter auf den aktuellsten, bzw. einen vollst�ndigen Stand
			% bringen:
			for i=1:size(obj.Members,1)
				dev_name = obj.Members{i,1};
				% �berpr�fen, ob bereits Parameterwerte f�r diese Klasse existieren:
				if isfield(Model.Args, dev_name)
					% Wenn ja, Parameter zusammenf�hren:
					Model.Args.(dev_name) = ...
						obj.merge_parameters(Model.Args.(dev_name),	obj.Args.dev);
					% Parameter gem�� der Gruppenaufteilung anpassen:
					Model.Args.(dev_name) = ...
						obj.adapt_parameters(Model.Args.(dev_name), ...
						obj.Args.add(i,:));	
				else
					% Wenn nicht, die Parameterwerte der Ger�tegruppe �bernehmen:
					Model.Args.(dev_name) = obj.Args.dev;
				end
				% Das gleiche f�r die DSM-Einstellungen:
				if ~isempty(obj.Args.dsm) && isfield(Model.Args, [dev_name,'_dsm'])
					% Wenn ja, Parameter zusammenf�hren:
					Model.Args.([dev_name,'_dsm']) = ...
						obj.merge_parameters(Model.Args.([dev_name,'_dsm']),...
						obj.Args.dsm);
					%
				elseif ~isempty(obj.Args.dsm)
					% Wenn nicht, die Parameterwerte der Ger�tegruppe �bernehmen:
					Model.Args.([dev_name,'_dsm']) = obj.Args.dsm;
				end
			end
		end
		
		function Model = update_device_assembly(obj, Model)
			%UPDATE_DEVICE_ASSEMBLY    Updaten der Ger�tezusammenstellung
			
			grp_name = obj.Name{1};
			% Wenn die Ger�tegruppe in der Simulation ber�cksichtigt werden soll,
			% alle Mitglieder der Ger�tegruppe f�r Simulation aktivieren.
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
				% ACHTUNG - Funktion noch nicht vollst�ndig fertig implementiert,
				% befindet sich noch in der Testphase - Es wird angenommen, dass in
				% der zweiten Spalte von ADD_GROUP_ARGS eine Verteilung der einzelnen
				% Ger�te innerhalb der Ger�tegruppe angegebene wurde. Diese
				% Verteilung wird nun auf die Startwahrscheinlichkeiten
				% aufgeschlagen:
				idx = find(strcmpi('Start_Probability', dev_args));
				dev_args{idx+1} = dev_args{idx+1} * add_group_args{2}/100;
			end
		end
		
		function dev_args = merge_parameters(dev_args, group_args)
			%MERGE_PARAMETERS    zusammef�hren der Gruppen- und Ger�teparameter
			%    DEV_ARGS = MERGE_PARAMETERS(DEV_ARGS, GROUP_ARGS) sorgt f�r die 
			%    Zusammmenf�hrung der Parameterlisten DEV_ARGS und GROUP_ARGS. Dazu
			%    werden die einzelnen Parameternamen verglichen. Sind gleiche
			%    Parameter bei der Gruppe und dem Ger�t vorhanden, werden die
			%    Parameterwerte des Ger�tes �bernommen. Fehlende Parameter
			%    werden jeweils in der Ger�teliste erg�nzt.
			
			% Durchlaufen der Gruppenparameterliste und suchen nach identischen
			% Eintr�gen in der Ger�teparameterliste:
			for i=1:3:numel(group_args)
				par_name = group_args{i};
				if isempty(find(strcmp(par_name, dev_args),1))
					% Paramter noch nicht vorhanden, neu zur Ger�teparameterliste
					% hinzuf�gen:
					dev_args = [dev_args, group_args(i:i+2)];
				end
			end
		end
	end
end

