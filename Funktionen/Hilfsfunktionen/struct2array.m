function mat = struct2array(structure)
    temp = struct2cell(structure);
    mat = horzcat(temp{:});
end