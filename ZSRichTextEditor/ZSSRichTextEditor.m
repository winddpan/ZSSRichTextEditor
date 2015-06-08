//
//  ZSSRichTextEditorViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ZSSRichTextEditor.h"
#import "ZSSBarButtonItem.h"
#import "HRColorUtil.h"
#import "ZSSTextView.h"
#import "UIWebView+GUIFixes.h"

@interface ZSSRichTextEditor ()
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSString *htmlString;
@property (nonatomic, strong) ZSSTextView *sourceView;
@property (nonatomic) CGRect editorViewFrame;
@property (nonatomic) BOOL resourcesLoaded;
@property (nonatomic, strong) NSArray *editorItemsEnabled;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSString *selectedLinkURL;
@property (nonatomic, strong) NSString *selectedLinkTitle;
@property (nonatomic, strong) NSString *internalHTML;
@property (nonatomic, strong) NSString *originHTML;
@property (nonatomic) BOOL editorLoaded;
@property (nonatomic) NSInteger lastEditorHeight;

- (NSString *)removeQuotesFromHTML:(NSString *)html;
- (NSString *)tidyHTML:(NSString *)html;
- (void)enableToolbarItems:(BOOL)enable;

- (void)didSelectedImageURL:(NSString *)imageURL
                   withMeta:(NSDictionary *)imageMeta;
- (void)didSelectedLinkURL:(NSString *)linkURL
                 withTitle:(NSString *)title;
- (void)didScrollWithPosition:(NSInteger)position;
@end

@implementation ZSSRichTextEditor

//ZSSRichTextEditorSubProtocol
- (void)didScrollWithPosition:(NSInteger)position {}
- (void)didSelectedImageURL:(NSString *)imageURL withMeta:(NSDictionary *)imageMeta {}
- (void)didSelectedLinkURL:(NSString *)linkURL withTitle:(NSString *)title {}

- (void)dealloc {
    [self.editorView.scrollView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)initialize {
    self.editable = YES;
    self.editorLoaded = NO;
    self.shouldShowKeyboard = NO;
    self.formatHTML = YES;
    self.baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Source View
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.sourceView = [[ZSSTextView alloc] initWithFrame:frame];
    self.sourceView.hidden = YES;
    self.sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.sourceView.font = [UIFont fontWithName:@"Courier" size:13.0];
    self.sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.sourceView.autoresizesSubviews = YES;
    self.sourceView.delegate = self;
    [self.view addSubview:self.sourceView];
    
    // Editor View
    self.editorView = [[UIWebView alloc] initWithFrame:frame];
    self.editorView.delegate = self;
    self.editorView.scalesPageToFit = YES;
    self.editorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.editorView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.editorView.backgroundColor = [UIColor whiteColor];
    self.editorView.opaque = NO;
    self.editorView.scrollView.bounces = NO;
    self.editorView.usesGUIFixes = YES;
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    self.editorView.scrollView.bounces = YES;
    [self.view addSubview:self.editorView];
    
    [self.editorView.scrollView addObserver:self
                          forKeyPath:@"contentSize"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
    
    if (!self.resourcesLoaded) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"editor" ofType:@"html"];
        NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
        NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
        [self.editorView loadHTMLString:htmlString baseURL:self.baseURL];
        self.resourcesLoaded = YES;
    }
    
}

- (void)setPlaceholderText {
    
    NSString *js = [NSString stringWithFormat:@"zss_editor.setPlaceholder(\"%@\");", self.placeholder];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
    
}

- (void)setContentHeight:(float)contentHeight {
    
    NSString *js = [NSString stringWithFormat:@"zss_editor.contentHeight = %f;", contentHeight];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setupToolbarHolder:(UIView *)toolbarHolder withItems:(NSArray *)items
{
    _toolbarHolder = toolbarHolder;
    _accessoryToolbarItems = items;
    
    [self buildToolbar];
}

- (void)buildToolbar {
    
    // init toolbarItem selector
    NSDictionary *selectorDictionary = @{ ZSSRichTextEditorToolbarBold : @"setBold",
                                          ZSSRichTextEditorToolbarItalic : @"setItalic",
                                          ZSSRichTextEditorToolbarSubscript : @"setSubscript",
                                          ZSSRichTextEditorToolbarSuperscript : @"setSuperscript",
                                          ZSSRichTextEditorToolbarStrikeThrough : @"setStrikethrough",
                                          ZSSRichTextEditorToolbarUnderline : @"setUnderline",
                                          ZSSRichTextEditorToolbarRemoveFormat : @"removeFormat",
                                          ZSSRichTextEditorToolbarJustifyLeft : @"alignLeft",
                                          ZSSRichTextEditorToolbarJustifyCenter : @"alignCenter",
                                          ZSSRichTextEditorToolbarJustifyRight : @"alignRight",
                                          ZSSRichTextEditorToolbarJustifyFull : @"alignFull",
                                          ZSSRichTextEditorToolbarH1 : @"heading1",
                                          ZSSRichTextEditorToolbarH2 : @"heading2",
                                          ZSSRichTextEditorToolbarH3 : @"heading3",
                                          ZSSRichTextEditorToolbarH4 : @"heading4",
                                          ZSSRichTextEditorToolbarH5 : @"heading5",
                                          ZSSRichTextEditorToolbarH6 : @"heading6",
                                          ZSSRichTextEditorToolbarTextColor : @"textColor",
                                          ZSSRichTextEditorToolbarBackgroundColor : @"bgColor",
                                          ZSSRichTextEditorToolbarUnorderedList : @"setUnorderedList",
                                          ZSSRichTextEditorToolbarOrderedList : @"setOrderedList",
                                          ZSSRichTextEditorToolbarHorizontalRule : @"setHR",
                                          ZSSRichTextEditorToolbarIndent : @"setIndent",
                                          ZSSRichTextEditorToolbarOutdent : @"setOutdent",
                                          ZSSRichTextEditorToolbarInsertImage : @"insertImage",
                                          ZSSRichTextEditorToolbarInsertLink : @"insertLink",
                                          ZSSRichTextEditorToolbarRemoveLink : @"removeLink",
                                          ZSSRichTextEditorToolbarQuickLink : @"quickLink",
                                          ZSSRichTextEditorToolbarUndo : @"undo:",
                                          ZSSRichTextEditorToolbarRedo : @"redo:",
                                          ZSSRichTextEditorToolbarViewSource : @"showHTMLSource:",
                                          ZSSRichTextEditorToolbarParagraph : @"paragraph",
                                          ZSSRichTextEditorToolbarHideKeyboard : @"dismissKeyboard",
                                          };
    
    [self.accessoryToolbarItems enumerateObjectsUsingBlock:^(ZSSBarButtonItem *item, NSUInteger idx, BOOL *stop) {
        if ([item isKindOfClass:ZSSBarButtonItem.class] && [selectorDictionary.allKeys containsObject:item.identifier]) {
            [item setTarget:self];
            [item setAction:NSSelectorFromString(selectorDictionary[item.identifier])];
        }
    }];

    for (ZSSBarButtonItem *item in self.accessoryToolbarItems) {
        item.selected = NO;
    }
    
    self.editorView.customInputAccessoryView = self.toolbarHolder;
    self.sourceView.inputAccessoryView = self.toolbarHolder;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshVisibleViewportAndContentSize
{
    NSString *newTopString = [self.editorView stringByEvaluatingJavaScriptFromString:@"$(zss_editor_content).offset().top;"];
    NSString *newHeightString = [self.editorView stringByEvaluatingJavaScriptFromString:@"$(zss_editor_content).height();"];
    CGFloat newHeight = [newTopString integerValue] + [newHeightString integerValue] + 20;
    
    self.lastEditorHeight = newHeight;
    self.editorView.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.editorView.frame),  newHeight);
}

#pragma mark - Editor Interaction

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    
    NSString *js = [NSString stringWithFormat:@"document.getElementById('zss_editor_content').setAttribute('contenteditable','%@')", editable ? @"true" : @"false"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)focusTextEditor {
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    NSString *js = [NSString stringWithFormat:@"zss_editor.focusEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)blurTextEditor {
    NSString *js = [NSString stringWithFormat:@"zss_editor.blurEditor();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
}

- (void)setHTML:(NSString *)html {
    
    self.internalHTML = html;
    
    if (self.editorLoaded) {
        [self updateHTML];
    }
}

- (void)updateHTML {
    
    NSString *html = self.internalHTML ?: @"";
    self.sourceView.text = html;
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.setHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (NSString *)getHTML {
    NSString *html = [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getHTML();"];
    html = [self removeQuotesFromHTML:html];
    html = [self tidyHTML:html];
    return html;
}

- (void)insertHTML:(NSString *)html {
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (BOOL)didContentChanged {
    return ![_originHTML isEqualToString:[self getHTML]];
}

- (NSString *)getText {
    return [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.getText();"];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (BOOL)isEditing {
    NSString *str = [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.hasFocus();"];
    return [str isEqualToString:@"true"];
}

- (void)showHTMLSource:(ZSSBarButtonItem *)barButtonItem {
    if (self.sourceView.hidden) {
        self.sourceView.text = [self getHTML];
        self.sourceView.hidden = NO;
        barButtonItem.tintColor = [UIColor blackColor];
        self.editorView.hidden = YES;
        [self enableToolbarItems:NO];
    } else {
        [self setHTML:self.sourceView.text];
        barButtonItem.selected = NO;
        self.sourceView.hidden = YES;
        self.editorView.hidden = NO;
        [self enableToolbarItems:YES];
    }
}

- (void)removeFormat {
    NSString *trigger = @"zss_editor.removeFormating();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignLeft {
    NSString *trigger = @"zss_editor.setJustifyLeft();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignCenter {
    NSString *trigger = @"zss_editor.setJustifyCenter();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignRight {
    NSString *trigger = @"zss_editor.setJustifyRight();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)alignFull {
    NSString *trigger = @"zss_editor.setJustifyFull();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setBold {
    NSString *trigger = @"zss_editor.setBold();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setItalic {
    NSString *trigger = @"zss_editor.setItalic();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSubscript {
    NSString *trigger = @"zss_editor.setSubscript();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnderline {
    NSString *trigger = @"zss_editor.setUnderline();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setSuperscript {
    NSString *trigger = @"zss_editor.setSuperscript();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setStrikethrough {
    NSString *trigger = @"zss_editor.setStrikeThrough();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setUnorderedList {
    NSString *trigger = @"zss_editor.setUnorderedList();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOrderedList {
    NSString *trigger = @"zss_editor.setOrderedList();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setHR {
    NSString *trigger = @"zss_editor.setHorizontalRule();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setIndent {
    NSString *trigger = @"zss_editor.setIndent();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)setOutdent {
    NSString *trigger = @"zss_editor.setOutdent();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading1 {
    NSString *trigger = @"zss_editor.setHeading('h1');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading2 {
    NSString *trigger = @"zss_editor.setHeading('h2');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading3 {
    NSString *trigger = @"zss_editor.setHeading('h3');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading4 {
    NSString *trigger = @"zss_editor.setHeading('h4');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading5 {
    NSString *trigger = @"zss_editor.setHeading('h5');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)heading6 {
    NSString *trigger = @"zss_editor.setHeading('h6');";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)paragraph {
    NSString *trigger = @"zss_editor.setParagraph();";
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)textColor {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 1;
    colorPicker.title = NSLocalizedString(@"Text Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
    
}

- (void)bgColor {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 2;
    colorPicker.title = NSLocalizedString(@"BG Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
    
}

- (void)setSelectedColor:(UIColor*)color tag:(int)tag {
    
    NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
    NSString *trigger;
    if (tag == 1) {
        trigger = [NSString stringWithFormat:@"zss_editor.setTextColor(\"%@\");", hex];
    } else if (tag == 2) {
        trigger = [NSString stringWithFormat:@"zss_editor.setBackgroundColor(\"%@\");", hex];
    }
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (void)undo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.undo();"];
}

- (void)redo:(ZSSBarButtonItem *)barButtonItem {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.redo();"];
}

- (void)insertLink {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    // Show the dialog for inserting or editing a link
    [self showInsertLinkDialogWithLink:self.selectedLinkURL title:self.selectedLinkTitle];
    
}


- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedLinkURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png"] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertURLAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Title", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (title) {
                textField.text = title;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *linkURL = [alertController.textFields objectAtIndex:0];
            UITextField *title = [alertController.textFields objectAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
                NSLog(@"insert link");
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
            [self focusTextEditor];
        }]];
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 2;
        UITextField *linkURL = [self.alertView textFieldAtIndex:0];
        linkURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            linkURL.text = url;
        }
        
        linkURL.rightView = am;
        linkURL.rightViewMode = UITextFieldViewModeAlways;
        
        UITextField *alt = [self.alertView textFieldAtIndex:1];
        alt.secureTextEntry = NO;
        alt.placeholder = NSLocalizedString(@"Title", nil);
        if (title) {
            alt.text = title;
        }
        
        [self.alertView show];
    }
    
}


- (void)insertLink:(NSString *)url title:(NSString *)title {
    
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}


- (void)updateLink:(NSString *)url title:(NSString *)title {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateLink(\"%@\", \"%@\");", url, title];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)dismissAlertView {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:YES];
}

- (void)removeLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.unlink();"];
}//end

- (void)quickLink {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.quickLink();"];
}

- (void)insertImage {
    
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
    
    [self showInsertImageDialogWithLink:nil alt:nil];
    
}

- (void)prepareForInsert {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.prepareInsert();"];
}

- (void)finishedInsert {
    [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.finishedInsert();"];
}

- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt {
    
    // Insert Button Title
    NSString *insertButtonTitle = NSLocalizedString(@"Insert", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png"] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertImageAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Alt", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (alt) {
                textField.text = alt;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *imageURL = [alertController.textFields objectAtIndex:0];
            UITextField *alt = [alertController.textFields objectAtIndex:1];
            [self insertImage:imageURL.text alt:alt.text];
            [self focusTextEditor];
        }]];
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 1;
        UITextField *imageURL = [self.alertView textFieldAtIndex:0];
        imageURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            imageURL.text = url;
        }
        
        imageURL.rightView = am;
        imageURL.rightViewMode = UITextFieldViewModeAlways;
        imageURL.clearButtonMode = UITextFieldViewModeAlways;
        
        UITextField *alt1 = [self.alertView textFieldAtIndex:1];
        alt1.secureTextEntry = NO;
        alt1.placeholder = NSLocalizedString(@"Alt", nil);
        alt1.clearButtonMode = UITextFieldViewModeAlways;
        if (alt) {
            alt1.text = alt;
        }
        
        [self.alertView show];
    }
    
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.insertImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}


- (void)updateImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"zss_editor.updateImage(\"%@\", \"%@\");", url, alt];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
}

- (void)updateToolBarWithButtonName:(NSString *)name {
    
    NSString *selectedImageURL = nil;

    // Items that are enabled
    NSArray *itemNames = [name componentsSeparatedByString:@","];
    
    // Special case for link
    NSMutableArray *itemsModified = [[NSMutableArray alloc] init];
    for (NSString *linkItem in itemNames) {
        NSString *updatedItem = linkItem;
        if ([linkItem hasPrefix:@"link:"]) {
            updatedItem = @"link";
            self.selectedLinkURL = [linkItem stringByReplacingOccurrencesOfString:@"link:" withString:@""];
        } else if ([linkItem hasPrefix:@"link-title:"]) {
            self.selectedLinkTitle = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"link-title:" withString:@""]];
        } else if ([linkItem hasPrefix:@"image:"]) {
            updatedItem = @"image";
            selectedImageURL = [linkItem stringByReplacingOccurrencesOfString:@"image:" withString:@""];
        } else if ([linkItem hasPrefix:@"image-alt:"]) {
            //self.selectedImageAlt = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"image-alt:" withString:@""]];
        } else {
            self.selectedLinkURL = nil;
            self.selectedLinkTitle = nil;
        }
        [itemsModified addObject:updatedItem];
    }
    
    if (selectedImageURL) {
        NSMutableDictionary *meta = [NSMutableDictionary dictionary];
        [itemNames enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx, BOOL *stop) {
            NSArray *p = [item componentsSeparatedByString:@":"];
            if (p.count >= 2) {
                NSMutableArray *temp = [NSMutableArray arrayWithArray:p];
                [temp removeObjectAtIndex:0];
                [meta setObject:[temp componentsJoinedByString:@":"] forKey:p[0]];
            }
        }];
        [self didSelectedImageURL:selectedImageURL withMeta:meta];
        if ([self.delegate respondsToSelector:@selector(editorViewController:didSelectedImageURL:withMeta:)]) {
            [self.delegate editorViewController:self didSelectedImageURL:selectedImageURL withMeta:meta];
        }
    }
    if (self.selectedLinkURL && [self.delegate respondsToSelector:@selector(editorViewController:didSelectedLinkURL:withTitle:)]) {
        [self didSelectedLinkURL:self.selectedLinkURL withTitle:self.selectedLinkTitle];
        [self.delegate editorViewController:self didSelectedLinkURL:self.selectedLinkURL withTitle:self.selectedLinkTitle];
    }
    
    itemNames = [NSArray arrayWithArray:itemsModified];
    self.editorItemsEnabled = itemNames;
    
    // Highlight items
    NSArray *items = self.accessoryToolbarItems;
    for (ZSSBarButtonItem *item in items) {
        if ([itemNames containsObject:item.identifier]) {
            item.selected = YES;
        } else {
            item.selected = NO;
        }
    }//end
}

#pragma mark - UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView {
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}


#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *urlString = [[request URL] absoluteString];
    NSLog(@"web request - %@", urlString);

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    } else if ([urlString rangeOfString:@"callback://0/"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *className = [urlString stringByReplacingOccurrencesOfString:@"callback://0/" withString:@""];
        [self updateToolBarWithButtonName:className];
    }
#ifdef DEBUG
    else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        NSLog(@"%@", debug);
    }
#endif
    else if ([urlString rangeOfString:@"scroll://"].location != NSNotFound) {
        NSInteger position = [[urlString stringByReplacingOccurrencesOfString:@"scroll://" withString:@""] integerValue];
        [self didScrollWithPosition:position];
    }
    else if ([urlString rangeOfString:@"input://"].location != NSNotFound ) {
        [self refreshVisibleViewportAndContentSize];
        [self scrollToCaretAnimated:NO];
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.editorLoaded = YES;
    //[self setPlaceholderText];
    [self updateHTML];
    
    //首次载入html后，提取一次作为原始html，用作修改判定
    if(!_originHTML) {
        _originHTML = [self getHTML];
    }
    
    if (self.navigationController.navigationBar.translucent) {
        CGFloat topBarOffset = self.topLayoutGuide.length;
        webView.scrollView.contentInset = UIEdgeInsetsMake(topBarOffset, 0, 0, 0);
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(topBarOffset, 0, 0, 0);
    }
    
    if ([self.delegate respondsToSelector:@selector(editorTextDidLoaded:)]) {
        [self.delegate editorTextDidLoaded:self];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.shouldShowKeyboard) {
            self.editable = _editable;
            if (_editable) {
                [self focusTextEditor];
            }
        }
    });
}


#pragma mark - Scrolling support

- (CGRect)viewport
{
    UIScrollView* scrollView = self.editorView.scrollView;
    
    CGRect viewport;
    
    viewport.origin = scrollView.contentOffset;
    viewport.size = scrollView.bounds.size;
    
    viewport.size.height -= (scrollView.contentInset.top + scrollView.contentInset.bottom);
    viewport.size.width -= (scrollView.contentInset.left + scrollView.contentInset.right);
    
    return viewport;
}

/**
 *  @brief      Scrolls to a position where the caret is visible. This uses the values stored in caretYOffest and lineHeight properties.
 *  @param      animated    If the scrolling shoud be animated  The offset to show.
 */
- (void)scrollToCaretAnimated:(BOOL)animated
{
    NSString *offset = [self.editorView stringByEvaluatingJavaScriptFromString:@"zss_editor.calculateEditorHeightWithCaretPosition()"];
    
    CGRect viewport = [self viewport];
    CGFloat caretYOffset = [offset integerValue];
    CGFloat lineHeight = 21;
    CGFloat offsetBottom = caretYOffset + lineHeight;
    
    BOOL mustScroll = (caretYOffset < viewport.origin.y
                       || offsetBottom > viewport.origin.y + CGRectGetHeight(viewport));
    
    //NSLog(@"viewport:%@ caretY:%f", NSStringFromCGRect(viewport), offsetBottom);

    if (mustScroll) {
        CGFloat necessaryHeight = viewport.size.height / 2;
        caretYOffset = MIN(caretYOffset, self.editorView.scrollView.contentSize.height - necessaryHeight);
        CGRect targetRect = CGRectMake(0.0f,
                                       caretYOffset,
                                       CGRectGetWidth(viewport),
                                       necessaryHeight);
        
        [self.editorView.scrollView scrollRectToVisible:targetRect animated:animated];
    }
}

#pragma mark - AlertView

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    if (alertView.tag == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        if ([textField.text length] == 0 || [textField2.text length] == 0) {
            return NO;
        }
    } else if (alertView.tag == 2) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0) {
            return NO;
        }
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            UITextField *imageURL = [alertView textFieldAtIndex:0];
            UITextField *alt = [alertView textFieldAtIndex:1];
            [self insertImage:imageURL.text alt:alt.text];
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            UITextField *linkURL = [alertView textFieldAtIndex:0];
            UITextField *title = [alertView textFieldAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
        }
    }
    
}


#pragma mark - Asset Picker

- (void)showInsertURLAlternatePicker {
    // Blank method. User should implement this in their subclass
}


- (void)showInsertImageAlternatePicker {
    // Blank method. User should implement this in their subclass
}


#pragma mark - Utilities

- (NSString *)removeQuotesFromHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    html = [html stringByReplacingOccurrencesOfString:@"“" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"”" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    return html;
}//end


- (NSString *)tidyHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"<br />"];
    html = [html stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
    if (self.formatHTML) {
        html = [self.editorView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"style_html(\"%@\");", html]];
    }
    return html;
}//end

- (NSString *)stringByDecodingURLFormat:(NSString *)string {
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}


- (void)enableToolbarItems:(BOOL)enable {
    NSArray *items = self.accessoryToolbarItems;
    for (ZSSBarButtonItem *item in items) {
        if (![item.identifier isEqualToString:ZSSRichTextEditorToolbarViewSource]) {
            item.enabled = enable;
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // IMPORTANT: WORKAROUND: the following code is a fix to prevent the web view from thinking it's
    // taller than it really is.  The problem we were having is that when we were switching the
    // focus from the title field to the content field, the web view was trying to scroll down, and
    // jumping back up.
    //
    // The reason behind the sizing issues is that the web view doesn't really like having insets
    // and wants it's body and content to be as tall as possible.
    //
    // Ref bug: https://github.com/wordpress-mobile/WordPress-iOS-Editor/issues/324
    //
    if (object == self.editorView.scrollView) {
        if ([keyPath isEqualToString:@"contentSize"]) {
            if (!self.editorLoaded) {
                return;
            }
            
            NSValue *newValue = change[NSKeyValueChangeNewKey];
            CGSize newSize = [newValue CGSizeValue];
            if (newSize.height != self.lastEditorHeight) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self refreshVisibleViewportAndContentSize];
                });
            }
        }
    }
}


@end
