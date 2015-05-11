//
//  CSEditorToobar.m
//  ZSSRichTextEditor
//
//  Created by Pan Xiao Ping on 15/5/11.
//  Copyright (c) 2015年 Zed Said Studio. All rights reserved.
//

#import "CSEditorToobarHolder.h"
#import "ZSSRichTextEditor.h"

@implementation CSEditorToobarHolder

- (BOOL)isIpad {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}//end

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self isIpad] ? self.frame.size.width : self.frame.size.width - 44, self.frame.size.height)];
        toolBarScroll.backgroundColor = [UIColor clearColor];
        toolBarScroll.showsHorizontalScrollIndicator = NO;
        toolBarScroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // Toolbar with icons
        toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        toolbar.backgroundColor = [UIColor clearColor];
        [toolBarScroll addSubview:toolbar];
        
        // Background Toolbar
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
        backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:toolBarScroll];
        [self insertSubview:backgroundToolbar atIndex:0];
        
        NSArray *itemStrs = @[ZSSRichTextEditorToolbarBold, ZSSRichTextEditorToolbarItalic,ZSSRichTextEditorToolbarStrikeThrough, ZSSRichTextEditorToolbarUnderline ,ZSSRichTextEditorToolbarUnorderedList,ZSSRichTextEditorToolbarOrderedList, @"CustomInsertImage", ZSSRichTextEditorToolbarUndo, ZSSRichTextEditorToolbarRedo];
        NSArray *itemImgs = @[@"ZSSbold", @"ZSSitalic", @"ZSSstrikethrough", @"ZSSunderline", @"ZSSunorderedlist", @"ZSSorderedlist", @"ZSSimage", @"ZSSundo", @"ZSSredo"];
        
        NSMutableArray *toolbarItems = [NSMutableArray array];
        [itemStrs enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            ZSSBarButtonItem *item = [[ZSSBarButtonItem alloc] init];
            item.width = 44;
            item.image = [UIImage imageNamed:itemImgs[idx]];
            [toolbarItems addObject:item];
            
            NSString *identifier = itemStrs[idx];
            if ([identifier isEqualToString:@"CustomInsertImage"]) {
                _insertImageItem = item;
            } else {
                item.identifier = identifier;
            }
        }];
        [toolbar setItems:toolbarItems animated:NO];
        
        
        // Hide Keyboard
        if (![self isIpad]) {
            
            // Toolbar holder used to crop and position toolbar
            UIView *toolbarCropper = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width-44, 0, 44, 44)];
            toolbarCropper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            toolbarCropper.clipsToBounds = YES;
            
            // Use a toolbar so that we can tint
            UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(-7, -1, 44, 44)];
            [toolbarCropper addSubview:keyboardToolbar];
            
            _keyboardItem = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSkeyboard.png"] style:UIBarButtonItemStylePlain target:nil action:nil];
            self.keyboardItem.identifier = ZSSRichTextEditorToolbarHideKeyboard;
            keyboardToolbar.items = @[self.keyboardItem];
            [self addSubview:toolbarCropper];
            
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.6f, 44)];
            line.backgroundColor = [UIColor lightGrayColor];
            line.alpha = 0.7f;
            [toolbarCropper addSubview:line];
            
            [toolbarItems addObject:self.keyboardItem];
        }
        _items = [toolbarItems copy];
        
        CGFloat toolbarWidth = self.frame.size.width;
        toolbar.frame = CGRectMake(0, 0, toolbarWidth, self.frame.size.height);
        toolBarScroll.contentSize = CGSizeMake(toolbar.frame.size.width, self.frame.size.height);
    }
    return self;
}

@end
