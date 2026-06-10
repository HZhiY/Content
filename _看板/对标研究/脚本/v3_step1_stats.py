#!/usr/bin/env python3
import pandas as pd
import os
import re
from collections import Counter

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_DIR = os.path.join(BASE_DIR, 'v3_output')
SAMPLE_FILE = os.path.join(OUTPUT_DIR, 'v3_samples_all.csv')

# 1. Load Data
print(f"Loading data from {SAMPLE_FILE}...")
if not os.path.exists(SAMPLE_FILE):
    print(f"Error: {SAMPLE_FILE} not found.")
    exit(1)

df = pd.read_csv(SAMPLE_FILE)
print(f"Loaded {len(df)} rows.")

# Ensure reads is numeric
df['reads'] = pd.to_numeric(df['reads'], errors='coerce').fillna(0).astype(int)

# 2. Define Top 10%
print("[2] Defining Top 10%...")
top_rows = []
for account, group in df.groupby('account'):
    n = max(1, int(len(group) * 0.10))
    top = group.nlargest(n, 'reads')
    top_rows.append(top)
    
df_top = pd.concat(top_rows)
print(f"Top rows: {len(df_top)}")

# 3. Tokenize (N-grams)
def get_ngrams(text, n):
    text = re.sub(r'[^\u4e00-\u9fff]', '', str(text))
    return [text[i:i+n] for i in range(len(text)-n+1)]

# Stopwords (load from file if exists, else empty)
stopwords_file = os.path.join(BASE_DIR, '_v3_stopwords.txt')
stopwords = set()
if os.path.exists(stopwords_file):
    with open(stopwords_file, 'r', encoding='utf-8') as f:
        stopwords = set([line.strip() for line in f if line.strip()])

print("[3] Counting n-grams...")
counts_all = Counter()
counts_top = Counter()

for idx, row in df.iterrows():
    for n in [1, 2, 3]:
        grams = get_ngrams(row['title'], n)
        for g in grams:
            if g not in stopwords:
                counts_all[(g, n)] += 1

for idx, row in df_top.iterrows():
    for n in [1, 2, 3]:
        grams = get_ngrams(row['title'], n)
        for g in grams:
            if g not in stopwords:
                counts_top[(g, n)] += 1

# 4. Save Wordfreq
def save_freqs(counts, filename):
    rows = []
    for (gram, n), count in counts.items():
        if count >= 2:
            rows.append({'ngram': gram, 'n': n, 'count': count})
    df_out = pd.DataFrame(rows)
    df_out = df_out.sort_values('count', ascending=False)
    df_out.to_csv(os.path.join(OUTPUT_DIR, filename), index=False)
    print(f"Saved {filename}: {len(df_out)} rows")

save_freqs(counts_all, 'v3_wordfreq_all.csv')
save_freqs(counts_top, 'v3_wordfreq_top.csv')

# 5. Poison Check
print("[4] Poison check...")
poisons_file = os.path.join(BASE_DIR, '_v3_poisons.txt')
poisons = []
if os.path.exists(poisons_file):
    with open(poisons_file, 'r', encoding='utf-8') as f:
        poisons = [line.strip() for line in f if line.strip()]

poison_rows = []
total_all = len(df)
total_top = len(df_top)

for w in poisons:
    n_all = df['title'].str.contains(w, regex=False).sum()
    n_top = df_top['title'].str.contains(w, regex=False).sum()
    
    rate_all = n_all / total_all if total_all > 0 else 0
    rate_top = n_top / total_top if total_top > 0 else 0
    boost = rate_top / rate_all if rate_all > 0 else 0
    
    verdict = 'ban' if boost < 0.8 else ('careful' if boost < 0.95 else ('neutral' if boost < 1.1 else 'ok'))
    
    poison_rows.append({
        'word': w,
        'n_all': n_all,
        'n_top': n_top,
        'rate_all': round(rate_all, 4),
        'rate_top': round(rate_top, 4),
        'boost': round(boost, 3),
        'verdict': verdict
    })

df_poison = pd.DataFrame(poison_rows)
df_poison = df_poison.sort_values('boost')
df_poison.to_csv(os.path.join(OUTPUT_DIR, 'v3_poison_check.csv'), index=False)
print(f"Saved v3_poison_check.csv: {len(df_poison)} rows")

# 6. N-gram Boost
print("[5] N-gram boost...")
boost_rows = []
for (gram, n), count_all in counts_all.items():
    if count_all < 3: continue
    count_top = counts_top.get((gram, n), 0)
    if count_top == 0: continue
    
    rate_all = count_all / total_all
    rate_top = count_top / total_top
    boost = rate_top / rate_all if rate_all > 0 else 0
    
    boost_rows.append({
        'ngram': gram,
        'n': n,
        'count_all': count_all,
        'count_top': count_top,
        'rate_all': round(rate_all, 4),
        'rate_top': round(rate_top, 4),
        'boost': round(boost, 3)
    })

df_boost = pd.DataFrame(boost_rows)
df_boost = df_boost.sort_values('count_all', ascending=False)
df_boost.to_csv(os.path.join(OUTPUT_DIR, 'v3_ngram_boost.csv'), index=False)
print(f"Saved v3_ngram_boost.csv: {len(df_boost)} rows")

# 7. Split by Account
print("[6] Splitting by account...")
for account, group in df.groupby(account):
    counts_acc = Counter()
    for idx, row in group.iterrows():
        for n in [1, 2, 3]:
            grams = get_ngrams(row['title'], n)
            for g in grams:
                if g not in stopwords:
                    counts_acc[(g, n)] += 1
                    
    rows = []
    for (gram, n), count in counts_acc.items():
        if count >= 2:
            rows.append({'ngram': gram, 'n': n, 'count': count})
            
    df_acc = pd.DataFrame(rows)
    df_acc = df_acc.sort_values('count', ascending=False)
    
    safe_name = re.sub(r'[\\/:*?"<>|]', '_', account)
    df_acc.to_csv(os.path.join(ACCOUNT_DIR, f'v3_words_{safe_name}.csv'), index=False)

print("Done.")
