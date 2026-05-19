clear
clc

%% load data

scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(fileparts(scriptDir));

addpath(genpath(fullfile(projectDir, "scripts")));

modelPath = fullfile(projectDir, "data", "processed", "minHashNBA.mat");

if ~isfile(modelPath)
    MINHASH_genData
end

load(modelPath, "MH", "R", "playerTags", "tagLimits", "statNames", "cleanTable");

%% parameters

threshold = 0.6;
maxResults = 10;

% stats format:
% [PTS, TRB, AST, STL, BLK, FGp, P3p, P3A, P2p, FTp]

statsJordan = [34.98, 5.48, 5.91, 3.16, 1.60, 53.5, 13.2, 0.65, 54.6, 84.1];

%% test 1 - find similar players by stats

fprintf("\n TEST 1: Michael Jordan 1988 profile \n");

result = MINHASH_findSimilarStats(statsJordan, threshold, maxResults);
disp(result);

%% test 2 - compare MinHash with exact Jaccard

fprintf("\n TEST 2: MinHash vs exact Jaccard \n");

queryTags = NBA_statsToTags(statsJordan, tagLimits, statNames);

[similarIdx, minhashSim] = MINHASH_findSimilar(queryTags, MH, threshold, R, []);

n = min(maxResults, length(similarIdx));

exactSim = zeros(n, 1);

for i = 1:n
    exactSim(i) = exactJaccard(queryTags, playerTags{similarIdx(i)});
end

comparison = table( ...
    minhashSim(1:n)', ...
    exactSim, ...
    abs(minhashSim(1:n)' - exactSim), ...
    cleanTable.Player(similarIdx(1:n)), ...
    cleanTable.Year(similarIdx(1:n)), ...
    cleanTable.Pos(similarIdx(1:n)), ...
    'VariableNames', {'MinHashSimilarity', 'ExactJaccard', 'AbsError', 'Player', 'Year', 'Pos'} ...
);

disp(comparison);

%% test 3 - compare different values of k

fprintf("\n TEST 3: Different values of k\n");

kValues = [50, 100, 200];

exactAll = zeros(1, length(playerTags));

for i = 1:length(playerTags)
    exactAll(i) = exactJaccard(queryTags, playerTags{i});
end

summary = table();

for i = 1:length(kValues)

    k = kValues(i);

    rng(1);
    Rtest = MINHASH_genHashFunc(k);
    MHtest = MINHASH_genMH(playerTags, Rtest, false);

    queryMH = MINHASH_genMH({queryTags}, Rtest, false);

    minhashAll = mean(MHtest == repmat(queryMH, 1, size(MHtest, 2)), 1);

    playersFound = sum(minhashAll >= threshold);
    meanAbsError = mean(abs(minhashAll - exactAll));
    bestSimilarity = max(minhashAll);

    summary = [summary; table(k, playersFound, meanAbsError, bestSimilarity)];

end

disp(summary);

%% local function

function sim = exactJaccard(tagsA, tagsB)

    tagsA = unique(string(tagsA));
    tagsB = unique(string(tagsB));

    interSize = numel(intersect(tagsA, tagsB));
    unionSize = numel(union(tagsA, tagsB));

    if unionSize == 0
        sim = 0;
    else
        sim = interSize / unionSize;
    end

end