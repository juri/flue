//
//  sectdata.m
//  FlueCLIExample
//
//  Created by Juri Pakaste on 29/09/2016.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <mach-o/getsect.h>
#include <mach-o/ldsyms.h>

#import "sectdata.h"

NSDictionary<NSString *, NSString *>* readLocalizations() {
    unsigned long size;
    void *ptr = getsectiondata(&_mh_execute_header, "__LOCALIZATIONS",
                               "__base", &size);
    NSCParameterAssert(ptr != nil);
    NSCParameterAssert(size > 0);
    NSData *data = [NSData dataWithBytesNoCopy:ptr length:size
                                  freeWhenDone:NO];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *plist = [str propertyListFromStringsFileFormat];
    return plist ?: @{};
}

