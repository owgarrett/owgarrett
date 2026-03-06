function gp = compute_gain_phase(t_s, accel_v, sensor_v, f0_hz)
%COMPUTE_GAIN_PHASE Gain and phase at drive tone.

a = extract_tone_amplitude(t_s, accel_v, f0_hz);
s = extract_tone_amplitude(t_s, sensor_v, f0_hz);

gp = struct();
gp.accel_amp = a.amp;
gp.sensor_amp = s.amp;
gp.gain = s.amp / max(a.amp, eps);
gp.phase_deg = rad2deg(wrap_pi(s.phase_rad - a.phase_rad));
end

function y = wrap_pi(x)
y = mod(x + pi, 2*pi) - pi;
end
