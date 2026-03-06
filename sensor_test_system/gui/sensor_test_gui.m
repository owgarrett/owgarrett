function sensor_test_gui()
%SENSOR_TEST_GUI Minimal GUI for running acquisition workflows.
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
uilabel(fig,'Text','Amp list','Position',[420 525 80 22]);
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

            S = readtable(out.summary_csv);
            raw_file = char(S.raw_file(end));
            raw_path = fullfile(out.raw_dir, raw_file);
            d = load_raw_data(raw_path);

            plot(ax1, d.t_s, d.accel_v); hold(ax1,'on'); plot(ax1, d.t_s, d.sensor_v); hold(ax1,'off'); grid(ax1,'on');
            legend(ax1, {'Accel','Sensor'});

            fa = compute_fft(d.accel_v, local_cfg.fs_hz);
            fs = compute_fft(d.sensor_v, local_cfg.fs_hz);
            plot(ax2, fa.f_hz, fa.mag); hold(ax2,'on'); plot(ax2, fs.f_hz, fs.mag); hold(ax2,'off'); grid(ax2,'on');
            legend(ax2, {'Accel','Sensor'});
        catch ME
            status.Value = [status.Value; "ERROR: " + string(ME.message)];
        end
    end
end
