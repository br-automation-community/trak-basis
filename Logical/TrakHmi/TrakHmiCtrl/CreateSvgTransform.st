
ACTION CreateSvgTransform:

	//*************************************************************************************************************
	// BUILD THE TRANSFORM STRING - one "select" command per element, in the format expected by widget Paper
	// Built with brsstrcat (not CONCAT: its result is hard-capped at STRING[255], which silently truncated
	// the front of SvgTransform - i.e. dropped earlier segments - once the string grew past that size)
	//*************************************************************************************************************
	SvgTransform := '[';

	//*************************************************************************************************************
	// SEGMENTS - fill only, always emitted (they're always part of the project/assembly). Selects
	// SVG_FILL_PREFIX+ID (the polygon nested inside each gsg_Seg_N group), not ID itself: ID is the
	// <g> wrapper, whose own fill can never override the inline style already set on its child polygon.
	//*************************************************************************************************************
	FOR i := 0 TO TRAK_MAX_SEGMENT_MINUS_ONE DO
		AuxID := CONCAT(SVG_FILL_PREFIX, SvgSegment[i].ID);
		brsstrcat(ADR(SvgTransform), ADR('{"select":"#'));
		brsstrcat(ADR(SvgTransform), ADR(AuxID));
		brsstrcat(ADR(SvgTransform), ADR('","fill":'));
		brsitoa(SvgSegment[i].Fill, ADR(AuxNum));
		brsstrcat(ADR(SvgTransform), ADR(AuxNum));
		brsstrcat(ADR(SvgTransform), ADR('},'));
	END_FOR

	//*************************************************************************************************************
	// SHUTTLES - display, position, orientation and fill. Skipped entirely (not just hidden) while
	// ShowShuttles is FALSE - their icons don't even exist in SvgContent then.
	//*************************************************************************************************************
	IF ShowShuttles THEN
		FOR i := 0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
			brsstrcat(ADR(SvgTransform), ADR('{"select":"#'));
			brsstrcat(ADR(SvgTransform), ADR(SvgShuttle[i].ID));
			brsstrcat(ADR(SvgTransform), ADR('","display":'));
			IF NOT SvgShuttle[i].Visible THEN
				brsstrcat(ADR(SvgTransform), ADR('false},'));
			ELSE
				brsstrcat(ADR(SvgTransform), ADR('true'));
				IF (SvgShuttle[i].TranslateX <> 0) OR (SvgShuttle[i].TranslateY <> 0) THEN
					brsstrcat(ADR(SvgTransform), ADR(',"translate":['));
					brsftoa(SvgShuttle[i].TranslateX, ADR(AuxNum));
					brsstrcat(ADR(SvgTransform), ADR(AuxNum));
					brsstrcat(ADR(SvgTransform), ADR(','));
					brsftoa(SvgShuttle[i].TranslateY, ADR(AuxNum));
					brsstrcat(ADR(SvgTransform), ADR(AuxNum));
					brsstrcat(ADR(SvgTransform), ADR(']'));
				END_IF
				brsstrcat(ADR(SvgTransform), ADR('},'));

				// spin/fill go on the inner polygon (AuxID), not the outer <g> (ID): the outer <g> already got
				// translated above, so spinning IT around (0,0) would orbit it around the SVG's global origin
				// instead of its own center - see repo memory for the full reasoning
				AuxID := CONCAT(SVG_FILL_PREFIX, SvgShuttle[i].ID);
				brsstrcat(ADR(SvgTransform), ADR('{"select":"#'));
				brsstrcat(ADR(SvgTransform), ADR(AuxID));
				brsstrcat(ADR(SvgTransform), ADR('","fill":'));
				brsitoa(SvgShuttle[i].Fill, ADR(AuxNum));
				brsstrcat(ADR(SvgTransform), ADR(AuxNum));
				IF SvgShuttle[i].Angle <> 0 THEN
					brsstrcat(ADR(SvgTransform), ADR(',"spin":['));
					brsftoa(SvgShuttle[i].Angle, ADR(AuxNum));
					brsstrcat(ADR(SvgTransform), ADR(AuxNum));
					brsstrcat(ADR(SvgTransform), ADR(',0,0]'));
				END_IF
				brsstrcat(ADR(SvgTransform), ADR('},'));
			END_IF
		END_FOR
	END_IF

	brsstrcat(ADR(SvgTransform), ADR('{}]'));

END_ACTION
