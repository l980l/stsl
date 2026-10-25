// Read-only post-hoc summary. No tuning or production state is changed.
// node tools/summarize_tempo_balance.mjs /absolute/path/tempo_policy_balance.json
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';

const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
assert.equal(report.runs.length, report.expected_pairs);
assert.equal(report.expected_pairs, report.mode === 'full' ? 864 : 4);
assert.deepEqual(report.source_sha256_start, report.source_sha256_end);
for (const [path, expected] of Object.entries(report.source_sha256_end)) {
  assert.ok(path.startsWith('res://') && !path.includes('..'));
  const actual = createHash('sha256').update(readFileSync(resolve(path.slice(6)))).digest('hex');
  assert.equal(actual, expected, `Source changed: ${path}`);
}
for (const row of report.runs) assert.equal(row.initial_equal, true);

const median = values => {
  if (!values.length) return null;
  const sorted = values.toSorted((a, b) => a - b);
  return (sorted[Math.floor((sorted.length - 1) / 2)] + sorted[Math.floor(sorted.length / 2)]) / 2;
};
const mean = values => values.length ? values.reduce((a, b) => a + b, 0) / values.length : null;
function summary(rows) {
  const common = rows.filter(r => r.baseline.won && r.candidate.won);
  const checkpointPairs = {};
  for (const turn of ['1', '2', '4', '8']) {
    const both = rows.filter(r => r.baseline.tempo_metrics.checkpoints[turn] && r.candidate.tempo_metrics.checkpoints[turn]);
    checkpointPairs[turn] = {
      total_pairs: rows.length, both_reached: both.length,
      baseline_reached: rows.filter(r => r.baseline.tempo_metrics.checkpoints[turn]).length,
      candidate_reached: rows.filter(r => r.candidate.tempo_metrics.checkpoints[turn]).length,
      paired_mean_delta: Object.fromEntries(['enemy_hp', 'owner_hp', 'team_hp', 'living_enemies', 'owner_strength', 'owner_morale', 'owner_tokens', 'owner_sacrifice_bank', 'enemy_poison', 'enemy_charm'].map(metric => [metric,
        mean(both.map(r => r.candidate.tempo_metrics.checkpoints[turn][metric] - r.baseline.tempo_metrics.checkpoints[turn][metric]))])),
    };
  }
  return { pairs: rows.length,
    baseline_wins: rows.filter(r => r.baseline.won).length,
    candidate_wins: rows.filter(r => r.candidate.won).length,
    new_wins: rows.filter(r => !r.baseline.won && r.candidate.won).length,
    new_losses: rows.filter(r => r.baseline.won && !r.candidate.won).length,
    common_wins: common.length,
    common_win_input_delta_median: median(common.map(r => r.input_delta)),
    common_win_team_hp_delta_median: median(common.map(r => r.hp_delta)),
    checkpoint_pairs: checkpointPairs };
}
const rows = report.runs;
const multi = rows.filter(r => report.scenarios[r.encounter].length > 1);
const segments = {};
for (const field of ['composition', 'initial_hp_percent', 'seed_segment']) {
  segments[field] = Object.fromEntries([...new Set(rows.map(r => r[field]))].map(value => [value, summary(rows.filter(r => r[field] === value))]));
}
console.log(JSON.stringify({
  contract: 'Fixed battle states, not player win rates or fun. Checkpoint deltas use only paired reachers; missing states are censored, not zero. Longer survival/earlier wins change who reaches later checkpoints. Resource stocks and power timing are not attributed ROI.',
  mode: report.mode, source_fingerprints_verified: Object.keys(report.source_sha256_end).length,
  integrity_failures: report.integrity_failures,
  all: summary(rows), multi: summary(multi),
  single: summary(rows.filter(r => report.scenarios[r.encounter].length === 1)),
  segments,
  multi_by_deck: Object.fromEntries([...new Set(multi.map(r => r.deck))].map(deck => [deck, summary(multi.filter(r => r.deck === deck))])),
  new_loss_cases: rows.filter(r => r.baseline.won && !r.candidate.won).map(r => ({ deck: r.deck, encounter: r.encounter, composition: r.composition, hp_percent: r.initial_hp_percent, seed: r.seed, candidate_outcome: r.candidate.outcome })),
}, null, 2));
