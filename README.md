# NBA Time Machine - MPEI Project

This project analyses NBA player statistics using probabilistic and similarity-based algorithms.

The main goal is to classify players by position and find players with similar statistical profiles, while also showing how NBA positions changed over time.

## Dataset

Dataset used:

[NBA Players stats since 1950 - Kaggle](https://www.kaggle.com/datasets/drgilermo/nba-players-stats)

After downloading it, place the file here:

```text
data/raw/Seasons_Stats.csv
```

## Algorithms Used

- Naive Bayes: predicts the player's position
- Bloom Filter: checks if a player/key probably exists
- MinHash: finds statistically similar players
- Jaccard Similarity: used to compare with MinHash results

## Tags

The project does not use raw statistics directly.  
Each player is converted into tags based on statistical limits.

Example:

```text
points_high
rebounds_medium_low
assists_medium_high
steals_high
```

The limits used are:

| Stat | Limits |
|---|---|
| Points | 8, 15, 25 |
| Rebounds | 3, 6, 9 |
| Assists | 2, 4.5, 7 |
| Steals | 0.7, 1.2, 1.8 |
| Blocks | 0.3, 0.8, 1.5 |
| FG% | 43, 47, 51 |
| 3P% | 20, 30, 36 |
| 3PA | 0.5, 2, 5 |
| 2P% | 44, 48, 52 |
| FT% | 65, 75, 82 |

Each value is classified as:

```text
low
medium_low
medium_high
high
```

These tags are then used by Naive Bayes and MinHash.

## How to Run

Open MATLAB in the project root folder.

### 1. Prepare the dataset

```matlab
prepare_dataset
```

This creates the cleaned files in:

```text
data/processed
```

### 2. Train Naive Bayes

```matlab
NB_genData
```

### 3. Generate MinHash data

```matlab
MINHASH_genData
```

## Run Without Interface

To test the algorithms directly, run:

```matlab
NB_Test
MINHASH_teste
```

You can also search for similar players manually:

```matlab
MINHASH_findSimilarPlayer("Michael Jordan", 0.6, 10, 1991, true)
```

## Run With Interface

The project can also be used through the MATLAB interface:

```matlab
NBA_interface
```

Before opening the interface, make sure these scripts were already executed:

```matlab
prepare_dataset
NB_genData
MINHASH_genData
```

The interface allows the user to test the main features without running every command manually.

## Project Structure

```text
.
├── data
│   ├── raw
│   └── processed
├── scripts
│   ├── NB
│   ├── BF
│   ├── MinHash
│   └── GeneralFuncs
├── prepare_dataset.m
├── NBA_interface.m
└── README.md
```

## Conclusion

This project applies Naive Bayes, Bloom Filter and MinHash to NBA player statistics.

Naive Bayes is used to classify player positions, Bloom Filter is used for fast membership checks, and MinHash is used to find similar players efficiently.
