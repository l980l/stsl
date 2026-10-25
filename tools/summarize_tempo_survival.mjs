// Read-only: validate source/initial/trajectory identity before reporting gains.
// node tools/summarize_tempo_survival.mjs new.json [historical-v2-v3.json]
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';

const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const expected = { full: 864, holdout: 432, regressions: 2, smoke: 4, coverage: 72 };
assert.equal(report.expected_pairs, expected[report.mode]);
assert.equal(report.runs.length, report.expected_pairs);
assert.deepEqual(report.integrity_failures, []);
assert.deepEqual(report.source_sha256_start, report.source_sha256_end);
function verifySources(hashes) {
  for (const [path, hash] of Object.entries(hashes)) {
    assert.ok(path.startsWith('res://') && !path.includes('..'));
    assert.equal(createHash('sha256').update(readFileSync(resolve(path.slice(6)))).digest('hex'), hash, `Source drift: ${path}`);
  }
}
verifySources(report.source_sha256_end);
const key = r => [r.deck,r.composition,r.encounter,r.initial_hp_percent,r.grade,r.seed].join('|');
const unique = new Set();
for (const row of report.runs) {
  assert.ok(!unique.has(key(row)), 'Duplicate fixture key'); unique.add(key(row));
  assert.equal(row.baseline.initial_hash,row.candidate.initial_hash);
  for (const side of ['baseline','candidate']) {
    assert.ok(['win','loss'].includes(row[side].outcome));
    assert.equal(row[side].capped,false);
    assert.equal(row[side].decisions.filter(d=>d.card && !d.played).length,0);
  }
  if (['sekhmet','surtr'].includes(row.encounter)) assert.equal(row.baseline.trajectory_hash,row.candidate.trajectory_hash);
}
const median = values => {
  if (!values.length) return null;
  const sorted = values.toSorted((a,b)=>a-b);
  return (sorted[Math.floor((sorted.length-1)/2)]+sorted[Math.floor(sorted.length/2)])/2;
};
function summarize(rows) {
  const common = rows.filter(r=>r.baseline.won && r.candidate.won);
  return {pairs:rows.length,baseline_wins:rows.filter(r=>r.baseline.won).length,candidate_wins:rows.filter(r=>r.candidate.won).length,
    new_wins:rows.filter(r=>!r.baseline.won&&r.candidate.won).length,new_losses:rows.filter(r=>r.baseline.won&&!r.candidate.won).length,
    common_wins:common.length,common_win_hp_delta_median:median(common.map(r=>r.hp_delta)),common_win_input_delta_median:median(common.map(r=>r.input_delta)),
    checkpoints:Object.fromEntries(['1','2','4','8'].map(turn=>{
      const paired=rows.filter(r=>r.baseline.tempo_metrics.checkpoints[turn]&&r.candidate.tempo_metrics.checkpoints[turn]);
      return [turn,{total_pairs:rows.length,paired_reached:paired.length,
        baseline_reached:rows.filter(r=>r.baseline.tempo_metrics.checkpoints[turn]).length,
        candidate_reached:rows.filter(r=>r.candidate.tempo_metrics.checkpoints[turn]).length,
        paired_team_hp_delta_median:median(paired.map(r=>r.candidate.tempo_metrics.checkpoints[turn].team_hp-r.baseline.tempo_metrics.checkpoints[turn].team_hp)),
        paired_living_enemy_delta_median:median(paired.map(r=>r.candidate.tempo_metrics.checkpoints[turn].living_enemies-r.baseline.tempo_metrics.checkpoints[turn].living_enemies))}];
    }))};
}
const cases = rows => rows.map(r=>({key:key(r),baseline_hp:r.baseline.remaining_hp,candidate_hp:r.candidate.remaining_hp,
  baseline_inputs:r.baseline.hero_input_turns,candidate_inputs:r.candidate.hero_input_turns}));
const activations=report.runs.filter(r=>r.candidate.decisions.some(d=>d.version===report.policy.candidate));
const interventionReasons={};
for(const row of report.runs) for(const decision of row.candidate.decisions) {
  if(decision.version!==report.policy.candidate) continue;
  interventionReasons[decision.reason]=(interventionReasons[decision.reason]??0)+1;
}
const summary = {mode:report.mode,policy:report.policy,contract:'Actual ATB battle fixtures, not player win rate, fun or chapter clear. Reached checkpoints are censored/selected, not unconditional ROI.',
  activated_fixture_count:activations.length,intervention_reasons:interventionReasons,
  identical_recorded_trajectories:report.runs.filter(r=>r.baseline.trajectory_hash===r.candidate.trajectory_hash).length,
  fingerprints_verified:Object.keys(report.source_sha256_end).length,all:summarize(report.runs),
  by_deck:Object.fromEntries([...new Set(report.runs.map(r=>r.deck))].map(deck=>[deck,summarize(report.runs.filter(r=>r.deck===deck))])),
  by_hp:Object.fromEntries([...new Set(report.runs.map(r=>r.initial_hp_percent))].map(hp=>[hp,summarize(report.runs.filter(r=>r.initial_hp_percent===hp))])),
  by_seed:Object.fromEntries([...new Set(report.runs.map(r=>r.seed))].map(seed=>[seed,summarize(report.runs.filter(r=>r.seed===seed))])),
  new_loss_cases:cases(report.runs.filter(r=>r.baseline.won&&!r.candidate.won)),
  new_win_cases:cases(report.runs.filter(r=>!r.baseline.won&&r.candidate.won)),
  high_hp_gate:!report.runs.some(r=>r.initial_hp_percent>=50&&r.baseline.won&&!r.candidate.won)};
if (process.argv[3]) {
  const old=JSON.parse(readFileSync(process.argv[3],'utf8'));
  verifySources(old.source_sha256_end);
  const oldRows=new Map(old.runs.map(r=>[key(r),r]));
  const paired=[];
  for(const row of report.runs) {
    const prior=oldRows.get(key(row));
    assert.ok(prior,'Historical fixture missing: '+key(row));
    assert.equal(prior.candidate.initial_hash,row.baseline.initial_hash,'Initial historical drift');
    assert.equal(prior.candidate.trajectory_hash,row.baseline.trajectory_hash,'Frozen v3 trajectory drift');
    paired.push({...row,baseline:prior.baseline,hp_delta:row.candidate.remaining_hp-prior.baseline.remaining_hp,
      input_delta:row.candidate.hero_input_turns-prior.baseline.hero_input_turns});
  }
  summary.historical_v3_reproduced=paired.length;
  summary.historical_guard_to_candidate=summarize(paired);
  if(report.policy.candidate==='tempo-v4') summary.historical_guard_to_v4=summary.historical_guard_to_candidate;
  summary.historical_guard_new_loss_cases=cases(paired.filter(r=>r.baseline.won&&!r.candidate.won));
}
console.log(JSON.stringify(summary,null,2));
