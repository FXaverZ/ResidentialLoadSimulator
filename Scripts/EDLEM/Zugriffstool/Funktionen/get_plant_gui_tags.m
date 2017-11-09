function tags = get_plant_gui_tags(tag_structure, idx_plant)
% wandelt die grobe Struktur von Tagbenennungen mit Hilfe einer Indexzahl in
% real vorhandene Tagnamen durch.
tags = cell(size(tag_structure,1),1);
for i = 1:size(tag_structure,1)
	tags{i,1} = [tag_structure{i,1},num2str(idx_plant),tag_structure{i,2}];
end
end
