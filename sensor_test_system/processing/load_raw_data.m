function data = load_raw_data(csv_path)
%LOAD_RAW_DATA Load raw CSV with expected channel columns.
T = readtable(csv_path);
required = {'time_s','accel_v','sensor_v'};
if ~all(ismember(required, T.Properties.VariableNames))
    error('CSV missing required columns: time_s, accel_v, sensor_v');
end

data = struct();
data.t_s = T.time_s;
data.accel_v = T.accel_v;
data.sensor_v = T.sensor_v;
end
