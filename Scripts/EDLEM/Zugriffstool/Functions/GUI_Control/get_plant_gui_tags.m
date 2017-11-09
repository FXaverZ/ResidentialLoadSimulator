function tags = get_plant_gui_tags(tag_structure, idx_plant)
%GET_PLANT_GUI_TAGS    erstellt GUI-Tags mit einer Indexzahl.
% TAGS = GET_PLANT_GUI_TAGS(TAG_STRUCTURE, IDX_PLANT) wandelt die grobe Struktur von
% Tagbenennungen, gegeben in TAG_STRUCTURE, mit Hilfe einer Indexzahl in real
% vorhandene Tagnamen mit Hilfe des Cell-Arrays TAG_STRUCTURE (werden in der 
% Funktion GET_DEFAULT_VALUES für die verschiedenen GUI-Tags definiert) durch. Diese
% werden als Cell-Array TAGS zurückgegeben. 
% Mit diesen können dann die GUI-Elemente angesprochen werden. Diese Funktion wird
% für dynamisch erzeugte GUI-Elementen benötigt!

% Franz Zeilinger - 30.05.2012

tags = cell(size(tag_structure,1),1);
for i = 1:size(tag_structure,1)
	tags{i,1} = [tag_structure{i,1},num2str(idx_plant),tag_structure{i,2}];
end
end
