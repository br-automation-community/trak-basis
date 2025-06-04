(********************************************************************
 * COPYRIGHT - B&R Spain
 ********************************************************************
 * Program: TrakCtrl
 * File: References.st
 * Author: B&R Spain
 * Created: July 22, 2024
 * Modified: July 22, 2024
 ********************************************************************
 * Implementation of program TrakCtrl
 ********************************************************************
 * Gets the references to the structures
 ********************************************************************) 
ACTION References: 

	// Obtain the address of the global assembly structure. This pointer can be used in other places to read/write the assembly's data.
	AdrAssembly	:=	ADR(gAssembly_1);
	// Obtain the address of the default sector structure where initial shuttle movements will be performed.
	AdrSector := ADR(Sector_1);
	
	// Store the name of the global assembly for identification or logging purposes.
	AssemblyName 	:= 'gAssembly_1';
	
	// Access the address of gTrakCtrl using the built-in ACCESS operator. This ensures pTrakCtrl points directly to gTrakCtrl for control operations.
	pTrakCtrl ACCESS ADR(gTrakCtrl);
	
END_ACTION
