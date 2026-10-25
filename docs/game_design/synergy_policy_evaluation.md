# Synergy policy evaluator — contract and evidence

This evaluator compares the inherited hand-order policy with a policy supplied by `synergy_decision_policy.gd`. It is a policy ablation, not a card-buff or ruleset ablation: both sides use the current production small-number combat rules and identical combat fixtures.

## Fixed population

- 18 validated owner decks: actual owner starter 10 plus six distinct authored rewards; two partners receive their actual starter 10-card decks.
- Sekhmet and Surtr; starting team HP 100%, 50%, and 25%; grades 0 and 1; seeds 101 and 202.
- This is `18 × 2 encounters × 3 HP bands × 2 grades × 2 seeds = 432` paired runs, or 864 battles. The cap is 120 hero input turns. Relics and critical hits are disabled.
- The baseline calls the inherited `_play_hand_order`. The candidate calls `Policy.choose(bm, hero_id)`, uses its card/target/ally result, and uses `Policy.discard_choice` for pending discards. Neither side directly modifies combat state.

## Integrity and reporting

Every pair requires equal initial-state hashes. The report records initial-state and paired-trajectory uniqueness, outcomes/caps/incompletes, new wins and losses, and common-win remaining-HP and input-action deltas. It includes individual decision reason/score logs and runtime source hashes for the policy and inherited fixtures.

`STSL_POLICY_SMOKE=1` declares a smoke run: first deck, seed 101, grade 0, HP 25/100, and both encounters (`4` pairs). It is explicitly not a full result and computes its expected count separately, so it cannot falsely pass as the 432-pair evaluation.

## Decision boundary

New losses do not automatically authorize policy adoption. This evaluator does not measure campaign acquisition, player expertise, fun, or a campaign-wide balance result. The final paired result below keeps the candidate opt-in because it contains regressions despite a net gain.

## Implemented policy and safety boundaries

- Shared `tools/synergy_decision_policy.gd`: deterministic visible-state scoring, current hand/energy/hero resources, actual damage previews, living/taunted enemy targets and living ally targets. It does not read future draws, run combat speculatively, roll random targets or mutate battle state. Ties retain stable hand/target order.
- Setup credit requires a follow-up in the present hand that can be paid for after setup. Attack discounts project only the explicit granted discount. Opening debuffs, poison setup, attack preparation, bank draw vs payoff, last-card reload, token income vs defense/damage and current block vs defense/damage receive bounded heuristic weights, not an optimal multi-card search.
- Fatal printed sacrifice and already registered sacrifice-power sources are rejected. Healing/guard target values use missing HP and visible attack demand. Ordinary counter mitigation/reflection remains valuable outside boss charge windows. Immediate poison ticks bypass enemy block in the evaluator as in runtime.
- `incoming()` estimates the visible current ATTACK intents only: random targets use expected shares; known lowest-HP/last-attacker/taunt targets are honored. It is not an exact ATB forecast and does not model future phases, charge payoff, MIMIC, critical RNG, every signature or relic reaction. Effect-by-effect scores are not a full ordered resolution forecast.
- Optional discard without a reward is skipped; rewarded/mandatory discards choose the lowest evaluated hand card. It does not optimize all possible future draws or the full empty-hand combo tree.
- Campaign integration is **opt-in** via `--policy=synergy-aware`; default remains `corrected`, existing route/reward rules remain, and campaign safety predicates still apply. Living Buddhist enemies fall back to the established policy because its karma gates were authored for the old target selector. This campaign mode is therefore not identical to the isolated evaluator in every encounter.
- Card data, monster stats, combat rules and actual player save/settings are unchanged. Test launchers retain Dummy audio, Master mute and isolated `user://`; performance profiling remains disabled.

The 60 deterministic regression checks cover both unit systems, affordability/discount boundaries, forced target cleanup, resource tradeoffs, fatal self-cost, redundant sacrifice power, poison bypass, counter fallback, campaign opt-in/Buddhist fallback and non-mutation/RNG preservation. The initial read-only review found four evaluation mismatches (counter fallback, poison block, projected discount and repeated sacrifice power); all were fixed before the final full comparison. Early partial runs are not final evidence.

## Campaign connection smoke — 2026-10-18

`VGHJ92`: actual scenes, headless, Cleopatra/seed101/chapter1, speed8, `synergy-aware`, diagnosis enabled, profiling disabled. The intentionally limited 45-second run completed six battles, played124 cards, recorded165 card decisions and rejected0 cards. Master mute was true; script/engine errors and warnings were0. It stopped at the wall-clock cap with a battle still active: **not a chapter clear, win-rate sample or hang-free campaign certificate**. The subsequent static wrapper extraction for the Buddhist gate was covered by the final60 checks; this smoke is evidence for the same gate behavior before that extraction.

```sh
bash tools/run_campaign_bot.sh --headless --chapter=1 --hero=cleopatra --seed=101 --speed=8 --policy=synergy-aware --diagnose-battles --max-seconds=45
```

## Reproduction

```sh
bash tools/run_live_balance_checks.sh run_synergy_policy_balance
```

The report is written to `user://synergy_policy_balance.json`; raw decision arrays are retained in that local report for diagnosis and should not be treated as independent-player samples.

## Final paired results — 2026-10-18

`EO87cM`: 432 pairs / 864 actual battles, 432 unique initial-state hashes and432 unique paired trajectories. All initial hashes matched; integrity failures, caps, incompletes and rejected candidate plays were0. All57 runtime source hashes matched the final files. Both sides use the same current card/monster/block rules; only policy differs. Source commit is `e900b44` plus the declared dirty tree, on `test/synergy-aware-policy`.

| Initial team HP | Pairs | Hand-order wins | Synergy-policy wins | New wins | New losses |
|---|---:|---:|---:|---:|---:|
| 100% | 144 | 144 | 144 | 0 | 0 |
| 50% | 144 | 144 | 144 | 0 | 0 |
| 25% | 144 | 113 | 118 | 17 | 12 |
| Total | 432 | 401 | 406 | 17 | 12 |

This is a finite deterministic policy comparison, not an independent-player win-rate estimate. Within the389 common victories, input delta (candidate minus baseline) had median−6, mean−6.20 and range−21..+4: faster371 / slower9 / unchanged9. Remaining team HP delta had median+1, mean+3.96 and range−107..+109: improved196 / worse174 / unchanged19. Faster is not uniformly safer. Decimal figures are summary statistics, not newly introduced decimal game quantities.

### Wounded-entry deck breakdown

Each row is8 paired battles at HP25% (two bosses × two grades × two seeds). This denominator differs from the earlier4 base-grade stress cases per deck. Partners remain fixed within each hero but differ across heroes; these are not hero rankings.

| Deck | Hand-order wins / 8 | Candidate wins / 8 |
|---|---:|---:|
| Napoleon charge | 7 | 6 |
| Napoleon legion | 7 | 5 |
| Napoleon command | 6 | 5 |
| Cleopatra poison | 7 | 6 |
| Cleopatra curse | 7 | 7 |
| Cleopatra charm | 7 | 6 |
| Yi turtle ship | 8 | 7 |
| Yi formation | 6 | 7 |
| Yi desperate | 7 | 8 |
| Joan holy | 5 | 7 |
| Joan restoration | 8 | 8 |
| Joan martyr | 3 | 7 |
| Genghis mobility | 6 | 6 |
| Genghis horde | 2 | 5 |
| Genghis plunder | 5 | 5 |
| Musashi dual blades | 7 | 8 |
| Musashi duel | 8 | 7 |
| Musashi empty mind | 7 | 8 |

All12 new losses were Surtr/HP25%. They span Napoleon charge1/legion2/command1, Cleopatra poison1/curse1/charm1, Yi turtle1/formation1, Genghis horde1/plunder1 and Musashi duel1. Thus a deck can have both new wins and new losses even when its total improves or stays equal. Genghis plunder/grade1/seed101 ended with enemyHP1; Yi turtle/grade0/seed202 with enemyHP6. Near misses are observations, not proof that a flat+1 card buff is correct. The raw records retain seeds, grades, initial states, both traces and candidate reason logs for diagnosis; a reason label is a heuristic explanation, not proof of an effect activating.

### Decision

1. Keep the new shared policy available for explicit tests and campaign `--policy=synergy-aware`; **do not replace the default corrected campaign policy**. The baseline above is hand-order, not corrected campaign scoring, so these wins do not prove superiority to the existing campaign default.
2. Keep card/monster numbers unchanged. Joan holy/martyr and Genghis horde gains show that policy materially affects the apparent weakness; they do not establish final balance or optimal play.
3. Next diagnostic is the12 exact Surtr checkpoints: separate block consumption/transfer, token spending and boss-phase/ATB anticipation with targeted ablations. The current visible-intent heuristic omits future phase/turn ordering and must not be described as a solved survival policy. No post-result weights were silently tuned to these seeds.
4. Human combo readability, enjoyment, campaign acquisition and full chapter1→2 completion remain unmeasured by this comparison.

### Fresh verification

- Decision unit tests60/0, existing campaign policy PASS, live small-number1672/0, tutorial312/0: `GkgJ0i`.
- Existing legacy regression4156/0: `lzs0ei` (earlier pre-wrapper pass4169/0 is historical, not the final count).
- Snapshot5/0 and authored synergy485/0: `50sVGS`; production gameplay sources were not changed by this task.
- Final paired `EO87cM`, unit/regression and campaign smoke logs: script/engine errors and warnings0. `git diff --check` passed. Intermediate fixture/parse failures and the intentionally stopped pre-review comparison are excluded.
- Raw report: `~/Library/Application Support/STSL-tutorial-validation-live-EO87cM/synergy_policy_balance.json`; launcher logs: `log/live-balance/STSL-tutorial-validation-live-EO87cM/`. Generated logs are local ignored artifacts, not wiki raw sources or a new remote analytics service.
