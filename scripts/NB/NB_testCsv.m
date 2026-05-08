clear; clc;

scriptDir = fileparts(mfilename('fullpath'));

projectDir = scriptDir;
while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

addpath(fullfile(projectDir, "scripts", "generalFuncs"));
addpath(fullfile(projectDir, "scripts", "NB"));

modelPath = fullfile(projectDir, "data", "processed", "naiveBayesNBA.mat");
csvPath = fullfile(projectDir, "data", "raw", "current_players_test.csv");

load(modelPath);

T = readtable(csvPath, "TextType", "string");

numPlayers = height(T);
predicted = strings(numPlayers, 1);

for i = 1:numPlayers

    statsRow = [
        T.PTS(i), ...
        T.TRB(i), ...
        T.AST(i), ...
        T.STL(i), ...
        T.BLK(i), ...
        T.FGpct(i), ...
        T.P3pct(i), ...
        T.P3A(i), ...
        T.P2pct(i), ...
        T.FTpct(i)
    ];

    [predicted(i), tags, scores] = NB_classifyPlayer( ...
        statsRow, ...
        prior, ...
        vocabulary, ...
        loglikelihood, ...
        classes, ...
        tagLimits, ...
        statNames);

end

Result = table(T.Player, T.ExpectedPos, predicted, ...
    'VariableNames', {'Player','ExpectedPos','PredictedPos'});

disp(Result);

accuracy = sum(Result.ExpectedPos == Result.PredictedPos) / height(Result);

fprintf("\nCSV test accuracy: %.2f%%\n", accuracy * 100);

fprintf("\nWrong predictions:\n");
disp(Result(Result.ExpectedPos ~= Result.PredictedPos, :));