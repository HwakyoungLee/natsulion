#import "NTLNMessageListViewsController.h"
#import "NTLNAccount.h"
#import "NTLNConfiguration.h"
#import "TwitterStatusViewController.h"
#import "NTLNNotification.h"

// class holds an information of a message view which can be switched by messageViewSelector.
@interface NTLNMessageViewInfo : NSObject {
    NSPredicate *_predicate;
    float _knobPosition;
}
- (id) initWithPredicate:(NSPredicate*)predicate;
- (NSPredicate*)predicate;
- (float) knobPosition;
- (void) setKnobPosition:(float)position;
@end

@implementation NTLNMessageViewInfo

+ (id) infoWithPredicate:(NSPredicate*)predicate {
    return [[[[self class] alloc] initWithPredicate:predicate] autorelease];
}

- (id) initWithPredicate:(NSPredicate*)predicate {
    [predicate retain];
    _predicate = predicate;
    return self;
}

- (void) dealloc {
    [_predicate release];
    [super dealloc];
}

- (NSPredicate*)predicate {
    return _predicate;
}

- (float) knobPosition {
    return _knobPosition;
}

- (void) setKnobPosition:(float)position {
    _knobPosition = position;
}

@end

/////////////////////////////////////////////////////////////////////////////////////
@implementation NTLNMessageListViewsController
- (id) init {
    _messageViewInfoArray = [[NSMutableArray alloc] initWithCapacity:10];
    _currentViewIndex = 0;
    
//    [_messageViewInfoArray addObject:[NTLNMessageViewInfo infoWithPredicate:nil]];
    [_messageViewInfoArray addObject:[NTLNMessageViewInfo infoWithPredicate:
                                      [NSPredicate predicateWithFormat:@"message.replyType != 2 OR (message.replyType == 2 AND message.timestamp > %@)",
                                       [NSDate dateWithTimeIntervalSince1970:[[NTLNConfiguration instance] latestTimestampOfMessage]]]]];
    [_messageViewInfoArray addObject:[NTLNMessageViewInfo infoWithPredicate:
                                      [NSPredicate predicateWithFormat:@"message.replyType IN %@",
                                       [NSArray arrayWithObjects:
                                        [NSNumber numberWithInt:MESSAGE_REPLY_TYPE_REPLY],
                                        [NSNumber numberWithInt:MESSAGE_REPLY_TYPE_REPLY_PROBABLE],
                                        nil]]]];
    [_messageViewInfoArray addObject:[NTLNMessageViewInfo infoWithPredicate:
                                      [NSPredicate predicateWithFormat:@"message.screenName == %@", [[NTLNAccount instance] username]]]];
    [_messageViewInfoArray addObject:[NTLNMessageViewInfo infoWithPredicate:
                                      [NSPredicate predicateWithFormat:@"message.status == 0"]]];
    
    return self;
}

- (void) dealloc {
    [_messageViewInfoArray release];
    [super dealloc];
}

// not used yet
//- (void) addInfoWithPredicate:(NSPredicate*)predicate {
//    [_messageViewInfoArray addObject:[NTLNMessageViewInfo infoWithPredicate:predicate]];
//}

- (void) changeView:(int)index {
    [[NSNotificationCenter defaultCenter] postNotificationName:NTLN_NOTIFICATION_MESSAGE_VIEW_CHANGING object:nil];
    
    // save status
    [[_messageViewInfoArray objectAtIndex:_currentViewIndex] setKnobPosition:[messageTableViewController knobPosition]];
    
    _currentViewIndex = index;
    // change view
    NTLNMessageViewInfo *messageViewInfo = [_messageViewInfoArray objectAtIndex:_currentViewIndex];
    // to use original one causes an exception
    [messageViewControllerArrayController setFilterPredicate:[[messageViewInfo predicate] copy]];
    [messageTableViewController reloadTableView];
    [messageTableViewController setKnobPosition:[messageViewInfo knobPosition]];

    for (int i = 0; i < [[messageViewControllerArrayController arrangedObjects] count]; i++) {
        TwitterStatusViewController *c = [[messageViewControllerArrayController arrangedObjects] objectAtIndex:i];
        [c exitFromScrollView];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NTLN_NOTIFICATION_MESSAGE_VIEW_CHANGED object:nil];
}

- (IBAction) changeViewByToolbar:(id) sender {
    [self changeView:[sender selectedSegment]];
}

- (IBAction) changeViewByMenu:(id) sender {
    [self changeView:[sender tag]];
}

- (void) applyCurrentPredicate {
    [messageViewControllerArrayController setFilterPredicate:[[[_messageViewInfoArray objectAtIndex:_currentViewIndex] predicate] copy]];
}

- (int) currentViewIndex {
    return _currentViewIndex;
}
     
@end
