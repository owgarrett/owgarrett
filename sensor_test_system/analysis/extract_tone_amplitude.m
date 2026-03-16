function tone = extract_tone_amplitude(t_s, x, f0_hz)
%EXTRACT_TONE_AMPLITUDE Estimate tone amplitude and phase by correlation.

x = x(:) - mean(x);
t = t_s(:);
w = 2*pi*f0_hz;
c = sum(x .* exp(-1j*w*t));

tone = struct();
tone.amp = 2*abs(c)/numel(t);
tone.phase_rad = angle(c);
end
