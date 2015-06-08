//
//  CSEditorViewController.m
//  ZSSRichTextEditor
//
//  Created by Pan Xiao Ping on 15/5/11.
//  Copyright (c) 2015年 Zed Said Studio. All rights reserved.
//

#import "CSEditorViewController.h"
#import "CSEditorToobarHolder.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CSEditorViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation CSEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Large";
    self.delegate = self;
    //self.shouldShowKeyboard = YES;
    
    CSEditorToobarHolder *toolbar = [[CSEditorToobarHolder alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self setupToolbarHolder:toolbar withItems:toolbar.items];
    
    [toolbar.insertImageItem setTarget:self];
    [toolbar.insertImageItem setAction:@selector(insertImage:)];
    
    // HTML Content to set in the editor
    NSString *html = @"<h1>Large Editor</h1>"
    //"<img src=\"http://g.hiphotos.baidu.com/image/w%3D2048/sign=ce557a47347adab43dd01c43bfecb21c/503d269759ee3d6d63b74ea441166d224f4ade68.jpg\"/>"
    "<img src=\"http://d.youth.cn/tpxw_35291/201505/W020150503294863773411.jpg\"/>"
    "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam at enim at nibh pulvinar sagittis eu non lacus. Quisque suscipit tempor urna vel pretium. Curabitur id enim auctor, cursus elit ac, porttitor sem. Ut suscipit purus odio, vitae sollicitudin sapien placerat in. Duis adipiscing urna id viverra tincidunt. Duis sit amet adipiscing justo, vitae facilisis ipsum. Vivamus scelerisque justo ut libero dictum, id tempor ipsum tempus. Nam nec dui dapibus, tristique dolor et, sollicitudin enim. Nullam sagittis arcu tortor, mollis porta mi laoreet ac. Proin lobortis bibendum urna, in ultrices dolor hendrerit quis. Morbi felis quam, luctus nec suscipit porttitor, lacinia vitae velit. Nulla ultricies pellentesque porta. <strong>Suspendisse suscipit sagittis metus non rhoncus</strong>.</p>";
    
    // Set the HTML contents of the editor
    [self setHTML:html];
 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableURLRequest *r = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://g.hiphotos.baidu.com/image/w%3D2048/sign=ce557a47347adab43dd01c43bfecb21c/503d269759ee3d6d63b74ea441166d224f4ade68.jpg"]];
        NSCachedURLResponse *cache = [[NSURLCache sharedURLCache] cachedResponseForRequest:r];
        NSData *data = cache.data;
        UIImage *image = [[UIImage alloc] initWithData:data];
        NSLog(@"cache:%@", image);

    });
}

- (void)insertImage:(ZSSBarButtonItem *)item
{
    [self showPhotoPicker];
}

- (void)showPhotoPicker
{
    [self prepareForInsert];
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.navigationBar.translucent = NO;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        NSURL *assetURL = info[UIImagePickerControllerReferenceURL];
        [self addAssetToContent:assetURL];
    }];
}

- (void)addAssetToContent:(NSURL *)assetURL
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        
        if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
            //[self addVideoAssetToContent:asset];
        } if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
            [self addImageAssetToContent:asset];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to insert media: %@", [error localizedDescription]);
    }];
}

- (void)addImageAssetToContent:(ALAsset *)asset
{
    UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
    NSData *data = UIImageJPEGRepresentation(image, 0.7);
    NSString *imageID = [[NSUUID UUID] UUIDString];
    NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:imageID] stringByAppendingString:@".jpg"];
    [data writeToFile:path atomically:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self insertImage:[[NSURL fileURLWithPath:path] absoluteString] alt:@""];
        //[self.editorView insertLocalImage:[[NSURL fileURLWithPath:path] absoluteString] uniqueId:imageID];
    });
    
//    NSProgress *progress = [[NSProgress alloc] initWithParent:nil userInfo:@{ @"imageID": imageID,
//                                                                              @"url": path }];
//    progress.cancellable = YES;
//    progress.totalUnitCount = 100;
//    [NSTimer scheduledTimerWithTimeInterval:0.1
//                                     target:self
//                                   selector:@selector(timerFireMethod:)
//                                   userInfo:progress
//                                    repeats:YES];
//    self.mediaAdded[imageID] = progress;
}

- (void)editorViewController:(ZSSRichTextEditor *)editorController didSelectedImageURL:(NSString *)imageURL withMeta:(NSDictionary *)imageMeta
{
    NSLog(@"meta:%@", imageMeta);
//    NSString *html = [self getHTML];
//    NSString *pattern = @"<img[^>]+src=\"([^\">]+)";
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
//    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
//    
//    NSMutableArray *allImageURLs = [NSMutableArray arrayWithCapacity:matches.count];
//    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
//        NSRange matchRange = [match range];
//        NSString *imageURL = [html substringWithRange:matchRange];
//        NSRange r = [imageURL rangeOfString:@"src=\""];
//        imageURL = [imageURL substringFromIndex:r.location + r.length];
//        [allImageURLs addObject:imageURL];
//    }];
//    NSLog(@"allImageURLs:%@", allImageURLs);
//
//    NSMutableArray *photos = [NSMutableArray array];
//    [allImageURLs enumerateObjectsUsingBlock:^(NSString *url, NSUInteger idx, BOOL *stop) {
//        NSURLRequest *r = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//        NSCachedURLResponse *cache = [[NSURLCache sharedURLCache] cachedResponseForRequest:r];
//        
//        CSPhotoObj *obj = [[CSPhotoObj alloc] init];
//        obj.url = url;
//        obj.image = [[UIImage alloc] initWithData:cache.data scale:0];
//        [photos addObject:obj];
//    }];
//    
//    NSURLRequest *r = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
//    NSCachedURLResponse *cache = [[NSURLCache sharedURLCache] cachedResponseForRequest:r];
//    UIImage *image = [[UIImage alloc] initWithData:cache.data scale:0];
//
//    CGRect fromRect = CGRectMake([imageMeta[@"x"] integerValue], [imageMeta[@"y"] integerValue] + 64, [imageMeta[@"width"] integerValue], [imageMeta[@"height"] integerValue]);
//    
//    CSPhotoBrowserController *broswer = [[CSPhotoBrowserController alloc] init];
//    broswer.photos = photos;
//    broswer.currentIndex = [allImageURLs indexOfObject:imageURL];
//    [broswer showFromWindowRect:fromRect withThumbImage:image];
}

@end
