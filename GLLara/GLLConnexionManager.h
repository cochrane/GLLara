//
//  GLLConnexionManager.h
//  GLLara
//
//  Created by Torsten Kammer on 19.02.23.
//  Copyright © 2023 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "simd_types.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Manager that listens to inputs on a 3D or "space" mouse device, if any is
 * connected, and provides its values to the program. They are processed by
 * the GLLView.
 *
 * These devices are rare but fun. The class uses the interface from Connexion
 * (these days the only manufacturer). Since that is C and is dynamically
 * loaded, this class is Objective C, as a rare exception for newer files.
 */
@interface GLLConnexionManager : NSObject

+ (GLLConnexionManager *)sharedConnexionManager;

- (simd_float3)averageRotation;
- (simd_float3)averagePosition;

@end

NS_ASSUME_NONNULL_END
