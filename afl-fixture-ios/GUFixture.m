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
             [GUFixture newFixture:@[ @"1", @"Tigers", @"Blues", @"MCG", @"2016-03-24T19:20:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Demons", @"Giants", @"MCG", @"2016-03-26T13:40:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Suns", @"Bombers", @"Gold Coast", @"2016-03-26T16:35:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Swans", @"Magpies", @"SCG", @"2016-03-26T19:25:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Kangaroos", @"Crows", @"Docklands", @"2016-03-26T19:25:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Bulldogs", @"Dockers", @"Docklands", @"2016-03-27T13:10:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Power", @"Saints", @"Adelaide", @"2016-03-27T15:20:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Eagles", @"Lions", @"Perth", @"2016-03-27T19:40:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Cats", @"Hawks", @"MCG", @"2016-03-28T15:20:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Magpies", @"Tigers", @"MCG", @"2016-04-01T19:50:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Crows", @"Power", @"Adelaide", @"2016-04-02T13:45:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Bombers", @"Demons", @"MCG", @"2016-04-02T14:10:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Lions", @"Kangaroos", @"Brisbane", @"2016-04-02T16:35:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Saints", @"Bulldogs", @"Docklands", @"2016-04-02T19:25:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Dockers", @"Suns", @"Perth", @"2016-04-02T19:40:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Giants", @"Cats", @"Canberra", @"2016-04-03T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"2", @"Hawks", @"Eagles", @"MCG", @"2016-04-03T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"2", @"Blues", @"Swans", @"Docklands", @"2016-04-03T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Power", @"Bombers", @"Adelaide", @"2016-04-08T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Saints", @"Magpies", @"MCG", @"2016-04-09T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Tigers", @"Crows", @"Docklands", @"2016-04-09T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Swans", @"Giants", @"SCG", @"2016-04-09T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Suns", @"Blues", @"Gold Coast", @"2016-04-09T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Eagles", @"Dockers", @"Perth", @"2016-04-09T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Kangaroos", @"Demons", @"Hobart", @"2016-04-10T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Bulldogs", @"Hawks", @"Docklands", @"2016-04-10T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Cats", @"Lions", @"Geelong", @"2016-04-10T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Eagles", @"Tigers", @"Perth", @"2016-04-15T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Bombers", @"Cats", @"MCG", @"2016-04-16T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Hawks", @"Saints", @"Launceston", @"2016-04-16T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Lions", @"Suns", @"Brisbane", @"2016-04-16T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Blues", @"Bulldogs", @"Docklands", @"2016-04-16T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Crows", @"Swans", @"Adelaide", @"2016-04-16T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Giants", @"Power", @"Canberra", @"2016-04-17T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Magpies", @"Demons", @"MCG", @"2016-04-17T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Kangaroos", @"Dockers", @"Docklands", @"2016-04-17T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Hawks", @"Crows", @"MCG", @"2016-04-22T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Swans", @"Eagles", @"SCG", @"2016-04-23T13:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Suns", @"Kangaroos", @"Gold Coast", @"2016-04-23T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Bulldogs", @"Lions", @"Docklands", @"2016-04-23T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Power", @"Cats", @"Adelaide", @"2016-04-23T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Saints", @"Giants", @"Docklands", @"2016-04-24T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Dockers", @"Blues", @"Perth", @"2016-04-24T16:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Demons", @"Tigers", @"MCG", @"2016-04-24T19:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Magpies", @"Bombers", @"MCG", @"2016-04-25T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Kangaroos", @"Bulldogs", @"Docklands", @"2016-04-29T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Demons", @"Saints", @"Docklands", @"2016-04-30T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Crows", @"Dockers", @"Adelaide", @"2016-04-30T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Giants", @"Hawks", @"Sydney Showground", @"2016-04-30T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Tigers", @"Power", @"MCG", @"2016-04-30T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Cats", @"Suns", @"Geelong", @"2016-04-30T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Lions", @"Swans", @"Brisbane", @"2016-05-01T12:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Blues", @"Bombers", @"MCG", @"2016-05-01T14:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Eagles", @"Magpies", @"Perth", @"2016-05-01T15:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Tigers", @"Hawks", @"MCG", @"2016-05-06T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Magpies", @"Blues", @"MCG", @"2016-05-07T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Cats", @"Eagles", @"Geelong", @"2016-05-07T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Swans", @"Bombers", @"SCG", @"2016-05-07T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Suns", @"Demons", @"Gold Coast", @"2016-05-07T17:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Bulldogs", @"Crows", @"Docklands", @"2016-05-07T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Dockers", @"Giants", @"Perth", @"2016-05-07T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Saints", @"Kangaroos", @"Docklands", @"2016-05-08T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Power", @"Lions", @"Adelaide", @"2016-05-08T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Crows", @"Cats", @"Adelaide", @"2016-05-13T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Bombers", @"Kangaroos", @"Docklands", @"2016-05-14T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Hawks", @"Dockers", @"Launceston", @"2016-05-14T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Giants", @"Suns", @"Sydney Showground", @"2016-05-14T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Lions", @"Magpies", @"Brisbane", @"2016-05-14T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Tigers", @"Swans", @"MCG", @"2016-05-14T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Blues", @"Power", @"Docklands", @"2016-05-15T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Demons", @"Bulldogs", @"MCG", @"2016-05-15T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Eagles", @"Saints", @"Perth", @"2016-05-15T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Hawks", @"Swans", @"MCG", @"2016-05-20T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Magpies", @"Cats", @"MCG", @"2016-05-21T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Suns", @"Crows", @"Gold Coast", @"2016-05-21T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Power", @"Eagles", @"Adelaide", @"2016-05-21T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Kangaroos", @"Blues", @"Docklands", @"2016-05-21T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Dockers", @"Tigers", @"Perth", @"2016-05-21T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Demons", @"Lions", @"MCG", @"2016-05-22T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Giants", @"Bulldogs", @"Sydney Showground", @"2016-05-22T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Saints", @"Bombers", @"Docklands", @"2016-05-22T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Swans", @"Kangaroos", @"SCG", @"2016-05-27T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Lions", @"Hawks", @"Brisbane", @"2016-05-28T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Demons", @"Power", @"Alice Springs", @"2016-05-28T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Saints", @"Dockers", @"Docklands", @"2016-05-28T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Bombers", @"Tigers", @"MCG", @"2016-05-28T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Crows", @"Giants", @"Adelaide", @"2016-05-28T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Blues", @"Cats", @"Docklands", @"2016-05-29T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Magpies", @"Bulldogs", @"MCG", @"2016-05-29T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Eagles", @"Suns", @"Perth", @"2016-05-29T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Kangaroos", @"Tigers", @"Hobart", @"2016-06-03T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Hawks", @"Demons", @"MCG", @"2016-06-04T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Blues", @"Lions", @"Docklands", @"2016-06-04T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Cats", @"Giants", @"Geelong", @"2016-06-04T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Suns", @"Swans", @"Gold Coast", @"2016-06-04T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Dockers", @"Bombers", @"Perth", @"2016-06-04T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Magpies", @"Power", @"MCG", @"2016-06-05T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Bulldogs", @"Eagles", @"Docklands", @"2016-06-05T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Crows", @"Saints", @"Adelaide", @"2016-06-05T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Bombers", @"Hawks", @"Docklands", @"2016-06-10T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Power", @"Bulldogs", @"Adelaide", @"2016-06-11T13:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Lions", @"Dockers", @"Brisbane", @"2016-06-11T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Cats", @"Kangaroos", @"Docklands", @"2016-06-11T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Eagles", @"Crows", @"Perth", @"2016-06-11T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Saints", @"Blues", @"Docklands", @"2016-06-12T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Tigers", @"Suns", @"MCG", @"2016-06-12T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Giants", @"Swans", @"Sydney Showground", @"2016-06-12T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Demons", @"Magpies", @"MCG", @"2016-06-13T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Kangaroos", @"Hawks", @"Docklands", @"2016-06-17T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Lions", @"Eagles", @"Brisbane", @"2016-06-18T13:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Dockers", @"Power", @"Perth", @"2016-06-18T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Bulldogs", @"Cats", @"Docklands", @"2016-06-18T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Swans", @"Demons", @"SCG", @"2016-06-19T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Bombers", @"Giants", @"Docklands", @"2016-06-19T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Crows", @"Kangaroos", @"Adelaide", @"2016-06-23T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Magpies", @"Dockers", @"MCG", @"2016-06-24T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Tigers", @"Lions", @"MCG", @"2016-06-25T13:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Giants", @"Blues", @"Sydney Showground", @"2016-06-25T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Saints", @"Cats", @"Docklands", @"2016-06-25T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Hawks", @"Suns", @"Launceston", @"2016-06-26T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Eagles", @"Bombers", @"Perth", @"2016-06-30T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Power", @"Tigers", @"Adelaide", @"2016-07-01T18:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Suns", @"Saints", @"Gold Coast", @"2016-07-02T12:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Swans", @"Bulldogs", @"SCG", @"2016-07-02T15:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Blues", @"Magpies", @"MCG", @"2016-07-02T18:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Demons", @"Crows", @"MCG", @"2016-07-03T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Power", @"Hawks", @"Adelaide", @"2016-07-07T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Cats", @"Swans", @"Geelong", @"2016-07-08T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Giants", @"Magpies", @"Sydney Showground", @"2016-07-09T13:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Suns", @"Lions", @"Gold Coast", @"2016-07-09T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Bulldogs", @"Tigers", @"Docklands", @"2016-07-09T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Demons", @"Dockers", @"Darwin", @"2016-07-09T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Blues", @"Crows", @"MCG", @"2016-07-10T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Eagles", @"Kangaroos", @"Perth", @"2016-07-10T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Bombers", @"Saints", @"Docklands", @"2016-07-10T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Swans", @"Hawks", @"SCG", @"2016-07-14T19:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Dockers", @"Cats", @"Perth", @"2016-07-15T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Tigers", @"Bombers", @"MCG", @"2016-07-16T13:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Kangaroos", @"Power", @"Docklands", @"2016-07-16T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Bulldogs", @"Suns", @"Cairns", @"2016-07-16T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Crows", @"Magpies", @"Adelaide", @"2016-07-16T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Blues", @"Eagles", @"MCG", @"2016-07-17T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Saints", @"Demons", @"Docklands", @"2016-07-17T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Lions", @"Giants", @"Brisbane", @"2016-07-17T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Magpies", @"Kangaroos", @"Docklands", @"2016-07-22T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Swans", @"Blues", @"SCG", @"2016-07-23T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Suns", @"Dockers", @"Gold Coast", @"2016-07-23T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Eagles", @"Demons", @"Perth", @"2016-07-23T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Bulldogs", @"Saints", @"Docklands", @"2016-07-23T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Cats", @"Crows", @"Geelong", @"2016-07-23T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Bombers", @"Lions", @"Docklands", @"2016-07-24T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Hawks", @"Tigers", @"MCG", @"2016-07-24T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Power", @"Giants", @"Adelaide", @"2016-07-24T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Cats", @"Bulldogs", @"Geelong", @"2016-07-29T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Giants", @"Tigers", @"Canberra", @"2016-07-30T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Hawks", @"Blues", @"Launceston", @"2016-07-30T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Magpies", @"Eagles", @"MCG", @"2016-07-30T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Lions", @"Power", @"Brisbane", @"2016-07-30T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Kangaroos", @"Saints", @"Docklands", @"2016-07-30T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Demons", @"Suns", @"MCG", @"2016-07-31T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Dockers", @"Swans", @"Perth", @"2016-07-31T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Crows", @"Bombers", @"Adelaide", @"2016-07-31T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Tigers", @"Magpies", @"MCG", @"2016-08-05T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Swans", @"Power", @"SCG", @"2016-08-06T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Demons", @"Hawks", @"MCG", @"2016-08-06T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Suns", @"Giants", @"Gold Coast", @"2016-08-06T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Bulldogs", @"Kangaroos", @"Docklands", @"2016-08-06T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Crows", @"Lions", @"Adelaide", @"2016-08-06T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Blues", @"Saints", @"MCG", @"2016-08-07T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Cats", @"Bombers", @"Docklands", @"2016-08-07T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Dockers", @"Eagles", @"Perth", @"2016-08-07T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Bulldogs", @"Magpies", @"Docklands", @"2016-08-12T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Lions", @"Blues", @"Brisbane", @"2016-08-13T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Hawks", @"Kangaroos", @"MCG", @"2016-08-13T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Giants", @"Eagles", @"Sydney Showground", @"2016-08-13T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Saints", @"Swans", @"Docklands", @"2016-08-13T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Power", @"Demons", @"Adelaide", @"2016-08-13T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Bombers", @"Suns", @"Docklands", @"2016-08-14T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Tigers", @"Cats", @"MCG", @"2016-08-14T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Dockers", @"Crows", @"Perth", @"2016-08-14T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Eagles", @"Hawks", @"Perth", @"2016-08-19T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Kangaroos", @"Swans", @"Hobart", @"2016-08-20T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Tigers", @"Saints", @"MCG", @"2016-08-20T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Giants", @"Dockers", @"Sydney Showground", @"2016-08-20T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Magpies", @"Suns", @"Docklands", @"2016-08-20T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Power", @"Crows", @"Adelaide", @"2016-08-20T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Blues", @"Demons", @"MCG", @"2016-08-21T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Lions", @"Cats", @"Brisbane", @"2016-08-21T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Bombers", @"Bulldogs", @"Docklands", @"2016-08-21T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Hawks", @"Magpies", @"MCG", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Bombers", @"Blues", @"MCG", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Crows", @"Eagles", @"Adelaide", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Saints", @"Lions", @"Docklands", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Swans", @"Tigers", @"SCG", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Suns", @"Power", @"Gold Coast", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Cats", @"Demons", @"Geelong", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Kangaroos", @"Giants", @"Docklands", @"2016-08-27T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Dockers", @"Bulldogs", @"Perth", @"2016-08-27T14:10:00+10:00" ]],
             ];
}

@end
