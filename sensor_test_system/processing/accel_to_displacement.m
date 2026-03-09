function disp_um = accel_to_displacement(accel_v, fs_hz, f0_hz, accel_sens_v_per_ms2)
%ACCEL_TO_DISPLACEMENT Approximate displacement amplitude around f0.
% Converts voltage to acceleration, bandpasses around tone, then integrates twice.

if nargin < 4 || accel_sens_v_per_ms2 <= 0
    accel_sens_v_per_ms2 = 0.1;
end
accel_ms2 = accel_v / accel_sens_v_per_ms2;

bp = bandpass(accel_ms2, [max(1,f0_hz-100) f0_hz+100], fs_hz);
vel = cumtrapz(bp) / fs_hz;
disp_m = cumtrapz(vel) / fs_hz;
disp_um = disp_m * 1e6;
end
