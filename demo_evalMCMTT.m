benchmarkGtDir = '/data/MCMTT/PETS2009.S2.L1/groundTruth/';

allSequences = {'PETS'};

[allMets, metsBenchmark] = evaluateMCMTT(allSequences, '/data/MCMTT/PETS2009.S2.L1/mcmtt_results/', benchmarkGtDir, 'PETS');

