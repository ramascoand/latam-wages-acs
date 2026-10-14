"""LinkedIn figures (4:5, 1080x1350) from results/tables/population_profile.csv."""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
FIG = ROOT / "results" / "figures"
prof = pd.read_csv(ROOT / "results" / "tables" / "population_profile.csv", index_col=0)

BLUE, ORANGE, GRAY = "#2a78d6", "#eb6834", "#c9c7c0"
INK, INK2, MUTED, SURF = "#0b0b0b", "#52514e", "#8a8880", "#fcfcfb"
plt.rcParams.update({
    "font.family": "sans-serif", "font.sans-serif": ["Segoe UI", "Arial", "DejaVu Sans"],
    "figure.facecolor": SURF, "axes.facecolor": SURF, "savefig.facecolor": SURF,
    "axes.spines.top": False, "axes.spines.right": False, "axes.spines.left": False,
    "axes.edgecolor": "#d8d6cf", "xtick.color": INK2, "ytick.color": INK, "text.color": INK,
})
SOURCE = "Source: US Census Bureau, American Community Survey 2021–2023 (IPUMS USA). Analysis: Andrés Ramasco"
us = prof.loc["US-born"]
latam = prof.drop("US-born")


def header(fig, title, subtitle):
    fig.text(0.06, 0.965, title, fontsize=15.5, fontweight="bold", va="top", ha="left", wrap=True)
    fig.text(0.06, 0.885, subtitle, fontsize=9.5, color=INK2, va="top", ha="left", linespacing=1.4)
    fig.text(0.06, 0.02, SOURCE, fontsize=7, color=MUTED, ha="left")


# ---------------- 1. College degree share ----------------
d = prof.sort_values("pct_ba_plus_25")
fig = plt.figure(figsize=(5.4, 6.75), dpi=200)
ax = fig.add_axes([0.30, 0.08, 0.62, 0.74])
colors = [ORANGE if c == "US-born" else (BLUE if v > us["pct_ba_plus_25"] + 1 else GRAY)
          for c, v in zip(d.index, d["pct_ba_plus_25"])]
y = np.arange(len(d))
ax.barh(y, d["pct_ba_plus_25"], color=colors, height=0.72)
ax.axvline(us["pct_ba_plus_25"], color=ORANGE, lw=1, ls=(0, (3, 3)), zorder=0)
ax.set_yticks(y)
ax.set_yticklabels([("United States (US-born)" if c == "US-born" else c) for c in d.index], fontsize=9)
for t, c in zip(ax.get_yticklabels(), d.index):
    if c in ("US-born", "Venezuela"):
        t.set_fontweight("bold")
for yi, v in zip(y, d["pct_ba_plus_25"]):
    ax.text(v + 0.8, yi, f"{v:.0f}%", va="center", fontsize=8, color=INK2,
            bbox=dict(boxstyle="square,pad=0.1", fc=SURF, ec="none"), zorder=3)
ax.set_xlim(0, 60)
ax.xaxis.set_visible(False)
ax.tick_params(axis="y", length=0)
header(fig,
       "Venezuelan immigrants are more likely\nto hold a college degree than Americans",
       "Share of adults 25+ with a bachelor's degree or higher, by country of birth.\n"
       "Blue = clearly more educated than the US-born population (orange).")
fig.savefig(FIG / "pop_college_share_LI.png")
plt.close(fig)

# ---------------- 2. Education vs earnings ----------------
fig = plt.figure(figsize=(5.4, 6.75), dpi=200)
ax = fig.add_axes([0.14, 0.10, 0.80, 0.70])
x, yv = latam["pct_ba_plus_25"], latam["median_earn_ftyr_2023usd"] / 1000
size = 18 + 900 * np.sqrt(latam["population"] / latam["population"].max())

# Weighted fit across Latin American countries excluding Venezuela: "expected" pay for its education
fit = latam.drop("Venezuela")
b, a = np.polyfit(fit["pct_ba_plus_25"], fit["median_earn_ftyr_2023usd"] / 1000, 1,
                  w=np.sqrt(fit["population"]))
xs = np.linspace(5, 58, 50)
ax.plot(xs, a + b * xs, color=MUTED, lw=1, ls=(0, (4, 3)), zorder=1)
ax.text(57, a + b * 57 + 1.2, "trend across other\nLatin American countries", fontsize=7.5,
        color=MUTED, ha="right", va="bottom")

for c in latam.index:
    col = BLUE if c == "Venezuela" else GRAY
    ax.scatter(x[c], yv[c], s=size[c], color=col, edgecolor=SURF, linewidth=1.2, zorder=3 if c == "Venezuela" else 2,
               alpha=1 if c == "Venezuela" else 0.9)
ax.scatter(us["pct_ba_plus_25"], us["median_earn_ftyr_2023usd"] / 1000, s=120, color=ORANGE,
           edgecolor=SURF, linewidth=1.2, zorder=4, marker="D")

labels = {"Mexico": (-14, 14), "Guatemala": (-6, -12), "Cuba": (8, 4), "Colombia": (8, -4),
          "Brazil": (8, 4), "Argentina": (8, 4), "Chile": (-8, -12), "Peru": (8, -6)}
for c, (dx, dy) in labels.items():
    ax.annotate(c, (x[c], yv[c]), xytext=(dx, dy), textcoords="offset points", fontsize=8,
                color=INK2, ha="left" if dx > 0 else "right")
ax.annotate("United States (US-born)", (us["pct_ba_plus_25"], us["median_earn_ftyr_2023usd"] / 1000),
            xytext=(-8, 7), textcoords="offset points", fontsize=8.5, fontweight="bold", color=INK, ha="right")
v = latam.loc["Venezuela"]
gap = us["median_earn_ftyr_2023usd"] - v["median_earn_ftyr_2023usd"]
ax.annotate(f"Venezuela\n{v['pct_ba_plus_25']:.0f}% college grads, ${v['median_earn_ftyr_2023usd']/1000:.0f}k median pay\n"
            f"{v['pct_arrived_last_10y']:.0f}% arrived in the last 10 years",
            (v["pct_ba_plus_25"], v["median_earn_ftyr_2023usd"] / 1000), xytext=(-10, -44),
            textcoords="offset points", fontsize=8, color=INK, ha="right",
            arrowprops=dict(arrowstyle="-", color=BLUE, lw=0.8))

ax.set_xlim(0, 60)
ax.set_ylim(30, 72)
ax.set_xlabel("Adults 25+ with a bachelor's degree or higher (%)", fontsize=8.5, color=INK2)
ax.set_ylabel("Median annual earnings, full-time workers ($k, 2023)", fontsize=8.5, color=INK2)
ax.grid(axis="y", color="#e8e6df", lw=0.7)
ax.spines["left"].set_visible(False)
ax.tick_params(length=0, labelsize=8)
header(fig,
       f"The most educated group earns ${gap/1000:.0f}k less\nthan the typical US-born worker",
       "Each bubble is a country of birth (size = population in the US).\n"
       "Median earnings of full-time, year-round workers aged 25–64.")
fig.savefig(FIG / "pop_education_vs_pay_LI.png")
plt.close(fig)
print("saved; fit slope $k per pp:", round(b, 3), "gap", round(gap))
