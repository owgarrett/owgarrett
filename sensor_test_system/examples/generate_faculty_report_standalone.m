%% GENERATE_FACULTY_REPORT_STANDALONE
% Standalone reporting script (no project function dependencies required).
%
% What it does:
% - Scans one or more processed session folders
% - Reads summary.csv and corresponding raw CSV files
% - Exports Task 1-4 presentation figures + quick metrics CSV
%
% How to use:
% 1) Edit USER SETTINGS below.
% 2) Press Run in MATLAB.
%
% Notes:
% - This script is intentionally self-contained.
% - It does NOT call default_config(), load_raw_data(), compute_fft(), etc.

%% ========================= USER SETTINGS ===============================
% Option A (recommended): point to the processed root and auto-pick sessions
processed_root = fullfile('data','processed');
auto_select_latest_n_sessions = 1;   % set >1 to export multiple recent sessions

% Option B: explicitly provide session directories (relative or absolute)
% Leave empty to use Option A.
explicit_session_dirs = {
    % 'data/processed/SENSOR_001/20260316/session_20260316_120000'
};

% Plotting/analysis controls
bandpass_half_width_hz = 100;
zoom_cycles = 2;
fft_upper_multiplier = 2;   % show up to 2*f0 in FFT task plots

%% ========================= SESSION DISCOVERY ===========================
if isempty(explicit_session_dirs)
    summaries = dir(fullfile(processed_root, '**', 'summary.csv'));
    if isempty(summaries)
        error('No summary.csv found under: %s', processed_root);
    end
    [~, ord] = sort([summaries.datenum], 'descend');
    ord = ord(1:min(auto_select_latest_n_sessions, numel(ord)));
    session_dirs = cellfun(@(f) fileparts(f), fullfile({summaries(ord).folder}, {summaries(ord).name}), 'UniformOutput', false);
else
    session_dirs = explicit_session_dirs;
end

fprintf('Found %d session(s) to process.\n', numel(session_dirs));
for i = 1:numel(session_dirs)
    fprintf('  [%d] %s\n', i, session_dirs{i});
end

%% ========================= RUN EXPORT =================================
for i = 1:numel(session_dirs)
    process_session(session_dirs{i}, bandpass_half_width_hz, zoom_cycles, fft_upper_multiplier);
end

fprintf('\nDone.\n');

%% ========================= LOCAL FUNCTIONS ============================
function process_session(session_proc_dir, bp_half, zoom_cycles, fft_mul)
summary_path = fullfile(session_proc_dir, 'summary.csv');
if ~exist(summary_path, 'file')
    warning('Skipping (no summary.csv): %s', session_proc_dir);
    return;
end

S = readtable(summary_path);
if isempty(S)
    warning('Skipping (empty summary.csv): %s', session_proc_dir);
    return;
end

% Infer raw directory from processed path convention.
raw_dir = strrep(session_proc_dir, [filesep 'processed' filesep], [filesep 'raw' filesep]);
fig_dir = fullfile(session_proc_dir, 'presentation_figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Task 1 - Sensitivity linearity/repeatability
x = S.disp_peak_um;
y = S.sensitivity_ohm_per_um;
valid = isfinite(x) & isfinite(y);
x = x(valid); y = y(valid);
if numel(x) >= 2
    p = polyfit(x, y, 1);
    yhat = polyval(p, x);
    r2 = 1 - sum((y-yhat).^2) / max(sum((y-mean(y)).^2), eps);
else
    yhat = y; r2 = NaN;
end

fig1 = figure('Name','Task1','Color','w');
tiledlayout(1,2, 'TileSpacing', 'compact');
nexttile;
scatter(x, y, 40, 'filled'); hold on;
if numel(x) >= 2
    [xs, idx] = sort(x);
    plot(xs, yhat(idx), 'r-', 'LineWidth', 1.5);
end
grid on;
xlabel('Displacement amplitude (um)');
ylabel('Sensitivity (ohm/um)');
title(sprintf('Task 1: Sensitivity linearity (R^2 = %.3f)', r2));

nexttile;
[g_freq, ~, gidx] = unique(S.freq_hz);
mu = accumarray(gidx, S.sensitivity_ohm_per_um, [], @(v) mean(v,'omitnan'));
sd = accumarray(gidx, S.sensitivity_ohm_per_um, [], @(v) std(v,'omitnan'));
errorbar(g_freq, mu, sd, '-o', 'LineWidth', 1.3); grid on;
xlabel('Frequency (Hz)'); ylabel('Sensitivity (ohm/um)');
title('Task 1: Repeatability by frequency');
saveas(fig1, fullfile(fig_dir, 'task1_sensitivity_linearity.png'));

%% Task 2 - Detection limit + SNR + pass rate
fig2 = figure('Name','Task2','Color','w');
tiledlayout(1,2, 'TileSpacing', 'compact');
nexttile;
min_detect = accumarray(gidx, S.min_detect_disp_um_3sigma, [], @(v) mean(v,'omitnan'));
plot(g_freq, min_detect, '-o', 'LineWidth', 1.5); grid on;
xlabel('Frequency (Hz)'); ylabel('Min detectable displacement (um)');
title('Task 2: Detection limit');

nexttile;
snr_mu = accumarray(gidx, S.snr_db, [], @(v) mean(v,'omitnan'));
pass_rate = accumarray(gidx, S.trial_pass, [], @(v) mean(v,'omitnan'));
plot(g_freq, snr_mu, '-o', 'LineWidth', 1.5); hold on;
yyaxis right; plot(g_freq, pass_rate*100, '--s', 'LineWidth', 1.4); ylabel('Pass rate (%)'); ylim([0 100]);
yyaxis left; ylabel('SNR (dB)');
grid on; xlabel('Frequency (Hz)');
title('Task 2: SNR and pass-rate');
legend({'Mean SNR','Pass rate'}, 'Location','best');
saveas(fig2, fullfile(fig_dir, 'task2_detection_limit_snr.png'));

%% Task 3 - Pipeline validation + FFT amplitudes
f_mode = mode(S.freq_hz);
idx_mode = find(S.freq_hz == f_mode, 1, 'first');
if isempty(idx_mode), idx_mode = 1; end

raw_path = fullfile(raw_dir, S.raw_file{idx_mode});
if exist(raw_path, 'file')
    D = read_raw_csv(raw_path);
    fs = estimate_fs(D.time_s);

    lo = max(1, f_mode - bp_half);
    hi = f_mode + bp_half;
    a_raw = detrend(D.accel_v, 0);
    s_raw = detrend(D.sensor_v, 0);
    a_f = bandpass(a_raw, [lo hi], fs);
    s_f = bandpass(s_raw, [lo hi], fs);

    [tz, az, sz] = two_cycle_zoom(D.time_s, norm01(a_f), norm01(s_f), f_mode, zoom_cycles);

    fig3 = figure('Name','Task3','Color','w');
    tiledlayout(1,2, 'TileSpacing','compact');
    nexttile;
    plot(tz, az, 'b-', 'LineWidth', 1.4); hold on;
    plot(tz, sz, 'r-', 'LineWidth', 1.2);
    grid on; ylim([0 1]);
    xlabel('Time (s)'); ylabel('Normalized (0-1)');
    title('Task 3: Filtered normalized overlay (~2 cycles)');
    legend({'Accel','Sensor'}, 'Location','best');

    nexttile;
    Fr = one_sided_fft(s_raw, fs);
    Ff = one_sided_fft(s_f, fs);
    m1 = Fr.f_hz <= max(fft_mul*f_mode, 2000);
    m2 = Ff.f_hz <= max(fft_mul*f_mode, 2000);
    plot(Fr.f_hz(m1), Fr.mag(m1), 'Color', [0.75 0.75 0.75]); hold on;
    plot(Ff.f_hz(m2), Ff.mag(m2), 'r', 'LineWidth', 1.3);
    xline(f_mode, 'k--', 'f0'); grid on;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title('Task 3: FFT raw vs filtered');
    legend({'Raw','Filtered','f0'}, 'Location','best');
    saveas(fig3, fullfile(fig_dir, 'task3_pipeline_validation.png'));

    % FFT at varying amplitudes
    fig3b = figure('Name','Task3 FFT amplitudes','Color','w'); hold on;
    amps = unique(S.amp(S.freq_hz == f_mode));
    for k = 1:numel(amps)
        rr = find(S.freq_hz == f_mode & S.amp == amps(k), 1, 'first');
        if isempty(rr), continue; end
        pth = fullfile(raw_dir, S.raw_file{rr});
        if ~exist(pth, 'file'), continue; end
        Di = read_raw_csv(pth);
        fsi = estimate_fs(Di.time_s);
        sfi = bandpass(detrend(Di.sensor_v,0), [lo hi], fsi);
        Fi = one_sided_fft(sfi, fsi);
        mi = Fi.f_hz <= max(fft_mul*f_mode, 2000);
        plot(Fi.f_hz(mi), Fi.mag(mi), 'LineWidth', 1.1, 'DisplayName', sprintf('%.2g Vpp', amps(k)));
    end
    xline(f_mode, 'k--', 'f0'); grid on;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title(sprintf('Task 3: FFT at varying amplitudes (%.1f Hz)', f_mode));
    legend('Location','best');
    saveas(fig3b, fullfile(fig_dir, 'task3_fft_varying_amplitudes.png'));
else
    warning('Task 3 skipped: raw CSV not found: %s', raw_path);
end

%% Task 4 - Frequency response
fig4 = figure('Name','Task4','Color','w');
tiledlayout(1,2, 'TileSpacing', 'compact');
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
saveas(fig4, fullfile(fig_dir, 'task4_frequency_response.png'));

%% Quick metrics CSV for slide text boxes
Tquick = table();
Tquick.mean_snr_db = mean(S.snr_db, 'omitnan');
Tquick.mean_min_detect_um = mean(S.min_detect_disp_um_3sigma, 'omitnan');
Tquick.mean_clean_fraction = mean(S.clean_fraction, 'omitnan');
Tquick.pass_rate_pct = 100*mean(S.trial_pass, 'omitnan');
Tquick.task1_linearity_r2 = r2;
writetable(Tquick, fullfile(fig_dir, 'presentation_quick_metrics.csv'));

fprintf('\nPresentation figures generated in:\n  %s\n', fig_dir);
end

function D = read_raw_csv(path)
T = readtable(path);
D.time_s = T.time_s(:);
D.accel_v = T.accel_v(:);
D.sensor_v = T.sensor_v(:);
end

function fs = estimate_fs(t)
dt = diff(t(:));
fs = 1 / max(mean(dt, 'omitnan'), eps);
end

function F = one_sided_fft(x, fs)
x = x(:) - mean(x, 'omitnan');
N = numel(x);
X = fft(x);
f = (0:N-1)*(fs/N);
n = floor(N/2)+1;
F.f_hz = f(1:n);
F.mag = 2*abs(X(1:n))/max(N,1);
end

function y = norm01(x)
x = x(:);
y = (x - min(x)) / max(max(x)-min(x), eps);
end

function [tz, az, sz] = two_cycle_zoom(t, a, s, f0, ncyc)
if isempty(t) || f0 <= 0
    tz = t; az = a; sz = s; return;
end
t_end = t(1) + ncyc/f0;
idx = t <= t_end;
if nnz(idx) < 10, idx = true(size(t)); end
tz = t(idx); az = a(idx); sz = s(idx);
end
