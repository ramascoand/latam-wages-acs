"""
Population profile of Latin American-born residents of the US, by country of birth.
ACS 2021-2023 pooled (see extract_population.py); US-born benchmark from a 2% sample.
Output: results/tables/population_profile.csv
"""
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
df = pd.read_parquet(ROOT / "data" / "latam_population_2021_2023.parquet")
df = df[~df["country"].str.contains(", Ns", na=False)]

CPI = {2021: 270.970, 2022: 292.655, 2023: 304.702}
df["earn23"] = df["incearn"] * 304.702 / df["year"].map(CPI)
df["yrs_us"] = np.where((df["yrimmig"] > 0) & (df["yrimmig"] <= df["year"]), df["year"] - df["yrimmig"], np.nan)


def wmean(x, w):
    m = x.notna()
    return np.average(x[m], weights=w[m]) if m.any() else np.nan


def wmedian(x, w):
    m = x.notna()
    x, w = x[m].to_numpy(), w[m].to_numpy()
    if len(x) == 0:
        return np.nan
    o = np.argsort(x)
    cw = np.cumsum(w[o])
    return x[o][np.searchsorted(cw, cw[-1] / 2)]


rows = []
for country, g in df.groupby("country"):
    w = g["perwt"]
    a25 = g[g["age"] >= 25]
    a5 = g[g["age"] >= 5]
    wa = g[g["age"].between(25, 64)]
    ftyr = wa[(wa["uhrswork"] >= 35) & (wa["wkswork2"] == 6) & (wa["incearn"] > 0)]
    top_state = g.groupby("state")["perwt"].sum().sort_values(ascending=False)
    rows.append({
        "country": country,
        "n_obs": len(g),
        "population": w.sum() / 3,
        "median_age": wmedian(g["age"], w),
        "pct_female": 100 * wmean((g["sex"] == 2).astype(float), w),
        "pct_ba_plus_25": 100 * wmean((a25["educd"] >= 101).astype(float), a25["perwt"]),
        "pct_less_hs_25": 100 * wmean((a25["educd"] < 62).astype(float), a25["perwt"]),
        "pct_grad_degree_25": 100 * wmean((a25["educd"] >= 114).astype(float), a25["perwt"]),
        "pct_english_limited": 100 * wmean(a5["speakeng"].isin([1, 6]).astype(float), a5["perwt"]),
        "pct_naturalized": 100 * wmean((g["citizen"] == 2).astype(float), w),
        "median_yrs_in_us": wmedian(g["yrs_us"], w),
        "pct_arrived_last_10y": 100 * wmean((g["yrs_us"] <= 10).astype(float).where(g["yrs_us"].notna()), w),
        "employment_rate_25_64": 100 * wmean((wa["empstat"] == 1).astype(float), wa["perwt"]),
        "median_earn_ftyr_2023usd": wmedian(ftyr["earn23"], ftyr["perwt"]),
        "top_state": top_state.index[0] if len(top_state) else "",
        "pct_in_top_state": 100 * top_state.iloc[0] / top_state.sum() if len(top_state) else np.nan,
    })

prof = pd.DataFrame(rows).set_index("country").sort_values("population", ascending=False)
out = ROOT / "results" / "tables" / "population_profile.csv"
prof.round(1).to_csv(out)
pd.set_option("display.width", 250)
pd.set_option("display.max_columns", 30)
print(prof.round(1).to_string())
