function resultTable = MINHASH_findSimilarStats(statsRow, threshold, maxResults)

    if nargin < 2 || isempty(threshold)
        threshold = 0.6;
    end

    if nargin < 3 || isempty(maxResults)
        maxResults = 10;
    end

    scriptDir = fileparts(mfilename('fullpath'));

    projectDir = scriptDir;
    while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
          ~strcmp(projectDir, fileparts(projectDir))
        projectDir = fileparts(projectDir);
    end

    addpath(fullfile(projectDir, "scripts", "MINHASH"));
    addpath(fullfile(projectDir, "scripts", "GeneralFuncs"));
    addpath(fullfile(projectDir, "scripts", "NB"));

    modelPath = fullfile(projectDir, "data", "processed", "minHashNBA.mat");

    if ~isfile(modelPath)
        error("Ficheiro não encontrado: %s\nCorre primeiro MINHASH_genData.m", modelPath);
    end

    load(modelPath, "MH", "R", "tagLimits", "statNames", "cleanTable");

    queryTags = NBA_statsToTags(statsRow, tagLimits, statNames);
    [similarIdx, similarities] = MINHASH_findSimilar(queryTags, MH, threshold, R, []);

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
