function arg = rw_dev_assembly(mode, obj, fileid, name, value, Model, varargin)
%RW_DEV_ASSEMBLY    ermöglicht Zugriff auf die Gerätezusammenstellung
%    Diese Funktion gehört der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen für den jeweiligen Parametertyp
%    zuständig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_DEV_ASSEMBLY('Write', OBJ, FILEID, NAME, VALUE) schreibt die in MODEL
%    definierte Zusammestellung der Geräte für die Simulation in das durch
%    FILEID angegebene txt-File sowie in das durch die XLS_Writer-Instanz OBJ
%    definierte xls-File. Es werden alle definierten Gerätetype aufgelistet
%    sowie deren Verwendung in der Simulation markiert (im txt-File als Kreuz in
%    dem vorgesehenen Feld, im xls-File durch die Werte '1' bzw. '0'.
%
%    ARG = RW_DEV_ASSEMBLY('Read', DATA, MODEL) liest aus dem Cell-Array DATA
%    die Gerätekonfiguration für die Simulationseinstellungen ein. DATA muss
%    bereits so aufbereitet sein, dass sich darin nur die Gerätekonfiguration
%    (inkl. Überschrift) befindet. Die Parameterstruktur MODEL wird benötigt, um
%    die Gerätenamen richtig zuordnen zu können (Feld MODEL.ELEMENTS_POOL).

%    Franz Zeilinger - 11.08.2011

arg = [];

% Schreibmodus:
if strcmpi(mode,'write')
	fprintf(fileid,['\t',name,':\n']);
	for i = 1:size(Model.Device_Assembly_Pool,1)
		if Model.Device_Assembly.(Model.Device_Assembly_Pool{i,1})	
			sign = '[X] ';
		else
			sign = '[ ] ';
		end
		dist = blanks(20);
		fprintf(fileid, ['\t', dist, sign]);
		fprintf(fileid, [Model.Device_Assembly_Pool{i,2},'\n']);
	end
	
	obj.write_lines(name);
	obj.next_layer;
	obj.write_lines([Model.Device_Assembly_Pool(:,2),...
		struct2cell(Model.Device_Assembly)]);
	obj.reset_layer;
	obj.next_row;

% Lesemodus:
elseif strcmpi(mode,'read')
	data = obj;
	Model = fileid;
	
	for i=2:size(data,1)
		if ischar(data{i,2}) && isnumeric(data{i,3})
			ind = strcmp(data{i,2},Model.Device_Assembly_Pool(:,2));
			arg.(Model.Device_Assembly_Pool{ind,1}) = data{i,3};
		end
	end	
end
end