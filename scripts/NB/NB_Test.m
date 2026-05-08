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

if ~isfile(modelPath)
    error("Ficheiro não encontrado: %s\nCorre primeiro scripts/NB/NB_genData.m", modelPath);
end

load(modelPath);

numTests = length(testTags);
predictedLabels = strings(numTests, 1);

for i = 1:numTests

    predictedLabels(i) = NB_classifyTags( ...
        testTags{i}, ...
        prior, ...
        vocabulary, ...
        loglikelihood, ...
        classes);

end

accuracy = sum(predictedLabels == testLabels) / numTests;

fprintf("\nAccuracy: %.2f%%\n", accuracy * 100);

confMat = zeros(length(classes), length(classes));

for i = 1:numTests

    realIdx = find(classes == testLabels(i), 1);
    predIdx = find(classes == predictedLabels(i), 1);

    confMat(realIdx, predIdx) = confMat(realIdx, predIdx) + 1;

end

rowNames = "Real_" + classes;
colNames = "Pred_" + classes;

confTable = array2table(confMat, ...
    'RowNames', cellstr(rowNames), ...
    'VariableNames', cellstr(colNames));

disp(confTable);

lukaStats = [33.5, 8.8, 8.6, 1.4, 0.5, 48, 37, 57, 78];

[predictedPos, lukaTags, scores] = NB_classifyPlayer( ...
    lukaStats, ...
    prior, ...
    vocabulary, ...
    loglikelihood, ...
    classes, ...
    tagLimits, ...
    statNames);

fprintf("\nDemo player: Luka Doncic\n");
fprintf("Predicted position: %s\n", predictedPos);

fprintf("\nTags:\n");
disp(lukaTags);

fprintf("Scores:\n");
for i = 1:length(classes)
    fprintf("    %s: %.4f\n", classes(i), scores(i));
end