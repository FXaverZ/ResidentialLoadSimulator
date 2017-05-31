function reply = check_parameters (Model)
% WIRD NICHT VERWENDET

%    Franz Zeilinger - 13.08.2010

errortext = {};
error = 0;

%�berpr�fen, ob f�r alle Ger�teklassen die Argumente defniert sind:
for i=1:size(Model.Elements_Pool,1)
	name = Model.Elements_Pool{i,1};
	if Model.Device_Assembly.(name)
		if ~isfield(Model.Args.(name))
			error = 1;
			errortext(end+1)={[' - Keine Ger�teparameter f�r ',...
				Model.Elements_Pool{i,2},' gefunden!']};
		elseif ~isfield(Model.Args.([name,'_dsm'])) && Model.Use_DSM
			error = 1;
			errortext(end+1)={[' - Keine DSM Parameter f�r ',...
				Model.Elements_Pool{i,2},' gefunden!']};
		end
	end
end
end