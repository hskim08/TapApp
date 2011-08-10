//
//  AudioEngine.cpp
//  TapApp
//
//  Created by Hyung-Suk Kim( hskim08@stanford.edu ) on 5/4/11.
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

#include "AudioEngine.h"

#include "mo_audio.h"

int AudioEngine::FRAME_SIZE = 4096; // adjust value if necessary
int AudioEngine::SAMPLE_RATE = 44100;
int AudioEngine::NUM_CHANNELS = 2;

// constructor
AudioEngine::AudioEngine()
:_waveReader(NULL)
,_waveWriter(NULL)
,_isTaskRunning(false)
,_isTaskPrepared(false)
,_viewController(NULL)
{
}

// destructor
AudioEngine::~AudioEngine()
{
    if(_viewController != NULL) [_viewController release];
    if( _waveReader != NULL ) delete _waveReader;
    if( _waveWriter != NULL ) delete _waveWriter;
}

// late initialization
bool AudioEngine::initialize( TapAppViewController* vc )
{
    // initialize MoAudio
	bool result = MoAudio::init( SAMPLE_RATE, FRAME_SIZE, NUM_CHANNELS );
    if( !result ) 
    {
		NSLog( @"AudioEngine::initialize() - failed to initialize MoAudio." );
		return false;
	}
	
    // start MoAudio
    result = MoAudio::start( &callback, this );
    if( !result ) 
    {
		NSLog( @"AudioEngine::initialize() - failed to start MoAudio." );
		return false;
	}
	
    // set sample rate
	stk::Stk::setSampleRate( SAMPLE_RATE );
    
    _waveWriter = new stk::FileWvOut();
    _waveReader = new stk::FileWvIn();
    
    _viewController = vc;
    [vc retain];

    return true;
}

// prepares the task by loading the files
bool AudioEngine::loadFiles( std::string& trackUrl, std::string& outputUrl )
{
    // prepare readers and writers
    try
    {
        _waveReader->openFile( trackUrl );
        _waveWriter->openFile( outputUrl, 2, stk::FileWrite::FILE_WAV, stk::Stk::STK_SINT16 );
    }
    catch( stk::StkError& e )
    {
        _waveReader = NULL;
        e.printMessage();
        return false;
    }
    
    _isTaskPrepared = true;
    return true;
}

// unloads the files
void AudioEngine::unloadFiles()
{
    _waveWriter->closeFile();                
    _waveReader->closeFile();
    
    _isTaskRunning = false;
    _isTaskPrepared = false;
}

// start/stops the task
void AudioEngine::runTask( bool run )
{
    if( !_isTaskPrepared ) 
    {
        std::cout << "Task not prepared. Track must be loaded before playing.\n";
        return;
    }
    
    _isTaskRunning = run;
}

// returns the elapsed time in seconds
float AudioEngine::getElapsedTime()
{
    if( _waveWriter == NULL ) return 0;
    else return _waveWriter->getTime();
}

// handles the callback function. the actual work is done here.
void AudioEngine::handleCallback( Float32* buffer, UInt32 numFrames )
{
    if( _waveWriter == NULL || _waveReader == NULL ) return;
    
	for( int i = 0; i < numFrames; i++ )
	{
        if( _isTaskRunning )
        {
            // record mic input
            _waveWriter->tick( buffer[2*i] );
            
            // play audio
            _waveReader->tick();
            buffer[2*i] = _waveReader->lastOut(0);
            buffer[2*i + 1] = _waveReader->lastOut(1);
        }
        else buffer[2*i + 1] = buffer[2*i] = 0;
    }
    
    // check if finished
    if( _isTaskRunning && _waveReader->isFinished() )
    {
        // stop task
        runTask( false );
        unloadFiles();
        
        // signal task finished
        [_viewController handleTrackEnded];
    }
}

// the callback function. interface to MoAudio
void AudioEngine::callback( Float32* buffer, UInt32 numFrames, void* data )
{
	( (AudioEngine*) data )->handleCallback( buffer, numFrames );
}