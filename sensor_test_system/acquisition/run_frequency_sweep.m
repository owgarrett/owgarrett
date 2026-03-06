function out = run_frequency_sweep(dq, cfg, freqs_hz, amp, paths)
%RUN_FREQUENCY_SWEEP Acquire one run per frequency.
if isscalar(amp)
    amps = amp * ones(size(freqs_hz));
else
    amps = amp;
end
reps = ones(size(freqs_hz));
out = run_loop(dq, cfg, freqs_hz, amps, reps, paths, "frequency_sweep");
end

function out = run_loop(dq, cfg, freqs_hz, amps, reps, paths, test_type)
io = io_helpers();
th = table_helpers();
summary_path = fullfile(paths.proc_dir, 'summary.csv');
manifest = struct('sensor_id', cfg.sensor_id, 'session_id', paths.session_id, ...
    'test_type', test_type, 'measurements', []);

for i = 1:numel(freqs_hz)
    for r = 1:reps(i)
        trial = acquire_trial(dq, cfg, freqs_hz(i), amps(i), r);
        stamp = datestr(now,'yyyymmdd_HHMMSSFFF');
        raw_name = sprintf('f%04d_a%0.3g_r%02d_%s.csv', round(trial.f0_hz), trial.amp, r, stamp);
        raw_path = fullfile(paths.raw_dir, raw_name);

        T = table(trial.t_s, trial.accel_v, trial.sensor_v, 'VariableNames', {'time_s','accel_v','sensor_v'});
        writetable(T, raw_path);

        meta = trial;
        meta.csv_file = raw_name;
        json_name = replace(raw_name, '.csv', '.json');
        io.write_json(fullfile(paths.raw_dir, json_name), meta);

        row = table(string(trial.timestamp), string(test_type), trial.f0_hz, trial.amp, r, ...
            trial.num_samples, trial.dt_mean, trial.dt_std, trial.dropout_flag, string(raw_name), ...
            'VariableNames', {'timestamp','test_type','freq_hz','amp','rep','num_samples','dt_mean','dt_std','dropout_flag','raw_file'});
        th.append_or_create_table(summary_path, row);

        manifest.measurements = [manifest.measurements; struct('freq_hz',trial.f0_hz,'amp',trial.amp,'rep',r,'raw_file',raw_name)]; %#ok<AGROW>
    end
end
io.write_json(fullfile(paths.session_dir, 'session_manifest.json'), manifest);
out = struct('summary_csv', summary_path, 'raw_dir', paths.raw_dir, 'manifest', fullfile(paths.session_dir, 'session_manifest.json'));
end
