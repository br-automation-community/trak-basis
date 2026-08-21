
ACTION CreateSvgContent:

	//*************************************************************************************************************
	// BUILD SVGCONTENT - shuttle icons and UserID labels only exist here (not in gAssembly_1_Layout.svg). Only called while
	// ShowShuttles is TRUE; the caller clears SvgContent to '' directly when ShowShuttles goes FALSE.
	// Must be wrapped in its own <svg viewBox=...> (matching gAssembly_1_Layout.svg) - without it mapp View
	// does not mount/render the appended elements at all.
	//*************************************************************************************************************
	SvgContent := '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="';
	brsstrcat(ADR(SvgContent), ADR(SVG_CONTENT_VIEWBOX));
	brsstrcat(ADR(SvgContent), ADR('">'));
	FOR i := 0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
		AuxID := CONCAT(SVG_FILL_PREFIX, SvgShuttle[i].ID);
		brsstrcat(ADR(SvgContent), ADR('<g id="'));
		brsstrcat(ADR(SvgContent), ADR(SvgShuttle[i].ID));
		brsstrcat(ADR(SvgContent), ADR('"><polygon id="'));
		brsstrcat(ADR(SvgContent), ADR(AuxID));
		brsstrcat(ADR(SvgContent), ADR('" points="-0.025,-0.023 0.0125,-0.023 0.025,0 0.0125,0.023 -0.025,0.023 -0.025,-0.023" stroke="black" fill="lightgrey" style="stroke-width:0.004"/>'));

		IF SvgShuttle[i].UserID <> '' THEN
			// The label is a sibling of the rotating polygon. The outer group translates both elements, while
			// CreateSvgTransform spins only the polygon, so the UserID remains horizontal as the shuttle turns.
			// Alternate labels above and below neighboring shuttles to reduce text overlap.
			IF (i MOD 2) = 0 THEN
				brsstrcat(ADR(SvgContent), ADR('<line x1="0" y1="0" x2="0.03" y2="-0.035" stroke="black" stroke-width="0.002"/><text x="0.035" y="-0.04" font-size="0.035" style="fill:black">'));
			ELSE
				brsstrcat(ADR(SvgContent), ADR('<line x1="0" y1="0" x2="0.03" y2="0.035" stroke="black" stroke-width="0.002"/><text x="0.035" y="0.06" font-size="0.035" style="fill:black">'));
			END_IF
			XmlUserID := '';
			XmlCharCount := LEN(SvgShuttle[i].UserID);
			FOR XmlCharIndex := 1 TO XmlCharCount DO
				XmlChar := MID(SvgShuttle[i].UserID, 1, XmlCharIndex);
				IF XmlChar = '&' THEN
					brsstrcat(ADR(XmlUserID), ADR('&amp;'));
				ELSIF XmlChar = '<' THEN
					brsstrcat(ADR(XmlUserID), ADR('&lt;'));
				ELSIF XmlChar = '>' THEN
					brsstrcat(ADR(XmlUserID), ADR('&gt;'));
				ELSE
					brsstrcat(ADR(XmlUserID), ADR(XmlChar));
				END_IF
			END_FOR
			brsstrcat(ADR(SvgContent), ADR(XmlUserID));
			brsstrcat(ADR(SvgContent), ADR('</text>'));
		END_IF
		brsstrcat(ADR(SvgContent), ADR('</g>'));
	END_FOR
	brsstrcat(ADR(SvgContent), ADR('</svg>'));

END_ACTION
