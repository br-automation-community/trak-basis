(********************************************************************
 * COPYRIGHT - B&R Spain
 ********************************************************************
 * Program: TrakHmi
 * File: TrakHmi.st
 * Author: B&R Spain
 * Created: August 18, 2026
 ********************************************************************
 * Description:
 *  - Drives the diagnostics diagram shown in the "STATUS" Paper widget
 *    (ContentMain.content -> PaperShuttles) from gTrakCtrl.Status.
 *  - Builds the SVG "transform" command string consumed by mapp View, with
 *    ids built from SVG_ID_SYSTEM_PREFIX + SVG_SEG_NAME/SVG_SH_NAME (TrakHmi.var).
 *    Segments (SvgSegment) and shuttles (SvgShuttle) are kept as separate arrays:
 *    segments are always part OF gAssembly_1_Layout.svg (built BY the ACOPOStrak
 *    object hierarchy tool) and never move, so only their fill ever changes;
 *    shuttles don't exist in that file, so their icons are built as SvgContent
 *    and injected via the Paper widget "svgContent" property (ContentMain.binding),
 *    and they also need display/translate/spin, unlike segments.
 *  - Rebuilt at SVG_REFRESH_TIME instead of every PLC cycle: recomputing this ~50-element string on
 *    every fast controller cycle would be wasted CPU with no visible benefit.
 ********************************************************************)

PROGRAM _INIT

	SvgSegIdPrefix := CONCAT(SVG_ID_SYSTEM_PREFIX, SVG_SEG_NAME);
	SvgShIdPrefix := CONCAT(SVG_ID_SYSTEM_PREFIX, SVG_SH_NAME);

	// Segments: SvgSegIdPrefix1..SvgSegIdPrefix<TRAK_MAX_SEGMENT>
	FOR i := 0 TO TRAK_MAX_SEGMENT_MINUS_ONE DO
		SvgNum := i + 1;
		AuxNum := UINT_TO_STRING(SvgNum);
		SvgSegment[i].ID := CONCAT(SvgSegIdPrefix, AuxNum);
	END_FOR

	// Shuttles: SvgShIdPrefix1..SvgShIdPrefix<TRAK_MAX_SHUTTLE>. Ids are always computed (cheap, needed as
	// soon as ShowShuttles turns TRUE); the icons themselves (SvgContent) are only built when ShowShuttles
	// is already TRUE - see CreateSvgContent.
	FOR i := 0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
		SvgNum := i + 1;
		AuxNum := UINT_TO_STRING(SvgNum);
		SvgShuttle[i].ID := CONCAT(SvgShIdPrefix, AuxNum);
	END_FOR

	IF ShowShuttles THEN
		CreateSvgContent;
	ELSE
		SvgContent := '';
	END_IF

END_PROGRAM

PROGRAM _CYCLIC

	IF TON_0.Q THEN

		//*************************************************************************************************************
		// SHOW/HIDE SHUTTLES - (re)build SvgContent only on change, not every refresh tick
		//*************************************************************************************************************
		TrigShowShuttlesOn(CLK := ShowShuttles);
		TrigShowShuttlesOff(CLK := ShowShuttles);
		IF TrigShowShuttlesOn.Q THEN
			CreateSvgContent;
		ELSIF TrigShowShuttlesOff.Q THEN
			SvgContent := '';
		END_IF

		//*************************************************************************************************************
		// SEGMENTS - color only; always part of the project/assembly, so no display/position logic at all
		//*************************************************************************************************************
		FOR i := 0 TO TRAK_MAX_SEGMENT_MINUS_ONE DO
			IF NOT gTrakCtrl.Status.Segment[i].Valid THEN
				SvgSegment[i].Fill := 0;
			ELSIF gTrakCtrl.Status.Segment[i].State.StatusErrorStop THEN
				SvgSegment[i].Fill := 3;
			ELSIF gTrakCtrl.Status.Segment[i].State.StatusReady THEN
				SvgSegment[i].Fill := 1;
			ELSE
				SvgSegment[i].Fill := 0;
			END_IF
		END_FOR

		//*************************************************************************************************************
		// SHUTTLES - color, position and orientation
		//*************************************************************************************************************
		FOR i := 0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
			SvgShuttle[i].Visible := gTrakCtrl.Status.Shuttle[i].Valid AND ShowShuttles;
			SvgShuttle[i].TranslateX := LREAL_TO_REAL(gTrakCtrl.Status.Shuttle[i].Pos.X) / SVG_MM_PER_UNIT;
			SvgShuttle[i].TranslateY := -LREAL_TO_REAL(gTrakCtrl.Status.Shuttle[i].Pos.Y) / SVG_MM_PER_UNIT;

			// Heading from movement direction, not Frame.Orient.Angle1/2/3: those are an ambiguous multi-valued
			// Euler decomposition for this planar system (same physical heading can show up as completely
			// different Angle1/2/3 combinations - see repo memory) and aren't safely combinable by simple math.
			// Below MIN_HEADING_DELTA_SQ the movement is noise, so the last computed heading is kept as-is.
			DeltaX := gTrakCtrl.Status.Shuttle[i].Pos.X - PrevPosX[i];
			DeltaY := gTrakCtrl.Status.Shuttle[i].Pos.Y - PrevPosY[i];
			IF (DeltaX*DeltaX + DeltaY*DeltaY) > MIN_HEADING_DELTA_SQ THEN
				IF DeltaX > 0.0 THEN
					HeadingRad := ATAN(DeltaY/DeltaX);
				ELSIF DeltaX < 0.0 THEN
					IF DeltaY >= 0.0 THEN
						HeadingRad := ATAN(DeltaY/DeltaX) + PI;
					ELSE
						HeadingRad := ATAN(DeltaY/DeltaX) - PI;
					END_IF
				ELSIF DeltaY > 0.0 THEN
					HeadingRad := PI/2.0;
				ELSE
					HeadingRad := -PI/2.0;
				END_IF
				// SVG y-axis points down (opposite of the real-world coordinate system) - negate to compensate
				SvgShuttle[i].Angle := -LREAL_TO_REAL(HeadingRad * RAD_TO_DEG);
			END_IF
			PrevPosX[i] := gTrakCtrl.Status.Shuttle[i].Pos.X;
			PrevPosY[i] := gTrakCtrl.Status.Shuttle[i].Pos.Y;

			IF NOT gTrakCtrl.Status.PowerOn THEN
				SvgShuttle[i].Fill := 0;
			ELSIF gTrakCtrl.Status.Shuttle[i].State.StatusErrorStop THEN
				SvgShuttle[i].Fill := 3;
			ELSIF gTrakCtrl.Status.Shuttle[i].State.StatusStopping THEN
				SvgShuttle[i].Fill := 2;
			ELSE
				SvgShuttle[i].Fill := 1;
			END_IF
		END_FOR

		//*************************************************************************************************************
		// BUILD THE TRANSFORM STRING - one "select" command per element, in the format expected by widget Paper
		//*************************************************************************************************************
		CreateSvgTransform;

		TON_0.IN := FALSE;
	ELSE
		TON_0.IN := TRUE;
	END_IF

	TON_0.PT := SVG_REFRESH_TIME;
	TON_0();

END_PROGRAM

PROGRAM _EXIT

END_PROGRAM
