function paths = path_helpers(cfg)
%PATH_HELPERS Build and create deterministic data paths.

if strlength(string(cfg.session_id)) == 0
    cfg.session_id = "session_" + string(datestr(now,'yyyymmdd_HHMMSS'));
end

date_tag = string(datestr(now,'yyyymmdd'));
paths.raw_dir = fullfile(cfg.data_root, 'raw', char(cfg.sensor_id), char(date_tag), char(cfg.session_id));
paths.proc_dir = fullfile(cfg.data_root, 'processed', char(cfg.sensor_id), char(date_tag), char(cfg.session_id));
paths.session_dir = fullfile(cfg.data_root, 'sessions', char(cfg.sensor_id), char(date_tag), char(cfg.session_id));

if ~exist(paths.raw_dir, 'dir'), mkdir(paths.raw_dir); end
if ~exist(paths.proc_dir, 'dir'), mkdir(paths.proc_dir); end
if ~exist(paths.session_dir, 'dir'), mkdir(paths.session_dir); end

paths.session_id = cfg.session_id;
paths.date_tag = date_tag;
end
