function n = noise_analysis(t_s, x, fs_hz, f0_hz, line_hz)
%NOISE_ANALYSIS Dominant frequency, harmonics, and 60 Hz ratio.
if nargin < 5
    line_hz = 60;
end

fft_out = compute_fft(x, fs_hz);
[pk, idx] = max(fft_out.mag);

n = struct();
n.dominant_freq_hz = fft_out.f_hz(idx);
n.dominant_mag = pk;

harm_freqs = (2:5) * f0_hz;
n.harmonics = zeros(numel(harm_freqs),2);
for k = 1:numel(harm_freqs)
    [~, ii] = min(abs(fft_out.f_hz - harm_freqs(k)));
    n.harmonics(k,:) = [fft_out.f_hz(ii), fft_out.mag(ii)];
end

[~, i60] = min(abs(fft_out.f_hz - line_hz));
rms_x = rms(x - mean(x));
n.noise60_ratio = fft_out.mag(i60) / max(rms_x, eps);
n.fft = fft_out;
end
