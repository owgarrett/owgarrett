function metrics = compute_trial_metrics(t_s, accel_v, sensor_v, f0_hz, cfg)
%COMPUTE_TRIAL_METRICS Quantitative metrics for V&V on a single trial.

qc = quality_checks(t_s, accel_v, sensor_v, cfg.fs_hz);
seg = detect_bad_segments(t_s, sensor_v, cfg);

% Use stitched clean region when enough samples survive.
clean_mask = seg.clean_mask;
if nnz(clean_mask) < max(100, round(0.1*numel(t_s)))
    clean_mask = true(size(t_s));
end

t_clean = t_s(clean_mask);
a_clean = accel_v(clean_mask);
s_clean = sensor_v(clean_mask);

% Core frequency-domain metrics.
gp = compute_gain_phase(t_clean, a_clean, s_clean, f0_hz);
noise = noise_analysis(t_clean, s_clean, cfg.fs_hz, f0_hz, cfg.noise_line_hz);

% FFT noise floor-based SNR at tone.
fft_s = compute_fft(s_clean, cfg.fs_hz);
[~, i_f0] = min(abs(fft_s.f_hz - f0_hz));
exclude = abs(fft_s.f_hz - f0_hz) < 5;
noise_floor = median(fft_s.mag(~exclude));
snr_db = 20*log10(max(fft_s.mag(i_f0), eps) / max(noise_floor, eps));

% Convert to physical-ish units for displacement and sensitivity estimate.
disp_um = accel_to_displacement(a_clean, cfg.fs_hz, f0_hz, cfg.accel_sensitivity_v_per_ms2);
rs_ohm = convert_voltage_to_resistance(s_clean, cfg.vin_v, cfg.r_ref_ohm);
delta_r = rs_ohm - mean(rs_ohm, 'omitnan');

% Tone amplitudes on derived quantities.
r_tone = extract_tone_amplitude(t_clean, fillmissing(delta_r, 'constant', 0), f0_hz);
d_tone = extract_tone_amplitude(t_clean, disp_um, f0_hz);

sensitivity_ohm_per_um = r_tone.amp / max(d_tone.amp, eps);

% Estimate minimum detectable displacement from residual 3-sigma floor.
r_model = r_tone.amp * cos(2*pi*f0_hz*t_clean + r_tone.phase_rad);
r_resid = fillmissing(delta_r, 'constant', 0) - r_model;
r_noise_std = std(r_resid, 'omitnan');
min_detect_disp_um_3sigma = (3*r_noise_std) / max(abs(sensitivity_ohm_per_um), eps);

% Trial-level pass/fail gates.
pass_snr = snr_db >= cfg.vv.min_snr_db;
pass_clean = seg.clean_fraction >= cfg.vv.min_clean_fraction;
trial_pass = qc.pass && pass_snr && pass_clean;

metrics = struct();
metrics.qc = qc;
metrics.seg = seg;
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
end
