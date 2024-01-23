/**
 * The 'addon' C++ addon interface.
 */
interface addon {
  /**
   * Returns a string, confirming the module is online.
   * @returns string
   */
  hello(): string;
  /**
   * Returns a string, confirming the module version number.
   * @returns string
   */
  version(): string;
}
const addon: addon = require('../build/lib/addon.node');
export = addon;
