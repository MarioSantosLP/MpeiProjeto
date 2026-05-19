clear; clc;
tic


scriptDir  = fileparts(mfilename('fullpath'));
projectDir = scriptDir;

while ~isfolder(fullfile(projectDir, "data", "processed")) && ...
      ~strcmp(projectDir, fileparts(projectDir))
    projectDir = fileparts(projectDir);
end

addpath(fullfile(projectDir, "scripts", "BF"));

dataPath = fullfile(projectDir, "data", "processed", "nba_90s_clean.mat");

if ~isfile(dataPath)
    error("File not found: %s\nRun scripts/Prep/prepare_dataset.m first.", dataPath);
end

load(dataPath, "bloomKeys");

%% PARAMETERS
nEntries   = length(bloomKeys);
array_size = nEntries * 10;
num_hashes = 3;

fprintf("Dataset entries : %d\n",      nEntries);
fprintf("Array size      : %d bits\n", array_size);
fprintf("Num hashes      : %d\n\n",    num_hashes);

%% CREATE AND POPULATE THE FILTER
bf = BloomFilter(array_size, num_hashes);

for i = 1:nEntries
    bf = bf.add(bloomKeys(i));
end

fprintf("Bloom Filter populated.\n");
bf.printStats();

%% SAVE
savePath = fullfile(projectDir, "data", "processed", "bloomFilterNBA.mat");
save(savePath, "bf", "bloomKeys", "array_size", "num_hashes", "nEntries");
fprintf("\nBloom Filter saved to: %s\n", savePath);

toc