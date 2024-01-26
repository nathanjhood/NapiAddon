const platform = process.platform;
var buildDir = "build/lib";

if(platform === "windows")
  buildDir = "build/bin/Release";


function test_hello_v7() {

  let status = false;

  try {

    const addon = require(`../${buildDir}/addon_v7.node`);

    console.log(addon.hello());

    status = true;

  } catch(e) {

    console.log(`${e}`);
  }

  return status;
};

const res_test_hello_v7 = test_hello_v7();

if((!res_test_hello_v7))
{
  console.log("'test_hello_v7()' failed.");
  return false;
}

console.log("'test_hello_v7()' passed.");
return true;
