//
//  TopPlacesTableViewController.m
//  FlickrFetcher
//
//  Created by Jeffrey Lam on 11/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TopPlacesTableViewController.h"
#import "FlickrFetcher.h"
#import "RecentPhotosTableViewController.h"
#import "BackgroundLoader.h"

@interface TopPlacesTableViewController()
@property (nonatomic, strong) NSArray *topPlaces;
@property (nonatomic, strong) NSDictionary *countries;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView; // TODO extract all activityIndicatorViews and put into BackgroundLoader by programatically creating the activity indicator view and its parent plain UIView; or, use a 3rd party component like https://github.com/mattmmatt/MBProgressHUD when coding professionally instead of doing this as a homework
@end

@implementation TopPlacesTableViewController

@synthesize topPlaces = _topPlaces;
@synthesize countries = _countries;
@synthesize activityIndicatorView = _activityIndicatorView;

- (void)setTopPlaces:(NSArray *)topPlaces
{
    if (_topPlaces != topPlaces) {
        _topPlaces = topPlaces;
    }
}

- (void)setCountries:(NSDictionary *)countries
{
    if (_countries != countries) {
        _countries = countries;
        [self.tableView reloadData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Photos From City"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSString *country = [self tableView:self.tableView titleForHeaderInSection:indexPath.section];
        NSDictionary *place = [[self.countries valueForKey:country] objectAtIndex:indexPath.row];
        [segue.destinationViewController setPlace:place];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [BackgroundLoader viewDidLoad:nil withBlock:^{
        NSArray *unorderedPlaces = [FlickrFetcher topPlaces];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicatorView stopAnimating];
            NSArray *topPlaces = self.topPlaces = [unorderedPlaces sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:FLICKR_PLACE_NAME ascending:YES]]];
            NSMutableDictionary *countries = [NSMutableDictionary dictionary];
            for (NSDictionary *place in topPlaces) {
                NSString *country = [[[place valueForKeyPath:FLICKR_PLACE_NAME] componentsSeparatedByString:@","] lastObject];
                NSMutableArray *cities = [countries valueForKey:country];
                if (cities) {
                    [cities addObject:place];
                } else {
                    cities = [NSMutableArray arrayWithObject:place];
                    [countries setValue:cities forKey:country];
                }
            }
            self.countries = countries;
        });
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.countries count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *country = [self tableView:tableView titleForHeaderInSection:section];
    return [[self.countries valueForKey:country] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[[self.countries allKeys] mutableCopy] sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Place";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSString *country = [self tableView:tableView titleForHeaderInSection:indexPath.section];
    NSDictionary *place = [[self.countries valueForKey:country] objectAtIndex:indexPath.row];
    NSMutableString *placeString = [[place valueForKeyPath:FLICKR_PLACE_NAME] mutableCopy];
    NSMutableArray *placeComponents = [[placeString componentsSeparatedByString:@","] mutableCopy];
    NSString *city = [placeComponents objectAtIndex:0];
    cell.textLabel.text = city;
    [placeComponents removeObjectAtIndex:0];
    NSString *details;
    for (NSString *element in placeComponents) {
        if (!details) {
            details = element;
        } else {
            details = [details stringByAppendingString:[@"," stringByAppendingString:element]];
        }
    }
    if (details) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", details];
    }
    return cell;
}

- (void)viewDidUnload {
    self.activityIndicatorView = nil;
    [super viewDidUnload];
}
@end
