function out = run_deep_dive(dq, cfg, f0_hz, amp, n_reps, paths)
%RUN_DEEP_DIVE Acquire replicate runs at fixed frequency and amplitude.
freqs_hz = f0_hz * ones(1, n_reps);
amps = amp * ones(1, n_reps);
reps = ones(1, n_reps);
out = run_loop_deep(dq, cfg, freqs_hz, amps, reps, paths);
end

function out = run_loop_deep(dq, cfg, freqs_hz, amps, reps, paths)
io = io_helpers();
th = table_helpers();
summary_path = fullfile(paths.proc_dir, 'summary.csv');
manifest = struct('sensor_id', cfg.sensor_id, 'session_id', paths.session_id, ...
    'test_type', "deep_dive", 'measurements', []);

for i = 1:numel(freqs_hz)
    r = i;
    trial = acquire_trial(dq, cfg, freqs_hz(i), amps(i), r);
    stamp = datestr(now,'yyyymmdd_HHMMSSFFF');
    raw_name = sprintf('f%04d_a%0.3g_r%02d_%s.csv', round(trial.f0_hz), trial.amp, r, stamp);
    raw_path = fullfile(paths.raw_dir, raw_name);
    T = table(trial.t_s, trial.accel_v, trial.sensor_v, 'VariableNames', {'time_s','accel_v','sensor_v'});
    writetable(T, raw_path);

    meta = trial; meta.csv_file = raw_name;
    io.write_json(fullfile(paths.raw_dir, replace(raw_name,'.csv','.json')), meta);

    row = table(string(trial.timestamp), "deep_dive", trial.f0_hz, trial.amp, r, ...
        trial.num_samples, trial.dt_mean, trial.dt_std, trial.dropout_flag, string(raw_name), ...
        'VariableNames', {'timestamp','test_type','freq_hz','amp','rep','num_samples','dt_mean','dt_std','dropout_flag','raw_file'});
    th.append_or_create_table(summary_path, row);
    manifest.measurements = [manifest.measurements; struct('freq_hz',trial.f0_hz,'amp',trial.amp,'rep',r,'raw_file',raw_name)]; %#ok<AGROW>
end
io.write_json(fullfile(paths.session_dir, 'session_manifest.json'), manifest);
out = struct('summary_csv', summary_path, 'raw_dir', paths.raw_dir, 'manifest', fullfile(paths.session_dir, 'session_manifest.json'));
end
