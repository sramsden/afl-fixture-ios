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
    [GUFixture newFixture:@[ @"1", @"Tigers", @"Blues", @"MCG", @"2020-03-19T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Bulldogs", @"Magpies", @"Docklands", @"2020-03-20T19:50:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Bombers", @"Dockers", @"Docklands", @"2020-03-21T13:45:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Crows", @"Swans", @"Adelaide", @"2020-03-21T16:35:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Suns", @"Power", @"Gold Coast", @"2020-03-21T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Giants", @"Cats", @"Sydney Showground", @"2020-03-21T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Kangaroos", @"Saints", @"Docklands", @"2020-03-22T13:10:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Hawks", @"Lions", @"MCG", @"2020-03-22T15:20:00+11:00" ]],
    [GUFixture newFixture:@[ @"1", @"Eagles", @"Demons", @"Perth", @"2020-03-22T18:20:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Magpies", @"Tigers", @"MCG", @"2020-03-26T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Swans", @"Bombers", @"Sydney", @"2020-03-27T19:50:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Demons", @"Giants", @"MCG", @"2020-03-28T13:45:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Blues", @"Bulldogs", @"Docklands", @"2020-03-28T16:35:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Lions", @"Kangaroos", @"Brisbane", @"2020-03-28T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Power", @"Crows", @"Adelaide", @"2020-03-28T19:40:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Cats", @"Suns", @"Geelong", @"2020-03-29T13:10:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Saints", @"Eagles", @"Docklands", @"2020-03-29T15:20:00+11:00" ]],
    [GUFixture newFixture:@[ @"2", @"Dockers", @"Hawks", @"Perth", @"2020-03-29T18:20:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Blues", @"Bombers", @"MCG", @"2020-04-02T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Giants", @"Bulldogs", @"Canberra", @"2020-04-03T19:50:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Hawks", @"Magpies", @"MCG", @"2020-04-04T13:45:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Crows", @"Lions", @"Adelaide", @"2020-04-04T16:35:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Eagles", @"Cats", @"Perth", @"2020-04-04T19:10:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Kangaroos", @"Power", @"Docklands", @"2020-04-04T19:25:00+11:00" ]],
    [GUFixture newFixture:@[ @"3", @"Demons", @"Dockers", @"MCG", @"2020-04-05T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"3", @"Saints", @"Tigers", @"Docklands", @"2020-04-05T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"3", @"Suns", @"Swans", @"Gold Coast", @"2020-04-05T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Lions", @"Magpies", @"Brisbane", @"2020-04-09T19:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Kangaroos", @"Bulldogs", @"Docklands", @"2020-04-10T16:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Power", @"Eagles", @"Adelaide", @"2020-04-10T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Tigers", @"Crows", @"MCG", @"2020-04-11T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Dockers", @"Suns", @"Perth", @"2020-04-11T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Bombers", @"Giants", @"Docklands", @"2020-04-11T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Swans", @"Blues", @"Sydney", @"2020-04-12T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Saints", @"Demons", @"Docklands", @"2020-04-12T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"4", @"Cats", @"Hawks", @"MCG", @"2020-04-13T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Crows", @"Bombers", @"Adelaide", @"2020-04-16T19:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Eagles", @"Tigers", @"Perth", @"2020-04-17T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Suns", @"Demons", @"Gold Coast", @"2020-04-18T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Magpies", @"Power", @"MCG", @"2020-04-18T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Swans", @"Giants", @"Sydney", @"2020-04-18T19:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Bulldogs", @"Lions", @"Docklands", @"2020-04-18T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Kangaroos", @"Dockers", @"Hobart", @"2020-04-19T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Hawks", @"Blues", @"Docklands", @"2020-04-19T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"5", @"Cats", @"Saints", @"Geelong", @"2020-04-19T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Demons", @"Tigers", @"MCG", @"2020-04-24T19:55:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Hawks", @"Eagles", @"Launceston", @"2020-04-25T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Magpies", @"Bombers", @"MCG", @"2020-04-25T16:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Lions", @"Swans", @"Brisbane", @"2020-04-25T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Power", @"Bulldogs", @"Adelaide", @"2020-04-25T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Giants", @"Suns", @"Canberra", @"2020-04-26T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Blues", @"Kangaroos", @"MCG", @"2020-04-26T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Saints", @"Crows", @"Docklands", @"2020-04-26T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"6", @"Dockers", @"Cats", @"Perth", @"2020-04-26T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Magpies", @"Saints", @"Docklands", @"2020-05-01T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Tigers", @"Giants", @"MCG", @"2020-05-02T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Suns", @"Crows", @"Gold Coast", @"2020-05-02T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Power", @"Blues", @"Adelaide", @"2020-05-02T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Bulldogs", @"Hawks", @"Docklands", @"2020-05-02T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Cats", @"Lions", @"Geelong", @"2020-05-02T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Swans", @"Kangaroos", @"Sydney", @"2020-05-03T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Bombers", @"Demons", @"MCG", @"2020-05-03T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"7", @"Eagles", @"Dockers", @"Perth", @"2020-05-03T17:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Lions", @"Tigers", @"Brisbane", @"2020-05-08T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Crows", @"Dockers", @"Adelaide", @"2020-05-09T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Bulldogs", @"Suns", @"Ballarat", @"2020-05-09T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Eagles", @"Swans", @"Perth", @"2020-05-09T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Cats", @"Bombers", @"MCG", @"2020-05-09T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Giants", @"Magpies", @"Sydney Showground", @"2020-05-09T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Saints", @"Blues", @"Docklands", @"2020-05-09T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Demons", @"Power", @"MCG", @"2020-05-10T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"8", @"Kangaroos", @"Hawks", @"Docklands", @"2020-05-10T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Tigers", @"Cats", @"MCG", @"2020-05-15T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Kangaroos", @"Bombers", @"Docklands", @"2020-05-16T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Suns", @"Eagles", @"Gold Coast", @"2020-05-16T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Giants", @"Saints", @"Sydney Showground", @"2020-05-16T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Hawks", @"Swans", @"MCG", @"2020-05-16T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Power", @"Lions", @"Adelaide", @"2020-05-16T19:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Blues", @"Magpies", @"MCG", @"2020-05-17T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Demons", @"Crows", @"Alice Springs", @"2020-05-17T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"9", @"Dockers", @"Bulldogs", @"Perth", @"2020-05-17T17:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Swans", @"Cats", @"Sydney", @"2020-05-22T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Hawks", @"Power", @"Launceston", @"2020-05-23T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Saints", @"Dockers", @"Docklands", @"2020-05-23T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Crows", @"Blues", @"Adelaide", @"2020-05-23T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Bombers", @"Tigers", @"MCG", @"2020-05-23T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Lions", @"Suns", @"Brisbane", @"2020-05-23T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Demons", @"Bulldogs", @"MCG", @"2020-05-24T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Magpies", @"Kangaroos", @"Docklands", @"2020-05-24T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"10", @"Eagles", @"Giants", @"Perth", @"2020-05-24T17:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Hawks", @"Demons", @"MCG", @"2020-05-29T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Tigers", @"Swans", @"MCG", @"2020-05-30T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Cats", @"Kangaroos", @"Geelong", @"2020-05-30T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Giants", @"Crows", @"Sydney Showground", @"2020-05-30T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Bulldogs", @"Blues", @"Docklands", @"2020-05-30T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Dockers", @"Lions", @"Perth", @"2020-05-30T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Bombers", @"Suns", @"Docklands", @"2020-05-31T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Saints", @"Power", @"China", @"2020-05-31T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"11", @"Magpies", @"Eagles", @"MCG", @"2020-05-31T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"12", @"Crows", @"Bulldogs", @"Adelaide", @"2020-06-05T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"12", @"Swans", @"Dockers", @"Sydney", @"2020-06-06T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"12", @"Suns", @"Hawks", @"Gold Coast", @"2020-06-06T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"12", @"Blues", @"Giants", @"Docklands", @"2020-06-06T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"12", @"Tigers", @"Kangaroos", @"MCG", @"2020-06-07T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"12", @"Demons", @"Magpies", @"MCG", @"2020-06-08T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"13", @"Eagles", @"Bombers", @"Perth", @"2020-06-11T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"13", @"Hawks", @"Cats", @"MCG", @"2020-06-12T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"13", @"Kangaroos", @"Lions", @"Hobart", @"2020-06-13T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"13", @"Suns", @"Saints", @"Darwin", @"2020-06-13T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"13", @"Bulldogs", @"Giants", @"Docklands", @"2020-06-13T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"13", @"Crows", @"Power", @"Adelaide", @"2020-06-14T15:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"14", @"Swans", @"Magpies", @"Sydney", @"2020-06-18T19:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"14", @"Lions", @"Demons", @"Brisbane", @"2020-06-19T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"14", @"Bombers", @"Saints", @"Docklands", @"2020-06-20T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"14", @"Dockers", @"Blues", @"Perth", @"2020-06-20T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"14", @"Power", @"Cats", @"Adelaide", @"2020-06-20T19:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"14", @"Tigers", @"Eagles", @"MCG", @"2020-06-21T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Lions", @"Hawks", @"Brisbane", @"2020-06-25T19:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Bulldogs", @"Bombers", @"Docklands", @"2020-06-26T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Demons", @"Suns", @"MCG", @"2020-06-27T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Blues", @"Cats", @"Docklands", @"2020-06-27T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Giants", @"Tigers", @"Sydney Showground", @"2020-06-27T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Eagles", @"Kangaroos", @"Perth", @"2020-06-27T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Magpies", @"Crows", @"MCG", @"2020-06-28T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Saints", @"Swans", @"Docklands", @"2020-06-28T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"15", @"Power", @"Dockers", @"Adelaide", @"2020-06-28T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Bombers", @"Hawks", @"Docklands", @"2020-07-02T19:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Cats", @"Eagles", @"Geelong", @"2020-07-03T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Magpies", @"Lions", @"MCG", @"2020-07-04T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Tigers", @"Power", @"Docklands", @"2020-07-04T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Swans", @"Bulldogs", @"Sydney", @"2020-07-04T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Crows", @"Saints", @"Adelaide", @"2020-07-04T19:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Suns", @"Blues", @"Gold Coast", @"2020-07-05T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Kangaroos", @"Giants", @"Docklands", @"2020-07-05T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"16", @"Dockers", @"Demons", @"Perth", @"2020-07-05T17:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Tigers", @"Magpies", @"MCG", @"2020-07-10T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Demons", @"Saints", @"MCG", @"2020-07-11T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Hawks", @"Kangaroos", @"Launceston", @"2020-07-11T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Giants", @"Bombers", @"Sydney Showground", @"2020-07-11T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Bulldogs", @"Dockers", @"Docklands", @"2020-07-11T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Lions", @"Cats", @"Brisbane", @"2020-07-11T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Power", @"Suns", @"Adelaide", @"2020-07-12T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Blues", @"Swans", @"Docklands", @"2020-07-12T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"17", @"Eagles", @"Crows", @"Perth", @"2020-07-12T17:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Magpies", @"Cats", @"MCG", @"2020-07-17T19:50:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Hawks", @"Giants", @"MCG", @"2020-07-18T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Suns", @"Tigers", @"Gold Coast", @"2020-07-18T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Swans", @"Power", @"Sydney", @"2020-07-18T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Saints", @"Bulldogs", @"Docklands", @"2020-07-18T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Dockers", @"Eagles", @"Perth", @"2020-07-18T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Bombers", @"Kangaroos", @"MCG", @"2020-07-19T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Blues", @"Lions", @"Docklands", @"2020-07-19T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"18", @"Crows", @"Demons", @"Adelaide", @"2020-07-19T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Power", @"Hawks", @"Adelaide", @"2020-07-24T19:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Blues", @"Eagles", @"MCG", @"2020-07-25T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Kangaroos", @"Suns", @"Hobart", @"2020-07-25T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Cats", @"Demons", @"Geelong", @"2020-07-25T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Giants", @"Swans", @"Sydney Showground", @"2020-07-25T17:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Bombers", @"Crows", @"Docklands", @"2020-07-25T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Tigers", @"Bulldogs", @"MCG", @"2020-07-26T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Lions", @"Saints", @"Brisbane", @"2020-07-26T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"19", @"Dockers", @"Magpies", @"Perth", @"2020-07-26T17:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Crows", @"Tigers", @"Adelaide", @"2020-07-31T19:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Bombers", @"Magpies", @"MCG", @"2020-08-01T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Giants", @"Lions", @"Canberra", @"2020-08-01T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Cats", @"Bulldogs", @"Geelong", @"2020-08-01T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Saints", @"Hawks", @"Docklands", @"2020-08-01T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Eagles", @"Power", @"Perth", @"2020-08-01T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Kangaroos", @"Blues", @"Docklands", @"2020-08-02T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Demons", @"Swans", @"MCG", @"2020-08-02T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"20", @"Suns", @"Dockers", @"Gold Coast", @"2020-08-02T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Cats", @"Giants", @"Geelong", @"2020-08-07T19:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Magpies", @"Demons", @"MCG", @"2020-08-08T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Lions", @"Eagles", @"Brisbane", @"2020-08-08T14:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Hawks", @"Crows", @"Launceston", @"2020-08-08T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Swans", @"Suns", @"Sydney", @"2020-08-08T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Dockers", @"Saints", @"Perth", @"2020-08-08T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Blues", @"Tigers", @"MCG", @"2020-08-09T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Bulldogs", @"Kangaroos", @"Docklands", @"2020-08-09T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"21", @"Power", @"Bombers", @"Adelaide", @"2020-08-09T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Eagles", @"Magpies", @"Perth", @"2020-08-14T20:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Bulldogs", @"Power", @"Ballarat", @"2020-08-15T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Demons", @"Blues", @"MCG", @"2020-08-15T13:45:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Giants", @"Dockers", @"Sydney Showground", @"2020-08-15T16:35:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Bombers", @"Swans", @"Docklands", @"2020-08-15T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Suns", @"Lions", @"Gold Coast", @"2020-08-15T19:25:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Saints", @"Cats", @"Docklands", @"2020-08-16T13:10:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Tigers", @"Hawks", @"MCG", @"2020-08-16T15:20:00+10:00" ]],
    [GUFixture newFixture:@[ @"22", @"Crows", @"Kangaroos", @"Adelaide", @"2020-08-16T16:40:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Lions", @"Bombers", @"Brisbane", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Swans", @"Hawks", @"Sydney", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Magpies", @"Suns", @"MCG", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Blues", @"Saints", @"Docklands", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Bulldogs", @"Eagles", @"Docklands", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Cats", @"Crows", @"Geelong", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Kangaroos", @"Demons", @"Hobart", @"2020-08-22T00:00:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Power", @"Giants", @"Adelaide", @"2020-08-22T00:30:00+10:00" ]],
    [GUFixture newFixture:@[ @"23", @"Dockers", @"Tigers", @"Perth", @"2020-08-22T02:00:00+10:00" ]],             ];
}

@end
