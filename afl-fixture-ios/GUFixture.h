#import <Foundation/Foundation.h>


@interface GUFixture : NSObject
@property(nonatomic, strong) NSString *round;
@property(nonatomic, strong) NSString *team;
@property(nonatomic, strong) NSString *vs_team;
@property(nonatomic, strong) NSString *venue;
@property(nonatomic, strong) NSString *datetime;
@property (nonatomic, assign) BOOL upcoming;

- (id)init:(NSString *)round team:(NSString *)team vs_team:(NSString *)vs_team venue:(NSString *)venue datetime:(NSString *)datetime;

- (NSString *)descriptor;

- (NSComparisonResult)datetimeCompare:(GUFixture *)other;

+ (NSArray *)getDescriptors;

+ (NSArray *)getDescriptorsByFilter:(NSString *)filter;

+ (NSArray *)getFixtures;

+ (NSArray *)getTeams;

+ (NSArray *)getVenues;

+ (NSArray *)getTimeslots;@end