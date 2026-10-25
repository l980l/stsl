// Read-only reproducibility and observational summary, not causal attribution.
// node tools/summarize_tempo_sequence_diagnostics.mjs /absolute/diagnostics.json
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';

const report=JSON.parse(readFileSync(process.argv[2],'utf8'));
assert.deepEqual(report.integrity_failures,[]);
assert.equal(report.selected_states,31);
assert.equal(report.runs.length,31);
assert.equal(report.battles,124);
assert.deepEqual(report.source_sha256_start,report.source_sha256_end);
const hash=path=>createHash('sha256').update(readFileSync(path)).digest('hex');
for(const [path,expected] of Object.entries(report.source_sha256_end)) {
  assert.ok(path.startsWith('res://')&&!path.includes('..'));
  assert.equal(hash(resolve(path.slice(6))),expected,`Source drift: ${path}`);
}
const key=r=>[r.deck,r.composition,r.encounter,r.hp_percent??r.initial_hp_percent,r.seed].join('|');
const references=new Map();
for(const [path,expected] of Object.entries(report.reference_sha256)) {
  assert.equal(hash(path),expected,'Reference report changed');
  const prior=JSON.parse(readFileSync(path,'utf8'));
  for(const row of prior.runs) if(row.baseline.won!==row.candidate.won) references.set(key(row),row);
}
assert.equal(references.size,31);
const arms=['v3','v4','v3_order_v4_targets','v4_order_v3_targets'];
const rows=[];
const seen=new Set();
for(const row of report.runs) {
  assert.ok(!seen.has(key(row)));seen.add(key(row));
  const prior=references.get(key(row));assert.ok(prior);
  for(const arm of arms) {
    const result=row.arms[arm];
    assert.equal(result.initial_hash,prior.baseline.initial_hash,'Initial drift');
    assert.ok(['win','loss'].includes(result.outcome));assert.equal(result.capped,false);
    assert.ok(!result.decisions.some(d=>d.card&&!d.played));
  }
  assert.equal(row.arms.v3.trajectory_hash,prior.baseline.trajectory_hash,'v3 replay drift');
  assert.equal(row.arms.v4.trajectory_hash,prior.candidate.trajectory_hash,'v4 replay drift');
  const a=row.arms.v3.observations,b=row.arms.v4.observations;
  const different=a.findIndex((state,i)=>b[i]&&JSON.stringify(state.choice)!==JSON.stringify(b[i].choice));
  const first=different<0?null:{owner_input:a[different].owner_input,hp:a[different].hp,block:a[different].block,
    energy:a[different].energy,incoming_proxy:a[different].incoming_proxy,v3:a[different].choice,v4:b[different].choice};
  rows.push({key:key(row),change:row.reference_change,first_diverging_observed_choice:first,
    outcomes:Object.fromEntries(arms.map(arm=>[arm,row.arms[arm].outcome])),
    target_declined_fallbacks:Object.fromEntries(arms.map(arm=>[arm,row.arms[arm].target_policy_declined_fallbacks])),
    expiry:Object.fromEntries(arms.map(arm=>[arm,row.arms[arm].expired_block])),
    enemy_action_observations:Object.fromEntries(arms.map(arm=>[arm,row.arms[arm].pressure_events.length]))});
}
const groups={};
for(const change of ['v4_loss','v4_gain']) {
  const selected=report.runs.filter(r=>r.reference_change===change);
  groups[change]={states:selected.length,
    arm_wins:Object.fromEntries(arms.map(arm=>[arm,selected.filter(r=>r.arms[arm].won).length])),
    target_declined_fallbacks:Object.fromEntries(arms.map(arm=>[arm,selected.reduce((n,r)=>n+r.arms[arm].target_policy_declined_fallbacks,0)]))};
}
console.log(JSON.stringify({contract:'Selected counterexamples/internal controls; these interventions act throughout battle and cannot isolate a single action or prove that expiry causes defeat.',
  selected_states:31,battles:124,unique_reference_fixtures:seen.size,frozen_arms_reproduced:62,
  runtime_fingerprints_verified:Object.keys(report.source_sha256_end).length,groups,rows},null,2));
