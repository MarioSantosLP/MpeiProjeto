clear; clc;

scriptDir = fileparts(mfilename('fullpath'));

projectDir = scriptDir;
while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

addpath(fullfile(projectDir, "scripts", "GeneralFuncs"));
addpath(fullfile(projectDir, "scripts", "NB"));

modelPath = fullfile(projectDir, "data", "processed", "naiveBayesNBA.mat");

if ~isfile(modelPath)
    error("Model not found. Run scripts/NB/NB_genData.m first.");
end

load(modelPath);

namesToSearch = [
    "Michael Jordan"
    "Magic Johnson"
    "Scottie Pippen"
    "Charles Barkley"
    "Hakeem Olajuwon"
    "Shaquille O'Neal"
    "John Stockton"
    "Karl Malone"
    "Reggie Miller"
    "Patrick Ewing"
    "Dennis Rodman"
    "Gary Payton"
];

allResults = table();

for n = 1:length(namesToSearch)

    name = namesToSearch(n);
    rows = contains(cleanTable.Player, name, "IgnoreCase", true);
    idxs = find(rows);

    if isempty(idxs)
        fprintf("\nPlayer not found: %s\n", name);
        continue;
    end

    for k = 1:length(idxs)

        i = idxs(k);

        statsRow = statsMatrix(i, :);

        [predictedPos, tags, scores] = NB_classifyPlayer( ...
            statsRow, ...
            prior, ...
            vocabulary, ...
            loglikelihood, ...
            classes, ...
            tagLimits, ...
            statNames);

        correct = predictedPos == cleanTable.Pos(i);

        newRow = table( ...
            cleanTable.Player(i), ...
            cleanTable.Year(i), ...
            cleanTable.Pos(i), ...
            predictedPos, ...
            correct, ...
            cleanTable.PTS(i), ...
            cleanTable.TRB(i), ...
            cleanTable.AST(i), ...
            cleanTable.STL(i), ...
            cleanTable.BLK(i), ...
            cleanTable.FGpct(i), ...
            cleanTable.P3pct(i), ...
            cleanTable.P3A(i), ...
            cleanTable.P2pct(i), ...
            cleanTable.FTpct(i), ...
            {tags}, ...
            'VariableNames', {'Player','Year','RealPos','PredictedPos','Correct', ...
                              'PTS','TRB','AST','STL','BLK', ...
                              'FGpct','P3pct','P3A','P2pct','FTpct','Tags'} ...
        );

        allResults = [allResults; newRow];

    end

end

disp(allResults);

if height(allResults) <= 0
    disp("No results to calculate accuracy.");
    accuracy = 0;
else
    accuracy = sum(allResults.Correct) / height(allResults);
end

fprintf("\nAccuracy on selected dataset players: %.2f%%\n", accuracy * 100);

fprintf("\nWrong predictions:\n");
disp(allResults(~allResults.Correct, :));

if height(allResults) == 0
    fprintf("\nNo players were found to test.\n");
else
    accuracy = sum(allResults.Correct) / height(allResults);

    fprintf("\nAccuracy on selected dataset players: %.2f%%\n", accuracy * 100);
    fprintf("Correct predictions: %d / %d\n", sum(allResults.Correct), height(allResults));

    fprintf("\nWrong predictions:\n");
    disp(allResults(~allResults.Correct, :));
end