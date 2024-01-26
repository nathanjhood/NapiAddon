const platform = process.platform;
var buildDir = "build/lib";

if(platform === "windows")
  buildDir += "/Release";

const addon = require(`../${buildDir}/addon.node`);
module.exports = addon;
