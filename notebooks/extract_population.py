"""
Extract for the population profile by country of birth (ACS 2021-2023).

Reads the raw IPUMS extract in chunks (the machine has little free RAM) and keeps:
  - every person born in Latin America (Hispanic Latin America + Brazil), all ages
  - a 2% random sample of US-born people, as a benchmark

2020 is skipped: the pandemic-year ACS has experimental weights and lower response.
Output: data/latam_population_2021_2023.parquet
"""
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "acs_2010_2023_raw.dta"
OUT = ROOT / "data" / "latam_population_2021_2023.parquet"

YEARS = {2021, 2022, 2023}
COLS = ["year", "perwt", "statefip", "sex", "age", "bpl", "bpld", "citizen", "yrimmig",
        "speakeng", "educd", "empstat", "labforce", "occ2010", "uhrswork", "wkswork2",
        "incwage", "incearn"]
NATIVE_SAMPLE = 0.02

# Same exclusions as 1_data_prep.do (non-Hispanic Caribbean and the Guianas), plus the
# abbreviated IPUMS labels that the do-file missed
EXCLUDE = {
    "barbados", "belize/british honduras", "belize", "bermuda", "bahamas", "antigua",
    "antigua-barbuda", "british virgin islands", "cayman islands", "dominica", "grenada",
    "guadeloupe", "guyana/british guiana", "guyana", "haiti", "jamaica", "martinique",
    "montserrat", "saint kitts-nevis", "st. kitts-nevis", "saint lucia", "st. lucia",
    "saint vincent", "st. vincent", "trinidad and tobago", "turks and caicos",
    "u.s. virgin islands", "us virgin islands", "aruba", "curacao", "netherlands antilles",
    "anguilla", "bonaire", "sint maarten", "french guiana", "suriname", "west indies",
    "caribbean, ns", "central america, ns", "south america, ns", "americas, ns",
    "falkland islands",
}

reader = pd.read_stata(RAW, iterator=True)
labels = reader.value_labels()
bpld_lab = {int(k): str(v).lower() for k, v in labels["BPLD"].items()}
state_lab = {int(k): str(v) for k, v in labels["STATEFIP"].items()}
occ_lab = {int(k): str(v) for k, v in labels.get("OCC2010", {}).items()}

rng = np.random.default_rng(42)
keep = []
n_read = 0
for ch in pd.read_stata(RAW, chunksize=1_000_000, convert_categoricals=False, columns=COLS):
    n_read += len(ch)
    ch = ch[ch["year"].isin(YEARS)]
    if ch.empty:
        print(f"{n_read/1e6:6.1f}M rows read, no target years yet", flush=True)
        continue
    latam = (ch["bpl"] == 200) | ch["bpl"].between(210, 399)
    native = ch["bpl"].between(1, 56)
    native_s = native & (rng.random(len(ch)) < NATIVE_SAMPLE)
    sub = ch[latam | native_s].copy()
    sub["native"] = sub["bpl"].between(1, 56)
    keep.append(sub)
    print(f"{n_read/1e6:6.1f}M rows read, kept {sum(len(k) for k in keep):,}", flush=True)

df = pd.concat(keep, ignore_index=True)
df["country"] = np.where(df["native"], "US-born",
                         df["bpld"].map(bpld_lab).fillna("").str.title())
df = df[df["native"] | ~df["country"].str.lower().isin(EXCLUDE)]
df.loc[df["native"], "perwt"] = df.loc[df["native"], "perwt"] / NATIVE_SAMPLE
df["state"] = df["statefip"].map(state_lab)
df["occ_label"] = df["occ2010"].map(occ_lab)
for c in ["year", "sex", "age", "bpl", "bpld", "citizen", "yrimmig", "speakeng", "educd",
          "empstat", "labforce", "occ2010", "uhrswork", "wkswork2", "statefip"]:
    df[c] = pd.to_numeric(df[c], downcast="integer")
df.to_parquet(OUT, index=False)
print("saved", OUT, len(df), "rows")
print(df.loc[~df["native"]].groupby("country")["perwt"].sum().div(3).sort_values(ascending=False).round(-3).head(25))
print("SPEAKENG labels:", labels.get("SPEAKENG"))
print("CITIZEN labels:", labels.get("CITIZEN"))
