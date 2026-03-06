function cfg = default_config()
%DEFAULT_CONFIG Baseline configuration for NI shaker sensor testing.

cfg.project_root = fileparts(fileparts(mfilename('fullpath')));
cfg.data_root = fullfile(cfg.project_root, 'data');

cfg.device = "Dev1";
cfg.ai_accel = "ai0";
cfg.ai_sensor = "ai1";

cfg.fs_hz = 50000;
cfg.duration_s = 2.0;
cfg.settle_s = 1.0;

cfg.sensor_id = "SENSOR_001";
cfg.session_id = "";
cfg.auto_session_id = true;

cfg.freqs_hz = [100 200 500 800 1000 1100 1200];
cfg.amps = [0.2 0.5 1.0];
cfg.deep_dive_reps = 5;

cfg.vin_v = 5.0;
cfg.r_ref_ohm = 50000;
cfg.accel_sensitivity_v_per_ms2 = 0.1; % update with your accelerometer calibration

cfg.bandpass_half_width_hz = 100;
cfg.noise_line_hz = 60;
cfg.segment.min_clean_duration_s = 0.2;
cfg.segment.derivative_sigma = 5;
cfg.segment.envelope_floor = 0.15;


cfg.vv.min_snr_db = 10;
cfg.vv.min_clean_fraction = 0.70;

cfg.prompt_user = true;
end
