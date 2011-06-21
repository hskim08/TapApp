//
//  AudioEngine.h
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
 
 The authors encourage users of MoMu to include this copyright notice,
 and to let us know that you are using MoMu. Any person wishing to 
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
#ifndef __AUDIO_ENGINE_H__
#define __AUDIO_ENGINE_H__

#import "TapAppViewController.h"

#include "FileWvOut.h"
#include "FileWvIn.h"

class AudioEngine
{
public:
    static int FRAME_SIZE;
    static int SAMPLE_RATE;
    static int NUM_CHANNELS;
    
public:
    AudioEngine();
    ~AudioEngine();
    
    bool initialize( TapAppViewController* vc );
    
    bool loadFiles( std::string& trackUrl, std::string& outputUrl );
    void unloadFiles();
    
    void runTask( bool run );
    bool isTaskRunning(){ return _isTaskRunning; }
    
    float getElapsedTime();
    
private:	
    TapAppViewController* _viewController;
    stk::FileWvIn* _waveReader;
    stk::FileWvOut* _waveWriter;
    bool _isTaskRunning;
    bool _isTaskPrepared;
    
	void handleCallback( Float32* buffer, UInt32 numFrames );
	static void callback( Float32* buffer, UInt32 numFrames, void* data );
};

#endif // __AUDIO_ENGINE_H__