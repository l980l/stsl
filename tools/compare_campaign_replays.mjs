// Read-only report validator. Usage: node tools/compare_campaign_replays.mjs REPORT...
// Redirect stdout to an ignored local artifact if a persistent summary is wanted.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])]));
  }
  return value;
}
function hash(value) {
  return createHash('sha256').update(JSON.stringify(canonical(value))).digest('hex');
}

export function summarize(reports) {
  assert.ok(reports.length >= 2, 'At least two replay reports required');
  const rows = reports.map(({ path, report: r }) => {
    assert.equal(r.kind, 'stsl_campaign_autoplay_v1');
    assert.ok(r.config.replay_encounter, 'Full campaign runs are not encounter comparisons');
    assert.match(r.config.replay_identity?.sha256 ?? '', /^[a-f0-9]{64}$/, 'Checkpoint content fingerprint required; recapture legacy reports');
    assert.ok(Number.isSafeInteger(r.config.replay_identity.entry_seed), 'Checkpoint entry seed required');
    assert.equal(r.environment.master_muted, true);
    assert.equal(r.config.profile_frames, false);
    assert.equal(r.action_counts.card_rejected ?? 0, 0);
    assert.ok(['clear', 'defeat'].includes(r.outcome), 'Capped/incomplete run is not a resolved battle');
    const entries = r.action_log.filter(a => a.label === 'battle_entry');
    const contexts = r.action_log.filter(a => a.label === 'battle_context');
    assert.equal(entries.length, 1, 'Exactly one encounter entry required');
    assert.equal(contexts.length, 1);
    const first = r.action_log.find(a => a.label === 'card_decision');
    assert.ok(first, 'Missing initial decision');
    const entry = entries[0].detail;
    const initial = { checkpoint: r.config.replay_identity, entry, enemies: contexts[0].detail.enemies,
      first_state: first.detail.state, energy: first.detail.energy,
      hand: first.detail.options.map(c => [c.card, c.cost, c.playable]) };
    const trace = r.action_log.filter(a => ['actor_turn', 'play_card', 'end_turn', 'hero_damage', 'poison_tick', 'battle_result'].includes(a.label))
      .map(a => ({ label: a.label, detail: a.detail }));
    assert.ok(r.source.gameplay_hash, 'Missing gameplay fingerprint');
    assert.ok(r.source.hash, 'Missing bot/source fingerprint');
    return { path, checkpoint: r.config.replay_encounter, policy: r.config.policy,
      ablation: r.config.decision_ablation ?? 'none', outcome: r.outcome,
      replay_identity: r.config.replay_identity,
      initial_hash: hash(initial), observable_trace_hash: hash(trace),
      gameplay_hash: r.source.gameplay_hash, source_hash: r.source.hash,
      commit: r.source.commit, dirty_entries: r.source.dirty_entries,
      plays: r.action_counts.play_card ?? 0, final: r.runs.at(-1),
      initial_enemy_hp: entry.state.enemy_hp, initial_heroes: entry.state.heroes };
  });
  assert.equal(new Set(rows.map(r => r.checkpoint)).size, 1, 'Use one checkpoint per comparison');
  assert.equal(new Set(rows.map(r => r.gameplay_hash)).size, 1, 'Gameplay rules differ');
  assert.equal(new Set(rows.map(r => r.initial_hash)).size, 1, 'Encounter, deck, relics or initial hand differ');
  const groups = Object.groupBy(rows, row => `${row.policy}/${row.ablation}`);
  return { kind: 'stsl_campaign_checkpoint_comparison_v1',
    contract: { unit: 'one unique pre-entry checkpoint', unique_initial_states: 1,
      executed_replays: rows.length, unique_observable_action_traces: new Set(rows.map(r => r.observable_trace_hash)).size,
      interpretation: 'Repeated actual-scene runs measure repeatability, not independent win rate. Same initial hand does not guarantee identical later RNG or draws. Target-only ablation isolates a policy component, not future states.' },
    groups: Object.fromEntries(Object.entries(groups).map(([key, values]) => [key, {
      replays: values.length, wins: values.filter(r => r.outcome === 'clear').length,
      unique_observable_action_traces: new Set(values.map(r => r.observable_trace_hash)).size,
    }])), rows };
}

const paths = process.argv.slice(2);
if (paths[0] === '--self-test') {
  assert.equal(hash({ b: 1, a: { z: 2, c: 3 } }), hash({ a: { c: 3, z: 2 }, b: 1 }));
  const report = { kind: 'stsl_campaign_autoplay_v1', outcome: 'clear',
    config: { replay_encounter: 'fixture', policy: 'corrected', profile_frames: false,
      replay_identity: { sha256: 'a'.repeat(64), entry_seed: 42 } },
    environment: { master_muted: true }, action_counts: {}, runs: [{}],
    source: { gameplay_hash: 'rules', hash: 'source' }, action_log: [
      { label: 'battle_entry', detail: { state: { enemy_hp: [1], heroes: [] }, deck: {} } },
      { label: 'battle_context', detail: { enemies: ['fixture'] } },
      { label: 'card_decision', detail: { state: {}, energy: 3, options: [] } },
    ] };
  const pair = other => [{ path: 'a', report }, { path: 'b', report: other }];
  assert.equal(summarize(pair(structuredClone(report))).contract.unique_initial_states, 1);
  for (const mutate of [
    r => { r.config.replay_encounter = 'other'; },
    r => { r.config.replay_identity.entry_seed = 43; },
    r => { r.config.replay_identity.sha256 = 'b'.repeat(64); },
    r => { delete r.config.replay_identity; },
    r => { r.source.gameplay_hash = 'changed'; },
    r => { r.action_log[0].detail.deck = { changed: true }; },
    r => { r.action_log[2].detail.options = [{ card: 'changed', cost: 1, playable: true }]; },
    r => { r.environment.master_muted = false; },
    r => { r.config.profile_frames = true; },
    r => { r.outcome = 'stall'; },
    r => { r.action_counts.card_rejected = 1; },
  ]) {
    const altered = structuredClone(report);
    mutate(altered);
    assert.throws(() => summarize(pair(altered)));
  }
  console.log('Campaign replay comparison: 13 checks passed');
} else {
  console.log(JSON.stringify(summarize(paths.map(path => ({ path, report: JSON.parse(readFileSync(path, 'utf8')) }))), null, 2));
}
