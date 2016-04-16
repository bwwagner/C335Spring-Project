#pragma once

// includes are not working

#include "resource.h"
#include "stdafx.h"   //libraries loading in the wrong order?

#include <string>

using namespace std;

#define MAX_LOADSTRING 100

HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name


 /*case WM_PAINT:
 {
	 PAINTSTRUCT ps;
	 HDC hdc = BeginPaint(hWnd, &ps);
	 // TODO: Add any drawing code that uses hdc here...
	 doPaintData(hdc, airList);
	 EndPaint(hWnd, &ps);
 }*/

void doPaint(HDC hdc) {
	
	//SIZE strSize;

	int yLoc = 20, xLoc = 0;
	//int lineHeight;

		LPCWSTR x;
		x = L"V";
		xLoc += 200;
		yLoc += 200;
		TextOut(hdc, xLoc, yLoc, x, 1);
		//GetTextExtentPoint32(hdc, s1, size, ptr);
		//lineHeight = strSize.cy;  //string only?
		//yLoc += lineHeight;
		xLoc = 0;
		yLoc = 20;
	
} // doPaintData