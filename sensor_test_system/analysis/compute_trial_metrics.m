function metrics = compute_trial_metrics(t_s, accel_v, sensor_v, f0_hz, cfg)
%COMPUTE_TRIAL_METRICS Quantitative V&V metrics using filtered clean signals.

% Detrend raw signals.
t = t_s(:);
a_raw = detrend(accel_v(:), 0);
s_raw = detrend(sensor_v(:), 0);

% Bandpass around excitation.
lo = max(1, f0_hz - cfg.bandpass_half_width_hz);
hi = f0_hz + cfg.bandpass_half_width_hz;
a_filt = bandpass(a_raw, [lo hi], cfg.fs_hz);
s_filt = bandpass(s_raw, [lo hi], cfg.fs_hz);

% QC + bad-segment detection (on filtered channels).
qc = quality_checks(t, a_raw, s_raw, cfg.fs_hz);
seg_s = detect_bad_segments(t, s_filt, cfg);
seg_a = detect_bad_segments(t, a_filt, cfg);
clean_mask = seg_s.clean_mask & seg_a.clean_mask;
clean_fraction = mean(clean_mask);

if nnz(clean_mask) < max(100, round(0.1*numel(t)))
    clean_mask = true(size(t));
end

t_clean = t(clean_mask);
a_clean = a_filt(clean_mask);
s_clean = s_filt(clean_mask);

% Core frequency-domain metrics on clean, filtered signal.
gp = compute_gain_phase(t_clean, a_clean, s_clean, f0_hz);
noise = noise_analysis(t, s_raw, cfg.fs_hz, f0_hz, cfg.noise_line_hz);

fft_s = compute_fft(s_clean, cfg.fs_hz);
[~, i_f0] = min(abs(fft_s.f_hz - f0_hz));
exclude = abs(fft_s.f_hz - f0_hz) < 5;
noise_floor = median(fft_s.mag(~exclude));
snr_db = 20*log10(max(fft_s.mag(i_f0), eps) / max(noise_floor, eps));

% Physical estimates.
disp_um = accel_to_displacement(a_clean, cfg.fs_hz, f0_hz, cfg.accel_sensitivity_v_per_ms2);
rs_ohm = convert_voltage_to_resistance(s_clean, cfg.vin_v, cfg.r_ref_ohm);
delta_r = rs_ohm - mean(rs_ohm, 'omitnan');

r_tone = extract_tone_amplitude(t_clean, fillmissing(delta_r, 'constant', 0), f0_hz);
d_tone = extract_tone_amplitude(t_clean, disp_um, f0_hz);
sensitivity_ohm_per_um = r_tone.amp / max(d_tone.amp, eps);

r_model = r_tone.amp * cos(2*pi*f0_hz*t_clean + r_tone.phase_rad);
r_resid = fillmissing(delta_r, 'constant', 0) - r_model;
r_noise_std = std(r_resid, 'omitnan');
min_detect_disp_um_3sigma = (3*r_noise_std) / max(abs(sensitivity_ohm_per_um), eps);

% Pass/fail thresholds.
pass_snr = snr_db >= cfg.vv.min_snr_db;
pass_clean = clean_fraction >= cfg.vv.min_clean_fraction;
trial_pass = qc.pass && pass_snr && pass_clean;

metrics = struct();
metrics.qc = qc;
metrics.seg.clean_mask = clean_mask;
metrics.seg.clean_fraction = clean_fraction;
metrics.gp = gp;
metrics.noise = noise;
metrics.snr_db = snr_db;
metrics.noise_floor = noise_floor;
metrics.disp_peak_um = max(abs(disp_um));
metrics.sensitivity_ohm_per_um = sensitivity_ohm_per_um;
metrics.min_detect_disp_um_3sigma = min_detect_disp_um_3sigma;
metrics.pass_snr = pass_snr;
metrics.pass_clean = pass_clean;
metrics.trial_pass = trial_pass;

% Include processed traces for auto-report plotting.
metrics.traces.t = t;
metrics.traces.accel_raw = a_raw;
metrics.traces.sensor_raw = s_raw;
metrics.traces.accel_filt = a_filt;
metrics.traces.sensor_filt = s_filt;
metrics.traces.t_clean = t_clean;
metrics.traces.accel_clean = a_clean;
metrics.traces.sensor_clean = s_clean;
metrics.traces.accel_norm_01 = norm01(a_filt);
metrics.traces.sensor_norm_01 = norm01(s_filt);
metrics.traces.accel_clean_norm_01 = norm01(a_clean);
metrics.traces.sensor_clean_norm_01 = norm01(s_clean);
end

function y = norm01(x)
x = x(:);
xmin = min(x);
xmax = max(x);
y = (x - xmin) / max(xmax - xmin, eps);
end
