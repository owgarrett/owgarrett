function th = table_helpers()
%TABLE_HELPERS Utility function handles for table operations.
th.append_or_create_table = @append_or_create_table;
end

function append_or_create_table(path, row)
if exist(path, 'file')
    writetable(row, path, 'WriteMode', 'Append');
else
    writetable(row, path);
end
end
