clear; clc;

fprintf('=== Counting Bloom Filter Test ===\n\n');

tic;
load('data/processed/songs_dataset.mat');
cbf = CountingBloomFilter(1000000, 3);

fprintf('Adding 10000 songs...\n');
for i = 1:10000
    cbf = cbf.add(bloomKeys(i));
end
elapsed = toc;
fprintf('Done in %.2fs\n\n', elapsed);

%% 1. False Negatives (should be 0)
fprintf('=== False Negative Test ===\n');
fn = 0;
for i = 1:10000
    if ~cbf.exists(bloomKeys(i))
        fn = fn + 1;
    end
end
fprintf('False negatives: %d/10000 (should always be 0)\n\n', fn);

%% 2. False Positives
fprintf('=== False Positive Test ===\n');
fp = 0;
nTests = 10000;
for i = 1:nTests
    fakeKey = sprintf('fake artist %d - fake song %d', i, i);
    if cbf.exists(fakeKey)
        fp = fp + 1;
    end
end
fprintf('False positives: %d/%d (%.2f%%)\n\n', fp, nTests, fp/nTests*100);

%% 3. Exists
fprintf('=== Exists Test ===\n');
fprintf('Exists "%s"? %d\n', bloomKeys(2), cbf.exists(bloomKeys(2)));
fprintf('Exists "fake artist - fake song"? %d\n', cbf.exists('fake artist - fake song'));
fprintf('\n');

%% 4. Remove
fprintf('=== Remove Test ===\n');
key = bloomKeys(1);
fprintf('Before remove - exists "%s"? %d\n', key, cbf.exists(key));
cbf = cbf.remove(key);
fprintf('After remove  - exists "%s"? %d\n\n', key, cbf.exists(key));

%% 5. Remove Non-Existing
fprintf('=== Remove Non-Existing Test ===\n');
try
    cbf = cbf.remove('fake artist - fake song');
    fprintf('ERROR: should have thrown an error\n');
catch e
    fprintf('Correctly threw error: %s\n', e.message);
end