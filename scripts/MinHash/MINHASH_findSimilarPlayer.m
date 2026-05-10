function resultTable = MINHASH_findSimilarPlayer(playerName, threshold, maxResults, year, includeSelf)

    if nargin < 2 || isempty(threshold)
        threshold = 0.6;
    end

    if nargin < 3 || isempty(maxResults)
        maxResults = 10;
    end

    if nargin < 4
        year = [];
    end

    if nargin < 5 || isempty(includeSelf)
        includeSelf = false;
    end

    scriptDir = fileparts(mfilename('fullpath'));

    projectDir = scriptDir;
    while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
          ~strcmp(projectDir, fileparts(projectDir))
        projectDir = fileparts(projectDir);
    end

    addpath(genpath(fullfile(projectDir, "scripts")));

    modelPath = fullfile(projectDir, "data", "processed", "minHashNBA.mat");

    if ~isfile(modelPath)
        error("Ficheiro não encontrado: %s\nCorre primeiro MINHASH_genData.m", modelPath);
    end

    load(modelPath, "MH", "R", "playerTags", "cleanTable");

    playerName = lower(string(playerName));
    matches = find(contains(lower(cleanTable.Player), playerName));

    if ~isempty(year)
        matches = matches(cleanTable.Year(matches) == year);
    end

    if isempty(matches)
        error("Jogador não encontrado.");
    end

    selectedIdx = matches(1);

    if includeSelf
        excludeIdx = [];
    else
        excludeIdx = selectedIdx;
    end

    [similarIdx, similarities] = MINHASH_findSimilar(playerTags{selectedIdx}, MH, threshold, R, excludeIdx);

    if isempty(similarIdx)
        resultTable = table();
        return;
    end

    n = min(maxResults, length(similarIdx));
    similarIdx = similarIdx(1:n);
    similarities = similarities(1:n);

    resultTable = table( ...
        similarities(:), ...
        cleanTable.Player(similarIdx), ...
        cleanTable.Year(similarIdx), ...
        cleanTable.Pos(similarIdx), ...
        cleanTable.Tm(similarIdx), ...
        cleanTable.PTS(similarIdx), ...
        cleanTable.TRB(similarIdx), ...
        cleanTable.AST(similarIdx), ...
        cleanTable.STL(similarIdx), ...
        cleanTable.BLK(similarIdx), ...
        'VariableNames', {'Similarity','Player','Year','Pos','Tm','PTS','TRB','AST','STL','BLK'});

end