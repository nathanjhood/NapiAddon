const platform = process.platform;
var buildDir = "build/lib";

if(platform === "windows")
  buildDir = "build/bin/Release";


const addon = require(`../${buildDir}/addon.node`);
module.exports = addon;
