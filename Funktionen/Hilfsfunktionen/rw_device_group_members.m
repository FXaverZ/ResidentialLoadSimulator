function arg = rw_device_group_members(mode, obj, fileid, name, content, varargin)
%RW_DEVICE_GROUP_MEMBERS    ermöglicht Zugriff auf Parameter von Gerätegruppen
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_DEVICE_GROUP_MEMBERS('Read',DATA)

%    Franz Zeilinger - 04.08.2011

% Schreibmodus:
if strcmpi(mode,'write')
	fprintf(fileid,[name,'\n']);
	for i=1:size(content,1)
		fprintf(fileid,['\t',content{i,1},blanks(20-length(content{i,1})),...
			num2str(content{i,3},'%8.3f'),' %%\n']);
	end
	obj.write_lines(name);
	obj.next_layer;
	obj.write_values(content)
	obj.prev_layer;
	obj.next_row;
% Lesemodus:
elseif strcmpi(mode,'read')
	data = obj;
	arg = {data{1,1},[],[]};
	% Suchen nach dem letzen Eintrag der Geräteliste (Zeile in 2.Spalte mit NaN):
	for i = numel(data(:,2)):-1:1
		if ~isnan(data{i,2})
			end_row_idx = i;
			break;
		end
	end
	% Den Bereich mit den weiteren interessanten Daten als Cell-Array der 
	% Argumentenliste zuführen (ist die Gerätezuordnung zur Gerätegruppe + deren
	% Parameter):
	arg{2} = data(2:end_row_idx,2:5);
end

end

