#import "GUFixture.h"


@implementation GUFixture {

}

- (id)init:(NSString *)round team:(NSString *)team vs_team:(NSString *)vs_team venue:(NSString *)venue datetime:(NSString *)datetime {
    [self setRound:round];
    [self setTeam:team];
    [self setVs_team:vs_team];
    [self setVenue:venue];
    [self setDatetime:datetime];

    return self;
}

- (NSString *)descriptor {
    NSArray *formattedDatetime = [GUFixture parseAndReformatDatetime:_datetime];
    id time = formattedDatetime[1];
    id date = formattedDatetime[0];
    // set the upcoming flag as it was determined by the parseAndReformatDatetime method..
    [self setUpcoming:[formattedDatetime[2] boolValue]];
    return [NSString stringWithFormat:@"%@ vs %@ %@\n%@ @ %@", _team, _vs_team, time, date, _venue];
}

- (NSComparisonResult)datetimeCompare:(GUFixture *)other {
    NSComparisonResult result = [_datetime localizedCaseInsensitiveCompare:other.datetime];
    return result;
}

+ (NSArray *)parseAndReformatDatetime:(NSString *)datetimeString {
    NSDateFormatter *dateParser = [[NSDateFormatter alloc] init];
    // expect datetime format eg, "1971-08-19T09:40:00+00:00"
    //                             2011-04-05T16:28:22-0700
    [dateParser setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [dateParser setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *date = [dateParser dateFromString:datetimeString];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"eeee MMM dd"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"h:mm a"];
    [timeFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *formattedTime = [timeFormatter stringFromDate:date];
    NSDate *now = [NSDate date];
    // maintain flag to specify isUpcoming but has to be a number to be able to send it back in the array..
    NSNumber *isUpcoming = [NSNumber numberWithBool:[now compare:date] == NSOrderedAscending];
    return @[formattedDate, formattedTime, isUpcoming];
}

+ (GUFixture *)newFixture:(NSArray *)properties {
    return [[GUFixture alloc] init:properties[0] team:properties[1] vs_team:properties[2] venue:properties[3] datetime:properties[4]];
}

+ (NSArray *)getDescriptors {
    return [self getDescriptorsUnderHeadings:[self getFixtures]];
}

+ (NSArray *)getDescriptorsUnderHeadings:(NSArray *)fixturesArray {
    NSMutableArray *fixtures = [fixturesArray mutableCopy];
    NSMutableArray *descriptors = [[NSMutableArray alloc] init];
    NSString *round = nil;
    int i = 0;
    for (GUFixture *fixture in fixtures) {
        if (![fixture.round isEqualToString:round]) {
            round = fixture.round;
            NSString *label = [NSString stringWithFormat:@"ROUND %@", round];
            [descriptors addObject:label];
        }
        [descriptors addObject:fixture.descriptor];
        if (!fixture.upcoming) {
            i = descriptors.count - 1; // default to last descriptor when nothing upcoming
        }
    }
    return @[descriptors, [NSNumber numberWithInt:i]];
}

+ (NSArray *)getDescriptorsByFilter:(NSString *)filter {
    // keep descriptors matching filters but also the round labels..
    NSString *predicateFormat = [NSString stringWithFormat:@"(SELF contains[c] '%@') OR (SELF contains[c] 'ROUND ')", filter];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
    NSMutableArray *descriptors = [self getDescriptorsUnderHeadings:[self getFixtures]][0]; // note index because we want just descriptors, ignoring the 'next' integer returned
    [descriptors filterUsingPredicate:predicate];
    return descriptors;
}

+ (NSArray *)getFixtures {
    static dispatch_once_t once;
    static NSArray *fixtures;
    dispatch_once(&once, ^{
        fixtures = [self buildFixtures];
    });
    fixtures = [fixtures sortedArrayUsingSelector:@selector(datetimeCompare:)];
    return fixtures;
}

+ (NSArray *)getTeams {
    NSArray *fixtures = [self getFixtures];
    NSMutableArray *teams = [[NSMutableArray alloc] init];
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (id fixture in fixtures) {
        NSString *team = [fixture team];
        NSString *vs_team = [fixture vs_team];
        if (![map valueForKey:team]) {
            [teams addObject:team];
            [map setObject:team forKey:team];
        }
        if (![map valueForKey:vs_team]) {
            [teams addObject:vs_team];
            [map setObject:vs_team forKey:vs_team];
        }
    }
    return [teams sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray *)getVenues {
    NSArray *fixtures = [self getFixtures];
    NSMutableArray *venues = [[NSMutableArray alloc] init];
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (id fixture in fixtures) {
        NSString *venue = [fixture venue];
        if (![map valueForKey:venue]) {
            [venues addObject:venue];
            [map setObject:venue forKey:venue];
        }
    }
    return [venues sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray *)getTimeslots {
    NSArray *fixtures = [self getFixtures];
    NSMutableArray *timeslots = [[NSMutableArray alloc] init];
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (id fixture in fixtures) {
        NSString *datetime = [fixture datetime];
        NSString *timeslot = [self parseAndReformatDatetime:datetime][1];
        if (![map valueForKey:timeslot]) {
            [timeslots addObject:timeslot];
            [map setObject:timeslot forKey:timeslot];
        }
    }
    return [timeslots sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray *)buildFixtures {
    return @[
            [GUFixture newFixture:@[@"1", @"Blues", @"Tigers", @"MCG", @"2015-04-02T19:20:00+11:00"]],
            [GUFixture newFixture:@[@"1", @"Demons", @"Suns", @"MCG", @"2015-04-04T13:40:00+11:00"]],
            [GUFixture newFixture:@[@"1", @"Swans", @"Bombers", @"Sydney Olympic", @"2015-04-04T16:35:00+11:00"]],
            [GUFixture newFixture:@[@"1", @"Lions", @"Magpies", @"Brisbane", @"2015-04-04T18:20:00+11:00"]],
            [GUFixture newFixture:@[@"1", @"Bulldogs", @"Eagles", @"Docklands", @"2015-04-04T19:20:00+11:00"]],
            [GUFixture newFixture:@[@"1", @"Saints", @"Giants", @"Docklands", @"2015-04-05T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"1", @"Crows", @"Kangaroos", @"Adelaide", @"2015-04-05T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"1", @"Dockers", @"Power", @"Perth", @"2015-04-05T18:40:00+10:00"]],
            [GUFixture newFixture:@[@"1", @"Hawks", @"Cats", @"MCG", @"2015-04-06T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Eagles", @"Blues", @"Perth", @"2015-04-10T20:10:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Tigers", @"Bulldogs", @"MCG", @"2015-04-11T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Giants", @"Demons", @"Canberra", @"2015-04-11T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Magpies", @"Crows", @"Docklands", @"2015-04-11T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Suns", @"Saints", @"Gold Coast", @"2015-04-11T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Power", @"Swans", @"Adelaide", @"2015-04-11T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Cats", @"Dockers", @"Geelong", @"2015-04-12T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Bombers", @"Hawks", @"MCG", @"2015-04-12T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"2", @"Kangaroos", @"Lions", @"Docklands", @"2015-04-12T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Magpies", @"Saints", @"MCG", @"2015-04-17T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Blues", @"Bombers", @"MCG", @"2015-04-18T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Crows", @"Demons", @"Adelaide", @"2015-04-18T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Swans", @"Giants", @"SCG", @"2015-04-18T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Kangaroos", @"Power", @"Docklands", @"2015-04-18T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Lions", @"Tigers", @"Brisbane", @"2015-04-18T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Hawks", @"Bulldogs", @"Launceston", @"2015-04-19T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Cats", @"Suns", @"Geelong", @"2015-04-19T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"3", @"Eagles", @"Dockers", @"Perth", @"2015-04-19T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Tigers", @"Demons", @"MCG", @"2015-04-24T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Saints", @"Blues", @"New Zealand", @"2015-04-25T11:10:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Bombers", @"Magpies", @"MCG", @"2015-04-25T14:40:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Giants", @"Suns", @"Canberra", @"2015-04-25T17:40:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Power", @"Hawks", @"Adelaide", @"2015-04-25T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Dockers", @"Swans", @"Perth", @"2015-04-25T20:40:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Lions", @"Eagles", @"Brisbane", @"2015-04-26T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Cats", @"Kangaroos", @"Geelong", @"2015-04-26T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"4", @"Bulldogs", @"Crows", @"Docklands", @"2015-04-26T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Blues", @"Magpies", @"MCG", @"2015-05-01T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Tigers", @"Cats", @"MCG", @"2015-05-02T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Swans", @"Bulldogs", @"SCG", @"2015-05-02T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Suns", @"Lions", @"Gold Coast", @"2015-05-02T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Kangaroos", @"Hawks", @"Docklands", @"2015-05-02T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Eagles", @"Giants", @"Perth", @"2015-05-02T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Demons", @"Dockers", @"MCG", @"2015-05-03T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Saints", @"Bombers", @"Docklands", @"2015-05-03T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"5", @"Crows", @"Power", @"Adelaide", @"2015-05-03T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Magpies", @"Cats", @"MCG", @"2015-05-08T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Kangaroos", @"Tigers", @"Hobart", @"2015-05-09T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Bulldogs", @"Saints", @"Docklands", @"2015-05-09T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Giants", @"Hawks", @"Sydney Showground", @"2015-05-09T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Suns", @"Crows", @"Gold Coast", @"2015-05-09T17:10:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Demons", @"Swans", @"MCG", @"2015-05-09T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Dockers", @"Bombers", @"Perth", @"2015-05-09T20:10:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Blues", @"Lions", @"Docklands", @"2015-05-10T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"6", @"Power", @"Eagles", @"Adelaide", @"2015-05-10T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Bombers", @"Kangaroos", @"Docklands", @"2015-05-15T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Crows", @"Saints", @"Adelaide", @"2015-05-16T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Hawks", @"Demons", @"MCG", @"2015-05-16T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Blues", @"Giants", @"Docklands", @"2015-05-16T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Swans", @"Cats", @"Sydney Olympic", @"2015-05-16T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Eagles", @"Suns", @"Perth", @"2015-05-16T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Bulldogs", @"Dockers", @"Docklands", @"2015-05-17T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Tigers", @"Magpies", @"MCG", @"2015-05-17T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"7", @"Lions", @"Power", @"Brisbane", @"2015-05-17T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Cats", @"Blues", @"Docklands", @"2015-05-22T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Saints", @"Eagles", @"Docklands", @"2015-05-23T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Giants", @"Crows", @"Sydney Showground", @"2015-05-23T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Suns", @"Magpies", @"Gold Coast", @"2015-05-23T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Hawks", @"Swans", @"MCG", @"2015-05-23T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Dockers", @"Kangaroos", @"Perth", @"2015-05-23T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Bombers", @"Lions", @"Docklands", @"2015-05-24T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Demons", @"Bulldogs", @"MCG", @"2015-05-24T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"8", @"Power", @"Tigers", @"Adelaide", @"2015-05-24T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Swans", @"Blues", @"SCG", @"2015-05-29T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Hawks", @"Suns", @"Launceston", @"2015-05-30T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Demons", @"Power", @"Alice Springs", @"2015-05-30T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Bulldogs", @"Giants", @"Docklands", @"2015-05-30T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Tigers", @"Bombers", @"MCG", @"2015-05-30T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Crows", @"Dockers", @"Adelaide", @"2015-05-30T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Lions", @"Saints", @"Brisbane", @"2015-05-31T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Magpies", @"Kangaroos", @"MCG", @"2015-05-31T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"9", @"Eagles", @"Cats", @"Perth", @"2015-05-31T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Dockers", @"Tigers", @"Perth", @"2015-06-05T20:10:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Blues", @"Crows", @"MCG", @"2015-06-06T13:40:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Suns", @"Swans", @"Gold Coast", @"2015-06-06T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Bombers", @"Cats", @"Docklands", @"2015-06-06T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Power", @"Bulldogs", @"Adelaide", @"2015-06-06T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Giants", @"Lions", @"Sydney Showground", @"2015-06-07T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Kangaroos", @"Eagles", @"Hobart", @"2015-06-07T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Saints", @"Hawks", @"Docklands", @"2015-06-07T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"10", @"Demons", @"Magpies", @"MCG", @"2015-06-08T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"11", @"Power", @"Cats", @"Adelaide", @"2015-06-12T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"11", @"Suns", @"Dockers", @"Gold Coast", @"2015-06-13T13:40:00+10:00"]],
            [GUFixture newFixture:@[@"11", @"Eagles", @"Bombers", @"Perth", @"2015-06-13T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"11", @"Kangaroos", @"Swans", @"Docklands", @"2015-06-13T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"11", @"Magpies", @"Giants", @"MCG", @"2015-06-14T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"11", @"Saints", @"Demons", @"Docklands", @"2015-06-14T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"12", @"Crows", @"Hawks", @"Adelaide", @"2015-06-18T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"12", @"Tigers", @"Eagles", @"MCG", @"2015-06-19T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"12", @"Blues", @"Power", @"MCG", @"2015-06-20T13:40:00+10:00"]],
            [GUFixture newFixture:@[@"12", @"Giants", @"Kangaroos", @"Sydney Showground", @"2015-06-20T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"12", @"Bulldogs", @"Lions", @"Docklands", @"2015-06-20T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"12", @"Cats", @"Demons", @"Geelong", @"2015-06-21T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"13", @"Dockers", @"Magpies", @"Perth", @"2015-06-25T20:10:00+10:00"]],
            [GUFixture newFixture:@[@"13", @"Swans", @"Tigers", @"SCG", @"2015-06-26T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"13", @"Hawks", @"Bombers", @"MCG", @"2015-06-27T13:40:00+10:00"]],
            [GUFixture newFixture:@[@"13", @"Lions", @"Crows", @"Brisbane", @"2015-06-27T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"13", @"Saints", @"Bulldogs", @"Docklands", @"2015-06-27T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"13", @"Blues", @"Suns", @"Docklands", @"2015-06-28T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Swans", @"Power", @"SCG", @"2015-07-02T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Magpies", @"Hawks", @"MCG", @"2015-07-03T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Tigers", @"Giants", @"MCG", @"2015-07-04T13:40:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Suns", @"Kangaroos", @"Gold Coast", @"2015-07-04T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Bulldogs", @"Blues", @"Docklands", @"2015-07-04T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Demons", @"Eagles", @"Darwin", @"2015-07-04T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Bombers", @"Saints", @"Docklands", @"2015-07-05T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Crows", @"Cats", @"Adelaide", @"2015-07-05T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"14", @"Dockers", @"Lions", @"Perth", @"2015-07-05T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Power", @"Magpies", @"Adelaide", @"2015-07-09T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Tigers", @"Blues", @"MCG", @"2015-07-10T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Bombers", @"Demons", @"MCG", @"2015-07-11T13:40:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Bulldogs", @"Suns", @"Cairns", @"2015-07-11T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Kangaroos", @"Cats", @"Docklands", @"2015-07-11T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Eagles", @"Crows", @"Perth", @"2015-07-11T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Giants", @"Saints", @"Sydney Showground", @"2015-07-12T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Hawks", @"Dockers", @"Launceston", @"2015-07-12T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"15", @"Lions", @"Swans", @"Brisbane", @"2015-07-12T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Kangaroos", @"Bombers", @"Docklands", @"2015-07-17T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Cats", @"Bulldogs", @"Geelong", @"2015-07-18T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Suns", @"Giants", @"Gold Coast", @"2015-07-18T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Magpies", @"Eagles", @"Docklands", @"2015-07-18T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Swans", @"Hawks", @"Sydney Olympic", @"2015-07-18T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Dockers", @"Blues", @"Perth", @"2015-07-18T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Demons", @"Lions", @"MCG", @"2015-07-19T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Power", @"Crows", @"Adelaide", @"2015-07-19T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"16", @"Saints", @"Tigers", @"Docklands", @"2015-07-19T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Blues", @"Hawks", @"Docklands", @"2015-07-24T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Giants", @"Cats", @"Canberra", @"2015-07-25T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Crows", @"Suns", @"Adelaide", @"2015-07-25T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Tigers", @"Dockers", @"MCG", @"2015-07-25T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Bombers", @"Power", @"Docklands", @"2015-07-25T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Lions", @"Kangaroos", @"Brisbane", @"2015-07-25T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Bulldogs", @"Magpies", @"Docklands", @"2015-07-26T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Demons", @"Saints", @"MCG", @"2015-07-26T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"17", @"Eagles", @"Swans", @"Perth", @"2015-07-26T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Hawks", @"Tigers", @"MCG", @"2015-07-31T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Cats", @"Lions", @"Geelong", @"2015-08-01T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Magpies", @"Demons", @"MCG", @"2015-08-01T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Swans", @"Crows", @"SCG", @"2015-08-01T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Blues", @"Kangaroos", @"Docklands", @"2015-08-01T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Suns", @"Eagles", @"Gold Coast", @"2015-08-01T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Power", @"Saints", @"Adelaide", @"2015-08-02T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Bombers", @"Bulldogs", @"Docklands", @"2015-08-02T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"18", @"Dockers", @"Giants", @"Perth", @"2015-08-02T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Crows", @"Tigers", @"Adelaide", @"2015-08-07T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Magpies", @"Blues", @"MCG", @"2015-08-08T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Bulldogs", @"Power", @"Docklands", @"2015-08-08T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Lions", @"Suns", @"Brisbane", @"2015-08-08T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Cats", @"Swans", @"Geelong", @"2015-08-08T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Eagles", @"Hawks", @"Perth", @"2015-08-08T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Demons", @"Kangaroos", @"MCG", @"2015-08-09T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Giants", @"Bombers", @"Sydney Showground", @"2015-08-09T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"19", @"Saints", @"Dockers", @"Docklands", @"2015-08-09T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Swans", @"Magpies", @"SCG", @"2015-08-14T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Bombers", @"Crows", @"Docklands", @"2015-08-15T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Kangaroos", @"Saints", @"Hobart", @"2015-08-15T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Power", @"Giants", @"Adelaide", @"2015-08-15T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Cats", @"Hawks", @"MCG", @"2015-08-15T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Lions", @"Blues", @"Brisbane", @"2015-08-15T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Tigers", @"Suns", @"MCG", @"2015-08-16T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Bulldogs", @"Demons", @"Docklands", @"2015-08-16T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"20", @"Dockers", @"Eagles", @"Perth", @"2015-08-16T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Hawks", @"Power", @"Docklands", @"2015-08-21T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Magpies", @"Tigers", @"MCG", @"2015-08-22T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Giants", @"Swans", @"Sydney Showground", @"2015-08-22T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Suns", @"Bombers", @"Gold Coast", @"2015-08-22T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Saints", @"Cats", @"Docklands", @"2015-08-22T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Crows", @"Lions", @"Adelaide", @"2015-08-22T19:40:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Kangaroos", @"Dockers", @"Docklands", @"2015-08-23T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Blues", @"Demons", @"MCG", @"2015-08-23T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"21", @"Eagles", @"Bulldogs", @"Perth", @"2015-08-23T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Cats", @"Magpies", @"MCG", @"2015-08-28T19:50:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Giants", @"Blues", @"Sydney Showground", @"2015-08-29T13:45:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Hawks", @"Lions", @"Launceston", @"2015-08-29T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Kangaroos", @"Bulldogs", @"Docklands", @"2015-08-29T16:35:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Bombers", @"Tigers", @"MCG", @"2015-08-29T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Suns", @"Power", @"Gold Coast", @"2015-08-29T19:20:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Crows", @"Eagles", @"Adelaide", @"2015-08-30T13:10:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Saints", @"Swans", @"Docklands", @"2015-08-30T15:20:00+10:00"]],
            [GUFixture newFixture:@[@"22", @"Dockers", @"Demons", @"Perth", @"2015-08-30T16:40:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Magpies", @"Bombers", @"MCG", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Tigers", @"Kangaroos", @"Docklands", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Hawks", @"Blues", @"MCG", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Cats", @"Crows", @"Geelong", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Swans", @"Suns", @"SCG", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Demons", @"Giants", @"Docklands", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Lions", @"Bulldogs", @"Brisbane", @"2015-09-05T14:10:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Power", @"Dockers", @"Adelaide", @"2015-09-05T14:40:00+10:00"]],
            [GUFixture newFixture:@[@"23", @"Eagles", @"Saints", @"Perth", @"2015-09-05T16:10:00+10:00"]],
    ];
}

@end
