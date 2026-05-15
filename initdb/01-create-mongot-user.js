db = db.getSiblingDB("admin");

db.createUser({
  user: "mongot",
  pwd: "mongot-password",
  roles: [
    { role: "readAnyDatabase", db: "admin" },
    { role: "clusterMonitor", db: "admin" }
  ]
});
