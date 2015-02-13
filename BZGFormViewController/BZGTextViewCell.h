//
//  BZGTextViewCell.h
//
//  https://github.com/benzguo/BZGFormViewController
//

#import <UIKit/UIKit.h>
#import "BZGFormCell.h"

@interface BZGTextViewCell : BZGFormCell

@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UITextView *textView;

// A Boolean value indicating whether the text field is currently in edit mode.
@property (assign, nonatomic) BOOL editing;

/// The color of the text field's text when the cell's state is not invalid.
@property (strong, nonatomic) UIColor *textViewNormalColor;

/// The color of the text field's text when the cell's state is invalid.
@property (strong, nonatomic) UIColor *textViewInvalidColor;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

/// A value indicating whether or not the cell shows a checkmark when valid. Default is YES.
@property (assign, nonatomic) BOOL showsCheckmarkWhenValid;

/// A value indicating whether or not the cell displays its validation state while being edited. Default is NO.
@property (assign, nonatomic) BOOL showsValidationWhileEditing;

/// The block called when the text field's text begins editing.
@property (copy, nonatomic) void (^didBeginEditingBlock)(BZGTextViewCell *cell, NSString *text);

/**
 * The block called before the text field's text changes.
 * The block's newText parameter will be the text field's text after changing. Return NO if the text shouldn't change.
 */
@property (copy, nonatomic) BOOL (^shouldChangeTextBlock)(BZGTextViewCell *cell, NSRange range, NSString *newText);

/// The block called when the text field's text ends editing.
@property (copy, nonatomic) void (^didEndEditingBlock)(BZGTextViewCell *cell, NSString *text);

/// The block called before the text field returns. Return NO if the text field shouldn't return.
@property (copy, nonatomic) BOOL (^shouldReturnBlock)(BZGTextViewCell *cell, NSString *text);

/// The block called when the text view's content changes.
@property (copy, nonatomic) void (^didChangeBlock)(BZGTextViewCell *cell);

/// The block called when the text view's selection changes.
@property (copy, nonatomic) void (^didChangeSelection)(BZGTextViewCell *cell);

/**
 * Returns the parent BZGTextViewCell for the given text field. If no cell is found, returns nil.
 *
 * @param textView A UITextView instance that may or may not belong to this BZGTextViewCell instance.
 */
+ (BZGTextViewCell *)parentCellForTextView:(UITextView *)textView;

// Handle UITextViewTextDidChangeNotification
- (void)textViewTextDidChange:(NSNotification *)notification;

// Character limit
@property (assign, nonatomic) NSUInteger characterLimit;

@end
