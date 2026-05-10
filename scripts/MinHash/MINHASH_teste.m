clear; clc;

result1 = MINHASH_findSimilarPlayer("Michael Jordan", 0.6, 10);
disp(result1);

statsRow = [27.1, 7.5, 7.4, 1.5, 0.7, 51.3, 37.6, 5.2, 56.8, 78.2];
result2 = MINHASH_findSimilarStats(statsRow, 0.6, 10);
disp(result2);
