/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "TouchIDKeychain.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import <Cordova/CDV.h>

@implementation TouchIDKeychain

- (void)isTouchIDAvailable:(CDVInvokedUrlCommand*)command{
    self.laContext = [[LAContext alloc] init];
    BOOL touchIDAvailable = [self.laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    if(touchIDAvailable){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else{
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"TouchID no se encuentra en este dispositivo"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)hasPasswordInKeychain:(CDVInvokedUrlCommand*)command{
    self.TAG = @"hasLoginKeyOnChain";
    BOOL hasLoginKey = [[NSUserDefaults standardUserDefaults] boolForKey:self.TAG];
    if(hasLoginKey){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else{
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"No hay password almacenado en keychain"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)savePasswordToKeychain:(CDVInvokedUrlCommand*)command{
    NSString* password = (NSString*)[command.arguments objectAtIndex:0];
    self.TAG = @"hasLoginKeyOnChain";
    @try {
        self.MyKeychainWrapper = [[KeychainWrapper alloc]init];
        [self.MyKeychainWrapper mySetObject:password forKey:(__bridge id)(kSecValueData)];
        [self.MyKeychainWrapper writeToKeychain];
        [[NSUserDefaults standardUserDefaults]setBool:true forKey:self.TAG];
        [[NSUserDefaults standardUserDefaults]synchronize];

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    @catch(NSException *exception){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"No se puede guardar la contraseña en el Keychain"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void)deleteKeychainPassword:(CDVInvokedUrlCommand*)command{
    self.TAG = @"hasLoginKeyOnChain";
    @try {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.TAG];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    @catch(NSException *exception) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Error al eliminar el flag en deleteKeychainPassword"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    
    
}

-(void)getPasswordFromKeychain:(CDVInvokedUrlCommand*)command{
    self.laContext = [[LAContext alloc] init];
    self.TAG = @"hasLoginKeyOnChain";
    self.MyKeychainWrapper = [[KeychainWrapper alloc]init];
    
    BOOL hasLoginKey = [[NSUserDefaults standardUserDefaults] boolForKey:self.TAG];
    if(hasLoginKey){
        BOOL touchIDAvailable = [self.laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
        
        if(touchIDAvailable){
            [self.laContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Ingrese su huella para iniciar sesión automáticamente" reply:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                if(success){
                    //Entonces busca el password en el keychain
                    NSString *password = [self.MyKeychainWrapper myObjectForKey:@"v_Data"];
                    NSMutableDictionary* retorno = [NSMutableDictionary dictionaryWithCapacity:1];
                    [retorno setObject:password forKey:@"password"];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:retorno];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
                if(error != nil) {
                    NSString *message;
                    BOOL showAlert = false;
                    
                    switch (error.code) {
                        case LAErrorAuthenticationFailed:
                            message = @"No se puede verificar su identidad. Por favor, ingrese su Pin";
                            showAlert = true;
                            break;
                        
                        case LAErrorUserFallback:
                            message = @"Ingrese su Pin";
                            showAlert = true;
                            break;
                        
                        default:
                            message = @"TouchID no se encuentra configurado. Por favor, ingrese su Pin";
                            showAlert = true;
                            break;
                    }
                    if(showAlert){
                        //Retorna error
                        UIAlertView * alerta = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alerta show];
                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: message];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                    
                    
                }
                });
            }];
            
        }
        else{
            // UIAlertView * alerta = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Su dispositivo no cuenta con TouchID" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            // [alerta show];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Su dispositivo no cuenta con TouchID"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
    else{
        UIAlertView * alerta = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No se ha encontrado una contraseña guardada. Para guardar la contraseña enrolese nuevamente en la aplicación." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alerta show];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"No se ha encontrado una contraseña guardada. Para guardar la contraseña enrolese nuevamente en la aplicación."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}
@end
