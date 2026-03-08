function artifacts = generate_trial_outputs(raw_name, f0_hz, metrics, fs_hz, proc_dir)
%GENERATE_TRIAL_OUTPUTS Create interactive figures and concise tables per trial.

[~, stem, ~] = fileparts(raw_name);

% Figure 1: normalized overlays (filtered and clean-only).
fig1 = figure('Name', ['Trial Overlay - ' stem], 'Color', 'w');
tiledlayout(2,1);

nexttile;
plot(metrics.traces.t, metrics.traces.accel_norm_01, 'b-', 'DisplayName', 'Accel filt norm'); hold on;
plot(metrics.traces.t, metrics.traces.sensor_norm_01, 'r-', 'DisplayName', 'Sensor filt norm');
grid on; ylim([0 1]);
title(sprintf('Filtered normalized overlay @ %.1f Hz', f0_hz));
xlabel('Time (s)'); ylabel('Normalized (0-1)'); legend('Location','best');

nexttile;
plot(metrics.traces.t_clean, metrics.traces.accel_clean_norm_01, 'b-', 'DisplayName', 'Accel clean norm'); hold on;
plot(metrics.traces.t_clean, metrics.traces.sensor_clean_norm_01, 'r-', 'DisplayName', 'Sensor clean norm');
grid on; ylim([0 1]);
title('Blip-trimmed clean-only normalized overlay');
xlabel('Time (s)'); ylabel('Normalized (0-1)'); legend('Location','best');

overlay_png = fullfile(proc_dir, [stem '_overlay.png']);
saveas(fig1, overlay_png);

% Figure 2: FFT comparison raw vs clean-filtered.
fig2 = figure('Name', ['Trial FFT - ' stem], 'Color', 'w');
fr_raw = compute_fft(metrics.traces.sensor_raw, fs_hz);
fr_clean = compute_fft(metrics.traces.sensor_clean, fs_hz);
plot(fr_raw.f_hz, fr_raw.mag, 'Color', [0.7 0.7 0.7], 'DisplayName', 'Sensor raw'); hold on;
plot(fr_clean.f_hz, fr_clean.mag, 'r', 'LineWidth', 1.2, 'DisplayName', 'Sensor clean+filtered');
xline(f0_hz, 'k--', 'f0');
grid on; xlim([0, max(2*f0_hz, 2000)]);
title('FFT: raw vs clean filtered sensor');
xlabel('Frequency (Hz)'); ylabel('Magnitude'); legend('Location','best');
fft_png = fullfile(proc_dir, [stem '_fft.png']);
saveas(fig2, fft_png);

% Concise one-row trial results table.
trial_table = table(f0_hz, metrics.seg.clean_fraction, metrics.snr_db, metrics.gp.gain, ...
    metrics.gp.phase_deg, metrics.noise.noise60_ratio, metrics.disp_peak_um, ...
    metrics.sensitivity_ohm_per_um, metrics.min_detect_disp_um_3sigma, metrics.trial_pass, ...
    'VariableNames', {'freq_hz','clean_fraction','snr_db','gain','phase_deg','noise60_ratio', ...
    'disp_peak_um','sensitivity_ohm_per_um','min_detect_disp_um_3sigma','trial_pass'});

trial_csv = fullfile(proc_dir, [stem '_trial_results.csv']);
writetable(trial_table, trial_csv);

artifacts = struct();
artifacts.overlay_png = overlay_png;
artifacts.fft_png = fft_png;
artifacts.trial_csv = trial_csv;
end
