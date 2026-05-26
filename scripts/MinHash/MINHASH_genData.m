clear; clc;
tic

scriptDir = fileparts(mfilename('fullpath'));

projectDir = scriptDir;
while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

addpath(fullfile(projectDir, "scripts", "GeneralFuncs"));
addpath(fullfile(projectDir, "scripts", "NB"));
addpath(fullfile(projectDir, "scripts", "MinHash"));

dataPath = fullfile(projectDir, "data", "processed", "nba_90s_clean.mat");
saveDir = fullfile(projectDir, "data", "processed");

if ~isfile(dataPath)
    error("Ficheiro não encontrado: %s\nCorre primeiro scripts/Prep/prepare_dataset.m", dataPath);
end

load(dataPath, "cleanTable", "statsMatrix", "positionLabels");

[playerTags, tagLimits, statNames] = NBA_generateAllTags(statsMatrix);

rng(1);
k = 100;
R = MINHASH_genHashFunc(k);
MH = MINHASH_genMH(playerTags, R, true);

modelPath = fullfile(saveDir, "minHashNBA.mat");

save(modelPath, ...
    "MH", ...
    "R", ...
    "playerTags", ...
    "tagLimits", ...
    "statNames", ...
    "cleanTable", ...
    "statsMatrix", ...
    "positionLabels", ...
    "k");

fprintf("MinHash NBA model saved.\n");
fprintf("Players: %d\n", length(playerTags));
fprintf("Hash functions: %d\n", k);
fprintf("Saved at: %s\n", modelPath);
fprintf("Elapsed time: %.2f seconds\n", toc);
