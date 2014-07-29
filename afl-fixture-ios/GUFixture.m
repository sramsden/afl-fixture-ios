#import "GUFixture.h"


@implementation GUFixture
{

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
  NSDate* now = [NSDate date];
  // maintain flag to specify isUpcoming but has to be a number to be able to send it back in the array..
  NSNumber *isUpcoming = [NSNumber numberWithBool:[now compare:date] == NSOrderedAscending];
  return @[formattedDate, formattedTime, isUpcoming ];
}

+ (GUFixture *)newFixture:(NSArray *)properties {
  return [[GUFixture alloc] init:properties[0] team:properties[1] vs_team: properties[2] venue:properties[3] datetime:properties[4]];
}

+ (NSArray *)getDescriptors {
  return [self getDescriptorsUnderHeadings:[self getFixtures]];
}

+ (NSArray *)getDescriptorsUnderHeadings:(NSArray *)fixturesArray {
  NSMutableArray *fixtures = [fixturesArray mutableCopy];
  NSMutableArray *descriptors = [[NSMutableArray alloc] init];
  NSString *round = nil;
  int i = 0;
  for (GUFixture *fixture in fixtures){
    if(![fixture.round isEqualToString:round]){
      round = fixture.round;
      NSString *label = [NSString stringWithFormat:@"ROUND %@", round];
      [descriptors addObject:label];
    }
    [descriptors addObject:fixture.descriptor];
    if(!fixture.upcoming){
      i = descriptors.count - 1; // default to last descriptor when nothing upcoming
    }
  }
  return @[descriptors, [NSNumber numberWithInt:i] ];
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
    fixtures= [self buildFixtures];
  });
  fixtures = [fixtures sortedArrayUsingSelector:@selector(datetimeCompare:)];
  return fixtures;
}

+ (NSArray *)getTeams{
  NSArray *fixtures = [self getFixtures];
  NSMutableArray *teams = [[NSMutableArray alloc] init];
  NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
  for( id fixture in fixtures )
  {
    NSString *team = [fixture team];
    NSString *vs_team = [fixture vs_team];
    if( ![map valueForKey:team] ){
      [teams addObject:team];
      [map setObject:team forKey:team];
    }
    if( ![map valueForKey:vs_team] ){
      [teams addObject:vs_team];
      [map setObject:vs_team forKey:vs_team];
    }
  }
  return [teams sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray *)getVenues{
  NSArray *fixtures = [self getFixtures];
  NSMutableArray *venues = [[NSMutableArray alloc] init];
  NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
  for( id fixture in fixtures )
  {
    NSString *venue = [fixture venue];
    if( ![map valueForKey:venue] ){
      [venues addObject:venue];
      [map setObject:venue forKey:venue];
    }
  }
  return [venues sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray *)getTimeslots{
  NSArray *fixtures = [self getFixtures];
  NSMutableArray *timeslots = [[NSMutableArray alloc] init];
  NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
  for( id fixture in fixtures )
  {
    NSString *datetime = [fixture datetime];
    NSString *timeslot = [self parseAndReformatDatetime:datetime][1];
    if( ![map valueForKey:timeslot] ){
      [timeslots addObject:timeslot];
      [map setObject:timeslot forKey:timeslot];
    }
  }
  return [timeslots sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray *)buildFixtures {
  return @[
      [GUFixture newFixture:@[ @"1", @"Magpies", @"Dockers", @"Docklands", @"2014-03-14T19:50:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Giants", @"Swans", @"Sydney Showgrounds", @"2014-03-15T16:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Suns", @"Tigers", @"Gold Coast", @"2014-03-15T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Blues", @"Power", @"Docklands", @"2014-03-16T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Cats", @"Crows", @"Geelong", @"2014-03-20T19:10:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Kangaroos", @"Bombers", @"Docklands", @"2014-03-21T19:50:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Hawks", @"Lions", @"Launceston", @"2014-03-22T16:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Saints", @"Demons", @"Docklands", @"2014-03-22T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"1", @"Eagles", @"Bulldogs", @"Perth", @"2014-03-23T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Tigers", @"Blues", @"MCG", @"2014-03-27T19:45:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Bombers", @"Hawks", @"Docklands", @"2014-03-28T19:50:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Saints", @"Giants", @"Docklands", @"2014-03-29T13:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Power", @"Crows", @"Adelaide", @"2014-03-29T16:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Swans", @"Magpies", @"Sydney Olympic", @"2014-03-29T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Dockers", @"Suns", @"Perth", @"2014-03-29T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Lions", @"Cats", @"Brisbane", @"2014-03-30T13:10:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Demons", @"Eagles", @"MCG", @"2014-03-30T15:20:00+11:00" ]],
      [GUFixture newFixture:@[ @"2", @"Bulldogs", @"Kangaroos", @"Docklands", @"2014-03-30T16:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Hawks", @"Dockers", @"MCG", @"2014-04-04T19:50:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Bulldogs", @"Tigers", @"Docklands", @"2014-04-05T13:45:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Crows", @"Swans", @"Adelaide", @"2014-04-05T14:10:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Suns", @"Lions", @"Gold Coast", @"2014-04-05T16:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Magpies", @"Cats", @"MCG", @"2014-04-05T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Eagles", @"Saints", @"Perth", @"2014-04-05T19:40:00+11:00" ]],
      [GUFixture newFixture:@[ @"3", @"Giants", @"Demons", @"Sydney Showgrounds", @"2014-04-06T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"3", @"Kangaroos", @"Power", @"Docklands", @"2014-04-06T16:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"3", @"Bombers", @"Blues", @"MCG", @"2014-04-06T19:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Tigers", @"Magpies", @"MCG", @"2014-04-11T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Blues", @"Demons", @"MCG", @"2014-04-12T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Power", @"Lions", @"Adelaide", @"2014-04-12T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Giants", @"Bulldogs", @"Canberra", @"2014-04-12T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Suns", @"Hawks", @"Gold Coast", @"2014-04-12T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Cats", @"Eagles", @"Geelong", @"2014-04-12T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Swans", @"Kangaroos", @"SCG", @"2014-04-13T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Saints", @"Crows", @"Docklands", @"2014-04-13T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"4", @"Dockers", @"Bombers", @"Perth", @"2014-04-13T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Lions", @"Tigers", @"Brisbane", @"2014-04-17T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Magpies", @"Kangaroos", @"MCG", @"2014-04-19T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Swans", @"Dockers", @"SCG", @"2014-04-19T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Bombers", @"Saints", @"Docklands", @"2014-04-19T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Eagles", @"Power", @"Perth", @"2014-04-19T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Crows", @"Giants", @"Adelaide", @"2014-04-20T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Demons", @"Suns", @"MCG", @"2014-04-20T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Bulldogs", @"Blues", @"Docklands", @"2014-04-20T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"5", @"Cats", @"Hawks", @"MCG", @"2014-04-21T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Magpies", @"Bombers", @"MCG", @"2014-04-25T14:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Saints", @"Lions", @"New Zealand", @"2014-04-25T17:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Dockers", @"Kangaroos", @"Perth", @"2014-04-25T20:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Suns", @"Giants", @"Gold Coast", @"2014-04-26T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Blues", @"Eagles", @"Docklands", @"2014-04-26T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Demons", @"Swans", @"MCG", @"2014-04-26T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Bulldogs", @"Crows", @"Docklands", @"2014-04-27T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Tigers", @"Hawks", @"MCG", @"2014-04-27T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"6", @"Power", @"Cats", @"Adelaide", @"2014-04-27T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Blues", @"Magpies", @"MCG", @"2014-05-02T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Hawks", @"Saints", @"MCG", @"2014-05-03T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Giants", @"Power", @"Canberra", @"2014-05-03T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Crows", @"Demons", @"Adelaide", @"2014-05-03T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Bombers", @"Bulldogs", @"Docklands", @"2014-05-03T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Lions", @"Swans", @"Brisbane", @"2014-05-03T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Kangaroos", @"Suns", @"Docklands", @"2014-05-04T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Cats", @"Tigers", @"MCG", @"2014-05-04T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"7", @"Eagles", @"Dockers", @"Perth", @"2014-05-04T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"8", @"Swans", @"Hawks", @"Sydney Olympic", @"2014-05-09T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"8", @"Power", @"Dockers", @"Adelaide", @"2014-05-10T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"8", @"Lions", @"Bombers", @"Brisbane", @"2014-05-10T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"8", @"Demons", @"Bulldogs", @"MCG", @"2014-05-10T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"8", @"Eagles", @"Giants", @"Perth", @"2014-05-11T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"8", @"Saints", @"Blues", @"Docklands", @"2014-05-12T19:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"9", @"Crows", @"Magpies", @"Adelaide", @"2014-05-15T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"9", @"Bombers", @"Swans", @"Docklands", @"2014-05-16T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"9", @"Tigers", @"Demons", @"MCG", @"2014-05-17T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"9", @"Kangaroos", @"Lions", @"Docklands", @"2014-05-17T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"9", @"Dockers", @"Cats", @"Perth", @"2014-05-17T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"9", @"Saints", @"Suns", @"Docklands", @"2014-05-18T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"10", @"Cats", @"Kangaroos", @"Geelong", @"2014-05-23T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"10", @"Giants", @"Tigers", @"Sydney Showgrounds", @"2014-05-24T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"10", @"Magpies", @"Eagles", @"MCG", @"2014-05-24T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"10", @"Power", @"Hawks", @"Adelaide", @"2014-05-24T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"10", @"Suns", @"Bulldogs", @"Gold Coast", @"2014-05-25T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"10", @"Blues", @"Crows", @"MCG", @"2014-05-25T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Swans", @"Cats", @"SCG", @"2014-05-29T19:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Saints", @"Magpies", @"Docklands", @"2014-05-30T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Demons", @"Power", @"Alice Springs", @"2014-05-31T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Lions", @"Blues", @"Brisbane", @"2014-05-31T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Bombers", @"Tigers", @"MCG", @"2014-05-31T19:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Crows", @"Suns", @"Adelaide", @"2014-06-01T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Bulldogs", @"Dockers", @"Docklands", @"2014-06-01T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Hawks", @"Giants", @"MCG", @"2014-06-01T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"11", @"Eagles", @"Kangaroos", @"Perth", @"2014-06-01T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Cats", @"Blues", @"Docklands", @"2014-06-06T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Hawks", @"Eagles", @"Launceston", @"2014-06-07T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Power", @"Saints", @"Adelaide", @"2014-06-07T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Giants", @"Bombers", @"Sydney Showgrounds", @"2014-06-07T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Bulldogs", @"Lions", @"Docklands", @"2014-06-07T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Suns", @"Swans", @"Gold Coast", @"2014-06-08T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Dockers", @"Crows", @"Perth", @"2014-06-08T16:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Kangaroos", @"Tigers", @"Docklands", @"2014-06-08T19:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"12", @"Demons", @"Magpies", @"MCG", @"2014-06-09T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Blues", @"Hawks", @"MCG", @"2014-06-13T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Tigers", @"Dockers", @"MCG", @"2014-06-14T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Swans", @"Power", @"SCG", @"2014-06-14T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Eagles", @"Suns", @"Perth", @"2014-06-14T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Crows", @"Kangaroos", @"Adelaide", @"2014-06-14T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Lions", @"Giants", @"Brisbane", @"2014-06-14T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Cats", @"Saints", @"Geelong", @"2014-06-15T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Magpies", @"Bulldogs", @"Docklands", @"2014-06-15T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"13", @"Bombers", @"Demons", @"MCG", @"2014-06-15T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Tigers", @"Swans", @"MCG", @"2014-06-20T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Power", @"Bulldogs", @"Adelaide", @"2014-06-21T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Hawks", @"Magpies", @"MCG", @"2014-06-21T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Suns", @"Cats", @"Gold Coast", @"2014-06-21T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Bombers", @"Crows", @"Docklands", @"2014-06-21T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Dockers", @"Lions", @"Perth", @"2014-06-21T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Giants", @"Blues", @"Sydney Showgrounds", @"2014-06-22T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Saints", @"Eagles", @"Docklands", @"2014-06-22T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"14", @"Demons", @"Kangaroos", @"MCG", @"2014-06-22T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Cats", @"Bombers", @"Docklands", @"2014-06-27T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Hawks", @"Suns", @"Launceston", @"2014-06-28T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Saints", @"Tigers", @"Docklands", @"2014-06-28T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Dockers", @"Eagles", @"Perth", @"2014-06-28T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Lions", @"Kangaroos", @"Brisbane", @"2014-06-28T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Swans", @"Giants", @"SCG", @"2014-06-28T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Bulldogs", @"Demons", @"Docklands", @"2014-06-29T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Crows", @"Power", @"Adelaide", @"2014-06-29T16:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"15", @"Magpies", @"Blues", @"MCG", @"2014-06-29T19:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Kangaroos", @"Hawks", @"Docklands", @"2014-07-04T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Tigers", @"Lions", @"MCG", @"2014-07-05T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Giants", @"Crows", @"Sydney Showgrounds", @"2014-07-05T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Suns", @"Magpies", @"Gold Coast", @"2014-07-05T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Power", @"Bombers", @"Adelaide", @"2014-07-05T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Demons", @"Dockers", @"Darwin", @"2014-07-05T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Blues", @"Saints", @"Docklands", @"2014-07-06T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Eagles", @"Swans", @"Perth", @"2014-07-06T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"16", @"Cats", @"Bulldogs", @"Geelong", @"2014-07-06T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Crows", @"Hawks", @"Adelaide", @"2014-07-11T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Demons", @"Cats", @"MCG", @"2014-07-12T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Kangaroos", @"Saints", @"Hobart", @"2014-07-12T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Bulldogs", @"Suns", @"Cairns", @"2014-07-12T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Swans", @"Blues", @"SCG", @"2014-07-12T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Lions", @"Eagles", @"Brisbane", @"2014-07-12T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Tigers", @"Power", @"Docklands", @"2014-07-13T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Bombers", @"Magpies", @"MCG", @"2014-07-13T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"17", @"Dockers", @"Giants", @"Perth", @"2014-07-13T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Blues", @"Kangaroos", @"Docklands", @"2014-07-18T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Saints", @"Dockers", @"Docklands", @"2014-07-19T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Giants", @"Cats", @"Sydney Showgrounds", @"2014-07-19T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Power", @"Demons", @"Adelaide", @"2014-07-20T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Bulldogs", @"Bombers", @"Docklands", @"2014-07-20T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Eagles", @"Tigers", @"Perth", @"2014-07-25T20:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Lions", @"Suns", @"Brisbane", @"2014-07-26T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Hawks", @"Swans", @"MCG", @"2014-07-26T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"18", @"Magpies", @"Crows", @"MCG", @"2014-07-27T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Dockers", @"Blues", @"Perth", @"2014-07-31T20:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Swans", @"Bombers", @"SCG", @"2014-08-01T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Crows", @"Eagles", @"Adelaide", @"2014-08-02T13:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Tigers", @"Giants", @"MCG", @"2014-08-02T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Kangaroos", @"Cats", @"Docklands", @"2014-08-02T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Suns", @"Saints", @"Gold Coast", @"2014-08-02T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Demons", @"Lions", @"Docklands", @"2014-08-03T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Hawks", @"Bulldogs", @"Launceston", @"2014-08-03T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"19", @"Magpies", @"Power", @"MCG", @"2014-08-03T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Tigers", @"Bombers", @"MCG", @"2014-08-08T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Giants", @"Kangaroos", @"Canberra", @"2014-08-09T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Blues", @"Suns", @"Docklands", @"2014-08-09T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Hawks", @"Demons", @"MCG", @"2014-08-09T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Cats", @"Dockers", @"Geelong", @"2014-08-09T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Power", @"Swans", @"Adelaide", @"2014-08-09T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Lions", @"Crows", @"Brisbane", @"2014-08-10T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Saints", @"Bulldogs", @"Docklands", @"2014-08-10T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"20", @"Eagles", @"Magpies", @"Perth", @"2014-08-10T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Blues", @"Cats", @"Docklands", @"2014-08-15T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Swans", @"Saints", @"SCG", @"2014-08-16T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Suns", @"Power", @"Gold Coast", @"2014-08-16T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Bombers", @"Eagles", @"Docklands", @"2014-08-16T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Crows", @"Tigers", @"Adelaide", @"2014-08-16T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Magpies", @"Lions", @"MCG", @"2014-08-16T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Kangaroos", @"Bulldogs", @"Docklands", @"2014-08-17T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Demons", @"Giants", @"MCG", @"2014-08-17T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"21", @"Dockers", @"Hawks", @"Perth", @"2014-08-17T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Power", @"Blues", @"Adelaide", @"2014-08-22T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Kangaroos", @"Crows", @"Hobart", @"2014-08-23T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Bombers", @"Suns", @"Docklands", @"2014-08-23T14:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Giants", @"Magpies", @"Sydney Showgrounds", @"2014-08-23T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Hawks", @"Cats", @"MCG", @"2014-08-23T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Eagles", @"Demons", @"Perth", @"2014-08-23T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Lions", @"Dockers", @"Brisbane", @"2014-08-24T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Bulldogs", @"Swans", @"Docklands", @"2014-08-24T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"22", @"Tigers", @"Saints", @"MCG", @"2014-08-24T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Magpies", @"Hawks", @"MCG", @"2014-08-29T19:50:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Blues", @"Bombers", @"MCG", @"2014-08-30T13:45:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Dockers", @"Port", @"Perth", @"2014-08-30T15:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Swans", @"Tigers", @"Sydney Olympic", @"2014-08-30T16:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Cats", @"Lions", @"Geelong", @"2014-08-30T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Roos", @"Demons", @"Docklands", @"2014-08-30T19:40:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Suns", @"Eagles", @"Gold Coast", @"2014-08-31T13:10:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Crows", @"Saints", @"Adelaide", @"2014-08-31T15:20:00+10:00" ]],
      [GUFixture newFixture:@[ @"23", @"Bulldogs", @"Giants", @"Docklands", @"2014-08-31T16:40:00+10:00" ]]
  ];
}

@end
