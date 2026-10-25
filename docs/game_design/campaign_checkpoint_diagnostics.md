# Campaign floor10 diagnostics — 2026-10-20

Follow-up to [guard-v2 validation](guard_policy_v2_evaluation.md). Decision: distinguish encounter policy failure from recruitment/progression before changing card or monster numbers. No gameplay tuning, default-policy replacement, route change or performance profiling in this experiment.

## Profile and interpretation contract

- Hypotheses: (1) a recruit opportunity was missed; (2) enemy targeting contributes to the solo/multiple-enemy failure; (3) targeting alone is sufficient across the two observed campaign states.
- Unit: one unique pre-entry checkpoint, not one independent player or random campaign. Use both original floor10 checkpoints, `xvAH36` (A) and `JVb3SE` (B). They are two states from the **same seed303/map/encounter**, with different HP/decks/relics, not two authored encounters or an unseen holdout.
- Freeze actual gameplay, shared v1 and guard-v2 helpers. Replay each checkpoint through production scenes, preserve HP/deck/relics/encounter/entry seed. Compare checkpoint-content SHA256/entry seed plus canonical initial entry, deck/relics, first-decision state, energy and ordered hand. Never compare A and B as matched conditions.
- Keep actual-scene late RNG: repeated replay can produce different later hands/damage even with a matched first decision. This is a bounded policy-component intervention, not exact paired random streams or a statistical win-rate estimate.
- Intervention `--decision-ablation=corrected-targets`: leave shared card/ally choice intact, replace only enemy targeting with the established campaign rule (counter window if applicable, otherwise lowest living HP). Later card choices naturally diverge after changed targets. Require explicit encounter replay and `synergy-aware`/`guard-aware`; invalid combinations fail closed. Default is `none`. Buddhist safety fallback remains unchanged, so that path does not test the shared intervention.
- A pass here means only a resolved observed encounter and valid comparison inputs. Caps/incomplete/rejected actions or mismatched starts invalidate a resolved comparison. Retain failed repeats as counterexamples and do not promote a blanket policy fix or buff cards from this small population.

## Recruitment and route evidence

The seed1304 Act1 generated map (campaign seed303) has only two elite nodes: node10/floor10 and node25/floor11. Actual route `[14,15,16,17,18,19,20,21,22,23,24]` visits no elite. The bot wins ordinary battles at floors0/3/4/7, then dies at ordinary node24/floor10; its sole successor is the first planned elite node25. Solo status is **not evidence of a skipped recruitment screen**.

Production `game_manager.gd` sets first-elite recruitment pending after Act1 elite victory, opens selection after rewards, then adds the hero/start deck through `complete_hero_recruit`. The map forbids elites before floor5 but does not guarantee an early elite. We did not alter either rule.

Route heuristic limitations found read-only: it grants +45 for every future elite without carrying a simulated recruitment-used state, and values rest independently of current HP. These are separate follow-ups, **not established causes here**: the two elite branches do not form a consecutive-elite path in this seed. At node21, REST22→EVENT23→BATTLE24→ELITE25 and BATTLE32→REST33→EVENT54→ELITE25 have equal room counts but different order. No combat experiment established that changing this route improves survival.

## Actual-scene results

Final10 fingerprinted replays: headless Godot4.7.2, speed8, Master muted, Dummy audio, fresh isolated storage, profiling off. Source commit `e900b44` with recorded dirty tree. Gameplay aggregate SHA256 remained `f331e9b0b40c79bdea823a04b882dc7454d64c5db870a5d27fbcdb2fa2c51822`; bot/source hash `8f0ef7a61c611b04a1fc59ab5a0d3199ccdd34c39248b5f5aaf8ffb5246c35a7`. All runs resolved, no time/action caps, rejected plays, script/engine errors or warnings. All initial comparison hashes matched **within** their checkpoint, including exact checkpoint content and entry seed101327.

| Checkpoint | Policy | Observed wins / replays | Remaining HP in wins | Report IDs |
|---|---|---:|---|---|
| A: HP70/deck13 | guard-aware, unchanged | 0/2 | — | ULGNey, qH4UJv |
| A | synergy-aware v1 | 0/1 | — | 3iPFK3 |
| A | corrected default | 1/2 | 15 | yS5D37, 6W0FD3 |
| A | guard-aware + target-only intervention | 2/2 | 32, 32 | YMRlvj, X0jJAC |
| B: HP72/deck14 | guard-aware, unchanged | 0/1 | — | wA6PoN |
| B | corrected default | 1/1 | 10 | oBkGol |
| B | guard-aware + target-only intervention | 1/1 | 2 | GRucZh |

Final effective population: **2 unique initial states, 1 authored encounter, 10 executed replays and 10 unique observable action traces**, not full-state trajectories. A has7 repeats, B has3; do not call this a ten-state balance matrix. The initial hashes are A `3f64445f3ee891de7d1e4c12f1f4843b4b9cd2239ff0c9ee6e47791a2802e7b3`, B `fc34124942758e30c5b168ee04b3b6f28ef1242b0cbbf8933adbb778852bd01c`. Checkpoint-content hashes are A `0248fe05cc5c44ce9d47518933e35848972f96a87ad70c0d6244a542a205b896`, B `5761bf4f7e3e70cf0c9850dc570b63e72d717aa988471b4bdef443bfae628101`.

A's opponents start at HP `[60,45,40]`: jotun_soldier, garmr, nidhogg_scale. The unmodified shared policy begins attacks on index0 then index1; the intervention begins on index2 and removes that enemy first. The recovered outcomes support targeting as a contributor. They do **not** establish enemy focus as the sole mechanism, an optimal target model, or future-RNG-equivalent causal HP gains. Guard-v2 falls back to v1 with multiple living enemies, so the early decisions do not measure its single-boss forecast.

Before content/entry-seed recording was added,10 exploratory runs used the same two checkpoint paths. A: guard0/2 (`U1o7DL`,`zmm4rh`), v1-0/1 (`vQlzIY`), corrected2/2 (`BUN5HZ`,`9AcnoH`), intervention2/2 (`zXTa5U`,`bcppIf`,HP32/12). B: guard0/1 (`5Aq5lR`), corrected0/1 (`1GGr6y`), intervention0/1 (`j4F0nz`). Their entry/deck/relic/first-hand hashes matched within each state, but their reports cannot retrospectively prove exact checkpoint bytes/entry seed; the final comparator deliberately rejects them. They are retained as exploratory failures, not silently discarded or combined into final-rate estimates. Total execution in this task was20 battles, not20 independent states.

In exploratory B, the intervention removed index2 but still lost with enemies `[49,6,0]`; corrected ended `[49,2,0]`. In the final fingerprinted B both won. Similarly final corrected-A won1/2 rather than the exploratory2/2. This variation prevents claiming guaranteed recovery; same first hand and entry seed do not fix later presentation/combat RNG. B lacks A's pharaoh_venom/serpent_ritual and has different rewards/relics. Those differences are recorded, not isolated causes or proof that a particular card is weak. Reward acquisition, sequencing, status pressure and survival remain possible contributors. Neither checkpoint is proven unwinnable.

## Deliverables and next decision

- `tools/campaign_bot.gd`: opt-in replay-only intervention and explicit report metadata; no default behavior change.
- `tests/test_campaign_policy.gd`: six added argument-contract cases.
- `tools/compare_campaign_replays.mjs`: read-only CLI, canonical checkpoint/initial and **observable-action-trace** fingerprints, per-policy denominators, rejects mismatched starts/gameplay/entry seed/checkpoint contents, capped runs, unmuted/profiling runs and rejected plays. Thirteen self-checks pass. Observable traces include logged actor/card/end-turn/hero-damage/poison/result events and their available states, not complete intents/deck/draw/energy histories; no claim of full-state trajectory uniqueness.
- Fresh campaign-policy PASS, guard74/0 and v1-60/0: `90RZvR`; final identity-recording version campaign-policy PASS: `oXyDFJ`; actual-unit regression1672/0: `sOKfwm`; tutorial312/0: `B5HeZE`. The small-number suite's first wrapper invocation requested a nonexistent tutorial suite afterward; that failed launch is not counted as tutorial verification. The corrected `test_tutorial_integration` invocation passed312 checks.
- Source helpers remain byte-for-byte frozen: v1 `5e255e251bea0e7d3647822e3fb4fce24e4b0f40f3b108481a5a804a7a997d04`, v2 `55f2580b4f916f5ca6a3fa4e63b030355861a4eeac1a74a878ee5c4510837810`. No card/monster/scene/autoload changes.
- Next: use these two states as regression cases for a **separately versioned multi-enemy targeting + card-sequencing candidate**, with additional early-campaign checkpoints. Do not silently modify v1/v2 or enable this diagnostic override for general campaigns. Route-state accounting is a separate bounded defect; whole chapter1/2 completion and human enjoyment remain unresolved.

Raw reports/checkpoints remain under ignored `log/campaign-bot/STSL-campaign-bot-<ID>/`. No player save/settings writes, commit, push or PR.

```sh
node tools/compare_campaign_replays.mjs --self-test
bash tools/run_live_balance_checks.sh test_campaign_policy run_guard_policy_checks run_synergy_decision_checks
bash tools/run_campaign_bot.sh --headless --chapter=1 --hero=cleopatra --seed=303 --speed=8 --policy=guard-aware --max-seconds=45 --decision-ablation=corrected-targets --replay-encounter=/ABS/PROJECT/log/campaign-bot/STSL-campaign-bot-xvAH36/encounter-c1-a1-n24.json
# Supply reports from ONE checkpoint, not mixed A/B inputs:
node tools/compare_campaign_replays.mjs log/campaign-bot/STSL-campaign-bot-ULGNey/report.json log/campaign-bot/STSL-campaign-bot-YMRlvj/report.json
```
