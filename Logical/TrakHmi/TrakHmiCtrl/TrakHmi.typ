(********************************************************************
 * COPYRIGHT - B&R Spain
 ********************************************************************
 * Program: TrakHmi
 * File: TrakHmi.typ
 * Author: B&R Spain
 * Created: August 18, 2026
 ********************************************************************
 * Local data types of program TrakHmi
 ********************************************************************)

TYPE
	SvgSegmentType : 	STRUCT  (*Runtime state of one segment - always part of gAssembly_1_Layout.svg, never moves, only its fill changes*)
		ID : STRING[10]; (*<g> id in gAssembly_1_Layout.svg (e.g. gsg_Seg_1)*)
		Fill : UINT; (*Index into the Paper widget colorList (0 Disabled, 1 Ready, 2 Stopping, 3 ErrorStop)*)
	END_STRUCT;
	SvgShuttleType : 	STRUCT  (*Runtime state of one shuttle - shown/hidden, moved, rotated and colored*)
		ID : STRING[10]; (*<g> id built in SvgContent (e.g. gsg_Sh_1)*)
		UserID : STRING[32]; (*UserID displayed next to the shuttle; empty means the shuttle is not identified*)
		Visible : BOOL; (*Element is shown on the diagram*)
		TranslateX : REAL; (*Pixel offset in x-direction*)
		TranslateY : REAL; (*Pixel offset in y-direction*)
		Angle : REAL; (*Rotation in degrees around the element's own origin*)
		Fill : UINT; (*Index into the Paper widget colorList (0 Disabled, 1 Ready, 2 Stopping, 3 ErrorStop)*)
	END_STRUCT;
END_TYPE
