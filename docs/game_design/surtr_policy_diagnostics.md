# Surtr low-HP policy regression diagnostics — preregistered interventions

2026-10-18. Follow-up to [the432-pair policy evaluation](synergy_policy_evaluation.md). Card/monster/combat rules and the shared/campaign policy are frozen; new files are evaluator-only. The decision is whether the12 new Surtr/HP25% losses support a specific policy correction, not whether cards need buffs.

## Population and comparison contract

- All18 validated owner16-card archetype decks, same two starter partners per hero, Surtr, HP25%, grades0/1 and seeds101/202:72 fixed initial states. Crit/relics off, real ATB/card effects, input cap120, isolated silent `user://`.
- The12 regressions are selected post-hoc from the previous report; the other60 Surtr/HP25% states are retained as internal controls, not independent holdout data. A recovery on selected failures alone is not a general win-rate gain.
- Six arms per state,432 actual battles. Reference arm `synergy` must exactly reproduce every historical initial hash and trajectory hash. All other arms require the same initial hash. Record wins/losses/caps/incompletes/rejected plays, recovered regressions /12, control regressions /60, unique trajectories, per-decision resources/phase/ATB queue and enemy-turn snapshots. Source hashes plus the frozen reference file hash bound reproducibility.

## Hypotheses and interventions

1. `no_block_spend`: hard-veto own-block attack conversion, actual nonself transfer and block-to-heal consumption when their source has block. Zero-spend self-transfer remains legal. This asks whether eliminating those choices helps; it is not a proposed permanent rule and may remove winning lethal plays.
2. `legacy_ally`: constrain ALLY effects to the previous hand-order policy's lowest-HP living ally, excluding self for transfer. Enemy target/scoring stay as shared policy. This tests protection-target choice, not new card strength.
3. `random_risk`: value current RANDOM attacks at their full possible hit for each hero, instead of certain fractional expected damage. Only guard gains/consumption valuation changes; this is a risk aversion ablation, not a probability correction.
4. `prepare_guard`: inspect up to8 authored slots in the current phase for the first attack, including charge payoffs and intervening strength/form steps. The copied ATB queue determines whether the hero can act again before it (reserve discounted by0.5 if so). Guard still persists until attacked. This explicitly uses authored boss-pattern knowledge, not future RNG/draws; it does not forecast damage-triggered phase changes, ally future plays, all signatures or exact status expiry. Only guard gains/consumption valuation changes.
5. `marginal_guard`: replace `min(spent,incoming)` block-loss cost with `min(block,incoming)-min(block-spent,incoming)`, so spending surplus protection is not charged as immediate HP loss. It retains the old incoming estimator to isolate that arithmetic change.
6. `synergy`: untouched original reference. Discard selection and safety gates are identical in all arms. Interventions are evaluated individually, not silently combined or tuned after observing outcomes.

The known runtime facts are preparation does not expire block; hero turns do not expire block; actual RANDOM attacks hit a selected hero for the full amount; Surtr's phase transition resets intent index. These motivate hypotheses but do not establish which caused a given loss. Decision labels alone are not effect activation evidence.

## Stop and adoption boundary

Run these arms once and report the whole denominator, including counterexamples. Do not promote a default or retune card/monster values from this selected sample. A promising mechanism requires targeted runtime regression tests and a new, separately declared wider policy comparison before adoption. No fun/campaign-clear/performance claim.

```sh
# First generate or retain the full432 reference from the previous evaluator.
STSL_SURTR_REFERENCE='/absolute/path/to/synergy_policy_balance.json' \
  bash tools/run_live_balance_checks.sh run_surtr_policy_diagnostics
# Add STSL_SURTR_SMOKE=1 for the declared one-fixture/six-arm smoke only.
```

## Results — 2026-10-18

Final `gjAmgO`:432 actual battles over72 unique initial states, six arms. Each arm had72 unique trajectories; there were340 distinct trajectories across arms (unchanged interventions are not independent evidence). The original arm reproduced all72 historical initial hashes and all72 original trajectory hashes exactly. All59 consumed source hashes matched final files. Integrity failures, capped/incomplete runs, rejected plays and engine errors/warnings were0.

| Arm | Wins / 72 | Recovered selected failures / 12 | New losses in other60 controls | New wins in other60 controls |
|---|---:|---:|---:|---:|
| Original synergy | 46 | 0 | 0 | 0 |
| No actual block spending | 49 | 8 | 9 | 4 |
| Legacy ally selection | 47 | 1 | 1 | 1 |
| Full random-hit guard risk | 60 | 10 | 3 | 7 |
| First-attack preparation reserve | 64 | 8 | 0 | 10 |
| Marginal block-loss arithmetic | 52 | 1 | 0 | 5 |

“New losses” here compares against the original **synergy** arm inside this72-state population, not against the older hand-order policy. “Recovered” is separately measured on the12 cases where hand order won but original synergy lost. The same72 states selected the hypotheses; the other60 are internal controls, not a new holdout set. Do not combine recoveries across arms as if they were additive.

### Mechanism and counterexamples

- **Preparation reserve is the strongest supported next change:** it preserved all46 original victories, recovered8/12 selected failures and won10 additional controls. In the46 common victories its remaining-team-HP delta averaged+4.54 and input delta median was+1: a survival/speed tradeoff, not a free improvement. It inspects authored boss patterns and discounts reserve when the hero can act again first; this is not a proof that a single larger block score is universally correct.
- **Random-hit averaging matters, but blanket worst-case protection is not safe to adopt:** it recovered10/12 yet lost3 former control victories. Treating expected damage as a certain fractional hit underestimates low-HP tail risk, but treating every random attack as a certain full hit for every hero can overdefend and lose damage tempo.
- **A blanket ban on consuming block is contradicted by controls:**8 selected recoveries came with9 new losses elsewhere. Conversion/transfer has useful winning roles; the result does not support removing those mechanics or globally buffing defense.
- **Ally selection is not the leading explanation in this sample:** reverting it recovered only1 case and lost1 control. This does not certify every target choice as optimal.
- **Marginal consumption loss is a concrete valuation mismatch:** block30 / threat10 / spend5 loses0 immediate protection, not5. The isolated arithmetic correction improved46→52 wins with0 control losses here, but recovered only1 of the12 regressions. This is promising alongside better threat forecasting, not evidence that both corrections' gains add independently.

### First-death and decision evidence

In the exactly reproduced original12 failures, first hero deaths occurred in actual phase0 in8 cases, phase1 in2 and phase2 in2. The instrumentation records `_enemy_phase` rather than inferring it solely from HP: damage-over-time can leave HP below a threshold before the phase transition is processed. Therefore “all12 are final-phase charge failures” is false. The future-guard arm can still recover a fight after an early hero death by keeping the remaining team alive; recovery is not proof it prevented the first death.

Examples of the first changed paid choice in recovered cases:

- `napoleon_legion:0:202`: phase1 / intent index0 (strength preparation), Yi HP12/block0 — original counter strike → prepared-arm defend.
- `yi_turtle_ship:0:202`: phase1 / intent index1 (FORM_SWITCH), Napoleon HP9/block0 — original strike → prepared-arm defend.
- `napoleon_command:0:202`: phase1 / intent index1, Yi HP12/block13 — original counter → prepared-arm defend. This is evidence of policy-level ordering, not a claim counter is generally wrong.

The remaining four selected failures under preparation reserve are `cleopatra_charm:0:202`, `yi_formation:0:202`, `genghis_horde:1:101`, `musashi_duel:0:101`. The random-risk arm recovers these but introduces control regressions; combining arms requires a new declared comparison rather than claiming a solved policy from the union.

### Decision and verification

Keep card/monster values and the production/shared/campaign policy unchanged in this diagnostic task. The next implementation priority is a versioned preparation-reserve / marginal-block-loss policy, with a separately declared wider18-deck/HP100·50·25 comparison and additional seeds before any default promotion. Preserve the remaining four checkpoint cases and the random-risk counterexamples as regression fixtures. Human fun, other bosses, campaign acquisition and full chapter completion remain unmeasured here.

- Final mechanism checks28/0 and existing policy checks60/0: `Z241tz`. These lock both unit systems, risk-vs-AOE behavior, surplus-vs-needed block loss, legal zero-spend self-transfer, preparation reserve, negative-score rescue and non-mutation/RNG preservation.
- Fresh legacy regression4161/0: `3hz3q4`; `git diff --check` passed. Original gameplay/shared policy source files did not change.
- Final full report: `~/Library/Application Support/STSL-tutorial-validation-live-gjAmgO/surtr_policy_diagnostics.json`; logs `log/live-balance/STSL-tutorial-validation-live-gjAmgO/`. The report includes the frozen reference file hash and per-decision/phase/queue evidence.
- Review caught and fixed initial probe errors (filtering ordinary negative scores as safety gates, missing team-bank targets, self-transfer/actual-consumption distinctions); final unit tests and full comparison use corrected code. Parse-failed or intentionally stopped development runs are excluded. The one-fixture smoke was not counted as additional population evidence.
