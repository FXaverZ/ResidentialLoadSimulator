function output_with_uniqe_entries = unique_cells( input_cell )
%UNIQUE_CELLS Summary of this function goes here
%   Detailed explanation goes here

output_with_uniqe_entries = {};
for z=1:numel(input_cell)
	if isempty(find(strcmp(output_with_uniqe_entries,input_cell{z}), 1))
		output_with_uniqe_entries{end+1} = input_cell{z};  %#ok<AGROW>
	end
end
end

