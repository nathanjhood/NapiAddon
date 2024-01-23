const addon = require("../lib/addon.node");

console.log(addon.hello());
console.log(`Napi Version: ${addon.version()}`);
