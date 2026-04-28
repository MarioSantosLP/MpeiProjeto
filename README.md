# Detetor de Plágio Musical
### MPEI 2025–2026 | Trabalho Prático

---

## O que é isto?

Um sistema que deteta automaticamente plágio entre letras de músicas. Dado uma música nova, o sistema verifica se já existe no corpus, prevê o seu género musical, e encontra as músicas mais semelhantes — sinalizando qualquer resultado suspeito como potencial caso de plágio.

O sistema é implementado de raiz em Matlab, combinando três algoritmos: Naïve Bayes, um Counting Bloom Filter e MinHash.

---

## Como funciona

Quando uma nova música é submetida, o sistema processa-a em três etapas:

**1. Bloom Filter — verificação de duplicados**
Antes de qualquer processamento, o sistema verifica se esta música já foi vista anteriormente. Se sim, é ignorada imediatamente. Utilizamos um Counting Bloom Filter, o que permite também remover músicas do corpus.

**2. Naïve Bayes — classificação por género**
Se a música for nova, um classificador Naïve Bayes prevê o seu género com base nas frequências das palavras na letra. Isto permite reduzir o espaço de pesquisa — comparamos apenas com músicas do mesmo género previsto.

**3. MinHash — deteção de similaridade**
A letra é dividida em sequências de 3 palavras consecutivas. É calculada uma assinatura MinHash que é comparada com as restantes músicas do mesmo género. Músicas acima de um limiar de similaridade são sinalizadas como potencial plágio, devolvendo os resultados mais similares com as respetivas pontuações.

---

## Dataset

Utilizamos o dataset [55,000+ Song Lyrics](https://www.kaggle.com/) do Kaggle, que inclui título, artista, género e letra completa de cada música. Para a demonstração, incluímos casos reais de plágio conhecidos como ponto de partida para validar o sistema.
