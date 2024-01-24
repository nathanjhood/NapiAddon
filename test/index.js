function test() {

  try {

    const addon = require("../lib/addon.node");

    console.log(addon.hello());
    console.log(`Napi Version: ${addon.version()}`);

  } catch(e) {

    console.log(`Error: ${e}`);
  }
};

function test_v7() {

  try {

    const addon_v7 = require("../build/lib/addon_v7.node");

    console.log(addon_v7.hello());
    console.log(`Napi Version: ${addon_v7.version()}`);

  } catch(e) {

    console.log(`Error: ${e}`);
  }
};

test();
test_v7();
