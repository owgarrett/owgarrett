function out = compute_fft(x, fs_hz)
%COMPUTE_FFT One-sided FFT magnitude spectrum.

x = x(:) - mean(x);
N = numel(x);
X = fft(x);
f = (0:N-1)*(fs_hz/N);

n_half = floor(N/2)+1;
out.f_hz = f(1:n_half);
out.mag = abs(X(1:n_half))/N*2;
out.phase_rad = angle(X(1:n_half));
end
