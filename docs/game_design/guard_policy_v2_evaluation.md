# Guard-aware v2 — implementation and validation contract

2026-10-18. Follow-up to [Surtr mechanism diagnostics](surtr_policy_diagnostics.md). Implement a production helper combining preparation reserve and marginal block consumption cost. Preserve the v1 shared policy, old diagnostic probes and card/monster rules byte-for-byte. Campaign default stays `corrected`; expose the candidate separately as `--policy=guard-aware`, retaining `synergy-aware` v1 for reproducibility.

## Frozen comparison population

- 18 owner starter10+reward6 archetype decks, two starter partners, Sekhmet/Surtr, HP100/50/25%, grades0/1, seeds101/202/303/404.
- `18×2×3×2×4 = 864` matched initial states, two fresh policy arms =1728 actual battles. v1 vs v2, same runtime rules and seeds, no relics/critical hits, real ATB, input cap120.
- Seeds101/202 are development population (432 pairs);303/404 are newly declared seed validation (432 pairs), not independent players or unseen authored content. Report them separately, including all new losses and caps. Reuse no historical outcomes as fresh battles.
- Require matched initial hashes, fixed count, source/config fingerprints, unique initial/paired trajectories, no rejected plays or incomplete execution. Caps remain censored outcomes, not proof of unwinnability. Store individual outcomes/HP/input and decision traces. Keep old12 failures as an explicit segmentation, not the only population.

## Policy and stop conditions

New production code may not import `tests/`. Keep a bounded, read-only authored-pattern/ATB forecast; no speculative effect execution, future draws or target RNG. Replace the old consumption penalty exactly once with marginal loss under the forecast, not a sum of two old probe adjustments. Keep ordinary negative valuations eligible after correction while honoring hard safety gates.

First-attacked-action block expiry makes multi-enemy aggregation unsafe without a probability model. v2 therefore conservatively falls back to v1 for multiple living enemies or unsupported single-enemy forecast states; this is an explicit rollout boundary, not full campaign expertise. Known taunt/last-attacker, exile, status expiry and composite charge semantics receive focused tests. Use a local ledger to value actual block grants/spends in effect order without mutating BM.

Run the frozen matrix once after targeted tests/review, without retuning to its outcomes. Any HP100/50 new loss, new cap or material per-deck regression prevents promoting this to the recommended general test policy. Regardless of result, retain the existing corrected default; this comparison is against v1, not corrected, and cannot justify replacing corrected. A net gain alone never proves final balance or fun. Additional bosses, acquisition economy and full campaign completion remain outside this matrix.

## Runtime implementation boundaries

- `tools/guard_decision_policy.gd`, version `guard-v2`, is a production helper with no `tests/` import. The v1 source and frozen diagnostic probe are preserved for historical replay. Campaign `guard-aware` selects v2, `synergy-aware` remains v1, `corrected` remains default. Both explicit modes retain campaign safety predicates and the Buddhist fallback gate.
- One living enemy only. Active stun/enthrall/threshold-ready charm/double-action, automatic time-limit growth and unsupported intent structures fall back to v1. Multi-enemy and fallback choices are not evidence that v2 forecasts those states.
- Bounded current-phase authored pattern scan (up to8 slots), copied ATB preview (64 entries), future strength/form steps, charge delay and ALL-hit composite charge. Known taunt and last-attacker targets respect current living-source rules; exile is not blanket AOE immunity. Current HP determines future lowest-HP targeting; unknown future ally plays/HP changes are not simulated.
- Hero vulnerability/foe weak/taunt/duel duration are projected against copied turn counts. Existing counter mitigates only the first applicable hit of a supported composite. A reserve is discounted by0.5 if another hero opportunity comes first. This is a preparation value heuristic, not exact future HP loss or an optimal policy. Random targets remain expected shares, not blanket worst-case guard.
- A local block ledger handles grants/spends in authored effect order. The v1 block contribution is removed once and replaced with forecast guard value / marginal protection loss once. Actual runtime-amplified holy-war healing determines overflow guard; v1's old printed calculation is retained only for its refund. No damage/heal/energy/state is actually applied during evaluation.
- No prediction of player-damage-triggered phase changes, all relic/signature/card-counter reactions, future speed changes, reflection kills or future draws. Unsupported/fallback behavior is deliberately versioned rather than marketed as full campaign expertise. Discard policy is v1 in both comparison arms, so play/guard changes are isolated.
- Targeted74 checks cover both unit systems, status expiry, target eligibility/forcing, ordered block ledger, surplus cost, composite counter/duel amplification, safety gates/fallback, holy-war overflow and non-mutation/RNG preservation. V1 checks60 and the existing campaign policy check pass. The read-only review's overflow-amplification and automatic-strength-growth findings were fixed before the final matrix was frozen. Additional assertions were added without changing the frozen runtime code.

## Actual-scene connection check

`xvAH36`: headless Cleopatra/chapter1/seed303/speed8, explicit `guard-aware`, diagnosis enabled, profiling off, Master muted and isolated storage. It completed4 battles, played72 cards, logged16 positive v2 choices, rejected0 cards and then actually lost on floor10 in a three-enemy encounter. This is a defeat, **not** a successful chapter-clear smoke or a wall-clock-censored battle. Script/engine errors and warnings were0.

The comparison connection run `JVb3SE`, same launch inputs but `synergy-aware` v1, also completed4 battles and lost on floor10, with74 card plays and0 rejects. It ended with a14-card deck versus13 for v2, so this is not an equivalent encounter checkpoint or a causal comparison of the final battle. Prior choices change routes/rewards/RNG consumption. Both modes' campaign completion remains unresolved; the isolated matched matrix is the controlled policy comparison. Neither run modifies player saves or settings.

## Final matrix — 2026-10-18

`KzuITH`:864 fresh matched pairs /1728 actual battles;864 unique initial hashes and864 unique paired trajectories. All initial hashes matched. Integrity failures, caps, incomplete runs and rejected plays were0. All59 runtime source fingerprints matched the final files. The development432 v1 traces exactly reproduced all432 original `EO87cM` v1 trajectory hashes: the baseline was preserved rather than replaced with a stronger/weaker policy during the comparison. Source `e900b44` + declared dirty tree; no card/monster/combat-rule changes.

| Seed segment | Initial HP | Pairs | v1 wins | v2 wins | New wins | New losses |
|---|---:|---:|---:|---:|---:|---:|
| Development101/202 | 100% | 144 | 144 | 144 | 0 | 0 |
| Development101/202 | 50% | 144 | 144 | 144 | 0 | 0 |
| Development101/202 | 25% | 144 | 118 | 137 | 20 | 1 |
| Additional303/404 | 100% | 144 | 144 | 144 | 0 | 0 |
| Additional303/404 | 50% | 144 | 144 | 144 | 0 | 0 |
| Additional303/404 | 25% | 144 | 123 | 133 | 11 | 1 |
| Total | — | 864 | 817 | 846 | 31 | 2 |

The improvement also occurred on the newly declared seeds, but these are still fixed deterministic deck/combat samples, not independent players. V2 is not claimed universally superior. No post-result weight changes were made. This matrix compares v1 synergy with v2 guard, **not corrected campaign scoring**.

### Per-deck wounded-entry results

Each seed segment has8 pairs per deck at HP25% (two bosses × two grades × two seeds). HP100/50 wins were unchanged across the576 corresponding states. Partners are fixed within a hero but differ across heroes; this table is not a hero ranking or a deck-acquisition test.

| Deck | Development v1→v2 /8 | Additional v1→v2 /8 |
|---|---:|---:|
| Napoleon charge | 6→7 | 7→7 |
| Napoleon legion | 5→8 | 8→8 |
| Napoleon command | 5→8 | 7→8 |
| Cleopatra poison | 6→8 | 6→7 |
| Cleopatra curse | 7→8 | 7→8 |
| Cleopatra charm | 6→7 | 7→7 |
| Yi turtle ship | 7→8 | 7→8 |
| Yi formation | 7→8 | 7→8 |
| Yi desperate | 8→8 | 8→8 |
| Joan holy | 7→7 | 6→7 |
| Joan restoration | 8→8 | 8→8 |
| Joan martyr | 7→8 | 6→7 |
| Genghis mobility | 6→7 | 7→8 |
| Genghis horde | 5→8 | 5→5 |
| Genghis plunder | 5→7 | 5→6 |
| Musashi dual blades | 8→8 | 8→8 |
| Musashi duel | 7→7 | 8→8 |
| Musashi empty mind | 8→7 | 6→7 |

The old hand-order→v1 regression set recovered11/12. The remaining historical case is `musashi_duel:surtr:25:0:101`. There are two **new** v1→v2 losses: `musashi_empty_mind:surtr:25:0:202` (enemyHP14,41 hero inputs) and `joan_holy:surtr:25:0:303` (enemyHP10,35 inputs). Joan holy's additional-seed net result still improved because it also gained victories; do not hide that new loss behind the aggregate. These three checkpoints are separate follow-up cases, not an excuse for a flat damage buff.

### Tradeoffs and rollout decision

Among815 common victories, remaining-team-HP delta had median0, mean+3.10 and range−92..+104 (improved340 / worse189 / same286). Hero-input delta had median0, mean+0.21 and range−6..+10 (faster226 / slower289 / same300). More survival was not universally more HP or speed. Decimal values are summary statistics, not decimal game quantities.

There were58717 successful candidate card choices:58058 used v2 guard scoring and659 used the preserved v1 fallback. These are decisions within864 battles, not extra games or independent samples.

- Keep v2 available as the explicit **single-enemy guard-aware comparison policy** for future balance tests. The high-HP/no-cap gate passed and additional seeds improved, but two low-HP counterexamples and the failed actual campaign smoke prevent describing it as a completed general campaign bot.
- Do **not** change the corrected campaign default, do not rename/overwrite v1 and do not silently change old evaluators' hand-order/v1 baselines. Use `--policy=guard-aware` when v2 is intended; multiple/unsupported enemies use its documented v1 fallback.
- Keep card/monster numbers unchanged. The remaining checkpoints, random-hit tail risk and solo/multiple-enemy campaign failures need their own scoped tests. The wider result does not establish fun, all-boss balance, optimal play or chapter1→2 completion.

### Verification evidence

- Final v2 unit74/live1672/tutorial312: `xCVxzN`; v1 unit60 + existing campaign policy PASS: `uSqKOe`; fresh legacy regression4150/0: `jDxZbH`.
- Final matrix `KzuITH`: error/warning0 and all59 source hashes verified; old432 traces exactly reproduced. Four-pair smoke `sDlLrJ` is development evidence only and is not added to the864-state population.
- Both actual-scene connection runs had error/warning0, Master mute true and frame profiling false; both defeats are retained above rather than labeled passes.
- `git diff --check` passed. New production helper imports no test scripts. The previous v1/helper/probe and gameplay data were preserved; existing art/experiments/player saves were untouched. No commit/push was performed.
- Raw report: `~/Library/Application Support/STSL-tutorial-validation-live-KzuITH/guard_policy_balance.json`; launcher logs under `log/live-balance/STSL-tutorial-validation-live-KzuITH/`. These are local ignored artifacts, not wiki raw-source edits or remote telemetry.

```sh
bash tools/run_live_balance_checks.sh run_guard_policy_balance
# STSL_GUARD_SMOKE=1 declares a small fixed smoke, never the full result.
bash tools/run_campaign_bot.sh --headless --chapter=1 --hero=cleopatra --seed=303 --speed=8 --policy=guard-aware --max-seconds=45 --diagnose-battles
```
