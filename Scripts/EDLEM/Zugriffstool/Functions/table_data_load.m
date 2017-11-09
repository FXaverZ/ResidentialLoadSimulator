function [data, names] = table_data_load (SincalNetworkDataSource, tablename)
% Die Variable 'data' enthält nun eine Kopie der Tabellendaten, die Variable
% 'names' die Namen der einzelnen Spalten, welche mit der Datenbankbeschreibung von
% SINCAL ident sind. 

% Franz Zeilinger - 12.06.2012

% Auslesen der Tabelle:
table = SincalNetworkDataSource.GetRowObj(tablename);
table.Open();
% Die Namen der Tabellenbezeichnungen auslesen:
number_names = table.Count;
names = cell(1,number_names);
for i = 1:number_names
	names{i} = table.get('Name',i);
end
% Die Daten auslesen:
number_rows = table.CountRow;
table.MoveFirst();
data = cell(number_rows,number_names);
for i = 1:number_rows
	for j = 1:number_names
		data{i,j} = table.get('Item',names{j});
	end
	table.MoveNext();
end
table.Close();
clear('table');
end