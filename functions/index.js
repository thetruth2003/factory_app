const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Build the legacy company notification topic.
 * @param {string} companyId Company identifier.
 * @return {string} Topic name.
 */
function topicForCompany(companyId) {
  return `company_${companyId}`;
}

// incidents/{id} create -> bildirim
exports.onIncidentCreate = functions.firestore
    .document("incidents/{incidentId}")
    .onCreate(async (snap, context) => {
      const data = snap.data() || {};
      const companyId = data.createdByCompanyId || data.companyId;
      if (!companyId) return null;
      const machineKey = data.machineKey || data.machineId || "unknown";
      const category = data.category || "unknown";
      const status = data.status || "open";
      const errorCode = data.errorCode || "";

      const topic = topicForCompany(companyId);

      const payload = {
        notification: {
          title: `Yeni çağrı: ${machineKey}`,
          body: `${errorCode ? errorCode + " | " : ""}${category} / ${status}`,
        },
        data: {
          type: "incident_created",
          incidentId: context.params.incidentId,
          machineId: data.machineId || "",
          machineKey: machineKey,
          category: category,
          status: status,
          companyId: companyId,
        },
      };

      try {
        await admin.messaging().send({
          topic,
          ...payload,
        });
        return null;
      } catch (e) {
        console.error("FCM create send error:", e);
        throw e;
      }
    });

// incidents/{id} update -> status değiştiyse bildirim
exports.onIncidentUpdate = functions.firestore
    .document("incidents/{incidentId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data() || {};
      const after = change.after.data() || {};

      const beforeStatus = before.status || "";
      const afterStatus = after.status || "";

      // status değişmediyse boşuna spam yok
      if (beforeStatus === afterStatus && before.canRun === after.canRun &&
          before.targetTeam === after.targetTeam) return null;

      const companyId = after.createdByCompanyId || after.companyId;
      if (!companyId) return null;
      const machineKey = after.machineKey || after.machineId || "unknown";
      const category = after.category || "unknown";
      const topic = topicForCompany(companyId);

      const payload = {
        notification: {
          title: `Durum güncellendi: ${machineKey}`,
          body: beforeStatus !== afterStatus ?
            `${beforeStatus} → ${afterStatus}` :
            (after.canRun === false ? "Üretim durdu" : "Çağrı güncellendi"),
        },
        data: {
          type: "incident_status_changed",
          incidentId: context.params.incidentId,
          machineId: after.machineId || "",
          machineKey: machineKey,
          category: category,
          fromStatus: beforeStatus,
          toStatus: afterStatus,
          companyId: companyId,
        },
      };

      try {
        await admin.messaging().send({
          topic,
          ...payload,
        });
        return null;
      } catch (e) {
        console.error("FCM update send error:", e);
        throw e;
      }
    });
