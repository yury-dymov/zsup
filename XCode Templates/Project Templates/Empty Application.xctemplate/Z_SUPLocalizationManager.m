#import "Z_SUPLocalizationManager.h"

@implementation Z_SUPLocalizationManager

@synthesize updateDatabaseDialogMessage;
@synthesize updateDatabaseDialogTitle;
@synthesize updateDatabaseDialogNoButtonText;
@synthesize updateDatabaseDialogYesButtonText;

static Z_SUPLocalizationManager *singletonInstance;

+ (id)getInstance {
    if (!singletonInstance) {
        singletonInstance = [Z_SUPLocalizationManager new];
    }
    return singletonInstance;
}

- (id)init {
    if (!singletonInstance) {
        self = [super init];
        if (self) {
            self.updateDatabaseDialogTitle = NSLocalizedString(@"Warning!", @"");
            self.updateDatabaseDialogMessage = NSLocalizedString(@"Application schema was updated. To get new data from the system I have to delete all local data first. Do you want me to delete it now?", @"");
            self.updateDatabaseDialogYesButtonText = NSLocalizedString(@"Delete", @"");
            self.updateDatabaseDialogNoButtonText = NSLocalizedString(@"Later", @"");
            
            self.restartApplicationDialogTitle = NSLocalizedString(@"Warning!", @"");
            self.restartApplicationDialogMessage = NSLocalizedString(@"Press OK to restart the application. After restart all data will be deleted because data for user was deleted in SUP", @"");
            self.restartApplicationYesButtonText = NSLocalizedString(@"Delete", @"");
            self.restartApplicationNoButtonText = NSLocalizedString(@"Later", @"");            
        }
        singletonInstance = self;
    }
    return singletonInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    if (!singletonInstance) {
        return [super allocWithZone:zone];
    }
    return singletonInstance;
}

- (oneway void)release {
    
}

- (void)dealloc {
    [super dealloc];
}

- (id)autorelease {
    return singletonInstance;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

@end
