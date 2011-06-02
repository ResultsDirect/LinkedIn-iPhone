//
//  OAToken+storage.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 6/2/11.
//  Copyright 2011 Results Direct. All rights reserved.
//

#import <OAuthConsumer/OAToken.h>

#import "OAToken+storage.h"


@implementation OAToken (OAToken_RDLinkedIn_storage)

+ (NSString *)rd_defaultsKeyForKeyWithProviderName:(NSString *)provider prefix:(NSString *)prefix
{
  NSParameterAssert(provider);
  NSParameterAssert(prefix);
  
  return [NSString stringWithFormat:@"OAUTH_%@_%@_KEY", prefix, provider];
}

+ (NSString *)rd_defaultsKeyForSecretWithProviderName:(NSString *)provider prefix:(NSString *)prefix
{
  return [NSString stringWithFormat:@"OAUTH_%@_%@_SECRET", prefix, provider];
}

+ (OAToken *)rd_tokenWithUserDefaultsUsingServiceProviderName:(NSString *)provider prefix:(NSString *)prefix
{
  OAToken* token = nil;
  NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:[self rd_defaultsKeyForKeyWithProviderName:provider prefix:prefix]];
  NSString *secret = [[NSUserDefaults standardUserDefaults] stringForKey:[self rd_defaultsKeyForSecretWithProviderName:provider prefix:prefix]];
  
  if( [key length] > 0 && [secret length] > 0 ) {
    token = [[[OAToken alloc] initWithKey:key secret:secret] autorelease];
  }
  return token;
}

+ (void)rd_clearUserDefaultsUsingServiceProviderName:(NSString *)provider prefix:(NSString *)prefix
{
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:[[self class] rd_defaultsKeyForKeyWithProviderName:provider prefix:prefix]];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:[[self class] rd_defaultsKeyForSecretWithProviderName:provider prefix:prefix]];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)rd_storeInUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix
{
  [[NSUserDefaults standardUserDefaults] setObject:self.key forKey:[[self class] rd_defaultsKeyForKeyWithProviderName:provider prefix:prefix]];
  [[NSUserDefaults standardUserDefaults] setObject:self.secret forKey:[[self class] rd_defaultsKeyForSecretWithProviderName:provider prefix:prefix]];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
