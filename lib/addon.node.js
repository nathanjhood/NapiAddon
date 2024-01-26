const platform = process.platform;
var buildDir = "build/lib";

if(platform === "windows")
  buildDir = "build/lib/Release";

const addon = require(`../${buildDir}/addon.node`);
module.exports = addon;
