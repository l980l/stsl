# Tempo-aware policy v3 — evaluation contract

2026-10-21. Follow-up to [checkpoint targeting diagnostics](campaign_checkpoint_diagnostics.md). Card/monster numbers stay frozen. Use `eval-balance` and the configured AI wiki; this measures observable decisions, not objective fun or expert play.

## Hypotheses before outcome inspection

1. Multi-enemy focus and removal reduce ongoing enemy pressure relative to guard-v2's v1 fallback.
2. Setup must retain value in long fights, but is not universally worth spending a threatened hero's last energy. Evaluate visible affordable follow-ups and a bounded future-turn estimate; do not treat all powers as the same flat benefit or all decks as fast damage decks.
3. Different archetypes have different curves. Keep **per-deck** owner-turn1/2/4/8 resource/HP/enemy-progress snapshots, first removal, first power play and setup energy. Do not rank healing, charm or sacrifice decks by earliest kill alone. Resource stock, power timing and setup spend are proxies, **not causal ROI or exact break-even turns**. An investment's actual credited payoff still requires effect-specific attribution or ablation.

## Candidate boundaries

- Separate `tools/tempo_decision_policy.gd`, version `tempo-v3`; v1/v2 remain byte-for-byte preserved. Explicit campaign `--policy=tempo-aware`; default `corrected` unchanged. Keep existing Buddhist safety fallback and callback predicate.
- Restrict new choice logic to multiple living enemies. With one enemy, delegate exactly to guard-v2; this staged rollout deliberately does **not** claim single-boss tempo expertise.
- Only current hand, effective costs, current HP/block/resources/poison/charm/visible intents and aggregate publicly known deck composition. No future draw order, target RNG, speculative effect execution, state mutation or card/deck fixture IDs in runtime decisions.
- Focus scoring, bounded known-power payoffs, visible affordable attack support and special remaining-energy poison amplification are heuristic estimates. No full future phase/relic/signature/critical simulation. Nonlethal setup vs survival remains a tradeoff, not an optimizer guarantee.

## Frozen sample and metrics

18 legal owner16-card decks (starter10+reward6); owner alone or with two fixed starter partners; Sekhmet, Surtr, Egyptian trio, Norse trio (jotun_soldier/garmr/nidhogg_scale); initial HP100/50/25%; grade0; seeds101/505. **18×2×4×3×2=864 pairs /1728 fresh actual battles.** Seed101 is development,505 additional validation, not independent player populations. This is battle-state evidence, not actual reward acquisition or chapter completion. Boss/multi packs are4 authored encounters, not864 distinct content items.

Both arms consume the same current production rules through real ATB. Cap120 total hero-input turns; report caps as censored, not unwinnable. Match initial hashes and record source fingerprints, commit/dirty tree, unique initials and sampled state-trace hashes. Compare per deck, team-size, encounter, HP and seed segment; enumerate new losses/caps, never hide them behind a net gain. Partners differ across owners, so cross-hero tables are not controlled rankings.

Owner-input snapshots at1/2/4/8 are observed **before** that owner's input. Missing later snapshots remain absent/censored, never synthetic zeroes. Record owner and team HP, enemy HP/alive count, own strength (including active power)/morale/tokens/sacrifice bank and active enemy poison/charm. First removal is an **observation** at an owner-input boundary, owner card resolution or battle end, with the observation mode recorded; it is not exact attributed owner damage or an exact enemy-turn timestamp. Record effective printed setup/power cost and net energy debit through effect resolution separately (refunds can make net debit negative); neither is attributed ROI.

## Gates and next decision

- Targeted tests: focus/kill, taunt, silence, fatal sacrifice and existing safety callback; zero-energy/no-poison amplification; affordable multi-hit preparation vs immediate lethal pressure; unit conversion; no state/RNG mutation; exact single-enemy v2 fallback.
- Smoke `STSL_TEMPO_SMOKE=1`: first deck, solo/team, Norse trio/Surtr, HP50,seed101 =4 pairs. Never add smoke to the full sample or tune based on the full matrix's outcomes.
- Full matrix after tests/review: if new highHP losses, new caps or meaningful per-deck regressions appear, retain as experimental and diagnose rather than silently retune the frozen candidate. Regardless of gains, do not replace campaign default or alter card stats.
- Actual scene replay A/B: content/entry-seed fingerprints and first hand must match using the checkpoint comparator. Repeated scenes are repeatability evidence only; later RNG can differ. A successful checkpoint is not a chapter clear.

No remote telemetry, dependencies, performance profiling, commit/push/PR or player-save writes.

## Frozen run results — bSu1ze

864 fresh matched initial states /1728 actual battles,864 unique initial fingerprints and864 unique paired sampled-state traces. All60 source fingerprints matched at start/end and the final files. Initial mismatches, incomplete execution, caps, rejected plays, script/engine errors and warnings:0. All432 single-enemy pairs reproduced the exact same recorded state trace under both policies. Do not treat sampled trace uniqueness as proof of logging every internal engine variable or independent player samples.

| Segment | Pairs | guard-v2 wins | tempo-v3 wins | New wins | New losses |
|---|---:|---:|---:|---:|---:|
| All | 864 | 503 | 535 | 34 | 2 |
| Multi-enemy | 432 | 295 | 327 | 34 | 2 |
| Single-enemy | 432 | 208 | 208 | 0 | 0 |
| Solo (both encounter sizes) | 432 | 88 | 120 | 34 | 2 |
| Three heroes | 432 | 415 | 415 | 0 | 0 |
| Development seed101 | 432 | 253 | 268 | 15 | 0 |
| Additional seed505 | 432 | 250 | 267 | 19 | 2 |

HP100:215→225/288; HP50:160→182/288; HP25:128→128/288 (one recovered win and one new loss cancel, not unchanged individual outcomes). Common victories501 have input and team-HP delta medians0. Multi-enemy common victories293 have team-HP median+4 and input median0: this is not a universal speed improvement. Decimal summary statistics are not decimal game numbers.

### Every archetype, multi-enemy only

Each row has24 matched states (two packs × solo/team × three HP levels × two seeds), not24 independent drafts. All single-enemy outcomes remain unchanged. Different owners have different fixed partners, so this is not a controlled hero ranking.

| Deck | v2→v3 wins /24 | New wins / losses |
|---|---:|---:|
| Napoleon charge | 18→20 | 2 /0 |
| Napoleon legion | 14→16 | 2 /0 |
| Napoleon command | 16→17 | 1 /0 |
| Cleopatra poison | 16→18 | 2 /0 |
| Cleopatra curse | 17→17 | 0 /0 |
| Cleopatra charm | 15→16 | 1 /0 |
| Yi turtle ship | 17→19 | 2 /0 |
| Yi formation | 13→17 | 4 /0 |
| Yi desperate | 15→17 | 2 /0 |
| Joan holy | 18→19 | 1 /0 |
| Joan restoration | 16→18 | 2 /0 |
| Joan martyr | 16→17 | 2 /1 |
| Genghis mobility | 17→20 | 3 /0 |
| Genghis horde | 19→19 | 1 /1 |
| Genghis plunder | 16→20 | 4 /0 |
| Musashi dual blades | 18→20 | 2 /0 |
| Musashi duel | 18→19 | 1 /0 |
| Musashi empty mind | 16→18 | 2 /0 |

### Tempo is not just first kill or largest resource stock

Concrete **single-state illustrations**, not archetype-wide causal estimates (solo, grade0,seed505):

- Napoleon charge, Norse trio/HP50: first removal observation3→2 owner inputs; baseline dies after4 inputs, candidate wins after8 with HP17. Candidate's first POWER play is later,3→6; playing a power earlier was not automatically better.
- Napoleon legion, same pack/HP50: at owner-input4 candidate has **more** enemy HP left95 vs90, but only2 enemies vs3 and ownHP18 vs6. It still loses after5 inputs versus4. More remaining enemy HP did not mean worse immediate survival, and one extra survived turn is not a win.
- Cleopatra poison, same pack/HP50: both play their first POWER on input2. At input4, candidate's active poison stock is6 vs12 and ownHP21 vs25, but has2 enemies rather than3. Baseline dies after4 inputs; candidate wins after9 with HP7. Raw poison stock, early HP and kill speed alone would miss this outcome. This does not attribute the win solely to the power or targeting component.
- Cleopatra charm, same pack/HP50: both still lose after4 inputs; candidate leaves a near-dead target rather than finishing it. The wider1-win gain does not establish that enthrall sequencing is solved.

The read-only `tools/summarize_tempo_balance.mjs` verifies all60 current fingerprints and produces per-deck **paired-reacher** checkpoint deltas with separate reached denominators. Even paired reachers are a selected survivor/long-fight population. Early victory, early death and slow fights change checkpoint availability; never average missing checkpoints as zero or use turn8 resource means as an unconditional strength ranking. Both policies control partners too, so team owner curves do not isolate the owner's deck effects.

### New regressions and rollout decision

Both new losses are on validation seed505, Egyptian trio, solo:

1. `joan_martyr/HP50`: v2 wins after8 inputs with HP31; v3 dies after4. V3 removes the first enemy on input2 rather than3, but at input2 has HP30 vs40, and at input4 HP13 vs38. The first turn changes from Shield Prayer + two Holy Smites to two Holy Smites + Strike. **Faster removal sacrificed survival**. Snapshots show no sacrifice bank at those boundaries; this is not proof the card rewards themselves are too weak.
2. `genghis_horde/HP25`: v2 wins after7 inputs with HP1; v3 dies after3. First removal3→2 still fails. In input2 both start at HP3; execution-target and following card order diverge. Army count snapshots alone do not establish the full cause; future target-death, consumption and defensive sequence effects need a separate intervention.

**Do not promote v3 to the default or recommended general campaign policy.** The preregistered HP≥50 no-new-loss gate failed on Joan. Keep the version opt-in/experimental, preserve the exact candidate and counterexamples, and diagnose these two survival-vs-removal failures before any v4. No full-matrix outcome-based retuning was performed. Card/monster numbers and default `corrected` remain unchanged. One-arm/multiple-setting ablations are still needed to separate targeting, preparation scoring and poison-energy handling; this result validates the package, not each component.

This matrix does not establish actual deck acquisition curves, higher upgrades, all bosses, full chapter1/2 completion, optimal expert play or fun. The candidate's two-owner-turn horizon is deliberately rough: current-intent pressure does not model exact multi-enemy block expiry/ATB or future phases, and most unsupported powers retain v1's flat value. Exact attributed investment/payback, all resource economies and all card-condition sequences remain incomplete.

## Verification and reproduction

- `RFzUko`: tempo46/0, existing campaign-policy PASS, v2-74/0, v1-60/0, live-unit1672/0, tutorial312/0. Final warnings/errors0. Early parse/fixture assertion failures were corrected before this evidence and excluded.
- Reviewed bounded runtime choice logic and corrected evaluator poison key, active-strength accounting, energy refund/conversion distinction and removal-observation labels before freezing. `BOYUVO` final smoke4 pairs:2→3 wins, no caps/rejects/integrity failures; not added to864 full pairs. Earlier smoke runs are development evidence only.
- Actual-scene opt-in connection: A `4HkXwu` wins with HP18, B `i8I9np` loses; both replay identities/initial hands match their historical guard controls through the checkpoint comparator. Master muted, profiling off, rejection/error/warning0. These are **two connection replays**, not full campaign clears or finite-RNG-equivalent paired games, and not additional rows in the864 matrix.
- Policy SHA256 `fe1e09ca85acc6f082d846e3340ef6bb1073ffdc826ac9f5df04b473cc9bf5ea`; v1/v2 hashes remain exactly the prior versions. Source commit `e900b44` + dirty local tree, no commit/push/PR.
- Full raw report: `/Users/kimkwanhyeon/Library/Application Support/STSL-tutorial-validation-live-bSu1ze/tempo_policy_balance.json`; logs under ignored `log/live-balance/STSL-tutorial-validation-live-bSu1ze/`. Per-arm decisions, initial fingerprints, observed checkpoint curves, costs, outcomes and caps are retained. AI wiki stores conclusions, not raw logs.

```sh
bash tools/run_live_balance_checks.sh run_tempo_policy_checks test_campaign_policy run_guard_policy_checks run_synergy_decision_checks run_small_number_live test_tutorial_integration
STSL_TEMPO_SMOKE=1 bash tools/run_live_balance_checks.sh run_tempo_policy_balance
bash tools/run_live_balance_checks.sh run_tempo_policy_balance
node tools/summarize_tempo_balance.mjs '/Users/kimkwanhyeon/Library/Application Support/STSL-tutorial-validation-live-bSu1ze/tempo_policy_balance.json'
```
