# Tempo survival follow-up — frozen diagnostic contract

Game/card/enemy values and v1/v2/v3 policy bytes stay frozen. Use the configured AI wiki and eval-balance. No profiling, remote writes, dependencies or player-save writes. Dummy/muted isolated actual-ATB tests only.

## Before candidate implementation

Reproduce the two previously recorded seed505 Egyptian-trio solo regressions: Joan martyr HP50 and Genghis horde HP25. Match their historical initial and trajectory hashes under guard-v2 and tempo-v3 before attributing causes. Instrument pre-decision hand/cost/HP/block/enemy HP/intents/queue plus candidate scores. This diagnostic telemetry is not extra policy input.

Interventions: guard-v2, unchanged tempo-v3, v3 card order with guard target selection, guard card order with v3 target selection. The latter two are diagnostic-only, not campaign options. Every choice remains legal and uses only current state; no future draws or cloned speculative effect execution. A changed outcome supports a sequencing/targeting interaction, not a proof that every similar encounter is solved.

## Candidate decision and validation gates

Initial eight-battle diagnosis PDmsvS reproduced both historical initial/trajectory hashes exactly. Joan recovers under either guard-order or guard-target intervention; Horde recovers under guard-target but not guard-order. These interventions act throughout a battle, so they establish sequencing/targeting dependence, not a single-action causal attribution.

Candidate fixed before full-matrix outcomes: **lexicographic core utility, then same-card focus**. Preserve v3's bounded power/setup/poison values but strip its additive progress/removal bonus out of the primary action score. That score may not reorder different cards, nor override a target with greater core utility; the unchanged v3 score breaks ties only between targets of the same Resource. This protects an available shield from a merely partial-hit bonus and avoids assigning an oversized finisher to a 1HP target when the existing damage-capped core score values another target more. No new coefficients or hero/card IDs. It may lose some v3 wins; enumerate them rather than tune them away.

Only after these results, define a generic separate v4 policy and targeted tests. No fixture/hero/card IDs or outcome-informed numeric coefficient sweep. Preserve safety predicate, taunt/silence/fatal sacrifice, no state/RNG writes, exact single-enemy delegation. Keep v3/default corrected unchanged. A harmful candidate remains opt-in/experimental; do not silently tune on full-matrix failures.

Full paired validation: 18 legal decks × solo/team × four authored encounters × HP100/50/25 × seeds101/505 =864 pairs. Compare v3→v4, plus historical guard-v2 via matched initial hashes. Reserve seed909 for an additional same-matrix validation (432 pairs); do not tune from it. Separate diagnostic/development repeats from these samples. Require no new HP≥50 losses, no caps/rejected plays/initial mismatches/source drift. Enumerate low-HP regressions and per-deck changes even if net wins improve. Outcome gates are not engine test failures: failing rollout leaves candidate experimental.

Metrics: real battle outcome/input count/HP, per-deck matched tempo snapshots and censored reachers. First kill is not survival or fun. Record source hashes at start/end and raw decisions/trajectories. No full-game balance, human win rate or full chapter clear claim from battle fixtures.

## Result and decision

**Reject v4 for general/default rollout.** It fixes the two selected regressions, but loses more other states than it recovers. The retained implementation is an evaluation-only experimental candidate; it is deliberately **not connected to the campaign CLI or substituted for v3/default corrected**. Do not change game numbers to compensate. The frozen candidate was not retuned after either full or reserved-seed outcomes.

| Evaluation | Pairs | v3 wins | v4 wins | New wins | New losses |
|---|---:|---:|---:|---:|---:|
| Full, seeds101/505 |864|535|522|7|20|
| HP100 subset |288|225|223|0|2|
| HP50 subset |288|182|170|5|17|
| HP25 subset |288|128|129|2|1|
| Reserved909 |432|269|269|2|2|

Full20 regressions include19 at HP≥50; the preregistered survival gate fails. Reserved909 has two new HP50 losses despite unchanged total wins. These are matched battle fixtures, not human win rates. Full+reserved are1296 distinct initial fixtures /2592 fresh battles, not1296 authored encounters. Diagnostic, unit and narrow regression reruns are excluded from these totals.

The full baseline v3 reproduces **all864 historical initial and sampled trajectory hashes** from bSu1ze. Using that verified historical guard-v2 baseline, guard→v4 is503→522/864 (23 new wins/4 new losses), still not safe: those four losses are all solo HP50. All432 full single-enemy pairs, plus216 reserved single-enemy pairs, remain exactly delegated to v2. The candidate only changes multi-enemy decisions.

### Selected failures: repaired, not generalized

Final narrow replay `bpaZkZ` and full-matrix rows agree:

| Existing regression, Egypt trio/solo/seed505 | v3 | v4 |
|---|---|---|
| Joan martyr HP50 |loss after4 inputs|win after8 inputs, HP31|
| Genghis horde HP25 |loss after3 inputs|win after7 inputs, HP1|

Final diagnostic `8qooxY` (8 battles, two unique initials) confirms guard/v3 historical hashes. Both guard-order and guard-target interventions recover Joan; only guard-target recovers Horde. Changes apply throughout the fight, so this does not isolate the first changed card as the only cause. Diagnostic decision `score` is the original **card-order selection score** before a target intervention; the per-target `scores` grid contains the actual alternative target evaluation. Do not misread that original score as the changed target's score.

Observed Joan issue: shield-prayer core22.6 is outbid by Smite core18.7+v3 focus. Observed Horde issue: Execution Ground core16.2 on another target loses to core13.8+v3 overkill focus on a1HP enemy. The interventions and repaired rows support a sequencing/target-utility problem, not weak sacrifice rewards. Area attack ordering also changes later; the package is not a one-action causal proof.

### Every archetype, all four encounters

Each row has48 paired states (solo/team × four encounters × HP3 × two seeds), including24 single-enemy pairs that do not change. Fixed partners differ across owners; this is not a controlled hero ranking.

| Deck | v3→v4 wins /48 | New wins / losses |
|---|---:|---:|
| napoleon_charge |31→29|0/2|
| napoleon_legion |27→28|1/0|
| napoleon_command |28→27|0/1|
| cleopatra_poison |30→28|0/2|
| cleopatra_curse |29→29|0/0|
| cleopatra_charm |26→26|0/0|
| yi_turtle_ship |30→29|0/1|
| yi_formation |28→25|0/3|
| yi_desperate |29→31|2/0|
| joan_holy |29→30|1/0|
| joan_restoration |32→31|0/1|
| joan_martyr |29→29|1/1|
| genghis_mobility |32→31|1/2|
| genghis_horde |30→31|1/0|
| genghis_plunder |30→27|0/3|
| musashi_dual_blades |33→33|0/0|
| musashi_duel |32→30|0/2|
| musashi_empty_mind |30→28|0/2|

### Every new full-matrix loss

All20 are solo/grade0. E=Egypt trio, N=Norse trio. These are v3 wins that v4 loses, not necessarily losses against corrected or guard-v2.

| Deck | Encounter | HP% | Seed |
|---|---|---:|---:|
| napoleon_charge |E|50|101|
| napoleon_charge |E|50|505|
| napoleon_command |E|50|101|
| cleopatra_poison |E|50|505|
| cleopatra_poison |N|50|505|
| yi_turtle_ship |E|50|505|
| yi_formation |E|100|101|
| yi_formation |N|100|101|
| yi_formation |N|50|505|
| joan_restoration |N|50|505|
| joan_martyr |N|50|505|
| genghis_mobility |E|50|505|
| genghis_mobility |N|50|101|
| genghis_plunder |E|50|101|
| genghis_plunder |E|50|505|
| genghis_plunder |E|25|505|
| musashi_duel |N|50|101|
| musashi_duel |N|50|505|
| musashi_empty_mind |E|50|101|
| musashi_empty_mind |N|50|101|

Reserved909: new wins are napoleon_charge/E/HP50 and yi_desperate/N/HP100; new losses are yi_turtle_ship/N/HP50 (v3 HP2/7inputs→v4 death/5) and musashi_empty_mind/E/HP50 (v3 HP3/10→v4 death/5). All solo. Do not tune on this reserved seed and continue calling it untouched validation.

## Validation and reproducibility

[Candidate policy](../../tools/tempo_survival_decision_policy.gd) · [targeted checks](../../tests/run_tempo_survival_checks.gd) · [diagnostic interventions](../../tests/run_tempo_survival_diagnostics.gd) · [paired evaluator](../../tests/run_tempo_survival_balance.gd) · [full verified summary](../../log/live-balance/STSL-tutorial-validation-live-TlwMpC/verified-summary.json) · [reserved summary](../../log/live-balance/STSL-tutorial-validation-live-3aOapc/verified-summary.json) · [full engine log](../../log/live-balance/STSL-tutorial-validation-live-TlwMpC/run_tempo_survival_balance.log)

- `rKZuI7`: new30/v3-46/v2-74/v1-60 checks passed, existing campaign policy PASS. Both unit systems, core-vs-focus counterexamples, mixed SINGLE+ALL exclusion, taunt, safety callback, silence, fatal sacrifice, RNG/state preservation and exact single-enemy fallback. A read-only independent review caught the mixed-card eligibility hole before the final freeze; it was repaired and regression-tested before full/reserved runs.
- `nqxwvm`: live-unit1672 and tutorial312 passed. Final measurement/test logs have no engine/script errors or warnings. These counts verify behavior, not balance or fun.
- `TlwMpC` full and `3aOapc` reserved: each62 runtime/evaluator fingerprints equal at start/end/current, initial/paired unique864 and432, initial mismatches/caps/incomplete/rejected0. Read-only [summary verifier](../../tools/summarize_tempo_survival.mjs) checks those contracts, source hashes, the historical v3 reproduction, single-enemy identity, per-deck/HP/seed and paired-reacher checkpoint medians. Unreached checkpoints stay censored; neither a shorter losing fight nor more remaining resources establishes a better power curve.
- Raw reports: `~/Library/Application Support/STSL-tutorial-validation-live-TlwMpC/tempo_survival_balance.json`, `...-3aOapc/tempo_survival_balance.json`, `...-bpaZkZ/tempo_survival_balance.json`, `...-8qooxY/tempo_survival_diagnostics.json`. Exact roots on this machine are under `/Users/kimkwanhyeon/Library/Application Support/`. Engine logs and `verified-summary.json` are in the corresponding ignored `log/live-balance/STSL-tutorial-validation-live-*/` directories. These are local operational artifacts, not committed wiki raw files.
- Historical v1/v2/v3 bytes, current game rules/card/monster/UI values and default corrected are unchanged. Source commit e900b44 + existing dirty tree. No commit/push/PR, player settings/save changes, profiling or portfolio edits.

```sh
bash tools/run_live_balance_checks.sh run_tempo_survival_checks run_tempo_policy_checks run_guard_policy_checks run_synergy_decision_checks test_campaign_policy
bash tools/run_live_balance_checks.sh run_small_number_live test_tutorial_integration
bash tools/run_live_balance_checks.sh run_tempo_survival_diagnostics
STSL_TEMPO_SURVIVAL_MODE=regressions bash tools/run_live_balance_checks.sh run_tempo_survival_balance
bash tools/run_live_balance_checks.sh run_tempo_survival_balance
STSL_TEMPO_SURVIVAL_MODE=holdout bash tools/run_live_balance_checks.sh run_tempo_survival_balance
node tools/summarize_tempo_survival.mjs '/absolute/new/tempo_survival_balance.json' '/absolute/bSu1ze/tempo_policy_balance.json'
```

The historical reference is optional for the new909 seed because it has no old fixture. Summary output is read-only stdout; preserve it beside the raw run when needed.

## Next bounded question

Blanket removal of cross-card focus is **not** a safe general fix, even though it repairs the chosen examples. Which particular action sequences cause the20 regressions remains unisolated. A next version should test current-turn affordable sequences and imminent enemy pressure/defense expiry rather than either always prioritizing progress or globally demoting it. First partition the observed failures with read-only decision logs and independent interventions, then preregister a fresh candidate and new validation seeds. Do not silently expand v4 or tune it using909. Full campaign acquisition/clear, exact multi-enemy ATB survival prediction, all effect-specific ROI and player fun remain unresolved.
