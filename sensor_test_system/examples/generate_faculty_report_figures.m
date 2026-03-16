function out = generate_faculty_report_figures(session_proc_dir)
%GENERATE_FACULTY_REPORT_FIGURES Build presentation-ready Task 1-4 figures.
% Usage:
%   generate_faculty_report_figures()
%   generate_faculty_report_figures('data/processed/<sensor>/<date>/<session>')

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));
cfg = default_config();

if nargin < 1 || strlength(string(session_proc_dir)) == 0
    session_proc_dir = find_latest_processed_dir(root);
end
session_proc_dir = char(session_proc_dir);
summary_path = fullfile(session_proc_dir, 'summary.csv');
if ~exist(summary_path, 'file')
    error('No summary.csv found in %s', session_proc_dir);
end

raw_dir = strrep(session_proc_dir, [filesep 'processed' filesep], [filesep 'raw' filesep]);
S = readtable(summary_path);
fig_dir = fullfile(session_proc_dir, 'presentation_figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

% ---------------- Task 1: sensitivity / linearity / repeatability ----------------
x = S.disp_peak_um;
y = S.sensitivity_ohm_per_um;
valid = isfinite(x) & isfinite(y);
x = x(valid); y = y(valid);

if numel(x) >= 2
    p = polyfit(x, y, 1);
    yhat = polyval(p, x);
    r2 = 1 - sum((y-yhat).^2) / max(sum((y-mean(y)).^2), eps);
else
    p = [NaN NaN]; r2 = NaN; yhat = y;
end

fig1 = figure('Name','Task1','Color','w');
tiledlayout(1,2, 'TileSpacing','compact');
nexttile;
scatter(x, y, 40, 'filled'); hold on;
if numel(x) >= 2
    [xs, idx] = sort(x);
    plot(xs, yhat(idx), 'r-', 'LineWidth', 1.5);
end
grid on;
xlabel('Displacement amplitude (um)');
ylabel('Sensitivity (ohm/um)');
title(sprintf('Task 1: Linearity (R^2 = %.3f)', r2));

nexttile;
[g_freq, ~, gidx] = unique(S.freq_hz);
mu = accumarray(gidx, S.sensitivity_ohm_per_um, [], @(v) mean(v,'omitnan'));
sd = accumarray(gidx, S.sensitivity_ohm_per_um, [], @(v) std(v,'omitnan'));
errorbar(g_freq, mu, sd, '-o', 'LineWidth', 1.3); grid on;
xlabel('Frequency (Hz)'); ylabel('Sensitivity (ohm/um)');
title('Repeatability across frequencies');

task1_png = fullfile(fig_dir, 'task1_sensitivity_linearity.png');
saveas(fig1, task1_png);

% ---------------- Task 2: minimum detectable motion + SNR ----------------
fig2 = figure('Name','Task2','Color','w');
tiledlayout(1,2, 'TileSpacing','compact');
nexttile;
[g_freq, ~, gidx] = unique(S.freq_hz);
min_detect = accumarray(gidx, S.min_detect_disp_um_3sigma, [], @(v) mean(v,'omitnan'));
plot(g_freq, min_detect, '-o', 'LineWidth', 1.5); grid on;
xlabel('Frequency (Hz)'); ylabel('Min detectable displacement (um)');
title('Task 2: Detection limit vs frequency');

nexttile;
snr_mu = accumarray(gidx, S.snr_db, [], @(v) mean(v,'omitnan'));
pass_rate = accumarray(gidx, S.trial_pass, [], @(v) mean(v,'omitnan'));
plot(g_freq, snr_mu, '-o', 'LineWidth', 1.5); hold on;
yyaxis right; plot(g_freq, pass_rate*100, '--s', 'LineWidth', 1.4);
ylabel('Trial pass rate (%)'); ylim([0 100]);
yyaxis left; ylabel('SNR (dB)');
grid on; xlabel('Frequency (Hz)');
title('Task 2: SNR and pass rate');
legend({'Mean SNR','Pass rate'}, 'Location','best');

task2_png = fullfile(fig_dir, 'task2_detection_limit_snr.png');
saveas(fig2, task2_png);

% ---------------- Task 3: pipeline validation ----------------
f_mode = mode(S.freq_hz);
idx_mode = find(S.freq_hz == f_mode, 1, 'first');
if isempty(idx_mode), idx_mode = 1; end
raw_path = fullfile(raw_dir, S.raw_file{idx_mode});
D = load_raw_data(raw_path);

lo = max(1, f_mode - cfg.bandpass_half_width_hz);
hi = f_mode + cfg.bandpass_half_width_hz;
a_raw = detrend(D.accel_v(:), 0);
s_raw = detrend(D.sensor_v(:), 0);
a_f = bandpass(a_raw, [lo hi], cfg.fs_hz);
s_f = bandpass(s_raw, [lo hi], cfg.fs_hz);

[tz, az, sz] = get_two_cycle_zoom(D.t_s(:), norm01(a_f), norm01(s_f), f_mode);

fig3 = figure('Name','Task3','Color','w');
tiledlayout(1,2, 'TileSpacing','compact');
nexttile;
plot(tz, az, 'b-', 'LineWidth', 1.4); hold on;
plot(tz, sz, 'r-', 'LineWidth', 1.2);
grid on; ylim([0 1]);
xlabel('Time (s)'); ylabel('Normalized (0-1)');
title('Task 3: Filtered + normalized overlay (~2 cycles)');
legend({'Accel','Sensor'}, 'Location','best');

nexttile;
fr = compute_fft(s_raw, cfg.fs_hz);
ff = compute_fft(s_f, cfg.fs_hz);
plot(fr.f_hz, fr.mag, 'Color', [0.75 0.75 0.75]); hold on;
plot(ff.f_hz, ff.mag, 'r', 'LineWidth', 1.3);
xline(f_mode, 'k--', 'f0');
xlim([0 max(2*f_mode, 2000)]); grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('Task 3: FFT isolates excitation frequency');
legend({'Raw','Filtered','f0'}, 'Location','best');

task3_png = fullfile(fig_dir, 'task3_pipeline_validation.png');
saveas(fig3, task3_png);

% Extra FFT at varying amplitudes
fig3b = figure('Name','Task3 FFT amplitudes','Color','w'); hold on;
amps = unique(S.amp(S.freq_hz == f_mode));
for k = 1:numel(amps)
    rr = find(S.freq_hz == f_mode & S.amp == amps(k), 1, 'first');
    if isempty(rr), continue; end
    pth = fullfile(raw_dir, S.raw_file{rr});
    if ~exist(pth, 'file'), continue; end
    Di = load_raw_data(pth);
    sf = bandpass(detrend(Di.sensor_v(:),0), [lo hi], cfg.fs_hz);
    Fi = compute_fft(sf, cfg.fs_hz);
    m = Fi.f_hz <= max(2*f_mode, 2000);
    plot(Fi.f_hz(m), Fi.mag(m), 'LineWidth', 1.1, 'DisplayName', sprintf('%.2g Vpp', amps(k)));
end
xline(f_mode, 'k--', 'f0'); grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title(sprintf('Task 3: FFT at varying amplitudes (%.1f Hz)', f_mode));
legend('Location','best');

task3b_png = fullfile(fig_dir, 'task3_fft_varying_amplitudes.png');
saveas(fig3b, task3b_png);

% ---------------- Task 4: frequency response ----------------
fig4 = figure('Name','Task4','Color','w');
tiledlayout(1,2, 'TileSpacing','compact');
nexttile;
gain_mu = accumarray(gidx, S.gain, [], @(v) mean(v,'omitnan'));
gain_sd = accumarray(gidx, S.gain, [], @(v) std(v,'omitnan'));
errorbar(g_freq, gain_mu, gain_sd, '-o', 'LineWidth', 1.4); grid on;
xlabel('Frequency (Hz)'); ylabel('Gain');
title('Task 4: Gain frequency response');

nexttile;
phase_mu = accumarray(gidx, S.phase_deg, [], @(v) mean(v,'omitnan'));
phase_sd = accumarray(gidx, S.phase_deg, [], @(v) std(v,'omitnan'));
errorbar(g_freq, phase_mu, phase_sd, '-o', 'LineWidth', 1.4); grid on;
xlabel('Frequency (Hz)'); ylabel('Phase (deg)');
title('Task 4: Phase frequency response');

task4_png = fullfile(fig_dir, 'task4_frequency_response.png');
saveas(fig4, task4_png);

% One-page quick metrics table.
Tquick = table();
Tquick.mean_snr_db = mean(S.snr_db, 'omitnan');
Tquick.mean_min_detect_um = mean(S.min_detect_disp_um_3sigma, 'omitnan');
Tquick.mean_clean_fraction = mean(S.clean_fraction, 'omitnan');
Tquick.pass_rate_pct = 100*mean(S.trial_pass, 'omitnan');
Tquick.task1_linearity_r2 = r2;
quick_csv = fullfile(fig_dir, 'presentation_quick_metrics.csv');
writetable(Tquick, quick_csv);

out = struct();
out.figure_dir = fig_dir;
out.files = {task1_png, task2_png, task3_png, task3b_png, task4_png, quick_csv};

fprintf('\nGenerated faculty report figures in:\n  %s\n', fig_dir);
for i = 1:numel(out.files)
    fprintf('  - %s\n', out.files{i});
end
end

function y = norm01(x)
x = x(:);
y = (x - min(x)) / max(max(x)-min(x), eps);
end

function [tz, az, sz] = get_two_cycle_zoom(t, a, s, f0)
if isempty(t) || f0 <= 0
    tz = t; az = a; sz = s; return;
end
t_end = t(1) + 2/f0;
idx = t <= t_end;
if nnz(idx) < 10, idx = true(size(t)); end
tz = t(idx); az = a(idx); sz = s(idx);
end

function p = find_latest_processed_dir(root)
all = dir(fullfile(root, 'data', 'processed', '**', 'summary.csv'));
if isempty(all)
    error('No processed sessions found under data/processed. Run acquisition first.');
end
[~, ix] = max([all.datenum]);
p = all(ix).folder;
end
