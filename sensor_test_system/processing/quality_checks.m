function qc = quality_checks(t_s, accel_v, sensor_v, fs_hz)
%QUALITY_CHECKS Basic QC checks for timing, clipping, and finite values.

dt = diff(t_s);
expected_dt = 1/fs_hz;

qc = struct();
qc.dt_mean = mean(dt);
qc.dt_std = std(dt);
qc.irregular_timing = any(dt > 2*expected_dt) || (qc.dt_std > 0.1*expected_dt);
qc.has_nan_inf = any(~isfinite(accel_v)) || any(~isfinite(sensor_v));
qc.clipping = any(abs(accel_v) > 9.9) || any(abs(sensor_v) > 9.9);
qc.pass = ~(qc.irregular_timing || qc.has_nan_inf || qc.clipping);
end
