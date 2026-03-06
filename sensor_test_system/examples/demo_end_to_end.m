% DEMO_END_TO_END
% Run a processing-only dry run (no DAQ required) using synthetic data.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

cfg = default_config();
fs = cfg.fs_hz;
t = (0:1/fs:2).';
f0 = 1200;

accel_v = 0.8*sin(2*pi*f0*t);
sensor_v = 0.1*sin(2*pi*f0*t + deg2rad(15)) + 0.01*sin(2*pi*60*t);

qc = quality_checks(t, accel_v, sensor_v, fs);
seg = detect_bad_segments(t, sensor_v, cfg);
stitched = stitch_good_cycles(t, sensor_v, seg.clean_mask);

gp = compute_gain_phase(t, accel_v, sensor_v, f0);
noise = noise_analysis(t, sensor_v, fs, f0, cfg.noise_line_hz);
rs = convert_voltage_to_resistance(sensor_v, cfg.vin_v, cfg.r_ref_ohm);
disp_um = accel_to_displacement(accel_v, fs, f0, cfg.accel_sensitivity_v_per_ms2);

fprintf('QC pass: %d\n', qc.pass);
fprintf('Gain: %.4f\n', gp.gain);
fprintf('Phase: %.2f deg\n', gp.phase_deg);
fprintf('60 Hz ratio: %.4f\n', noise.noise60_ratio);
fprintf('Resistance mean: %.2f ohm\n', mean(rs,'omitnan'));
fprintf('Displacement peak: %.3f um\n', max(abs(disp_um)));
fprintf('Stitched samples: %d\n', stitched.n_samples);

plot_time_signals(t, accel_v, sensor_v);
plot_fft(compute_fft(accel_v, fs), compute_fft(sensor_v, fs));
plot_noise_spectrum(noise);
plot_qc_dashboard(qc);
