var argscheck = require('cordova/argscheck'),
               exec = require('cordova/exec');
               
var touchIDKeychainPlugin = {
	isTouchIDAvailable: function(successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchIDKeychain", "isTouchIDAvailable", []);
	},
	savePassword: function(password, successCallback, errorCallback) {
		exec(successCallback, errorCallback, "TouchIDKeychain", "savePasswordToKeychain", [password]);
	},
	getPassword: function(successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchIDKeychain", "getPasswordFromKeychain", []);
	},
	hasPasswordInKeychain: function(successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchIDKeychain", "hasPasswordInKeychain", []);
	},
	deleteKeychainPassword: function(successCallback, errorCallback){
		exec(successCallback, errorCallback, "TouchIDKeychain", "deleteKeychainPassword", []);
	}
};

module.exports = touchIDKeychainPlugin;