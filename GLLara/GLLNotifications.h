//
//  GLLNotifications.h
//  GLLara
//
//  Created by Torsten Kammer on 19.03.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#include <Foundation/Foundation.h>

// Sent when bound textures or similar change outside of normal execution, to
// indicate that the draw state needs to be reset for the next frame.
extern NSString *GLLDrawStateChangedNotification;
