function dq = daq_setup(cfg)
%DAQ_SETUP Configure modern DataAcquisition object for NI hardware.

vendors = daq.getVendors;
is_ni_ok = any(strcmp({vendors.ID}, 'ni') & [vendors.IsOperational]);
if ~is_ni_ok
    error('NI vendor is not operational. Check NI-DAQmx and MATLAB support package.');
end

dq = daq("ni");
dq.Rate = cfg.fs_hz;

addinput(dq, cfg.device, normalize_channel(cfg.ai_accel), "Voltage");
addinput(dq, cfg.device, normalize_channel(cfg.ai_sensor), "Voltage");
end

function ch = normalize_channel(raw)
s = string(raw);
if startsWith(lower(s), "ai")
    ch = char(s);
else
    ch = sprintf('ai%d', str2double(s));
end
end
