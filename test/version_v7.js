const platform = process.platform;
var buildDir = "/build/lib/";

if(platform === "win32")
  buildDir = "\\build\\bin\\Release\\";


function test_version_v7() {

  let status = false;

  try {

    const addon = require(`..${buildDir}addon_v7.node`);

    console.log(`Napi Version: ${addon.version()}`);

    status = true;

  } catch(e) {

    console.log(`${e}`);
  }

  return status;
};

const res_test_version_v7 = test_version_v7();

if((!res_test_version_v7))
{
  console.log("'test_version_v7()' failed.");
  return false;
}

console.log("'test_version_v7()' passed.");
return true;
