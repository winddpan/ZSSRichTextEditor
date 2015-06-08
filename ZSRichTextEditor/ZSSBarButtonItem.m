//
//  ZSSBarButtonItem.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 12/3/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import "ZSSBarButtonItem.h"

@implementation ZSSBarButtonItem
{
    NSMutableDictionary *_tintColorDictionary;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tintColorDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor forState:(UIControlState)state {
    [_tintColorDictionary setObject:tintColor forKey:@(state)];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;

    if (selected && _tintColorDictionary[@(UIControlStateSelected)]) {
        self.tintColor = _tintColorDictionary[@(UIControlStateSelected)];
    }else if (!selected && _tintColorDictionary[@(UIControlStateNormal)]) {
        self.tintColor = _tintColorDictionary[@(UIControlStateNormal)];
    }
}

@end
