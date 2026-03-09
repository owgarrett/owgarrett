function io = io_helpers()
%IO_HELPERS Utility function handles for JSON and CSV related I/O.
io.write_json = @write_json;
end

function write_json(path, data)
fid = fopen(path, 'w');
if fid < 0
    error('Could not open JSON file for writing: %s', path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', jsonencode(data));
end
