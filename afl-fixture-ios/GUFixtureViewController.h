
#import <UIKit/UIKit.h>

static NSString *const NEXT_EVENT = @"Next Round";

static NSString *const TEAM = @"By Team";

static NSString *const VENUE = @"By Venue";

static NSString *const DAY_OF_WEEK = @"By Day of the Week";

static NSString *const TIMESLOT = @"By Timeslot";

@interface GUFixtureViewController : UITableViewController

@property(nonatomic, retain) NSArray *items;

@property (nonatomic, retain) NSNumber *next;

@property(nonatomic, strong) NSArray *filterOptions;

- (void)initFixtures;

+ (GUFixtureViewController *)initFixtureViewController;
@end