
ACTION CreateSvgContent:

	//*************************************************************************************************************
	// BUILD SVGCONTENT - shuttle icons only exist here (not in gAssembly_1_Layout.svg). Only called while
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
		brsstrcat(ADR(SvgContent), ADR('" points="-0.025,-0.023 0.0125,-0.023 0.025,0 0.0125,0.023 -0.025,0.023 -0.025,-0.023" stroke="black" fill="lightgrey" style="stroke-width:0.004"/></g>'));
	END_FOR
	brsstrcat(ADR(SvgContent), ADR('</svg>'));

END_ACTION
