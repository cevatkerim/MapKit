//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;


-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
    NSDictionary *options = [[NSDictionary alloc] init];
    [self createViewWithOptions:options];
}

- (void)createViewWithOptions:(NSDictionary *)options {

    //This is the Designated Initializer

    // defaults
    float height = ([options objectForKey:@"height"]) ? [[options objectForKey:@"height"] floatValue] : self.webView.bounds.size.height/2;
    float width = ([options objectForKey:@"width"]) ? [[options objectForKey:@"width"] floatValue] : self.webView.bounds.size.width;
    float x = self.webView.bounds.origin.x;
    float y = self.webView.bounds.origin.y;
    BOOL atBottom = ([options objectForKey:@"atBottom"]) ? [[options objectForKey:@"atBottom"] boolValue] : NO;
    BOOL startHidden = ([options objectForKey:@"startHidden"]) ? [[options objectForKey:@"startHidden"] boolValue] : NO;

    if(atBottom) {
        y += self.webView.bounds.size.height - height;
    }
    
    if(startHidden)
    {
        y -= self.webView.bounds.size.height;
    }

    self.childView = [[UIView alloc] initWithFrame:CGRectMake(x,y,width,height)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(self.childView.bounds.origin.x, self.childView.bounds.origin.x, self.childView.bounds.size.width, self.childView.bounds.size.height)];
    self.mapView.delegate = self;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
	self.mapView.showsUserLocation = YES;
	self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;


    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
	CLLocationDistance diameter = [[options objectForKey:@"diameter"] floatValue];

	MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord,
                                                                                                diameter*(height / self.webView.bounds.size.width),
                                                                                                diameter*(height / self.webView.bounds.size.width))];
    
    [self.mapView setRegion:region animated:YES];
	[self.childView addSubview:self.mapView];

	[ [ [ self viewController ] view ] addSubview:self.childView];

    if(startHidden == YES)
    {
        self.mapView.showsUserLocation = NO;
        self.childView.hidden = YES;
    }
}
- (void)destroyMap:(CDVInvokedUrlCommand *)command
{
	if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];

		mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
		//[ self.imageButton removeTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
		self.imageButton = nil;

	}
	if(self.childView)
	{
		[ self.childView removeFromSuperview];
		self.childView = nil;
	}
    self.buttonCallback = nil;
}

- (void)clearMapPins:(CDVInvokedUrlCommand *)command
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)addMapPins:(CDVInvokedUrlCommand *)command
{

    NSArray *pins = command.arguments[0];

  for (int y = 0; y < pins.count; y++)
    {
        NSDictionary *pinData = [pins objectAtIndex:y];
		CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
		NSString *title=[[pinData valueForKey:@"title"] description];
		NSString *subTitle=[[pinData valueForKey:@"snippet"] description];
		NSInteger index=[[pinData valueForKey:@"index"] integerValue];
		BOOL selected = [[pinData valueForKey:@"selected"] boolValue];

        NSString *pinColor = nil;
        NSString *imageURL = nil;

        if([[pinData valueForKey:@"icon"] isKindOfClass:[NSNumber class]])
        {
            pinColor = [[pinData valueForKey:@"icon"] description];
        }
        else if([[pinData valueForKey:@"icon"] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *iconOptions = [pinData valueForKey:@"icon"];
            pinColor = [[iconOptions valueForKey:@"pinColor" ] description];
            imageURL=[[iconOptions valueForKey:@"resource"] description];
        }

		CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle imageURL:imageURL];
		annotation.pinColor=pinColor;
		annotation.selected = selected;

		[self.mapView addAnnotation:annotation];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
	}

}

-(void)showMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView)
	{
        [self createViewWithOptions:command.arguments[0]];
	}
    
	self.childView.hidden = NO;
	self.mapView.showsUserLocation = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


- (void)hideMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES) 
	{
		return;
	}
	// disable location services, if we no longer need it.
	self.mapView.showsUserLocation = NO;
	self.childView.hidden = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)changeMapType:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
	{
		return;
	}

    int mapType = ([command.arguments[0] objectForKey:@"mapType"]) ? [[command.arguments[0] objectForKey:@"mapType"] intValue] : 0;

    switch (mapType) {
        case 4:
            [self.mapView setMapType:MKMapTypeHybrid];
            break;
        case 2:
            [self.mapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [self.mapView setMapType:MKMapTypeStandard];
            break;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

//Might need this later?
/*- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;

    [self.mapView setRegion:mapRegion animated: YES];
}


- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated
{
    NSLog(@"region did change animated");
    float currentLat = theMapView.region.center.latitude;
    float currentLon = theMapView.region.center.longitude;
    float latitudeDelta = theMapView.region.span.latitudeDelta;
    float longitudeDelta = theMapView.region.span.longitudeDelta;

    NSString* jsString = nil;
    jsString = [[NSString alloc] initWithFormat:@"geo.onMapMove(\'%f','%f','%f','%f\');", currentLat,currentLon,latitudeDelta,longitudeDelta];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    [jsString autorelease];
}
 */


- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation {
  
  if ([annotation class] != CDVAnnotation.class) {
    return nil;
  }

	CDVAnnotation *phAnnotation=(CDVAnnotation *) annotation;
	NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];

	MKPinAnnotationView *annView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];

	if (annView!=nil) return annView;

	annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];

	annView.animatesDrop=YES;
	annView.canShowCallout = YES;
	if ([phAnnotation.pinColor isEqualToString:@"120"])
		annView.pinColor = MKPinAnnotationColorGreen;
	else if ([phAnnotation.pinColor isEqualToString:@"270"])
		annView.pinColor = MKPinAnnotationColorPurple;
	else
		annView.pinColor = MKPinAnnotationColorRed;

	AsyncImageView* asyncImage = [[AsyncImageView alloc] initWithFrame:CGRectMake(0,0, 50, 32)];
	asyncImage.tag = 999;
	if (phAnnotation.imageURL)
	{
		NSURL *url = [[NSURL alloc] initWithString:phAnnotation.imageURL];
		[asyncImage loadImageFromURL:url];
	} 
	else 
	{
		[asyncImage loadDefaultImage];
	}

	annView.leftCalloutAccessoryView = asyncImage;


	if (self.buttonCallback && phAnnotation.index!=-1)
	{

		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		myDetailButton.tag=phAnnotation.index;
		annView.rightCalloutAccessoryView = myDetailButton;
		[ myDetailButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

	}

	if(phAnnotation.selected)
	{
		[self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
	}

	return annView;
}

-(void)openAnnotation:(id <MKAnnotation>) annotation
{
	[ self.mapView selectAnnotation:annotation animated:YES];  
	
}

- (void) checkButtonTapped:(id)button 
{
	UIButton *tmpButton = button;
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
	[self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void) renderMapViewToImage:(CDVInvokedUrlCommand*)command
{
    NSLog(@"renderMapViewToImage");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = self.mapView.region;
    options.scale = [UIScreen mainScreen].scale;
    
    CGSize size;
    size.width = 320;
    size.height= 100;
    options.size = size;
    
    //options.size = self.mapView.frame.size; //error on ios simulator
    
    
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    __block MapKitView *blockSafeSelf = self;
    
    [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        
        NSLog(@"Queued Function");
        
        //Cordova stuff
        CDVPluginResult* pluginResult;
        
        
        // string to hold encoded image
        NSString *base64image;
        
        // get the image associated with the snapshot
        
        UIImage *image = snapshot.image;
        
        // Get the size of the final image
        
        CGRect finalImageRect = CGRectMake(0, 0, image.size.width, image.size.height);
        
        // Get a standard annotation view pin. Clearly, Apple assumes that we'll only want to draw standard annotation pins!
        
        MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
        UIImage *pinImage = pin.image;
        
        // ok, let's start to create our final image
        
        UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
        
        // first, draw the image from the snapshotter
        
        [image drawAtPoint:CGPointMake(0, 0)];
        
        // now, let's iterate through the annotations and draw them, too
        
        for (id<MKAnnotation>annotation in self.mapView.annotations)
        {
            CGPoint point = [snapshot pointForCoordinate:annotation.coordinate];
            if (CGRectContainsPoint(finalImageRect, point)) // this is too conservative, but you get the idea
            {
                CGPoint pinCenterOffset = pin.centerOffset;
                point.x -= pin.bounds.size.width / 2.0;
                point.y -= pin.bounds.size.height / 2.0;
                point.x += pinCenterOffset.x;
                point.y += pinCenterOffset.y;
                
                [pinImage drawAtPoint:point];
            }
        }
        
        // grab the final image
        
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // and save it
        
        //NSData *data = UIImagePNGRepresentation(finalImage);
        
        
        
        base64image = [UIImagePNGRepresentation(finalImage) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64image];
        
        
    
        //return @"test";
        
        //[data writeToFile:[documentsDirectoryPath stringByAppendingPathComponent:@"map.png"] atomically:YES];
        
        NSLog(@"Wrote Image to callback");
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}




- (void)dealloc
{
    if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];
        self.mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
        self.imageButton = nil;
	}
	if(childView)
	{
		[ self.childView removeFromSuperview];
        self.childView = nil;
	}
    self.buttonCallback = nil;
}

@end
