function trial = acquire_trial(dq, cfg, f0_hz, amp, rep_idx)
%ACQUIRE_TRIAL Perform one foreground acquisition with metadata.

if cfg.prompt_user
    fprintf('\nSet shaker: f0=%.2f Hz, amplitude=%.4g, rep=%d\n', f0_hz, amp, rep_idx);
    input('Press ENTER when ready: ', 's');
end
pause(cfg.settle_s);

tt = read(dq, seconds(cfg.duration_s), 'OutputFormat', 'timetable');

t = seconds(tt.Time - tt.Time(1));
accel_v = tt{:,1};
sensor_v = tt{:,2};

dt = diff(t);
trial = struct();
trial.t_s = t;
trial.accel_v = accel_v;
trial.sensor_v = sensor_v;
trial.f0_hz = f0_hz;
trial.amp = amp;
trial.rep_idx = rep_idx;
trial.timestamp = string(datestr(now,'yyyy-mm-dd HH:MM:SS'));
trial.dt_mean = mean(dt);
trial.dt_std = std(dt);
trial.dropout_flag = any(dt > 2*(1/cfg.fs_hz)) || (trial.dt_std > 0.1*(1/cfg.fs_hz));
trial.num_samples = numel(t);
end
