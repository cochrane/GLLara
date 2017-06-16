//
//  GLLTiming.h
//  GLLara
//
//  Created by Torsten Kammer on 22.08.16.
//  Copyright © 2016 Torsten Kammer. All rights reserved.
//

#ifndef GLLTiming_h
#define GLLTiming_h

#ifdef __cplusplus

extern "C" {

#endif

void GLLBeginTiming(const char *tag);
void GLLEndTiming(const char *tag);
    
void GLLReportTiming();

#ifdef __cplusplus
}

class GLLTimer {
    const char *tag;
public:
    GLLTimer(const char *tag) : tag(tag) {
        GLLBeginTiming(tag);
    }
    ~GLLTimer() {
        GLLEndTiming(tag);
    }
};

#endif

#endif /* GLLTiming_h */
