//********************************************************************
// COPYRIGHT - B&R Spain
//********************************************************************
// Program: TrakCtrl
// File: InitSequence.st
// Author: B&R Spain
// Created: July 22, 2024
//********************************************************************
// Implementation of program TrakCtrl
//********************************************************************
// This action implements a state machine to initialize the AcoposTrak system.
//********************************************************************

ACTION InitSequence: 
	
	// State machine controlling the initialization of the AcoposTrak system
	CASE InitState OF
		
		INIT_STATE_SET_PARAMETER:
			
			// Set default motion parameters before communicating with the trak
			pTrakCtrl.Parameter.Speed := 0.5;
			pTrakCtrl.Parameter.Acceleration := 5.0;
			pTrakCtrl.Parameter.Deceleration := 5.0;
			pTrakCtrl.Parameter.Position := 0.0;
			pTrakCtrl.Parameter.Direction := mcDIR_POSITIVE;
			
			// Additional parameters for simulation and restore operations
			pTrakCtrl.Parameter.SimulationParameters.Position := 0.1;
			pTrakCtrl.Parameter.SimulationParameters.Quantity := 20;
			pTrakCtrl.Parameter.SimulationParameters.Separation := 0.06;
			pTrakCtrl.Parameter.RestoreEnabled := TRUE;
			pTrakCtrl.Parameter.RestoreTolerance := 0.02;
			
			InitState := INIT_STATE_CHECK_ASM_COMM;
		
		INIT_STATE_CHECK_ASM_COMM:
			
			 // Verify that the assembly is ready for communication
			IF (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.CommunicationReady) THEN
				InitState := INIT_STATE_ASM_RDY_TO_POWER;
			END_IF
		
		INIT_STATE_ASM_RDY_TO_POWER:
			
			// Verify that the assembly is ready to be powered on
			IF (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ReadyForPowerOn) THEN
				InitState := INIT_STATE_GET_SEGMENT;
			END_IF
		
		INIT_STATE_GET_SEGMENT:
			
			// Start retrieving segment information
			MC_BR_AsmGetSegment_AcpTrak_0.Enable := TRUE;
			MC_BR_AsmGetSegment_AcpTrak_0.Next := FALSE;
			Counter := 0;
			
			InitState := INIT_STATE_GET_SEGMENT_WAIT;
		
		INIT_STATE_GET_SEGMENT_WAIT:
			
			IF (MC_BR_AsmGetSegment_AcpTrak_0.Error) THEN
				MC_BR_AsmGetSegment_AcpTrak_0.Enable := FALSE;
				InitState := INIT_STATE_ERROR;
				
			// If there's no error, check if valid data is available	
			ELSIF (MC_BR_AsmGetSegment_AcpTrak_0.Valid) THEN
				
				// Store the total amount of segments
				TotalCountSegment := MC_BR_AsmGetSegment_AcpTrak_0.TotalCount;
				
				// If zero segments (or more than the maximum allowed), that's an error
				IF (MC_BR_AsmGetSegment_AcpTrak_0.TotalCount = 0) OR (MC_BR_AsmGetSegment_AcpTrak_0.TotalCount > TRAK_MAX_SEGMENT) THEN
					MC_BR_AsmGetSegment_AcpTrak_0.Enable := FALSE;
					InitState := INIT_STATE_ERROR;
				ELSE
					
					pTrakCtrl.Status.Segment[Counter].Segment := MC_BR_AsmGetSegment_AcpTrak_0.Segment;
					
					// Check if all segments are read
					IF (MC_BR_AsmGetSegment_AcpTrak_0.RemainingCount = 0) THEN
						// All segments are retreived -> Move on
						MC_BR_AsmGetSegment_AcpTrak_0.Enable := FALSE;
						MC_BR_AsmGetSegment_AcpTrak_0.Next := FALSE;
						InitState := INIT_STATE_DONE;
					
					ELSIF (Counter >= TRAK_MAX_SEGMENT) THEN
						MC_BR_AsmGetSegment_AcpTrak_0.Enable := FALSE;
						MC_BR_AsmGetSegment_AcpTrak_0.Next := FALSE;
						InitState := INIT_STATE_ERROR;
						
					ELSE
						// Still have more segments to retrieve -> Read the next one
						MC_BR_AsmGetSegment_AcpTrak_0.Next := FALSE;
						InitState := INIT_STATE_GET_SEGMENT_NEXT;
					END_IF
				END_IF
			END_IF
		
		INIT_STATE_GET_SEGMENT_NEXT:
			
			Counter := Counter + 1;
			MC_BR_AsmGetSegment_AcpTrak_0.Next := TRUE;
			InitState := INIT_STATE_GET_SEGMENT_WAIT;
			
		INIT_STATE_DONE:
			
			// Successfully completed the initialization process
			InitDone :=	TRUE;
		
		INIT_STATE_ERROR:
			
			// Wait until there are no more active errors. Error handling is managed by TrakCtrl task.
			// After the error has been reset, try again to repeat the initialization sequence.
			IF NOT pTrakCtrl.Status.Error THEN
				InitState := INIT_STATE_CHECK_ASM_COMM;
			END_IF
		
	END_CASE
	
END_ACTION
