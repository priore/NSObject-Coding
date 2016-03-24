//
//  NSObject+Coding.h
//
//  Created by Danilo Priore on 24/02/14.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (Coding)

+ (id)newFromObject:(id)object;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

- (BOOL)isEqualToObject:(id)object;
- (BOOL)isEqualToObject:(id)object forKeyPath:(NSString*)key;

- (void)copyValuesTo:(id)object;
- (void)copyValuesTo:(id)object ignoreEmpty:(BOOL)ignore;

- (NSString *)debugDescription;

@end
