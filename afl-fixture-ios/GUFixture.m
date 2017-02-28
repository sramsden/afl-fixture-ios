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
             [GUFixture newFixture:@[ @"1", @"Blues", @"Tigers", @"MCG", @"2017-03-23T19:20:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Magpies", @"Bulldogs", @"MCG", @"2017-03-24T19:50:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Saints", @"Demons", @"Docklands", @"2017-03-25T16:35:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Swans", @"Power", @"Sydney", @"2017-03-25T16:35:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Suns", @"Lions", @"Gold Coast", @"2017-03-25T19:25:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Bombers", @"Hawks", @"MCG", @"2017-03-25T19:25:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Kangaroos", @"Eagles", @"Docklands", @"2017-03-26T13:10:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Crows", @"Giants", @"Adelaide", @"2017-03-26T15:20:00+11:00" ]],
             [GUFixture newFixture:@[ @"1", @"Dockers", @"Cats", @"Perth", @"2017-03-26T19:40:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Tigers", @"Magpies", @"MCG", @"2017-03-30T19:20:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Bulldogs", @"Swans", @"Docklands", @"2017-03-31T19:50:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Hawks", @"Crows", @"MCG", @"2017-04-01T13:45:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Giants", @"Suns", @"Sydney Showgrounds", @"2017-04-01T16:35:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Lions", @"Bombers", @"Brisbane", @"2017-04-01T19:25:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Eagles", @"Saints", @"Perth", @"2017-04-01T19:40:00+11:00" ]],
             [GUFixture newFixture:@[ @"2", @"Cats", @"Kangaroos", @"Docklands", @"2017-04-02T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"2", @"Demons", @"Blues", @"MCG", @"2017-04-02T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"2", @"Power", @"Dockers", @"Adelaide", @"2017-04-02T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Swans", @"Magpies", @"Sydney", @"2017-04-07T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Kangaroos", @"Giants", @"Hobart", @"2017-04-08T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Tigers", @"Eagles", @"MCG", @"2017-04-08T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Cats", @"Demons", @"Docklands", @"2017-04-08T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Power", @"Crows", @"Adelaide", @"2017-04-08T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Dockers", @"Bulldogs", @"Perth", @"2017-04-08T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Saints", @"Lions", @"Docklands", @"2017-04-09T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Blues", @"Bombers", @"MCG", @"2017-04-09T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"3", @"Suns", @"Hawks", @"Gold Coast", @"2017-04-09T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Eagles", @"Swans", @"Perth", @"2017-04-13T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Kangaroos", @"Bulldogs", @"Docklands", @"2017-04-14T16:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Demons", @"Dockers", @"MCG", @"2017-04-15T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Giants", @"Power", @"Canberra", @"2017-04-15T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Blues", @"Suns", @"Docklands", @"2017-04-15T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Crows", @"Bombers", @"Adelaide", @"2017-04-15T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Magpies", @"Saints", @"Docklands", @"2017-04-16T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Lions", @"Tigers", @"Brisbane", @"2017-04-16T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"4", @"Hawks", @"Cats", @"MCG", @"2017-04-17T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Power", @"Blues", @"Adelaide", @"2017-04-21T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Bulldogs", @"Lions", @"Docklands", @"2017-04-22T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Suns", @"Crows", @"Gold Coast", @"2017-04-22T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Swans", @"Giants", @"Sydney", @"2017-04-22T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Dockers", @"Kangaroos", @"Perth", @"2017-04-22T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Saints", @"Cats", @"Docklands", @"2017-04-23T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Hawks", @"Eagles", @"MCG", @"2017-04-23T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Tigers", @"Demons", @"MCG", @"2017-04-24T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"5", @"Bombers", @"Magpies", @"MCG", @"2017-04-25T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Giants", @"Bulldogs", @"Canberra", @"2017-04-28T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Hawks", @"Saints", @"Launceston", @"2017-04-29T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Blues", @"Swans", @"MCG", @"2017-04-29T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Lions", @"Power", @"Brisbane", @"2017-04-29T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Kangaroos", @"Suns", @"Docklands", @"2017-04-29T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Eagles", @"Dockers", @"Perth", @"2017-04-29T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Bombers", @"Demons", @"Docklands", @"2017-04-30T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Cats", @"Magpies", @"MCG", @"2017-04-30T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"6", @"Crows", @"Tigers", @"Adelaide", @"2017-04-30T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Saints", @"Giants", @"Docklands", @"2017-05-05T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Kangaroos", @"Crows", @"Hobart", @"2017-05-06T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Magpies", @"Blues", @"MCG", @"2017-05-06T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Power", @"Eagles", @"Adelaide", @"2017-05-06T17:05:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Suns", @"Cats", @"Gold Coast", @"2017-05-06T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Bulldogs", @"Tigers", @"Docklands", @"2017-05-06T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Swans", @"Lions", @"Sydney", @"2017-05-07T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Demons", @"Hawks", @"MCG", @"2017-05-07T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"7", @"Dockers", @"Bombers", @"Perth", @"2017-05-07T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Eagles", @"Bulldogs", @"Perth", @"2017-05-12T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Hawks", @"Lions", @"Launceston", @"2017-05-13T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Saints", @"Blues", @"Docklands", @"2017-05-13T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Giants", @"Magpies", @"Sydney Showgrounds", @"2017-05-13T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Bombers", @"Cats", @"MCG", @"2017-05-13T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Crows", @"Demons", @"Adelaide", @"2017-05-13T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Tigers", @"Dockers", @"MCG", @"2017-05-14T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Kangaroos", @"Swans", @"Docklands", @"2017-05-14T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"8", @"Suns", @"Power", @"China", @"2017-05-14T17:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Cats", @"Bulldogs", @"Geelong", @"2017-05-19T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Saints", @"Swans", @"Docklands", @"2017-05-20T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Giants", @"Tigers", @"Sydney Showgrounds", @"2017-05-20T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Lions", @"Crows", @"Brisbane", @"2017-05-20T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Magpies", @"Hawks", @"MCG", @"2017-05-20T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Bombers", @"Eagles", @"Docklands", @"2017-05-21T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Demons", @"Kangaroos", @"MCG", @"2017-05-21T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"9", @"Dockers", @"Blues", @"Perth", @"2017-05-21T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Cats", @"Power", @"Geelong", @"2017-05-25T19:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Swans", @"Hawks", @"Sydney", @"2017-05-26T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Bulldogs", @"Saints", @"Docklands", @"2017-05-27T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Demons", @"Suns", @"Alice Springs", @"2017-05-27T17:05:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Tigers", @"Bombers", @"MCG", @"2017-05-27T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Crows", @"Dockers", @"Adelaide", @"2017-05-27T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Magpies", @"Lions", @"MCG", @"2017-05-28T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Blues", @"Kangaroos", @"Docklands", @"2017-05-28T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"10", @"Eagles", @"Giants", @"Perth", @"2017-05-28T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Power", @"Hawks", @"Adelaide", @"2017-06-01T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Cats", @"Crows", @"Geelong", @"2017-06-02T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Suns", @"Eagles", @"Gold Coast", @"2017-06-03T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Giants", @"Bombers", @"Sydney Showgrounds", @"2017-06-03T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Kangaroos", @"Tigers", @"Docklands", @"2017-06-03T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"11", @"Dockers", @"Magpies", @"Perth", @"2017-06-04T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Swans", @"Bulldogs", @"Sydney", @"2017-06-08T19:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Crows", @"Saints", @"Adelaide", @"2017-06-09T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Hawks", @"Suns", @"MCG", @"2017-06-10T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Lions", @"Dockers", @"Brisbane", @"2017-06-10T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Bombers", @"Power", @"Docklands", @"2017-06-10T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Blues", @"Giants", @"Docklands", @"2017-06-11T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"12", @"Demons", @"Magpies", @"MCG", @"2017-06-12T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Eagles", @"Cats", @"Perth", @"2017-06-15T20:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Kangaroos", @"Saints", @"Docklands", @"2017-06-16T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Tigers", @"Swans", @"MCG", @"2017-06-17T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Power", @"Lions", @"Adelaide", @"2017-06-17T17:05:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Suns", @"Blues", @"Gold Coast", @"2017-06-17T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"13", @"Bulldogs", @"Demons", @"Docklands", @"2017-06-18T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Crows", @"Hawks", @"Adelaide", @"2017-06-22T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Swans", @"Bombers", @"Sydney", @"2017-06-23T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Magpies", @"Power", @"MCG", @"2017-06-24T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Lions", @"Giants", @"Brisbane", @"2017-06-24T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Bulldogs", @"Kangaroos", @"Docklands", @"2017-06-24T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Eagles", @"Demons", @"Perth", @"2017-06-24T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Cats", @"Dockers", @"Geelong", @"2017-06-25T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Tigers", @"Blues", @"MCG", @"2017-06-25T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"14", @"Saints", @"Suns", @"Docklands", @"2017-06-25T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Demons", @"Swans", @"MCG", @"2017-06-30T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Bulldogs", @"Eagles", @"Docklands", @"2017-07-01T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Blues", @"Crows", @"MCG", @"2017-07-01T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Suns", @"Kangaroos", @"Gold Coast", @"2017-07-01T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Giants", @"Cats", @"Sydney Showgrounds", @"2017-07-01T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Power", @"Tigers", @"Adelaide", @"2017-07-01T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Bombers", @"Lions", @"Docklands", @"2017-07-02T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Hawks", @"Magpies", @"MCG", @"2017-07-02T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"15", @"Dockers", @"Saints", @"Perth", @"2017-07-02T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Crows", @"Bulldogs", @"Adelaide", @"2017-07-07T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Hawks", @"Giants", @"Launceston", @"2017-07-08T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Magpies", @"Bombers", @"MCG", @"2017-07-08T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Swans", @"Suns", @"Sydney", @"2017-07-08T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Lions", @"Cats", @"Brisbane", @"2017-07-08T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Saints", @"Tigers", @"Docklands", @"2017-07-08T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Kangaroos", @"Dockers", @"Docklands", @"2017-07-09T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Blues", @"Demons", @"MCG", @"2017-07-09T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"16", @"Eagles", @"Power", @"Perth", @"2017-07-09T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Saints", @"Bombers", @"Docklands", @"2017-07-14T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Cats", @"Hawks", @"MCG", @"2017-07-15T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Power", @"Kangaroos", @"Adelaide", @"2017-07-15T14:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Suns", @"Magpies", @"Gold Coast", @"2017-07-15T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Giants", @"Swans", @"Sydney Showgrounds", @"2017-07-15T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Demons", @"Crows", @"Darwin", @"2017-07-15T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Tigers", @"Lions", @"Docklands", @"2017-07-16T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Blues", @"Bulldogs", @"MCG", @"2017-07-16T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"17", @"Dockers", @"Eagles", @"Perth", @"2017-07-16T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Crows", @"Cats", @"Adelaide", @"2017-07-21T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Bombers", @"Kangaroos", @"Docklands", @"2017-07-22T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Demons", @"Power", @"MCG", @"2017-07-22T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Bulldogs", @"Suns", @"Cairns", @"2017-07-22T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Swans", @"Saints", @"Sydney", @"2017-07-22T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Dockers", @"Hawks", @"Perth", @"2017-07-22T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Tigers", @"Giants", @"MCG", @"2017-07-23T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Magpies", @"Eagles", @"Docklands", @"2017-07-23T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"18", @"Lions", @"Blues", @"Brisbane", @"2017-07-23T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Hawks", @"Swans", @"MCG", @"2017-07-28T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Kangaroos", @"Demons", @"Hobart", @"2017-07-29T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Giants", @"Dockers", @"Sydney Showgrounds", @"2017-07-29T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Power", @"Saints", @"Adelaide", @"2017-07-29T17:05:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Suns", @"Tigers", @"Gold Coast", @"2017-07-29T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Blues", @"Cats", @"Docklands", @"2017-07-29T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Bulldogs", @"Bombers", @"Docklands", @"2017-07-30T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Magpies", @"Crows", @"MCG", @"2017-07-30T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"19", @"Eagles", @"Lions", @"Perth", @"2017-07-30T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Cats", @"Swans", @"Geelong", @"2017-08-04T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Giants", @"Demons", @"Canberra", @"2017-08-05T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Bombers", @"Blues", @"MCG", @"2017-08-05T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Lions", @"Bulldogs", @"Brisbane", @"2017-08-05T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Kangaroos", @"Magpies", @"Docklands", @"2017-08-05T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Dockers", @"Suns", @"Perth", @"2017-08-05T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Saints", @"Eagles", @"Docklands", @"2017-08-06T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Tigers", @"Hawks", @"MCG", @"2017-08-06T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"20", @"Crows", @"Power", @"Adelaide", @"2017-08-06T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Bulldogs", @"Giants", @"Docklands", @"2017-08-11T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Swans", @"Dockers", @"Sydney", @"2017-08-12T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Cats", @"Tigers", @"Geelong", @"2017-08-12T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Lions", @"Suns", @"Brisbane", @"2017-08-12T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Bombers", @"Crows", @"Docklands", @"2017-08-12T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Eagles", @"Blues", @"Perth", @"2017-08-12T19:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Demons", @"Saints", @"MCG", @"2017-08-13T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Hawks", @"Kangaroos", @"Launceston", @"2017-08-13T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"21", @"Power", @"Magpies", @"Adelaide", @"2017-08-13T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Crows", @"Swans", @"Adelaide", @"2017-08-18T19:50:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Bulldogs", @"Power", @"Ballarat", @"2017-08-19T13:45:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Magpies", @"Cats", @"MCG", @"2017-08-19T14:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Giants", @"Eagles", @"Sydney Showgrounds", @"2017-08-19T16:35:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Suns", @"Bombers", @"Gold Coast", @"2017-08-19T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Blues", @"Hawks", @"Docklands", @"2017-08-19T19:25:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Demons", @"Lions", @"MCG", @"2017-08-20T13:10:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Saints", @"Kangaroos", @"Docklands", @"2017-08-20T15:20:00+10:00" ]],
             [GUFixture newFixture:@[ @"22", @"Dockers", @"Tigers", @"Perth", @"2017-08-20T16:40:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Hawks", @"Bulldogs", @"Docklands", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Magpies", @"Demons", @"MCG", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Swans", @"Blues", @"Sydney", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Lions", @"Kangaroos", @"Brisbane", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Bombers", @"Dockers", @"Docklands", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Tigers", @"Saints", @"MCG", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Cats", @"Giants", @"Geelong", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Power", @"Suns", @"Adelaide", @"2017-08-26T12:00:00+10:00" ]],
             [GUFixture newFixture:@[ @"23", @"Eagles", @"Crows", @"Perth", @"2017-08-26T12:00:00+10:00" ]],
             ];
}

@end
