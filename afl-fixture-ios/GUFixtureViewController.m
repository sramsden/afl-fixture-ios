#import "GUFixtureViewController.h"
#import "GUFixture.h"

@interface GUFixtureViewController () <UIActionSheetDelegate>
@property(nonatomic,retain) UIActionSheet *actionSheetForFilterTypes;
@property(nonatomic,retain) UIActionSheet *actionSheetForFilters;
@property(nonatomic,retain) UIBarButtonItem *barButton;
@end

@implementation GUFixtureViewController
{
  NSArray *_filterOptions;
}

- (void)viewDidLoad {
  [super viewDidLoad]; // doco says you should call this
  self.tableView.backgroundColor = [UIColor blackColor];
  self.title = @"AFL Fixture 2017";

  _barButton = [[UIBarButtonItem alloc] init];
  _barButton.title = @"Filter";
  _barButton.target = self;
  _barButton.action = @selector(clickFilterTypesActionSheet:);
  self.navigationItem.rightBarButtonItem = _barButton;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self scrollToNext];
}

- (void)scrollToNext {
  [[self tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_next intValue] inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (IBAction)clickFilterTypesActionSheet:(UIBarButtonItem *)sender {
  if( self.actionSheetForFilterTypes == nil )
  {
    _actionSheetForFilterTypes =
        [[UIActionSheet alloc] initWithTitle:nil
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil
        ];
    NSArray *options = @[ NEXT_EVENT, TEAM, VENUE, DAY_OF_WEEK, TIMESLOT ];
    for( id option in options )
    {
      [_actionSheetForFilterTypes addButtonWithTitle:option];
    }
    [_actionSheetForFilterTypes showFromBarButtonItem:sender animated:NO];
  }
}

- (IBAction)clickFiltersActionSheet:(UIBarButtonItem *)sender {
  if( self.actionSheetForFilters == nil )
  {
    _actionSheetForFilters =
        [[UIActionSheet alloc] initWithTitle:nil
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil
        ];
    for( id option in _filterOptions )
    {
      [_actionSheetForFilters addButtonWithTitle:option];
    }
    [_actionSheetForFilters showFromBarButtonItem:sender animated:NO];
  }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  // determine if it was a filter type or actual filter that was clicked...
  BOOL filterTypeChosen = [actionSheet isEqual:_actionSheetForFilterTypes];
  BOOL filterChosen = [actionSheet isEqual:_actionSheetForFilters];
  NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
  if( filterTypeChosen )
  {
    if( [NEXT_EVENT isEqualToString:choice] )
    {
      // ensure ALL data loaded...
      NSArray *descriptors = [GUFixture getDescriptors];
      _items = descriptors[0];
      _next = descriptors[1];
      [[self tableView] reloadData];
      [self scrollToNext];
    }
    else
    {
      if( [TEAM isEqualToString:choice] )
      {
        _filterOptions = [GUFixture getTeams];
      }
      else if( [VENUE isEqualToString:choice] )
      {
        _filterOptions = [GUFixture getVenues];
      }
      else if( [DAY_OF_WEEK isEqualToString:choice] )
      {
        _filterOptions = @[ @"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", ];
      }
      else if( [TIMESLOT isEqualToString:choice] )
      {
        _filterOptions = [GUFixture getTimeslots];
      }
      [self clickFiltersActionSheet:_barButton];
    }
    _actionSheetForFilterTypes = nil;
  }
  else if(filterChosen)
  {
    _items = [GUFixture getDescriptorsByFilter:choice];
    [[self tableView] reloadData];
    _actionSheetForFilters = nil;
  }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *MyIdentifier = @"MyIdentifier";

	// Try to retrieve from the table view a now-unused cell with the given identifier.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
  cell.textLabel.font  = ( [ UIFont fontWithName: @"Arial" size: 16.0 ] );

	// If no cell is available, create a new one using the given identifier.
  if ( cell == nil ) {
    // Use the default cell style.
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
	}

	// Set up the cell.
	NSString *item = [_items objectAtIndex:indexPath.row];
	cell.textLabel.text = item;
  cell.textLabel.numberOfLines = 0;
  //  cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  [self colorTextLabel:cell];
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

/*
 To conform to Human Interface Guildelines, since selecting a row would have no effect (such as navigation), make sure that rows cannot be selected.
 */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

+ (GUFixtureViewController *)initFixtureViewController {
  GUFixtureViewController *controller = [[GUFixtureViewController alloc] initWithNibName:nil bundle:nil];
  NSArray *descriptors = [GUFixture getDescriptors];
  [controller setItems:descriptors[0]];
  [controller setNext:descriptors[1]];

  return controller;
}

//- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated;
//{
//  UITableView *tableView = self.tableView;
//  UIView *view = [tableView viewAtIndex:index];
//  [[self scrollView] scrollRectToVisible:[view frame] animated:animated];
//}

- (void)colorTextLabel:(UITableViewCell *)cell {
  if( [cell.textLabel.text hasPrefix:@"ROUND"] )
  {
    UIColor *roundTextColor = [UIColor colorWithRed:(240. / 255.) green:(248. / 255.) blue:(255. / 255.) alpha:1]; // alice blue
    cell.textLabel.textColor = roundTextColor;
    UIColor *roundBgColor = [UIColor colorWithRed:(45. / 255.) green:(53. / 255.) blue:(57. / 255.) alpha:1]; // alice blue
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = roundBgColor;
  }
  else
  {
    // default colours..
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = [UIColor whiteColor];
  }
}


@end