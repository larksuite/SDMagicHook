//
//  SDMagicHookUtils.h
//  SDMagicHook
//
//  Created by 高少东 on 2020/5/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

bool sd_ifClassNameHasPrefix(Class cls, const char *prefix);
bool sd_ifClassIsSDMagicClass(Class cls);

NSString* createSelHeaderString(NSString *str, int index);

SEL createSel(SEL sel, NSString *str);

SEL createSelA(SEL sel, int index, NSString *flag);
SEL createSelB(SEL sel, int index, NSString *flag);

NSString* currentThreadTag(void);

NSMutableDictionary *threadStoredDictForEntry(NSString *entry);

NSString *entryForThreadStoredDict(const NSString *const key, NSString *className);

NSMutableDictionary *threadStoredDict(const NSString *const key, NSString *className);

@interface SDMagicHookUtils : NSObject

@end

NS_ASSUME_NONNULL_END
