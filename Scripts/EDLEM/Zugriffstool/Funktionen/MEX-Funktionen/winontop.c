/* winontop.c
 * set "topmost" state of a figure window 
 */

/*
 * Copyright (c) 2011, John Anderson
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in
 * the documentation and/or other materials provided with the distribution
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/* Alterations by Eckhard Lehmann applied by Franz Zeilinger on 27th June 11 
 * see http://www.mathworks.com/matlabcentral/fileexchange/8642
 * according to post of 7th March 2011
 */

/* Enhancement for proper use by Franz Zeilinger on 27th June 11 */

 #include <windows.h>
 #include <string.h>
 #include <shellapi.h>
 #include "mex.h"
 #include "matrix.h"

 void mexFunction( int nlhs, mxArray *plhs[], int nrhs, 
    const mxArray *prhs[]) 
 {
  char *windowName, *ntSwitch, n = 1; 
  mxArray *windowNameProp, *numberTitleProp; /* for getting the window name */ 
  double figureHandle;
  HWND hwnd;
  RECT rectWin;

  /* check for proper number of input arguments */
  if( !(nrhs > 0) || !(nrhs < 3) || !(nlhs == 0) )
    mexErrMsgIdAndTxt("MATLAB:winontop",
      "Improper number of input or output arguments");
  
  /* first input argument: figure handle */
  figureHandle = (double)mxGetScalar(prhs[0]);
  
  /* check that first input argument is a valid figure handle */
  if( mexGet(figureHandle,"Visible") == NULL ) {
    mexErrMsgIdAndTxt("MATLAB:winontop",
      "First input argument must be a figure handle");
    } 
  
  windowNameProp = mexGet(figureHandle, "Name"); 
  windowName = mxArrayToString(windowNameProp); 
  
  numberTitleProp = mexGet(figureHandle, "NumberTitle"); 
  ntSwitch = mxArrayToString(numberTitleProp); 
  if (strcmp(ntSwitch, "on") == 0) { 
	if (strlen(windowName) == 0) { 
		windowName = mxCalloc(1, sizeof(figureHandle)+8); 
		sprintf(windowName, "Figure %d", figureHandle); 
	} else { 
		char *wBuf = windowName; 
		windowName = mxCalloc(1, sizeof(figureHandle)+10+strlen(windowName)); 
		sprintf(windowName, "Figure %d: %s", figureHandle, wBuf); 
	} 
  }
  
  /* second input argument: changes 'topmost' property */
  if( nrhs == 2 )
    n = (char)mxGetScalar(prhs[1]);
  
  /* check that second input argument is valid */
  if( !( (n == 1) || (n == 0) ) )
    mexErrMsgIdAndTxt("MATLAB:winontop",
      "Second input argument must be 0 or 1");

  /* set state of topmost property */
 	if (hwnd = FindWindow(NULL,windowName)) {
        
        // get window position
        GetWindowRect(hwnd, &rectWin); 
        
  	if( n == 1 )
      SetWindowPos(hwnd,HWND_TOPMOST,rectWin.left,rectWin.top,0,0,SWP_NOSIZE);
  	else
      SetWindowPos(hwnd,HWND_NOTOPMOST,rectWin.left,rectWin.top,0,0,SWP_NOSIZE);
	}
}
