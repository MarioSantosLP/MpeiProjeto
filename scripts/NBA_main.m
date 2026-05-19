function result = NBA_main(playerName, playerYear, playerTm, playerStats)


    scriptDir  = fileparts(mfilename('fullpath'));
    projectDir = scriptDir;
    while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
          ~strcmp(projectDir, fileparts(projectDir))
        projectDir = fileparts(projectDir);
    end

    addpath(fullfile(projectDir, "scripts", "BF"));
    addpath(fullfile(projectDir, "scripts", "NB"));
    addpath(fullfile(projectDir, "scripts", "MinHash"));
    addpath(fullfile(projectDir, "scripts", "GeneralFuncs"));

    %% LOAD MODELS
    nbPath = fullfile(projectDir, "data", "processed", "naiveBayesNBA.mat");
    mhPath = fullfile(projectDir, "data", "processed", "minHashNBA.mat");
    bfPath = fullfile(projectDir, "data", "processed", "bloomFilterNBA.mat");

    load(nbPath, "prior", "vocabulary", "loglikelihood", "classes", "tagLimits", "statNames", "cleanTable");
    load(mhPath, "MH", "R", "playerTags", "positionLabels");
    load(bfPath, "bf");

    %% STEP 1:BF
    key = lower(strtrim(playerName)) + "_" + string(playerYear) + "_" + lower(strtrim(playerTm));

    result.inDataset = bf.exists(key);

    if result.inDataset
        fprintf("[BF] '%s' already exists in the 90s dataset.\n", playerName);
        result.position = "";
        result.tags     = [];
        result.matches  = [];
        return;
    end

    fprintf("[BF] '%s' is not in the 90s dataset. Proceeding...\n", playerName);

    %% NB
    [position, ~, ~] = NB_classifyPlayer(playerStats, prior, vocabulary, loglikelihood, classes, tagLimits, statNames);

    result.position = position;
    fprintf("[NB] Predicted position: %s\n", position);

    %% minhash

    tags = NBA_statsToTags(playerStats, tagLimits, statNames);
    result.tags = tags;


    positionMask = positionLabels == position;
    positionIdx  = find(positionMask);

    threshold = 0.3;
    [similarIdx, similarities] = MINHASH_findSimilar(tags, MH(:, positionIdx), threshold, R);

    similarIdx = positionIdx(similarIdx);

    %% table
    topN = min(3, length(similarIdx));

    names       = strings(topN, 1);
    years       = zeros(topN, 1);
    teams       = strings(topN, 1);
    positions   = strings(topN, 1);
    sims        = zeros(topN, 1);

    for i = 1:topN
        idx          = similarIdx(i);
        names(i)     = cleanTable.Player{idx};
        years(i)     = cleanTable.Year(idx);
        teams(i)     = cleanTable.Tm(idx);
        positions(i) = cleanTable.Pos(idx);
        sims(i)      = round(similarities(i) * 100, 1);
    end

    result.matches = table(names, years, teams, positions, sims, ...
        'VariableNames', {'Player', 'Year', 'Team', 'Position', 'Similarity'});

    %% res
    fprintf("\nTop similar 90s players to %s:\n", playerName);
    for i = 1:topN
        fprintf("  %d. %s (%d, %s) — %.1f%%\n", ...
            i, names(i), years(i), teams(i), sims(i));
    end

end
