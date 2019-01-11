function run_eval(data_root, res_root, seqmap, expname)
    %     seqmap = 'c10-train.txt';
    % resDir = fullfile(data_root, 'results', expname, filesep);
    % dataDir = fullfile(data_root, 'train', filesep);
    resDir = fullfile(res_root, filesep);
    dataDir = fullfile(data_root, filesep);
    
    benchmark = 'MOT15';
    if ~isempty(strfind(data_root, 'MOT2015'))
        benchmark = 'MOT15';
    elseif ~isempty(strfind(data_root, 'MOT16'))
        benchmark = 'MOT16';
    elseif ~isempty(strfind(data_root, 'MOT17'))
        benchmark = 'MOT17';
    end

    evaluateTracking(seqmap, resDir, dataDir, benchmark);
