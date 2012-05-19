//
//  TapAppViewController.h
//  TapApp
//
//  Created by Hyung-Suk Kim( hskim08@stanford.edu ) on 2/2/11.
//  Copyright 2011 CCRMA, Stanford University. All rights reserved.
/*-----------------------------------------------------------------------------
 This code is distributed under the following BSD style open source license:
 
 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The authors encourage users of TapApp to include this copyright notice,
 and to let us know that you are using TapApp. Any person wishing to 
 distribute modifications to the Software is encouraged to send the 
 modifications to the original authors so that they can be incorporated 
 into the canonical version.
 
 The Software is provided "as is", WITHOUT ANY WARRANTY, express or implied,
 including but not limited to the warranties of MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.  In no event shall the authors
 or copyright holders by liable for any claim, damages, or other liability,
 whether in an actino of a contract, tort or otherwise, arising from, out of
 or in connection with the Software or the use or other dealings in the 
 software.
 -----------------------------------------------------------------------------*/

#import <UIKit/UIKit.h>

@interface TapAppViewController : UIViewController <UITextFieldDelegate, NSXMLParserDelegate, UIAlertViewDelegate> {
	
    IBOutlet UINavigationBar* navigationBar;
	IBOutlet UITextField* userIdText;
    
    IBOutlet UIToolbar* kbToolbar;
    IBOutlet UIBarButtonItem* doneButton;
    IBOutlet UIBarButtonItem* cancelButton;
    IBOutlet UIToolbar* toolbar;
    
    NSString* _documentsDirectory;
    NSString* _dataDirectory;
	
    BOOL _parseElement;
    
    BOOL _isLoaded;
    BOOL _isPlaying;
    BOOL _isPaused;
    
    int _userID;
    int _taskID;
}

@property (nonatomic, strong) IBOutlet UINavigationBar* navigationBar;
@property (nonatomic, strong) IBOutlet UITextField* userIdText;
@property (nonatomic, strong) IBOutlet UIToolbar* kbToolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* doneButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* playButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* pauseButton;

@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;

@property (nonatomic, strong) NSString* _documentsDirectory;
@property (nonatomic, strong) NSMutableArray* playArray;
@property (nonatomic, strong) NSMutableArray* pauseArray;

- (void) handleTrackEnded;

- (IBAction) handleTapButton:(id)sender;

- (IBAction) handlePlayButton:(id)sender;
- (IBAction) handlePauseButton:(id)sender;

- (IBAction) handleNextButton:(id)sender;
- (IBAction) handlePrevButton:(id)sender;

- (IBAction) handleDoneButton:(id)sender;
- (IBAction) handleCancelButton:(id)sender;

@end

