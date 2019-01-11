function [allMets, metsBenchmark, metsMultiCam] = evaluateMCMTT(allSequences, resDir, gtDataDir, benchmark)

% Input:
% - seqmap
% Sequence map (e.g. `c2-train.txt` contains a list of all sequences to be 
% evaluated in a single run. These files are inside the ./seqmaps folder.
%
% - resDir
% The folder containing the tracking results. Each one should be saved in a
% separate .txt file with the name of the respective sequence (see ./res/data)
%
% - gtDataDir
% The folder containing the ground truth files.
%
% - benchmark
% The name of the benchmark, e.g. 'MOT15', 'MOT16', 'MOT17', 'DukeMTMCT'
%
% Output:
% - allMets
% Scores for each sequence
% 
% - metsBenchmark
% Aggregate score over all sequences
%
% - metsMultiCam
% Scores for multi-camera evaluation

addpath(genpath('.'));
warning off;

% Benchmark specific properties
world = 1;
threshold = 1000;
if strcmp(benchmark, 'PETS')
elseif strcmp(benchmark, 'PETS')
    world = 1;
    threshold = 1000;
end

% Read sequence list
% sequenceListFile = fullfile('seqmaps',seqmap);
% allSequences = parseSequences2(sequenceListFile);
fprintf('Sequences: \n');
disp(allSequences')
gtMat = [];
resMat = [];

% Evaluate sequences individually
allMets = [];
metsBenchmark = [];
metsMultiCam = [];

for ind = 1:length(allSequences)
    %% Parse ground truth
    % MOTX parsing
    sequenceName = char(allSequences(ind));
    gtFilename = [gtDataDir, sequenceName, '.txt'];
    gtdata = dlmread(gtFilename);
    gtdata(gtdata(:,7)==0,:) = [];     % ignore 0-marked GT
    gtdata(gtdata(:,1)<1,:) = [];      % ignore negative frames

    if world
        gtdata(:,[7 8]) = gtdata(:,[8 9]); % shift world coordinates
    end
    [~, ~, ic] = unique(gtdata(:,2)); % normalize IDs
    gtdata(:,2) = ic;
    gtMat{ind} = gtdata;
    
    %% Parse result
    % MOTX data format
    resFilename = [resDir, sequenceName,  '.txt'];
    
    % Skip evaluation if output is missing
    if ~exist(resFilename,'file')
        error('Invalid submission. Result for sequence %s not available!\n',sequenceName);
    end

    % Read result file
    if exist(resFilename,'file')
        s = dir(resFilename);
        if s.bytes ~= 0
            resdata = dlmread(resFilename);
        else
            resdata = zeros(0,9);
        end
    else
        error('Invalid submission. Result file for sequence %s is missing or invalid\n', resFilename);
    end
    resdata(resdata(:,1)<1,:) = [];      % ignore negative frames
    if world
        resdata(:,[7 8]) = resdata(:,[8 9]);  % shift world coordinates
    end
    
    resdata(resdata(:,1) > max(gtMat{ind}(:,1)),:) = []; % clip result to gtMaxFrame
    resMat{ind} = resdata;
        
    %% Sanity check
    frameIdPairs = resMat{ind}(:,1:2);
    [u,I,~] = unique(frameIdPairs, 'rows', 'first');
    hasDuplicates = size(u,1) < size(frameIdPairs,1);
    if hasDuplicates
        ixDupRows = setdiff(1:size(frameIdPairs,1), I);
        dupFrameIdExample = frameIdPairs(ixDupRows(1),:);
        rows = find(ismember(frameIdPairs, dupFrameIdExample, 'rows'));
        
        errorMessage = sprintf('Invalid submission: Found duplicate ID/Frame pairs in sequence %s.\nInstance:\n', sequenceName);
        errorMessage = [errorMessage, sprintf('%10.2f', resMat{ind}(rows(1),:)), sprintf('\n')];
        errorMessage = [errorMessage, sprintf('%10.2f', resMat{ind}(rows(2),:)), sprintf('\n')];
        assert(~hasDuplicates, errorMessage);
    end
    
    %% Evaluate sequence
    [metsCLEAR, mInf, additionalInfo] = CLEAR_MOT_HUN(gtMat{ind}, resMat{ind}, threshold, world);
    metsID = IDmeasures(gtMat{ind}, resMat{ind}, threshold, world);
    mets = [metsID.IDF1, metsID.IDP, metsID.IDR, metsCLEAR];
    allMets(ind).name = sequenceName;
    allMets(ind).m    = mets;
    allMets(ind).IDmeasures = metsID;
    allMets(ind).additionalInfo = additionalInfo;
    fprintf('%s\n', sequenceName); printMetrics(mets); fprintf('\n');
    evalFile = fullfile(resDir, sprintf('eval_%s.txt',sequenceName));
    dlmwrite(evalFile, mets);
    
end

%% Overall scores
metsBenchmark = evaluateBenchmark(allMets, world);
fprintf('\n');
fprintf(' ********************* Your %s Results *********************\n', benchmark);
printMetrics(metsBenchmark);
evalFile = fullfile(resDir, 'eval.txt');
dlmwrite(evalFile, metsBenchmark);
