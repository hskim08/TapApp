//
//  TapAppViewController.m
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

#import "TapAppViewController.h"

#import <vector>
#import <string>
#import <fstream>

#import "AudioEngine.h"

std::vector<std::string> _tempList;
std::vector<std::string> _trackList;
std::vector<int> _trackNoList;
std::string _tapData;

// the audio engine
AudioEngine _audioEngine;

// private interface
@interface TapAppViewController ()

- (void) createEmptyXml;
- (BOOL) parseTrackList;
- (BOOL) checkTrackListChange;
- (BOOL) validateTrackList;

- (BOOL) randomizeOrder;
- (void) createSequentialPlaylist;
- (void) createRandomPlaylist:(int)userId;
- (void) savePlayList:(int)userId;

- (void) reset;

- (void) loadAudioFile;

- (void) logTimeStamp;
- (void) saveLogToFile:(id)sender;

@end

@implementation TapAppViewController

@synthesize navigationBar;
@synthesize userIdText;
@synthesize playButton;
@synthesize kbToolbar;
@synthesize doneButton;
@synthesize cancelButton;

@synthesize playImage;
@synthesize pauseImage;

@synthesize _documentsDirectory;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void) awakeFromNib
{
    // load images for play/pause button
    playImage = [UIImage imageNamed:@"play.png"];
    [playImage retain];
    
	pauseImage = [UIImage imageNamed:@"pause.png"];
    [pauseImage retain];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// set textfield delegate
	userIdText.delegate = self;
    
    // initialize audio
    _audioEngine.initialize( self );
    
    // clear data
	_tapData.clear();
    
    // get documents directory
    NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
	_documentsDirectory = [paths objectAtIndex:0];
    [_documentsDirectory retain];
    
    // check for xml file and parse
    if( [self parseTrackList] ) 
    {
        // load into playlist
        _trackList = _tempList;
        
        if( [self validateTrackList] ) 
        {
            _isLoaded = YES;
            
            if( _trackList.size() == 0 ) navigationBar.topItem.title = @"Add Tracks to Tracklist";
            else navigationBar.topItem.title = @"Enter User ID";
        }
    }
    else navigationBar.topItem.title = @"XML File Error";
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [_documentsDirectory release];
    [super dealloc];
}


#pragma mark private_methods

- (void) createEmptyXml
{
    NSString* filePath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, @"trackList.xml"];
    
    NSString* xmlString = @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<xml>\n</xml>";
    
    [xmlString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// checks for trackList.xml and parses it
- (BOOL) parseTrackList
{
    // get full path of trackList.xml
    NSString* filePath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, @"trackList.xml"];
    NSURL* fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] )
    {
        // create trackList.xml
        [self createEmptyXml];
    }
    
    // create parser
    NSData *xml = [NSData dataWithContentsOfURL:fileURL];            
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xml];
    [xmlParser setDelegate:self];
    
    // prepare parsing to _tempList
    _parseElement = FALSE;
    _tempList.clear();
    
    // parse
    BOOL parsed = [xmlParser parse];
    
    // cleanup
    [xmlParser release];
    [fileURL release];  
    
    return parsed;
}


// checks for tracklist change
- (BOOL) checkTrackListChange
{
    if( _trackList.size() != _tempList.size() ) return YES;
    
    for( int i = 0; i < _trackList.size(); i++ )
    {
        if( _trackList.at(i).compare( _tempList.at(i) ) != 0 ) return YES;
    }
    
    return NO;
}


// validates the playlist by checking if each file actually exists
- (BOOL) validateTrackList
{
    // validate filenames
    for( int i = 0; i < _trackList.size(); i++ )
    {
        // check if file exists
        NSString* filePath = [NSString stringWithFormat: @"%@/%s", _documentsDirectory, _trackList.at(i).c_str()];
        
        if( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] )
        {
            NSString* errorString = [NSString stringWithFormat:@"Can't Load Audio File# %02d", i+1];
            navigationBar.topItem.title = errorString;
            
            return NO;
        }
    }
    
    return YES;
}


// reads random order preference from settings
- (BOOL) randomizeOrder
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"randomize_order"];
}


// creates a sequential playlist.
- (void) createSequentialPlaylist
{
    if( _trackNoList.size() != 0 ) _trackNoList.clear();
	
	for( int i = 0; i < _trackList.size(); i++ )
        _trackNoList.push_back(i);
}


// creates a randomized playlist based on the user id.
- (void) createRandomPlaylist:(int)userId
{
    if( _trackNoList.size() != 0 ) _trackNoList.clear();
	
	// set seed
	srandom(userId);
	
	bool* used = new bool[_trackList.size()];
    
	// initialize
	for( int i = 0; i < _trackList.size(); i++ )
		used[i] = false;
	
	// create play list order
	int c = 0;
	int n = 0;
	for( int i = 0; i < _trackList.size(); i++ )
	{
		c = 0;
		n = random() % (_trackList.size() - _trackNoList.size()); // get n-th unused track number
		
		for( int j = 0; j < _trackList.size(); j++ )
		{ // move up n unmarked track numbers
			if( !used[j] )
			{
				if( c == n )
				{ // use this
					used[j] = true;
					_trackNoList.push_back(j);
					break;
				}
				else c++; // increment counter
			}
		}
	}
	
	// clean up
	delete [] used;
}


// saves the tracklist
- (void) savePlayList:(int)userId
{
    NSMutableString* listString = [NSMutableString string];
	for( int i = 0; i < _trackNoList.size(); i++ )
        [listString appendFormat:@"%d ", _trackNoList.at(i)];
    
    //	NSLog(@"Play list: %@", listString);
    
    // save to file
    //make a file name to write the data to using the documents directory:
	NSString* fileName = [NSString stringWithFormat:@"%03d_play_order.txt", userId];
	NSString* fullName = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, fileName];
    
    [listString writeToFile:fullName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


// resets the flags and labels
- (void) reset
{
	// stop the audio
	if( _isPlaying ) 
    {
        _audioEngine.runTask( false );
        _audioEngine.unloadFiles();
    }
    
    _isPlaying = false;
    _isPaused = false;
    
	// clear data
	_tapData.clear();
    
    // update UI
    [playButton setImage:playImage forState:UIControlStateNormal];
}


// loads an audio file
- (void) loadAudioFile
{
    // create input file path
    NSString* filename = [NSString stringWithUTF8String:_trackList.at( _trackNoList.at(_taskID) ).c_str()];
    NSString* trackFilePath = [NSString stringWithFormat: @"%@/%@", _documentsDirectory, filename];
    std::string trackUrl( [trackFilePath UTF8String] );
    
    //make a file name to write the data to using the documents directory:
	NSString* outputFile = [NSString stringWithFormat:@"%03d_%02d.wav", _userID, (_trackNoList.at(_taskID)+1)];
	NSString* outputFilePath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, outputFile];
    std::string outputUrl( [outputFilePath UTF8String] );
    
    bool result = _audioEngine.loadFiles( trackUrl, outputUrl );
    
    if( !result ) navigationBar.topItem.title = @"Audio File Load Error";
}


// logs the time stamp
- (void) logTimeStamp
{
	// log time stamp
    float ts = _audioEngine.getElapsedTime();
    NSString* tapData = [NSString stringWithFormat:@"%f", ts];
//    NSLog(@"time stamp: %f", ts);
    
	_tapData += [tapData UTF8String];
	_tapData += "\n";
}


// saves tap data to file.
- (void) saveLogToFile:(id)sender
{	
    //make a file name to write the data to using the documents directory:
	NSString* fileName = [NSString stringWithFormat:@"%03d_%02d.txt", _userID, (_trackNoList.at(_taskID)+1)];
	NSString* filePath = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, fileName];
	
	//save content to the documents directory
	NSString* dataString = [NSString stringWithCString:_tapData.c_str() encoding:NSUTF8StringEncoding ];
	[dataString writeToFile:filePath atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}


#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    kbToolbar.hidden = NO;
    
    kbToolbar.transform = CGAffineTransformMakeTranslation(0, 260);
    [UIView animateWithDuration:0.3 animations:^{kbToolbar.transform = CGAffineTransformMakeTranslation(0, 0);}];
}


#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    _isLoaded = NO;
    _trackList = _tempList;
    
    if( [self validateTrackList] ) 
    {
        _isLoaded = YES;
        
        // get new ID
        int newID = [userIdText.text intValue];
        
        // reset for new user
        _userID = newID;
        
        if( _userID == 0 ) navigationBar.topItem.title = @"Enter User ID";
        else
        {
            // create playlist
            [self randomizeOrder] ? [self createRandomPlaylist:_userID] : [self createSequentialPlaylist];
            
            // save playlist
            [self savePlayList:_userID];
            
            // reset task id
            _taskID = 0;
            
            // reset state
            [self reset];
            
            // update label
            navigationBar.topItem.title = @"Press Play Button";
        }
        
        // pretty print
        NSString* numString = [NSString stringWithFormat:@"%d", _userID];
        userIdText.text = numString;
    } 
    else 
    {
        // restore previous value
        NSString* numString = [NSString stringWithFormat:@"%d", _userID];
        userIdText.text = numString;
    }
}


#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Parsing error: %@", [parseError localizedDescription]);
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if( _parseElement ) _tempList.push_back( std::string([string UTF8String]) );
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict 
{
    if( [elementName isEqualToString:@"filename"] ) _parseElement = TRUE;
    else _parseElement = FALSE;
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
    _parseElement = FALSE;
}


#pragma mark audio_engine_handler

- (void) resetPlayButtonMode:(id)object
{
    [playButton setImage:playImage forState:UIControlStateNormal];
}

// this is a workaround
- (void) setTaskLabelText:(NSString*)text
{
    navigationBar.topItem.title = text;
}


- (void) handleTrackEnded
{
    _isPlaying = false;
    
    // save to file
    [self performSelectorOnMainThread: @selector(saveLogToFile:) withObject:nil waitUntilDone:YES];
    
    // reset play button
    [self performSelectorOnMainThread: @selector(resetPlayButtonMode:) withObject:nil waitUntilDone:YES];
    
    // prepare next task
    _taskID++;
    
    if( _taskID == _trackList.size() ) 
    {
        _isPlaying = false;
        _isPaused = false;
        
        [self performSelectorOnMainThread: @selector(setTaskLabelText:) withObject:@"Finished!" waitUntilDone:YES];
    }
    else
    {
        // update task title
        NSString* taskTitle = [[NSString alloc] initWithFormat:@"Task# %02d", (_taskID+1)];
        [self performSelectorOnMainThread: @selector(setTaskLabelText:) withObject:taskTitle waitUntilDone:YES];

        [taskTitle release];
    }
}


#pragma mark ui_handlers

- (IBAction) handleTapButton:(id)sender
{	
    if( !_isLoaded || !_isPlaying || _isPaused ) return;
	
	[self logTimeStamp];
}


- (IBAction) handleStartButton:(id)sender
{	
	if( !_isPlaying  )
	{ // start
        if( _isLoaded && _userID != 0 && _taskID < _trackList.size() )
        {
            // update task title
            NSString* taskTitle = [NSString stringWithFormat:@"Task# %02d", (_taskID+1)];
            navigationBar.topItem.title = taskTitle;

            // reset
            [self reset];
                    
            // load audio file
            [self loadAudioFile];
            
            // play track
            _audioEngine.runTask( true );
            
            [playButton setImage:pauseImage forState:UIControlStateNormal];
            
            _isPlaying = TRUE;
        }
	}
    else
    {
        if( !_isPaused )
        { // pause track
            _audioEngine.runTask( false );
            _isPaused = TRUE;
            
            [playButton setImage:playImage forState:UIControlStateNormal];
        }
        else
        {
            _audioEngine.runTask( true );
            _isPaused = FALSE;
            
            [playButton setImage:pauseImage forState:UIControlStateNormal];
        }
    }
}


- (IBAction) handleNextButton:(id)sender
{
    if( !_isLoaded || _userID == 0 || _trackList.size() == 0 ) return;
	if( _taskID >= _trackList.size() - 1 ) return; // don't do anything on last task
    
	// reset flags
	[self reset];
	
	_taskID++;
	
	// update task title
	NSString* taskTitle = [NSString stringWithFormat:@"Task# %02d", (_taskID+1)];
    navigationBar.topItem.title = taskTitle;
}


- (IBAction) handlePrevButton:(id)sender
{
    if( !_isLoaded || _userID == 0 || _trackList.size() == 0 ) return;
	if( _taskID < 1 ) return; // don't do anything on first task
	
	// reset flags
	[self reset];
	
	_taskID--;
	
	// update task title
	NSString* taskTitle = [NSString stringWithFormat:@"Task# %02d", (_taskID+1)];
    navigationBar.topItem.title = taskTitle;
}


- (IBAction) handleDoneButton:(id)sender
{
    // hide keyboard
    [userIdText resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{kbToolbar.transform = CGAffineTransformMakeTranslation(0, 260);}];
    
    // check tracklist
    if( ![self parseTrackList] )
    {
        _isLoaded = NO;
        navigationBar.topItem.title = @"XML File Error";
        
        // restore previous value
        NSString* numString = [NSString stringWithFormat:@"%d", _userID];
        userIdText.text = numString;
        return;
    }
    
    // if changes found alert user of tracklist change
    if( [self checkTrackListChange] )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TrackList.xml Changed" 
                                                        message:@"There was a change in the trackList.xml file."
                                                       delegate:self 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else
    {       
        // get new ID
        int newID = [userIdText.text intValue];
        
        // reset for new user
        _userID = newID;
        
        if( _userID == 0 ) navigationBar.topItem.title = @"Enter User ID";
        else
        {
            // create playlist
            [self randomizeOrder] ? [self createRandomPlaylist:_userID] : [self createSequentialPlaylist];
            
            // save playlist
            [self savePlayList:_userID];
            
            // reset task id
            _taskID = 0;
            
            // reset state
            [self reset];
            
            // update label
            navigationBar.topItem.title = @"Press Play Button";
        }
        
        // pretty print
        NSString* numString = [NSString stringWithFormat:@"%d", _userID];
        userIdText.text = numString;
    }
}


- (IBAction) handleCancelButton:(id)sender
{
    // hide keyboard
    [userIdText resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{kbToolbar.transform = CGAffineTransformMakeTranslation(0, 260);}];
    
    // restore previous value
    NSString* numString = [NSString stringWithFormat:@"%d", _userID];
    userIdText.text = numString;
}

@end
