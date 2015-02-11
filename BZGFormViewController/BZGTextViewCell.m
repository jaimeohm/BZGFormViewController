//
//  BZGTextViewCell.m
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>

#import "BZGTextViewCell.h"
#import "BZGInfoCell.h"
#import "Constants.h"

@implementation BZGTextViewCell

- (id)init
{
    self = [super init];
    if (self) {
        self.showsCheckmarkWhenValid = YES;
        self.showsValidationWhileEditing = NO;
        self.infoCell = [[BZGInfoCell alloc] init];

        [self configureActivityIndicatorView];
        [self configureTextView];
        [self configureLabel];
        [self configureTap];
        [self configureBindings];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textViewTextDidEndEditing:)
                                                     name:UITextViewTextDidEndEditingNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textViewTextDidChange:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureTextView
{
    CGFloat textViewX = self.bounds.size.width * 0.35;
    CGFloat textViewY = 0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        textViewY = 12;
    }
    CGRect textViewFrame = CGRectMake(textViewX,
                                       textViewY,
                                       self.bounds.size.width - textViewX - self.activityIndicatorView.frame.size.width,
                                       self.bounds.size.height);
    self.textView = [[UITextView alloc] initWithFrame:textViewFrame];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textViewNormalColor = BZG_TEXTFIELD_NORMAL_COLOR;
    self.textViewInvalidColor = BZG_TEXTFIELD_INVALID_COLOR;
    self.textView.font = BZG_TEXTFIELD_FONT;
    self.textView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.textView];
}

- (void)configureLabel
{
    CGFloat labelX = 10;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        labelX = 15;
    }
    CGRect labelFrame = CGRectMake(labelX,
                                   0,
                                   self.textView.frame.origin.x - labelX,
                                   self.bounds.size.height);
    self.label = [[UILabel alloc] initWithFrame:labelFrame];
    self.label.font = BZG_TEXTFIELD_LABEL_FONT;
    self.label.textColor = BZG_TEXTFIELD_LABEL_COLOR;
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.label];
}

- (void)configureActivityIndicatorView
{
    CGFloat activityIndicatorWidth = self.bounds.size.height*0.7;
    CGRect activityIndicatorFrame = CGRectMake(self.bounds.size.width - activityIndicatorWidth,
                                               0,
                                               activityIndicatorWidth,
                                               self.bounds.size.height);
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicatorView setFrame:activityIndicatorFrame];
    self.activityIndicatorView.hidesWhenStopped = NO;
    self.activityIndicatorView.hidden = YES;
    [self addSubview:self.activityIndicatorView];
}

- (void)configureTap {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeFirstResponder)];
    [self.contentView addGestureRecognizer:tap];
}

- (void)configureBindings
{
    @weakify(self);

    RAC(self.textView, textColor) =
    [RACObserve(self, validationState) map:^UIColor *(NSNumber *validationState) {
        @strongify(self);
        if (self.textView.editing &&
            !self.showsValidationWhileEditing) {
            return self.textViewNormalColor;
        }
        switch (validationState.integerValue) {
            case BZGValidationStateInvalid:
                return self.textViewInvalidColor;
                break;
            case BZGValidationStateValid:
            case BZGValidationStateValidating:
            case BZGValidationStateWarning:
            case BZGValidationStateNone:
            default:
                return self.textViewNormalColor;
                break;
        }
    }];

    RAC(self.activityIndicatorView, hidden) =
    [RACObserve(self, validationState) map:^NSNumber *(NSNumber *validationState) {
        @strongify(self);
        if (validationState.integerValue == BZGValidationStateValidating) {
            [self.activityIndicatorView startAnimating];
            return @NO;
        } else {
            [self.activityIndicatorView stopAnimating];
            return @YES;
        }
    }];

    RAC(self, accessoryType) =
    [RACObserve(self, validationState) map:^NSNumber *(NSNumber *validationState) {
        @strongify(self);
        if (validationState.integerValue == BZGValidationStateValid &&
            (!self.textView.editing || self.showsValidationWhileEditing) &&
            self.showsCheckmarkWhenValid) {
            return @(UITableViewCellAccessoryCheckmark);
        } else {
            return @(UITableViewCellAccessoryNone);
        }
    }];
}

+ (BZGTextViewCell *)parentCellForTextView:(UITextView *)textView
{
    UIView *view = textView;
    while ((view = view.superview)) {
        if ([view isKindOfClass:[BZGTextViewCell class]]) break;
    }
    return (BZGTextViewCell *)view;
}

- (void)setShowsCheckmarkWhenValid:(BOOL)showsCheckmarkWhenValid
{
    _showsCheckmarkWhenValid = showsCheckmarkWhenValid;
    // Force RACObserve to trigger
    self.validationState = self.validationState;
}

#pragma mark - UITextView notification selectors
// I'm using these notifications to flush the validation state signal.
// It works, but seems hacky. Is there a better way?

- (void)textViewTextDidChange:(NSNotification *)notification
{
    UITextView *textView = (UITextView *)notification.object;
    if ([textView isEqual:self.textView]) {
        self.validationState = self.validationState;
        
        // Secure text fields clear on begin editing on iOS6+.
        // If it seems like the text field has been cleared,
        // invoke the text change delegate method again to ensure proper validation.
        if (textView.secureTextEntry && textView.text.length <= 1) {
            [self.textView.delegate textView:self.textView
                 shouldChangeCharactersInRange:NSMakeRange(0, textView.text.length)
                             replacementString:textView.text];
        }
    }
}

- (void)textViewTextDidEndEditing:(NSNotification *)notification
{
    UITextView *textView = (UITextView *)notification.object;
    if ([textView isEqual:self.textView]) {
        self.validationState = self.validationState;
    }
}

- (BOOL)becomeFirstResponder
{
    return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.textView resignFirstResponder];
}

@end
