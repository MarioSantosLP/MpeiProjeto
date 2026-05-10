clear; clc; tic

scriptDir = fileparts(mfilename('fullpath'));

projectDir = scriptDir;
while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

addpath(genpath(fullfile(projectDir, "scripts")));

modelPath = fullfile(projectDir, "data", "processed", "minHashNBA.mat");

if ~isfile(modelPath)
    MINHASH_genData
end

fprintf("\n--- TEST 1: Michael Jordan 1988 by name ---\n");
result1 = MINHASH_findSimilarPlayer("Michael Jordan", 0.6, 10, 1988);
disp(result1);

fprintf("\n--- TEST 2: Michael Jordan 1988 by stats ---\n");
statsJordan1988 = [34.98, 5.48, 5.91, 3.16, 1.60, 53.5, 13.2, 0.65, 54.6, 84.1];
result2 = MINHASH_findSimilarStats(statsJordan1988, 0.6, 10);
disp(result2);

fprintf("\n--- TEST 3: Michael Jordan 1988 with different thresholds ---\n");
thresholds = [0.9, 0.7, 0.5, 0.3];

for i = 1:length(thresholds)
    fprintf("\nThreshold %.1f\n", thresholds(i));
    result = MINHASH_findSimilarPlayer("Michael Jordan", thresholds(i), 10, 1988);
    disp(result);
end

fprintf("\n--- TEST 4: Shai Gilgeous-Alexander profile ---\n");
statsShai = [31.1, 4.3, 6.6, 1.4, 0.8, 55.3, 38.6, 4.4, 60.7, 87.9];
result4 = MINHASH_findSimilarStats(statsShai, 0.6, 10);
disp(result4);

fprintf("\n--- TEST 5: Scoring guard profile ---\n");
statsGuard = [30, 5, 6, 2, 1, 50, 35, 3, 52, 85];
result5 = MINHASH_findSimilarStats(statsGuard, 0.6, 10);
disp(result5);

fprintf("\n--- TEST 6: Rebounding big man profile ---\n");
statsBig = [12, 14, 2, 1, 2.5, 55, 0, 0, 55, 65];
result6 = MINHASH_findSimilarStats(statsBig, 0.6, 10);
disp(result6);

fprintf("\n--- TEST 7: Playmaking guard profile ---\n");
statsPlaymaker = [15, 3, 10, 2, 0.2, 45, 32, 2, 48, 80];
result7 = MINHASH_findSimilarStats(statsPlaymaker, 0.6, 10);
disp(result7);

fprintf("\nElapsed time: %.2f seconds\n", toc);