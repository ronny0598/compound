const firebase = require("@firebase/testing");
const fs = require("fs");

module.exports.teardown = async () => {
  // Delete all apps currently running in the firebase simulated environment
  Promise.all(firebase.apps().map(app => app.delete()));
};

module.exports.setup = async (auth, data) => {
  // Create a unique projectId for every firebase simulated app
  const projectId = `rules-spec-${Date.now()}`;

  // Create the test app using the unique ID and the given user auth object
  const app = await firebase.initializeTestApp({
    projectId,
    auth
  });

  // Get the db linked to the new firebase app that we creted
  const db = app.firestore();

  // Apply the test rules so we can write documents
  await firebase.loadFirestoreRules({
    projectId,
    rules: fs.readFileSync("firestore-test.rules", "utf8")
  });

  // Write mock documents with test rules
  if (data) {
    for (const key in data) {
      const ref = db.doc(key);
      await ref.set(data[key]);
    }
  }

  // Apply the rules that we have locally in the project file
  await firebase.loadFirestoreRules({
    projectId,
    rules: fs.readFileSync("firestore.rules", "utf8")
  });

  // return the initialised DB for testing
  return db;
};

expect.extend({
  async toAllow(testPromise) {
    let pass = false;
    try {
      await firebase.assertSucceeds(testPromise);
      pass = true;
    } catch (err) {
      console.log(err);
    }

    return {
      pass,
      message: () =>
        "Expected Firebase operation to be allowed, but it was denied"
    };
  }
});

expect.extend({
  async toDeny(testPromise) {
    let pass = false;
    try {
      await firebase.assertFails(testPromise);
      pass = true;
    } catch (err) {
      console.log(err);
    }
    return {
      pass,
      message: () =>
        "Expected Firebase operation to be denied, but it was allowed"
    };
  }
});
