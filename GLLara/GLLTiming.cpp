//
//  GLLTiming.cpp
//  GLLara
//
//  Created by Torsten Kammer on 22.08.16.
//  Copyright © 2016 Torsten Kammer. All rights reserved.
//

#include "GLLTiming.h"

#include <QuartzCore/QuartzCore.h>

#include <iostream>
#include <unordered_map>
#include <vector>
#include <limits>

struct Timing {
    std::vector<CFTimeInterval> times;
    CFTimeInterval lastStart;
};

static std::unordered_map<std::string, Timing> timingTags;

void GLLBeginTiming(const char *tag)
{
    Timing &time = timingTags[tag];
    time.lastStart = CACurrentMediaTime();
}

void GLLEndTiming(const char *tag)
{
    CFTimeInterval end = CACurrentMediaTime();
    auto time = timingTags.find(tag);
    assert(time != timingTags.end());
    
    CFTimeInterval total = end - time->second.lastStart;
    time->second.times.push_back(total);
}

void GLLReportTiming() {
    if (timingTags.empty())
        return;
    
    std::cout << "---------\n";
    

    for (const auto &entry : timingTags) {
        if (entry.second.times.size() == 1) {
			std::cout << std::fixed << entry.first << " total " << entry.second.times[0] << "\n";
        } else {
        CFTimeInterval total = 0.0;
        CFTimeInterval max = -std::numeric_limits<CFTimeInterval>::infinity();
        CFTimeInterval min = std::numeric_limits<CFTimeInterval>::infinity();
        for (auto interval : entry.second.times) {
            total += interval;
            max = std::fmax(max, interval);
            min = std::fmin(min, interval);
        }
        
			std::cout << std::fixed << entry.first << " total " << total << " max " << max << " min " << min << " avg " << (total / entry.second.times.size()) << "\n";
        }
    }
    std::cout << std::endl;
    
    timingTags.clear();
}