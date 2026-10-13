const {test, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const handlers = require("../index");

let sent;
beforeEach(() => {
  sent = [];
  admin.messaging().send = async (payload) => {
    sent.push(payload);
    return "test-message";
  };
});
const context = {params: {incidentId: "call-1"}};
const base = {
  machineId: "1A", machineKey: "1A", createdByCompanyId: "factory",
  status: "open", canRun: false, targetTeam: "operator",
};
const snap = (data) => ({data: () => data});

test("new call notification links to its record and company", async () => {
  await handlers.onIncidentCreate.run(snap(base), context);
  assert.equal(sent.length, 1);
  assert.equal(sent[0].data.incidentId, "call-1");
  assert.equal(sent[0].data.companyId, "factory");
  assert.equal(sent[0].topic, "company_factory");
});
test("missing company prevents a fallback notification", async () => {
  await handlers.onIncidentCreate.run(snap({status: "open"}), context);
  assert.equal(sent.length, 0);
});
test("notes and photo timestamps do not create status spam", async () => {
  await handlers.onIncidentUpdate.run({
    before: snap(base), after: snap({...base, updatedAt: 123}),
  }, context);
  assert.equal(sent.length, 0);
});
test("production restart notifies even if the call remains open", async () => {
  await handlers.onIncidentUpdate.run({
    before: snap(base), after: snap({...base, canRun: true}),
  }, context);
  assert.equal(sent.length, 1);
});
test("team handover and workflow transitions notify", async () => {
  await handlers.onIncidentUpdate.run({
    before: snap(base),
    after: snap({...base, status: "waiting", targetTeam: "maintenance"}),
  }, context);
  assert.equal(sent.length, 1);
  assert.equal(sent[0].data.toStatus, "waiting");
});
test("delivery failures are surfaced", async () => {
  admin.messaging().send = async () => {
    throw new Error("delivery unavailable");
  };
  const previous = console.error;
  console.error = () => {};
  try {
    await assert.rejects(
        handlers.onIncidentCreate.run(snap(base), context),
        /delivery unavailable/,
    );
  } finally {
    console.error = previous;
  }
});
