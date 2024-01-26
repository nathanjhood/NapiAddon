const platform = process.platform;
var buildDir = "build/lib";

if(platform === "windows")
  buildDir = "build/bin/Release";


function test() {

  let status = false;

  try {

    const addon = require("../lib/addon.node");

    console.log(addon.hello());
    console.log(`Napi Version: ${addon.version()}`);

    status = true;

  } catch(e) {

    console.log(`${e}`);
  }

  return status;
};

function test_v7() {

  let status = false;

  try {

    const addon_v7 = require(`../${buildDir}/addon_v7.node`);

    console.log(addon_v7.hello());
    console.log(`Napi Version: ${addon_v7.version()}`);

    status = true;

  } catch(e) {

    console.log(`${e}`);
  }

  return status;
};

const res_test = test();
const res_test_v7 = test_v7();

if((!res_test) || (!res_test_v7))
{
  console.log("tests failed.");
  return false;
}

console.log("tests passed.");
return true;
