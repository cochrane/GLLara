//
//  GLLConnexionManager.m
//  GLLara
//
//  Created by Torsten Kammer on 19.02.23.
//  Copyright © 2023 Torsten Kammer. All rights reserved.
//

#import "GLLConnexionManager.h"

#import "GLLara-Swift.h"

#include <dlfcn.h>
#include <stdbool.h>

// Types that we'll need
typedef void (*ConnexionAddedHandlerProc) (unsigned int productID);
typedef void (*ConnexionRemovedHandlerProc) (unsigned int productID);
typedef void (*ConnexionMessageHandlerProc) (unsigned int productID, unsigned int messageType, void* messageArgument);

// Functions from the Connexion framework
// I want this to be able to build even if you don't have the Connexion driver
// installed, so redefining these here instead of including that header.
//
// The official definitions are in
//  /Library/Frameworks/3DconnexionClient.framework/Versions/A/Headers
typedef int16_t (*SetConnexionHandlersProc) (ConnexionMessageHandlerProc messageHandler, ConnexionAddedHandlerProc addedHandler, ConnexionRemovedHandlerProc removedHandler, bool useSeparateThread);
typedef void (*CleanupConnexionHandlersProc) (void);
typedef uint16_t (*RegisterConnexionClientProc) (uint32_t signature, uint8_t *name, uint16_t mode, uint32_t mask);
typedef void (*UnregisterConnexionClientProc) (uint16_t clientID);
typedef void (*UnregisterConnexionClientProc) (uint16_t clientID);
typedef void (*SetConnexionClientMaskProc) (uint16_t clientID, uint32_t mask);
typedef void (*SetConnexionClientButtonMaskProc) (uint16_t clientID, uint32_t mask);

SetConnexionHandlersProc SetConnexionHandlers = NULL;
CleanupConnexionHandlersProc CleanupConnexionHandlers = NULL;
RegisterConnexionClientProc RegisterConnexionClient = NULL;
UnregisterConnexionClientProc UnregisterConnexionClient = NULL;
SetConnexionClientMaskProc SetConnexionClientMask = NULL;
SetConnexionClientButtonMaskProc SetConnexionClientButtonMask = NULL;

typedef struct {
    uint16_t version;
    uint16_t client;
    
    uint16_t command;
    int16_t param;
    int32_t value;
    
    uint64_t timestamp;
    
    uint8_t rawUsbReport[8];
    
    uint16_t buttonsHistoric;
    int16_t axis[6]; // translation x-y-z, rotation x-y-z
    uint16_t usbAddress;
    uint32_t buttonsFull;
} __attribute__((packed)) ConnexionDeviceState;


@interface GLLConnexionManagerKnownDevice : NSObject

@property (nonatomic) unsigned int productID;
@property (nonatomic) uint16_t usbAddress;
@property (nonatomic) simd_float3 lastPositionState;
@property (nonatomic) simd_float3 lastRotationState;
@property (nonatomic) uint32_t lastButtonState;

@end

@implementation GLLConnexionManagerKnownDevice

@end

@interface GLLConnexionManager()
{
    uint16_t clientID;
    NSMutableArray<GLLConnexionManagerKnownDevice*> *knownDevices;
}

- (void)deviceAdded:(unsigned int)productID;
- (void)deviceRemoved:(unsigned int)productID;
- (void)deviceMessage:(unsigned int)productID messageType:(unsigned int)messageType argument:(void*)messageArgument;

- (GLLConnexionManagerKnownDevice *)deviceMatchingProductID:(unsigned int)productID usbAddress:(uint16_t)address;

@end

static void ConnexionDeviceAdded(unsigned int productID) {
    [[GLLConnexionManager sharedConnexionManager] deviceAdded:productID];
}

static void ConnexionDeviceRemoved(unsigned int productID) {
    [[GLLConnexionManager sharedConnexionManager] deviceRemoved:productID];
}

static void ConnexionDeviceMessage(unsigned int productID, unsigned int messageType, void* messageArgument) {
    [[GLLConnexionManager sharedConnexionManager] deviceMessage:productID messageType:messageType argument:messageArgument];

}

static GLLConnexionManager *sharedManager;

@implementation GLLConnexionManager

+ (GLLConnexionManager *)sharedConnexionManager {
    if (!sharedManager) {
        sharedManager = [[GLLConnexionManager alloc] init];
    }
    return sharedManager;
}

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }
    
    knownDevices = [[NSMutableArray alloc] init];
    
    // Check whether we have the framework (and if it is the right one)
    NSBundle* connexionClientBundle = [NSBundle bundleWithPath:@"/Library/Frameworks/3DconnexionClient.framework"];
    if (!connexionClientBundle) {
        NSLog(@"Connexion client framework not found");
        return self;
    }
    if (![connexionClientBundle.bundleIdentifier isEqual:@"com.3dconnexion.driver.client"]) {
        NSLog(@"Connexion client framework not found");
        return self;
    }
    
    // Load it
    NSError* loadError = nil;
    if (![connexionClientBundle loadAndReturnError:&loadError]) {
        NSLog(@"Could not load Connexion client framework, error %@", loadError);
        return self;
    }
    
    // Load symbols
    NSString* basePath = connexionClientBundle.executablePath;
    void* handle = dlopen(basePath.UTF8String, RTLD_NOLOAD | RTLD_FIRST);
    if (!handle) {
        NSLog(@"Could not open handle, error %s", dlerror());
        return self;
    }
    SetConnexionHandlers = (SetConnexionHandlersProc) dlsym(handle, "SetConnexionHandlers");
    CleanupConnexionHandlers = (CleanupConnexionHandlersProc) dlsym(handle, "CleanupConnexionHandlers");
    RegisterConnexionClient = (RegisterConnexionClientProc) dlsym(handle, "RegisterConnexionClient");
    UnregisterConnexionClient = (UnregisterConnexionClientProc) dlsym(handle, "UnregisterConnexionClient");
    SetConnexionClientMask = (SetConnexionClientMaskProc) dlsym(handle, "SetConnexionClientMask");
    SetConnexionClientButtonMask = (SetConnexionClientButtonMaskProc) dlsym(handle, "SetConnexionClientButtonMask");
    
    if (!SetConnexionHandlers || !RegisterConnexionClient || !CleanupConnexionHandlers || !UnregisterConnexionClient || !SetConnexionClientMask || !SetConnexionClientButtonMask) {
        NSLog(@"Could not find connexion functions, error %s", dlerror());
        return self;
    }
    
    SetConnexionHandlers(ConnexionDeviceMessage, ConnexionDeviceAdded, ConnexionDeviceRemoved, false);
    clientID = RegisterConnexionClient('gLaR', (uint8_t *) "de.ferroequinologist.GLLara", 1, 0x3FFF);
    SetConnexionClientMask(clientID, 0x3FFF);
    SetConnexionClientButtonMask(clientID, 0xFFFFFFFF);
    
    return self;
}

- (void)dealloc {
    if (UnregisterConnexionClient && clientID) {
        UnregisterConnexionClient(clientID);
    }
    if (CleanupConnexionHandlers) {
        CleanupConnexionHandlers();
    }
}

- (void)deviceAdded:(unsigned int)productID {
    // Ignored, just here for completeness and because Connexion requires
    // the C callback
}

- (void)deviceRemoved:(unsigned int)productID {
    // Remove all with the same product ID
    // If a user has two identical 3DConnexion devices connected at the same
    // time, then as soon as they update the second it should fill its values
    // again.
    NSMutableIndexSet* matching = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < knownDevices.count; i++) {
        GLLConnexionManagerKnownDevice* device = knownDevices[i];
        if (device.productID == productID) {
            [matching addIndex:i];
        }
    }
    [knownDevices removeObjectsAtIndexes:matching];
}

- (GLLConnexionManagerKnownDevice *)deviceMatchingProductID:(unsigned int)productID usbAddress:(uint16_t)address {
    for (GLLConnexionManagerKnownDevice* device in knownDevices) {
        if (device.productID == productID && device.usbAddress == address) {
            return device;
        }
    }
    
    GLLConnexionManagerKnownDevice* device = [[GLLConnexionManagerKnownDevice alloc] init];
    device.productID = productID;
    device.usbAddress = address;
    [knownDevices addObject:device];
    return device;
}

- (void)deviceMessage:(unsigned int)productID messageType:(unsigned int)messageType argument:(void *)messageArgument {
    
    if (messageType != '3dSR') { // device state
        return;
    }
    
    ConnexionDeviceState* newState = (ConnexionDeviceState *) messageArgument;
    if (newState->version != 27955 || newState->client != clientID) {
        return;
    }
    
    if (newState->command == 2) { // Buttons
        GLLConnexionManagerKnownDevice* device = [self deviceMatchingProductID:productID usbAddress:newState->usbAddress];
        
        device.lastButtonState = newState->buttonsFull;
        
        [[GLLView lastActiveView] unpause];
    } else if (newState->command == 3) { // Axis
        GLLConnexionManagerKnownDevice* device = [self deviceMatchingProductID:productID usbAddress:newState->usbAddress];
        
        // Trial and error, the reported values aren't that consistent
        float scaleFactor = 1.0/530.0f;
        simd_float3 scaleFactorSimd = simd_make_float3(scaleFactor, scaleFactor, scaleFactor);
        device.lastPositionState = simd_make_float3((float) newState->axis[0], (float) newState->axis[1], (float) newState->axis[2]) * scaleFactorSimd;
        device.lastRotationState = simd_make_float3((float) newState->axis[3], (float) newState->axis[4], (float) newState->axis[5]) * scaleFactorSimd;
        
        [[GLLView lastActiveView] unpause];
    }
    
    
}

- (simd_float3)averagePosition {
    simd_float3 result = simd_make_float3(0.0f, 0.0f, 0.0f);
    
    for (GLLConnexionManagerKnownDevice* device in knownDevices) {
        result += device.lastPositionState;
    }
    float factor = 1.0f / fmaxf((float) knownDevices.count, 1.0f);
    return result / simd_make_float3(factor, factor, factor);
}

- (simd_float3)averageRotation {
    simd_float3 result = simd_make_float3(0.0f, 0.0f, 0.0f);
    
    for (GLLConnexionManagerKnownDevice* device in knownDevices) {
        result += device.lastRotationState;
    }
    float factor = 1.0f / fmaxf((float) knownDevices.count, 1.0f);
    return result / simd_make_float3(factor, factor, factor);
}

@end
