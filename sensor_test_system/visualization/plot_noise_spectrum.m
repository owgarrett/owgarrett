function plot_noise_spectrum(noise)
%PLOT_NOISE_SPECTRUM Plot FFT with dominant and line-noise markers.
figure('Name','Noise Spectrum');
plot(noise.fft.f_hz, noise.fft.mag); hold on; grid on;
xline(noise.dominant_freq_hz,'r--','Dominant');
xline(60,'k:','60 Hz');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
end
