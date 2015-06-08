//
//  CSEditorToobar.h
//  ZSSRichTextEditor
//
//  Created by Pan Xiao Ping on 15/5/11.
//  Copyright (c) 2015年 Zed Said Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZSSBarButtonItem.h"

@interface CSEditorToobarHolder : UIView
{
    UIScrollView *toolBarScroll;
    UIToolbar *toolbar;
}

@property (readonly, strong) ZSSBarButtonItem *keyboardItem;
@property (readonly, strong) ZSSBarButtonItem *insertImageItem;
@property (readonly, strong) NSArray *items;
@end
