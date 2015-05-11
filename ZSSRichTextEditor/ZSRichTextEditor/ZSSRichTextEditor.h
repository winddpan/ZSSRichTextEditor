//
//  ZSSRichTextEditorViewController.h
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRColorPickerViewController.h"

/**
 *  The types of toolbar items that built-in, set ZSSBarButtonItem property - identifier
 */
static NSString * const ZSSRichTextEditorToolbarBold = @"bold";
static NSString * const ZSSRichTextEditorToolbarItalic = @"italic";
static NSString * const ZSSRichTextEditorToolbarSubscript = @"subscript";
static NSString * const ZSSRichTextEditorToolbarSuperscript = @"superscript";
static NSString * const ZSSRichTextEditorToolbarStrikeThrough = @"strikeThrough";
static NSString * const ZSSRichTextEditorToolbarUnderline = @"underline";
static NSString * const ZSSRichTextEditorToolbarRemoveFormat = @"removeFormat";
static NSString * const ZSSRichTextEditorToolbarJustifyLeft = @"justifyLeft";
static NSString * const ZSSRichTextEditorToolbarJustifyCenter = @"justifyCenter";
static NSString * const ZSSRichTextEditorToolbarJustifyRight = @"justifyRight";
static NSString * const ZSSRichTextEditorToolbarJustifyFull = @"justifyFull";
static NSString * const ZSSRichTextEditorToolbarH1 = @"h1";
static NSString * const ZSSRichTextEditorToolbarH2 = @"h2";
static NSString * const ZSSRichTextEditorToolbarH3 = @"h3";
static NSString * const ZSSRichTextEditorToolbarH4 = @"h4";
static NSString * const ZSSRichTextEditorToolbarH5 = @"h5";
static NSString * const ZSSRichTextEditorToolbarH6 = @"h6";
static NSString * const ZSSRichTextEditorToolbarTextColor = @"textColor";
static NSString * const ZSSRichTextEditorToolbarBackgroundColor = @"backgroundColor";
static NSString * const ZSSRichTextEditorToolbarUnorderedList = @"unorderedList";
static NSString * const ZSSRichTextEditorToolbarOrderedList = @"orderedList";
static NSString * const ZSSRichTextEditorToolbarHorizontalRule = @"horizontalRule";
static NSString * const ZSSRichTextEditorToolbarIndent = @"indent";
static NSString * const ZSSRichTextEditorToolbarOutdent = @"outdent";
static NSString * const ZSSRichTextEditorToolbarInsertImage = @"img";
static NSString * const ZSSRichTextEditorToolbarInsertLink = @"link";
static NSString * const ZSSRichTextEditorToolbarRemoveLink = @"removeLink";
static NSString * const ZSSRichTextEditorToolbarQuickLink = @"quickLink";
static NSString * const ZSSRichTextEditorToolbarUndo = @"undo";
static NSString * const ZSSRichTextEditorToolbarRedo = @"redo";
static NSString * const ZSSRichTextEditorToolbarViewSource = @"source";
static NSString * const ZSSRichTextEditorToolbarParagraph = @"p";
static NSString * const ZSSRichTextEditorToolbarHideKeyboard = @"hideKeyboard";

@class ZSSRichTextEditor, ZSSBarButtonItem;


@protocol ZSSRichTextEditorDelegate <NSObject>
@optional

- (void)editorDidBeginEditing:(ZSSRichTextEditor *)editorController;
- (void)editorDidEndEditing:(ZSSRichTextEditor *)editorController;
- (void)editorDidFinishLoadingDOM:(ZSSRichTextEditor*)editorController;
- (BOOL)editorShouldDisplaySourceView:(ZSSRichTextEditor *)editorController;
- (void)editorTextDidChange:(ZSSRichTextEditor *)editorController;

/**
 *  Scroll event callback with position
 */
- (void)editorDidScrollWithPosition:(NSInteger)position;

//- (void)editorDidPressMedia:(ZSSRichTextEditor *)editorController;
//
///**
// *	@brief		Received when the user taps on a image in the editor.
// *
// *	@param		editorView	The editor view.
// *	@param		imageId		The id of image of the image that was tapped.
// *	@param		url			The url of the image that was tapped.
// *
// */
//- (void)editorViewController:(ZSSRichTextEditor*)editorViewController
//                 imageTapped:(NSString *)imageId
//                         url:(NSURL *)url;
//
///**
// *	@brief		Received when the local image url is replace by the final image in the editor.
// *
// *	@param		editorView	The editor view.
// *	@param		imageId		The id of image of the image that was tapped.
// */
//- (void)editorViewController:(ZSSRichTextEditor*)editorViewController
//               imageReplaced:(NSString *)imageId;


@end


/**
 *  The viewController used with ZSSRichTextEditor
 */
@interface ZSSRichTextEditor : UIViewController <UIWebViewDelegate, HRColorPickerViewControllerDelegate, UITextViewDelegate>


@property (nonatomic, weak) id<ZSSRichTextEditorDelegate> delegate;

/**
 *  The base URL to use for the webView
 */
@property (nonatomic, strong) NSURL *baseURL;

/**
 *  If the HTML should be formatted to be pretty
 */
@property (nonatomic) BOOL formatHTML;

/**
 *  If the keyboard should be shown when the editor loads
 */
@property (nonatomic) BOOL shouldShowKeyboard;

/**
 *  The placeholder text to use if there is no editor content
 */
@property (nonatomic, strong) NSString *placeholder;

/**
 *  CustomToolbar
 */
@property (strong, readonly) UIView *toolbarHolder;

/**
 *  accessoryToolbar items
 */
@property (strong, readonly) NSArray *accessoryToolbarItems;

/**
 *  Color to tint the toolbar items
 */
@property (nonatomic, strong) UIColor *toolbarItemTintColor;

/**
 *  Color to tint selected items
 */
@property (nonatomic, strong) UIColor *toolbarItemSelectedTintColor;

/**
 *  Sets the HTML for the entire editor
 *
 *  @param html  HTML string to set for the editor
 *
 */
- (void)setHTML:(NSString *)html;

/**
 *  Returns the HTML from the Rich Text Editor
 *
 */
- (NSString *)getHTML;

/**
 *  Returns the plain text from the Rich Text Editor
 *
 */
- (NSString *)getText;

/**
 *  Inserts HTML at the caret position
 *
 *  @param html  HTML string to insert
 *
 */
- (void)insertHTML:(NSString *)html;

/**
 *  Manually focuses on the text editor
 */
- (void)focusTextEditor;

/**
 *  Manually dismisses on the text editor
 */
- (void)blurTextEditor;

/**
 *  Setup Toobar
 *
 *  @param holder inputAccessoryView
 *  @param items  ZSSBarButtonItem items
 */
- (void)setupToolbarHolder:(UIView *)toolbarHolder withItems:(NSArray *)items;

/**
 *  Call before Insert image or link
 */
- (void)prepareForInsert;

/**
 *  Shows the insert image dialog with optinal inputs
 *
 *  @param url The URL for the image
 *  @param alt The alt for the image
 */
- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt;

/**
 *  Inserts an image
 *
 *  @param url The URL for the image
 *  @param alt The alt attribute for the image
 */
- (void)insertImage:(NSString *)url alt:(NSString *)alt;

/**
 *  Shows the insert link dialog with optional inputs
 *
 *  @param url   The URL for the link
 *  @param title The tile for the link
 */
- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title;

/**
 *  Inserts a link
 *
 *  @param url The URL for the link
 *  @param title The title for the link
 */
- (void)insertLink:(NSString *)url title:(NSString *)title;

/**
 *  Gets called when the insert URL picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertURLAlternatePicker;

/**
 *  Gets called when the insert Image picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertImageAlternatePicker;

/**
 *  Dismisses the current AlertView
 */
- (void)dismissAlertView;


@end