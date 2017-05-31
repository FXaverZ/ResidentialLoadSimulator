function arg = rw_dev_assembly(mode, obj, fileid, name, value, Model, varargin)
%RW_DEV_ASSEMBLY    erm�glicht Zugriff auf die Ger�tezusammenstellung
%    Diese Funktion geh�rt der RW_-Funktionenreihe an, die eine automatische
%    Abarbeitung aller im Simulationsprogamm vorkommendnen Parameter erlaubt.
%    Dazu werden die jeweiligen Parametern zentral in einem Cell-Array
%    definiert, in dem auch die Handles zu diesen Funktionen angegeben sind, um
%    so zu definieren, welche dieser Funktionen f�r den jeweiligen Parametertyp
%    zust�ndig ist. Weiters werden alle notwendigen Argumente in diesem
%    Cell-Array definiert.
%
%    RW_DEV_ASSEMBLY('Write', OBJ, FILEID, NAME, VALUE) schreibt die in MODEL
%    definierte Zusammestellung der Ger�te f�r die Simulation in das durch
%    FILEID angegebene txt-File sowie in das durch die XLS_Writer-Instanz OBJ
%    definierte xls-File. Es werden alle definierten Ger�tetype aufgelistet
%    sowie deren Verwendung in der Simulation markiert (im txt-File als Kreuz in
%    dem vorgesehenen Feld, im xls-File durch die Werte '1' bzw. '0'.
%
%    ARG = RW_DEV_ASSEMBLY('Read', DATA, MODEL) liest aus dem Cell-Array DATA
%    die Ger�tekonfiguration f�r die Simulationseinstellungen ein. DATA muss
%    bereits so aufbereitet sein, dass sich darin nur die Ger�tekonfiguration
%    (inkl. �berschrift) befindet. Die Parameterstruktur MODEL wird ben�tigt, um
%    die Ger�tenamen richtig zuordnen zu k�nnen (Feld MODEL.ELEMENTS_POOL).

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