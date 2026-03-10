function sensor_test_gui()
%SENSOR_TEST_GUI Minimal GUI for running acquisition workflows.
% Add project subfolders so this GUI can be launched from any working folder.
gui_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(gui_dir);
addpath(genpath(project_root));

cfg = default_config();

fig = uifigure('Name','Sensor Test System','Position',[100 100 900 600]);

uilabel(fig,'Text','Device','Position',[20 560 80 22]);
edev = uieditfield(fig,'text','Value',char(cfg.device),'Position',[100 560 100 22]);
uilabel(fig,'Text','AI0','Position',[220 560 40 22]);
eai0 = uieditfield(fig,'text','Value',char(cfg.ai_accel),'Position',[260 560 80 22]);
uilabel(fig,'Text','AI1','Position',[360 560 40 22]);
eai1 = uieditfield(fig,'text','Value',char(cfg.ai_sensor),'Position',[400 560 80 22]);
uilabel(fig,'Text','Fs (Hz)','Position',[500 560 60 22]);
efs = uieditfield(fig,'numeric','Value',cfg.fs_hz,'Position',[560 560 90 22]);
uilabel(fig,'Text','Duration (s)','Position',[670 560 80 22]);
edur = uieditfield(fig,'numeric','Value',cfg.duration_s,'Position',[750 560 90 22]);

uilabel(fig,'Text','Freq list [Hz]','Position',[20 525 100 22]);
ef = uieditfield(fig,'text','Value',mat2str(cfg.freqs_hz),'Position',[120 525 280 22]);
uilabel(fig,'Text','Amp list [Vpp]','Position',[420 525 80 22]);
ea = uieditfield(fig,'text','Value',mat2str(cfg.amps),'Position',[500 525 180 22]);

status = uitextarea(fig,'Position',[20 20 860 130],'Editable','off');
ax1 = uiaxes(fig,'Position',[20 170 410 330]); title(ax1,'Time Preview');
ax2 = uiaxes(fig,'Position',[470 170 410 330]); title(ax2,'FFT Preview');

uibutton(fig,'Text','Start Single Test','Position',[20 490 140 28], 'ButtonPushedFcn', @(~,~)run_mode("single"));
uibutton(fig,'Text','Run Frequency Sweep','Position',[170 490 150 28], 'ButtonPushedFcn', @(~,~)run_mode("frequency_sweep"));
uibutton(fig,'Text','Run Amplitude Sweep','Position',[330 490 150 28], 'ButtonPushedFcn', @(~,~)run_mode("amplitude_sweep"));
uibutton(fig,'Text','Run Deep Dive','Position',[490 490 120 28], 'ButtonPushedFcn', @(~,~)run_mode("deep_dive"));

    function run_mode(mode)
        try
            local_cfg = cfg;
            local_cfg.device = string(edev.Value);
            local_cfg.ai_accel = string(eai0.Value);
            local_cfg.ai_sensor = string(eai1.Value);
            local_cfg.fs_hz = efs.Value;
            local_cfg.duration_s = edur.Value;
            local_cfg.freqs_hz = str2num(ef.Value); %#ok<ST2NM>
            local_cfg.amps = str2num(ea.Value); %#ok<ST2NM>
            local_cfg.prompt_user = true;

            out = run_experiment(local_cfg, mode);
            status.Value = [status.Value; "Completed " + mode + " -> " + string(out.summary_csv)];
            status.Value = [status.Value; "Output folder: " + string(out.proc_dir)];

            S = readtable(out.summary_csv);
            last = S(end,:);
            pass_txt = "FAIL";
            if logical(last.trial_pass)
                pass_txt = "PASS";
            end
            status.Value = [status.Value; ...
                "Trial verdict: " + pass_txt + ...
                " | SNR(dB)=" + string(round(last.snr_db,2)) + ...
                " | Gain=" + string(round(last.gain,4)) + ...
                " | Phase(deg)=" + string(round(last.phase_deg,2)) + ...
                " | MinDetect(um)=" + string(round(last.min_detect_disp_um_3sigma,4))];
            if isfield(out, 'verification_report')
                status.Value = [status.Value; "Verification report: " + string(out.verification_report)];
            end
            if isfield(out, 'verification_plot')
                status.Value = [status.Value; "Verification plot: " + string(out.verification_plot)];
            end

            raw_file = char(S.raw_file(end));
            raw_path = fullfile(out.raw_dir, raw_file);
            d = load_raw_data(raw_path);

            f0 = last.freq_hz;
            lo = max(1, f0 - local_cfg.bandpass_half_width_hz);
            hi = f0 + local_cfg.bandpass_half_width_hz;
            a_f = bandpass(d.accel_v, [lo hi], local_cfg.fs_hz);
            s_f = bandpass(d.sensor_v, [lo hi], local_cfg.fs_hz);

            t = d.t_s(:);
            t_end = t(1) + 2/max(f0,1);
            idx = t <= t_end;
            if nnz(idx) < 10
                idx = true(size(t));
            end

            a_n = norm01(a_f(idx));
            s_n = norm01(s_f(idx));
            plot(ax1, t(idx), a_n, 'LineWidth', 1.4); hold(ax1,'on');
            plot(ax1, t(idx), s_n, 'LineWidth', 1.2); hold(ax1,'off');
            ylim(ax1, [0 1]); grid(ax1,'on');
            title(ax1, sprintf('Time Preview (~2 cycles @ %.1f Hz, normalized)', f0));
            legend(ax1, {'Accel filt','Sensor filt'}, 'Location', 'best');

            fa = compute_fft(s_f, local_cfg.fs_hz);
            plot(ax2, fa.f_hz, fa.mag, 'r', 'LineWidth', 1.2); hold(ax2,'on');
            xline(ax2, f0, 'k--', 'f0'); hold(ax2,'off');
            xlim(ax2, [0 max(2*f0, 2000)]); grid(ax2,'on');
            title(ax2, 'Sensor FFT (filtered)');
            legend(ax2, {'Sensor FFT','f0'}, 'Location', 'best');
        catch ME
            status.Value = [status.Value; "ERROR: " + string(ME.message)];
        end
    end
end

function y = norm01(x)
x = x(:);
y = (x - min(x)) / max(max(x)-min(x), eps);
end
