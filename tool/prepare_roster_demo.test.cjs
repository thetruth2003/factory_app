const {test} = require('node:test');
const assert = require('node:assert/strict');
const {todayInWarsaw, addDays, monday, instant, overlaps} = require('./prepare_roster_demo.cjs');

test('Polish date changes before UTC and the week begins on Monday', () => {
  assert.equal(todayInWarsaw(new Date('2026-10-14T22:01:00Z')), '2026-10-15');
  assert.equal(monday('2026-10-18'), '2026-10-12');
  assert.equal(monday('2026-10-19'), '2026-10-19');
  assert.equal(addDays('2026-12-31', 1), '2027-01-01');
});
test('Warsaw weeks and demo shifts use real instants across DST', () => {
  const hours = (a, b) => (b - a) / 3600000;
  assert.equal(hours(instant('2026-03-23', 0), instant('2026-03-30', 0)), 167);
  assert.equal(hours(instant('2026-10-19', 0), instant('2026-10-26', 0)), 169);
  assert.equal(hours(instant('2026-03-29', 0), instant('2026-03-29', 8)), 7);
  assert.equal(hours(instant('2026-10-25', 0), instant('2026-10-25', 8)), 9);
  assert.throws(() => instant('2026-03-29', 2), /invalid or ambiguous/);
  assert.throws(() => instant('2026-10-25', 2), /invalid or ambiguous/);
});
test('Adjacent overnight work blocks creation; cancelled and touching shifts do not', () => {
  const start = instant('2026-10-15', 0), end = instant('2026-10-15', 8);
  const old = {startAt: {toDate: () => instant('2026-10-14', 20)},
    endAt: {toDate: () => instant('2026-10-15', 4)}};
  assert.equal(overlaps(start, end, old), true);
  assert.equal(overlaps(start, end, {...old, cancelled: true}), false);
  assert.equal(overlaps(start, end, {...old, endAt: {toDate: () => start}}), false);
  assert.equal(overlaps(start, end, undefined), false);
});
