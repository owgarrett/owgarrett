function out = run_deep_dive(dq, cfg, f0_hz, amp, n_reps, paths)
%RUN_DEEP_DIVE Acquire replicate runs at fixed frequency and amplitude.
th = table_helpers();
summary_path = fullfile(paths.proc_dir, 'summary.csv');

for r = 1:n_reps
    trial = acquire_trial(dq, cfg, f0_hz, amp, r);
    metrics = compute_trial_metrics(trial.t_s, trial.accel_v, trial.sensor_v, trial.f0_hz, cfg);

    stamp = datestr(now,'yyyymmdd_HHMMSSFFF');
    raw_name = sprintf('f%04d_a%0.3g_r%02d_%s.csv', round(trial.f0_hz), trial.amp, r, stamp);
    raw_path = fullfile(paths.raw_dir, raw_name);

    T = table(trial.t_s, trial.accel_v, trial.sensor_v, 'VariableNames', {'time_s','accel_v','sensor_v'});
    writetable(T, raw_path);

    row = table(string(trial.timestamp), "deep_dive", trial.f0_hz, trial.amp, r, ...
        trial.num_samples, trial.dt_mean, trial.dt_std, trial.dropout_flag, ...
        metrics.seg.clean_fraction, metrics.snr_db, metrics.gp.gain, metrics.gp.phase_deg, ...
        metrics.noise.noise60_ratio, metrics.disp_peak_um, metrics.sensitivity_ohm_per_um, ...
        metrics.min_detect_disp_um_3sigma, metrics.trial_pass, string(raw_name), ...
        'VariableNames', {'timestamp','test_type','freq_hz','amp','rep','num_samples','dt_mean','dt_std','dropout_flag', ...
        'clean_fraction','snr_db','gain','phase_deg','noise60_ratio','disp_peak_um','sensitivity_ohm_per_um', ...
        'min_detect_disp_um_3sigma','trial_pass','raw_file'});
    th.append_or_create_table(summary_path, row);

    generate_trial_outputs(raw_name, trial.f0_hz, metrics, cfg.fs_hz, paths.proc_dir);
end

report = local_write_verification_report(summary_path, paths.proc_dir);
out = struct('summary_csv', summary_path, 'raw_dir', paths.raw_dir, 'proc_dir', paths.proc_dir, ...
    'verification_report', report.csv_path, 'verification_plot', report.plot_path);
end

function report = local_write_verification_report(summary_path, proc_dir)
S = readtable(summary_path);
uf = unique(S.freq_hz);
R = table();
for i = 1:numel(uf)
    idx = S.freq_hz == uf(i);
    row = table(uf(i), mean(S.gain(idx),'omitnan'), mean(S.phase_deg(idx),'omitnan'), ...
        std(S.phase_deg(idx),'omitnan'), mean(S.snr_db(idx),'omitnan'), ...
        mean(S.min_detect_disp_um_3sigma(idx),'omitnan'), mean(S.trial_pass(idx)), ...
        'VariableNames', {'freq_hz','gain_mean','phase_mean_deg','phase_std_deg','snr_mean_db', ...
        'min_detect_disp_um_mean','trial_pass_rate'});
    R = [R; row]; %#ok<AGROW>
end
csv_path = fullfile(proc_dir, 'verification_report.csv');
writetable(R, csv_path);

fig = figure('Name', 'Verification Summary', 'Color', 'w');
tiledlayout(2,2);
nexttile; plot(R.freq_hz, R.gain_mean, '-o'); grid on; title('Gain vs Frequency'); xlabel('Hz'); ylabel('Gain');
nexttile; errorbar(R.freq_hz, R.phase_mean_deg, R.phase_std_deg, '-o'); grid on; title('Phase vs Frequency'); xlabel('Hz'); ylabel('deg');
nexttile; plot(R.freq_hz, R.snr_mean_db, '-o'); grid on; title('Mean SNR vs Frequency'); xlabel('Hz'); ylabel('dB');
nexttile; plot(R.freq_hz, R.min_detect_disp_um_mean, '-o'); grid on; title('Min Detectable Disp vs Frequency'); xlabel('Hz'); ylabel('um');
plot_path = fullfile(proc_dir, 'verification_summary.png');
saveas(fig, plot_path);

report = struct('csv_path', csv_path, 'plot_path', plot_path);
end
