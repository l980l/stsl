# Tempo sequence follow-up — diagnosis before v5

## Frozen investigation contract

Use eval-balance and the configured AI wiki. Preserve v1/v2/v3/v4 policy bytes, production battle/card/enemy rules, existing work, player saves, default corrected and campaign options. No profiling, portfolio edits, dependencies, remote writes or commit/push. Run Dummy/muted actual ATB fixtures through the isolated launcher.

The previous v4 full/909 matrices are now **development evidence**, not untouched holdouts. Inspect all outcome-changing fixtures (20 losses+7 gains at101/505;2 losses+2 gains at909). These31 initial states are selected counterexamples/internal controls, not an unbiased win-rate sample. Reproduce both reference arms by initial and sampled trajectory hashes before interpreting interventions.

Compare frozen v3, frozen v4, v3 card order + v4 same-card target/ally choice, v4 card order + v3 target/ally choice. Respect legality/taunt/silence; if a target policy declines that card, retain the ordering policy's legal choice and count the fallback. These are diagnostic-only interventions; never claim a changed outcome isolates a single card or create a campaign option from an ablation.

Add a pure observation wrapper around the existing evaluation BattleManager: before/after each real enemy action record HP, block, old-block expiry, enemy index/action type and last owner-input boundary. Do not change expiry or damage. Per-choice log affordable hand, effective cost, current visible intents/queue and v3/v4 scores. An absent observation or unvisited owner turn is censored, not zero. Observed block expiry is not itself a bug or proof of the whole loss cause.

## Candidate/stop boundaries

After diagnosis, define a bounded new version and its tests **before** full outcomes. Prefer retaining v3 except states with a supported current-hand sequence/threat assessment; no fixture/card/hero IDs, future pile order, RNG writes or speculative mutation of live state. Unsupported effects/targets must fall back explicitly. Preserve exact single-enemy v2 delegation and safety callback.

New untouched validation seed:1301. Do not inspect its outcomes until candidate freeze. Development101/505/909 may diagnose but not certify. Final full development864 pairs and reserved432 pairs must enumerate new losses, initial/trace mismatches, rejected plays/caps and source drift. HP≥50 new losses block rollout even if total wins increase. If observations do not justify a safe candidate, report the precise evidence gap and keep the defaults unchanged rather than implement an arbitrary heuristic. No claim of full campaign clear, player balance, attributed ROI or fun from these tests.

## Candidate frozen after diagnosis, before candidate outcomes

QybbdC:31 selected states/124 battles, all62 frozen reference-arm trajectories and all initial hashes reproduced; zero integrity failures. Of22 v4 losses, v3-order/v4-targets recovers7 and v4-order/v3-targets13; among9 v4 gains those arms keep3/5. No universal order/target swap. Old-block expiry is non-monotonic (both more and less expiry occur in losses); do not restore the old rule as a presumed fix.

Concrete hand-dependence: Genghis horde/plunder Egypt/HP25/505 both reach HP3/block13 with enemies HP1/38/36; the same execution target0→1 repairs horde but breaks plunder. Hands differ by a2-cost token area payoff versus a1-cost on-kill-energy power. This is a counterexample to a universal conditional-finisher retarget rule, not proof that this one hand difference solely causes the whole outcome.

v5 keeps v3 card/target decisions exactly unless one of two explicit current-hand order predicates fires. Single enemy remains exact v2. Solo rollout only; team/unsupported states fall back to v3. Never retarget the finisher by deck identity.

1. **Refund setup→same lethal:** an inactive on-kill-energy-once power has no other nonzero effect, its refund covers its effective setup cost, its per-turn refund is unused, and setup+same current finisher are jointly affordable after discount consumption. The visible direct/conditional single-target finisher estimate is lethal against a target without revival/death-trigger complications. Play setup first, then re-evaluate normally; no queued forced follow-up or simulated live-state writes. Critical/passive/phase uncertainty means this is still a bounded preview, not a solver.
2. **Restorative guard→same nonlethal attack:** solo/no existing block/no active powers, at least two distinct currently attacking enemies occur before the next owner opportunity in the visible queue, and a pure direct BLOCK+HEAL card provides both real block and non-overheal healing. It must fit with the chosen attack after consumed discounts. Only plain attacks are supported; if the playable hand contains unknown damage conditions/rules, fall back. If any optimistically affordable plain-attack subset could remove a living enemy, retain v3 pressure/removal instead. This intentionally narrow branch is not a general defense optimizer or a claim that no future opportunity matters.

No new score coefficients or IDs. The subset check deliberately overestimates current one-use discounts to prefer fallback on uncertainty, never to claim an executable future combo. Guard setup is not used when an allowed predicate excludes any potential attack from the preview; the callback applies to both played and follow-up cards. Horde's original conditional-target failure can remain unresolved; do not reintroduce the falsified universal retarget to force that selected row to pass.

## Fixed coverage audit, registered after1301 but before1709

The untouched1301 matrix has zero v5 interventions:267→267/432 wins and identical decisions/outcomes do not validate either new branch. Without changing the frozen candidate, add exactly one fixed new batch at1709:18 decks × solo × two multi-enemy packs × HP50/25 =72 pairs. This is a declared branch-coverage audit in a narrower distribution, not a replacement for1301 or an independent full-campaign sample. Include all72 states even if neither branch fires; no loop searching seeds until a desired result appears. Any new HP≥50 losses still block rollout. If coverage is still absent, report absence instead of claiming validation.

## Results — keep v5 experimental/evaluation-only

The narrow no-new-loss gate passes, but **do not promote or connect this candidate as a general campaign policy**. Both fresh-seed batches fail to exercise either new branch, and existing victories have HP/action tradeoffs. v1/v2/v3/v4 bytes, default corrected, existing campaign options, player saves and game values remain unchanged. No post-outcome tuning or further seed search was performed.

| Batch | Paired fixtures | v3→v5 wins | New wins/losses | v5 interventions | Identical sampled trajectories |
|---|---:|---:|---:|---:|---:|
| Development101/505, full18 decks |864|535→536|1/0|9 in9 states|855|
| Untouched1301, same full matrix |432|267→267|0/0|0|432|
| Declared1709 solo coverage segment |72|17→17|0/0|0|72|

All1368 initial hashes are distinct across these three batches. They represent **2736 fresh battle executions**, not2736 authored encounters or independent players. The selected31-state/124-battle diagnosis and early narrow/unit reruns are not added to that matrix. All three matrix reports have62 start/end/current source fingerprints equal, zero initial mismatch/caps/incomplete/rejected plays, and no engine/script errors/warnings in final logs. Full baseline v3 reproduces all864 historical initial and sampled trajectory hashes exactly. Full432 plus reserved216 single-enemy pairs are unchanged; all team fixtures remain v3 (including when an ally has died).

### Actual interventions and tradeoffs

Only development seed505 exercises the new logic: three restorative-guard choices and six refund-setup choices. Same HP/inputs below means no observed improvement to those metrics, not full state identity.

| Solo deck / pack / initialHP% | Intervention | v3 result (HP / inputs) | v5 result (HP / inputs) |
|---|---|---|---|
| Joan holy / Egypt /50 |restorative guard|win20/7|win12/5|
| Joan restoration / Egypt /50 |restorative guard|win55/12|win40/14|
| Joan martyr / Egypt /50 |restorative guard|loss0/4|win28/7|
| Genghis plunder / Egypt /100 |refund setup|win76/7|win78/6|
| Genghis plunder / Egypt /50 |refund setup|win30/6|win28/6|
| Genghis plunder / Egypt /25 |refund setup|win5/7|win5/6|
| Genghis plunder / Norse /100 |refund setup|win51/8|win52/8|
| Genghis plunder / Norse /50 |refund setup|win3/8|win4/8|
| Genghis plunder / Norse /25 |refund setup|loss0/3|loss0/3|

Common535 victories have median HP/input delta0, but six have nonzero HP delta and four nonzero input delta. In particular restoration loses15 final HP and takes two more inputs, while holy loses8HP despite two fewer inputs. Neither median0 nor no-new-loss establishes better balance for every deck. Full HP100 stays225/288, HP50 is182→183/288, HP25 stays128/288.

### Every archetype, full matched matrix

Each row has48 paired states: solo/team × four encounters × three HP levels × two development seeds. Partners differ across owners; not a hero ranking.

| Deck | v3→v5 wins /48 |
|---|---:|
| napoleon_charge |31→31|
| napoleon_legion |27→27|
| napoleon_command |28→28|
| cleopatra_poison |30→30|
| cleopatra_curse |29→29|
| cleopatra_charm |26→26|
| yi_turtle_ship |30→30|
| yi_formation |28→28|
| yi_desperate |29→29|
| joan_holy |29→29|
| joan_restoration |32→32|
| joan_martyr |29→30|
| genghis_mobility |32→32|
| genghis_horde |30→30|
| genghis_plunder |30→30|
| musashi_dual_blades |33→33|
| musashi_duel |32→32|
| musashi_empty_mind |30→30|

Relative to the verified historical guard-v2 fixture baseline, v5 is503→536/864 (34 new wins/one new loss). The remaining loss versus guard is **Genghis horde/Egypt/solo/HP25/505**. v5 deliberately retains v3 there rather than applying a universal target swap falsified by the plunder counterexample. It has not solved both original regressions or the chapter campaign.

## Diagnostic interpretation

The observation-only `tempo_pressure_battle_manager.gd` wraps, rather than replaces, the inherited real intent/expiry path. All62 reference-arm trajectories reproduce, supporting that instrumentation did not perturb these recorded battles. It logs each real enemy action's before/after HP/block and actual old-block expiry with its last owner-input boundary. This is not a claim to capture every engine variable or a causally isolated HP contribution.

For22 selected v4 losses (20 full +2 former909), the v3-order/v4-targets intervention wins7, while v4-order/v3-targets wins13. For9 selected v4 gains, those interventions retain3/5 wins respectively. Target-policy-declined fallbacks are0. Some v4 losses expire more block and others less than v3, so total expiry alone does not diagnose the loss or justify restoring permanent block. Original/final rule behavior was never changed in the diagnosis.

`verified-summary.json` identifies each fixture's first **observed changed choice**, not a proven sole causal action. The two interventions act repeatedly throughout battle; their future hands/targets can diverge. The horde/plunder example motivates checking current affordable setup/payoff choices, but does not prove that only their one differing card explains every subsequent turn.

## Validation, artifacts and reproduction

- Final checks `5q44Iv`: v5-41/v2-74/v1-60 and existing campaign-policy PASS. `MkTiNt` additionally v4-30/v3-46. `xLKkko`: live-unit1672/tutorial312. Unit checks cover both unit scales, missing queue boundary, original team with dead ally, joint affordability, potential hand removal, callback exclusion, silence, no RNG/state/turn-use mutation, exact single-enemy fallback, real runtime setup+finisher spending/refund. Early fixture-only failures used an invalid SINGLE target on a block; fixed to SELF before final results, not reported as a gameplay bug. Independent read-only review verified team/queue fail-closed boundaries before matrix freeze.
- Diagnosis `QybbdC`: [verified summary](../../log/live-balance/STSL-tutorial-validation-live-QybbdC/verified-summary.json), [engine log](../../log/live-balance/STSL-tutorial-validation-live-QybbdC/run_tempo_sequence_diagnostics.log), [124-battle evaluator](../../tests/run_tempo_sequence_diagnostics.gd), [observation wrapper](../../tests/tempo_pressure_battle_manager.gd), [verifier](../../tools/summarize_tempo_sequence_diagnostics.mjs). Reference reports themselves are hashed;31 unique fixture/initial hashes and62 frozen arm trajectories verify.
- Full `UgaNRc`: [summary](../../log/live-balance/STSL-tutorial-validation-live-UgaNRc/verified-summary.json), [engine log](../../log/live-balance/STSL-tutorial-validation-live-UgaNRc/run_tempo_sequence_balance.log).
- Reserved `kPCxTl`: [summary](../../log/live-balance/STSL-tutorial-validation-live-kPCxTl/verified-summary.json), [engine log](../../log/live-balance/STSL-tutorial-validation-live-kPCxTl/run_tempo_sequence_balance.log).
- Coverage `OfH0e0`: [summary](../../log/live-balance/STSL-tutorial-validation-live-OfH0e0/verified-summary.json), [engine log](../../log/live-balance/STSL-tutorial-validation-live-OfH0e0/run_tempo_sequence_coverage.log), [fixed72-pair harness](../../tests/run_tempo_sequence_coverage.gd).
- Actual raw JSONs are in `/Users/kimkwanhyeon/Library/Application Support/STSL-tutorial-validation-live-<ID>/`: `tempo_sequence_diagnostics.json` for QybbdC; `tempo_sequence_balance.json` for UgaNRc/kPCxTl; `tempo_sequence_coverage.json` for OfH0e0. These are local ignored operational artifacts, not wiki raw. Each raw run retains decisions/checkpoints, source hashes and integrity results.
- [Policy](../../tools/tempo_sequence_decision_policy.gd), [41 checks](../../tests/run_tempo_sequence_checks.gd), [full/reserved evaluator](../../tests/run_tempo_sequence_balance.gd). Policy SHA256 `3a019e213d91291606688f727fb81cb6cf1a2c5dbacce04c5a8ea4e4688b87b1`. Production autoload/resources/scenes unchanged from HEAD; prior policy hashes retained. Source e900b44 + pre-existing dirty tree. No commit/push/PR or player-save/config edits.

```sh
STSL_V4_FULL_REPORT='/absolute/TlwMpC/tempo_survival_balance.json' STSL_V4_HOLDOUT_REPORT='/absolute/3aOapc/tempo_survival_balance.json' bash tools/run_live_balance_checks.sh run_tempo_sequence_diagnostics
node tools/summarize_tempo_sequence_diagnostics.mjs '/absolute/QybbdC/tempo_sequence_diagnostics.json'
bash tools/run_live_balance_checks.sh run_tempo_sequence_checks run_tempo_survival_checks run_tempo_policy_checks run_guard_policy_checks run_synergy_decision_checks test_campaign_policy
bash tools/run_live_balance_checks.sh run_small_number_live test_tutorial_integration
bash tools/run_live_balance_checks.sh run_tempo_sequence_balance
STSL_TEMPO_SEQUENCE_MODE=holdout bash tools/run_live_balance_checks.sh run_tempo_sequence_balance
bash tools/run_live_balance_checks.sh run_tempo_sequence_coverage
node tools/summarize_tempo_survival.mjs '/absolute/UgaNRc/tempo_sequence_balance.json' '/absolute/bSu1ze/tempo_policy_balance.json'
```

The shared summary verifier now reports the actual candidate version, branch-activation counts, identical sampled trajectories and generic historical-guard comparison; it still supports v4 output without changing any old policy or raw measurements. Coverage must not be inferred from sample size alone.

## Next bounded work

Retain v5 as an evaluator-only candidate. Next build a declared **branch-enriched legal-state validation suite** with genuinely different hands/resources/enemy windows and explicit negative controls, not a random-seed search until a win appears. Assess restorative-guard HP/input tradeoffs independently from the refund branch before deciding what to expose in the campaign bot. The horde/plunder conditional-target counterexample still needs multi-card payoff/resource planning; no blanket attack/defense or target override is justified. Full acquisition/upgrade curves, all-effect causal ROI, chapter completion and human fun remain unverified.
