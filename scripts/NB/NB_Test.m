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

fprintf("\nConfusion Matrix:\n");
disp(confTable);

TP = zeros(length(classes), 1);
FP = zeros(length(classes), 1);
FN = zeros(length(classes), 1);
TN = zeros(length(classes), 1);

precision = zeros(length(classes), 1);
recall = zeros(length(classes), 1);
f1 = zeros(length(classes), 1);
support = zeros(length(classes), 1);

total = sum(confMat, "all");

for c = 1:length(classes)

    TP(c) = confMat(c, c);
    FN(c) = sum(confMat(c, :)) - TP(c);
    FP(c) = sum(confMat(:, c)) - TP(c);
    TN(c) = total - TP(c) - FP(c) - FN(c);

    support(c) = sum(confMat(c, :));

    if TP(c) + FP(c) == 0
        precision(c) = 0;
    else
        precision(c) = TP(c) / (TP(c) + FP(c));
    end

    if TP(c) + FN(c) == 0
        recall(c) = 0;
    else
        recall(c) = TP(c) / (TP(c) + FN(c));
    end

    if precision(c) + recall(c) == 0
        f1(c) = 0;
    else
        f1(c) = 2 * precision(c) * recall(c) / (precision(c) + recall(c));
    end

end

metricsTable = table( ...
    classes(:), ...
    TP, ...
    FP, ...
    FN, ...
    TN, ...
    support, ...
    precision * 100, ...
    recall * 100, ...
    f1 * 100, ...
    'VariableNames', {'Class','TP','FP','FN','TN','Support','Precision','Recall','F1'} ...
);

fprintf("\nMetrics by class:\n");
disp(metricsTable);
fprintf("\nTP / FP / FN / TN by class:\n");

for c = 1:length(classes)

    fprintf("\nClass %s vs rest:\n", classes(c));
    fprintf("    True Positives  (TP): %d\n", TP(c));
    fprintf("    False Positives (FP): %d\n", FP(c));
    fprintf("    False Negatives (FN): %d\n", FN(c));
    fprintf("    True Negatives  (TN): %d\n", TN(c));

end

macroPrecision = mean(precision);
macroRecall = mean(recall);
macroF1 = mean(f1);

weightedPrecision = sum(precision .* support) / sum(support);
weightedRecall = sum(recall .* support) / sum(support);
weightedF1 = sum(f1 .* support) / sum(support);

fprintf("\nMacro Precision: %.2f%%\n", macroPrecision * 100);
fprintf("Macro Recall: %.2f%%\n", macroRecall * 100);
fprintf("Macro F1: %.2f%%\n", macroF1 * 100);

fprintf("\nWeighted Precision: %.2f%%\n", weightedPrecision * 100);
fprintf("Weighted Recall: %.2f%%\n", weightedRecall * 100);
fprintf("Weighted F1: %.2f%%\n", weightedF1 * 100);

lukaStats = [33.5, 8.8, 8.6, 1.4, 0.5, 48, 37, 10.6, 57, 78];

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