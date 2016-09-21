//
//  NSObject+Coding.m
//
//  Created by Danilo Priore on 24/02/14.
//
//

#import "NSObject+Coding.h"
#import <objc/runtime.h>

@implementation NSObject (Coding)

+ (id)newFromObject:(id)object
{
    id obj = [self new];
    [object copyValuesTo:obj];
    return obj;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [self init])
    {
        unsigned int count = 0;
        objc_property_t *propertys = class_copyPropertyList([self class], &count);
        for (int i = 0; i < count; ++i) {
            NSString *name = [NSString stringWithCString:property_getName(propertys[i]) encoding:NSUTF8StringEncoding];
            [self setValue:[decoder decodeObjectForKey:name] forKey:name];
        }
        free(propertys);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    unsigned int count = 0;
    objc_property_t *propertys = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; ++i) {
        NSString *name = [NSString stringWithCString:property_getName(propertys[i]) encoding:NSUTF8StringEncoding];
        [encoder encodeObject:[self valueForKey:name] forKey:name];
    }
    free(propertys);
}

- (BOOL)isEqualToObject:(id)object
{
    unsigned int count = 0;
    objc_property_t *propertys = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; ++i) {
        NSString *name = [NSString stringWithCString:property_getName(propertys[i]) encoding:NSUTF8StringEncoding];
        
        id val1 = [self valueForKey:name];
        id val2 = [object valueForKey:name];
        
        if (val1 != nil && val2 != nil && ![val1 isEqual:val2]) {
            return NO;
        }
        
    }
    free(propertys);
    return YES;
}

- (BOOL)isEqualToObject:(id)object forKeyPath:(NSString*)key
{
    return [self respondsToSelector:NSSelectorFromString(key)] && [object respondsToSelector:NSSelectorFromString(key)] && [[self valueForKey:key] isEqualToString:[object valueForKey:key]];
}

- (void)copyValuesTo:(id)object
{
    [self copyValuesTo:object ignoreEmpty:NO];
}

// copy the values of the same property between the two objects (recursive)
- (void)copyValuesTo:(id)object ignoreEmpty:(BOOL)ignore
{
    unsigned int count = 0;
    unsigned int count_obj = 0;
    
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    objc_property_t *properties_obj = class_copyPropertyList([object class], &count_obj);
    
    for (int i = 0; i < count; ++i) {
        
        NSString *name = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        id origin = [self valueForKey:name];
        
        for (int c = 0; c < count_obj; c++)
        {
            NSString *name_obj = [NSString stringWithCString:property_getName(properties_obj[c]) encoding:NSUTF8StringEncoding];
            if ([name_obj isEqualToString:name] && (!ignore || (ignore && origin != nil)))
            {
                NSString *propertyAttributes = [[NSString alloc] initWithUTF8String:property_getAttributes(properties_obj[c])];
                NSArray *propertyAttributeArray = [propertyAttributes componentsSeparatedByString:@","];
                
                BOOL isReadOnly = NO;
                for (NSString *string in propertyAttributeArray) {
                    isReadOnly = isReadOnly || [string isEqual:@"R"];
                }
                
                if (!isReadOnly && origin != nil)
                {
                    if ([propertyAttributes hasPrefix:@"T@\""] && ![propertyAttributes hasPrefix:@"T@\"NS"] && ![propertyAttributes hasPrefix:@"T@\"UI"] ) {
                        
                        id new_obj = [[[origin class] alloc] init];
                        
                        [origin copyValuesTo:new_obj ignoreEmpty:ignore];
                        [object setValue:new_obj forKey:name];
                    } else {
                        [object setValue:origin forKey:name];
                    }
                }
                
                
                break;
            }
        }
    }
    free(properties);
    free(properties_obj);
}

- (NSString *)debugDescription
{
    NSMutableString *propertyDescriptions = [NSMutableString string];
    for (NSString *key in [self describablePropertyNames])
    {
        id value = [self valueForKey:key];
        [propertyDescriptions appendFormat:@"\t%@ = %@\n", key, value];
    }
    return [NSString stringWithFormat:@"<%@: 0x%x>{\n%@}", [self class],
            (NSUInteger)self, propertyDescriptions];
}

- (NSArray *)describablePropertyNames
{
    // Loop through our superclasses until we hit NSObject
    NSMutableArray *array = [NSMutableArray array];
    Class subclass = [self class];
    while (subclass != [NSObject class])
    {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(subclass,&propertyCount);
        for (int i = 0; i < propertyCount; i++)
        {
            // Add property name to array
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            [array addObject:@(propertyName)];
        }
        free(properties);
        subclass = [subclass superclass];
    }
    
    return array;
}

@end
