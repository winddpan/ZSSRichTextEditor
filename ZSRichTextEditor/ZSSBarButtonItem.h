//
//  ZSSBarButtonItem.h
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 12/3/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZSSBarButtonItem : UIBarButtonItem

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) BOOL selected;

- (void)setTintColor:(UIColor *)tintColor forState:(UIControlState)state;

@end
