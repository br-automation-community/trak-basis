//*********************************************************************************************************************
// COPYRIGHT - B&R Spain
//*********************************************************************************************************************
// Program: TrakCtrl
// File: TrakCtrl.st
// Author: B&R Spain
// Created: July 22, 2024
//*********************************************************************************************************************
// Implementation of program TrakCtrl
//*********************************************************************************************************************
// Description:
//  - This program initializes and controls the main AcoposTrak assembly.
//  - Handles assembly power states, shuttle management, error handling,
//    and movement commands through a state machine.
//*********************************************************************************************************************

PROGRAM _INIT

	// Initialization of state machines 
	InitState := INIT_STATE_SET_PARAMETER;
	TrakState := TRAK_STATE_DISABLED;
	
	gTrakShBackupRestoreData;
	
	// Determine if the CPU is running in simulation mode 
	InSimulation := DiagCpuIsSimulated();
	
END_PROGRAM

PROGRAM _CYCLIC

	//*****************************************************************************************************************
    // GETS REFERENCES TO STRUCTURES                                                    
    // ATTENTION: This must be the first part in the cyclic PROGRAM                     
    //*****************************************************************************************************************
	References;
	
	//*****************************************************************************************************************
	// INITIALIZATION SEQUENCE 										                    
	//*****************************************************************************************************************
	InitSequence;
	
	//*****************************************************************************************************************
	// FBK CALLS for reading status. EXACTLY ONE PER CYCLE                              
	//*****************************************************************************************************************
	
	//*********************** MC_BR_ASMREADINFO_ACPTRAK ***************************************************************
	MC_BR_AsmReadInfo_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmReadInfo_AcpTrak_0.Enable := NOT MC_BR_AsmReadInfo_AcpTrak_0.Error;
	MC_BR_AsmReadInfo_AcpTrak_0();
	
	//*********************** MC_BR_ASMREADSTATUS_ACPTRAK *************************************************************
	MC_BR_AsmReadStatus_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmReadStatus_AcpTrak_0.Enable := NOT MC_BR_AsmReadStatus_AcpTrak_0.Error;
	MC_BR_AsmReadStatus_AcpTrak_0();
	
	
	//*****************************************************************************************************************
	// CHECK IF SOME TRAK COMPONENT IS IN ERROR                                                                    
	//*****************************************************************************************************************
	IF MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop OR (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ShuttleCount.InErrorStop > 0) 
		OR (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.SegmentCount.InErrorStop > 0) THEN
		pTrakCtrl.Status.Error := TRUE;
		TrakState := TRAK_STATE_ERROR;
	END_IF	
		
	//*****************************************************************************************************************
	// MAIN SEQUENCE                                                                    
	//*****************************************************************************************************************
	
	CASE TrakState OF 
		
		TRAK_STATE_DISABLED:
			
			// Waits until InitSequence has finished before accepting commands 
			IF InitDone THEN
				IF pTrakCtrl.Command.Power THEN
					PowerOn;
					TrakState := TRAK_STATE_SWITCHING_ON;
				END_IF
			END_IF

		TRAK_STATE_SWITCHING_OFF:	
			
			IF MC_BR_AsmPowerOff_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSIF MC_BR_AsmPowerOff_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_DISABLED;
			END_IF
		
		TRAK_STATE_SWITCHING_ON:
			
			IF MC_BR_AsmPowerOn_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSIF MC_BR_AsmPowerOn_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_DEL_SHUTTLE;
			END_IF
			
			IF NOT pTrakCtrl.Command.Power THEN
				PowerOff;
				TrakState := TRAK_STATE_SWITCHING_OFF;
			END_IF	
			
		TRAK_STATE_DEL_SHUTTLE:
			
			// Clean the array where the shuttles axis are saved
			brsmemset(ADR(pTrakCtrl.Status.Shuttle),0,SIZEOF(pTrakCtrl.Status.Shuttle));
			DeleteShuttles;
			TrakState := TRAK_STATE_DEL_SHUTTLE_WAIT;
			
		TRAK_STATE_DEL_SHUTTLE_WAIT:
			
			IF MC_BR_AsmDeleteShuttle_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;			
			ELSIF MC_BR_AsmDeleteShuttle_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_ADD_SHUTTLE_INIT;
			END_IF	
				
		TRAK_STATE_ADD_SHUTTLE_INIT:
			
			// Only add shuttles when working in simulation
			IF InSimulation THEN
				// Check if requested quantity exceeds maximum allowed
				IF (pTrakCtrl.Parameter.SimulationParameters.Quantity > TRAK_MAX_SHUTTLE) THEN
					// Set application error for user feedback and abort shuttle adding
					pTrakCtrl.Status.Error := TRUE;
					pTrakCtrl.Status.ErrorInfo.ID := TRAK_APP_ERR_SIM_SH_COUNT_MAX;
					pTrakCtrl.Status.ErrorInfo.Initiator := 'Application';
					AuxString := UINT_TO_STRING(pTrakCtrl.Parameter.SimulationParameters.Quantity);
					pTrakCtrl.Status.ErrorInfo.Text := CONCAT('Requested shuttle quantity (',AuxString);
					pTrakCtrl.Status.ErrorInfo.Text := CONCAT(pTrakCtrl.Status.ErrorInfo.Text,') exceeds TRAK_MAX_SHUTTLE limit (');
					AuxString := UINT_TO_STRING(TRAK_MAX_SHUTTLE);
					pTrakCtrl.Status.ErrorInfo.Text := CONCAT(pTrakCtrl.Status.ErrorInfo.Text,AuxString);
					pTrakCtrl.Status.ErrorInfo.Text := CONCAT(pTrakCtrl.Status.ErrorInfo.Text,'). Operation aborted.');
					// Abort shuttle adding and go to error state
					TrakState := TRAK_STATE_ERROR;
				ELSE
					Counter := 0;
					TrakState := TRAK_STATE_ADD_SHUTTLE;
				END_IF
			ELSE
				TrakState := TRAK_STATE_GET_SHUTTLE_INIT;
			END_IF
			
		TRAK_STATE_ADD_SHUTTLE:
 
			IF Counter > (pTrakCtrl.Parameter.SimulationParameters.Quantity - 1) THEN
				TrakState := TRAK_STATE_GET_SHUTTLE_INIT;		
			ELSE 
				AddShuttles;
				Counter := Counter + 1;
				TrakState := TRAK_STATE_ADD_SHUTTLE_WAIT;	
			END_IF
			
		TRAK_STATE_ADD_SHUTTLE_WAIT:
				
			IF MC_BR_SecAddShuttle_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;		
			ELSIF MC_BR_SecAddShuttle_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_ADD_SHUTTLE;
			END_IF	
			
		TRAK_STATE_GET_SHUTTLE_INIT:
					
			MC_BR_SecGetShuttle_AcpTrak_0.Enable := TRUE;
			MC_BR_SecGetShuttle_AcpTrak_0.Next := FALSE;
			
			Counter := 0; 
			TrakState := TRAK_STATE_GET_SHUTTLE_WAIT;
		
		TRAK_STATE_GET_SHUTTLE:
			
			Counter := Counter + 1;
			MC_BR_SecGetShuttle_AcpTrak_0.Next := TRUE;
			TrakState := TRAK_STATE_GET_SHUTTLE_WAIT;
			
		TRAK_STATE_GET_SHUTTLE_WAIT:
			 
			IF (MC_BR_SecGetShuttle_AcpTrak_0.Error) THEN
				MC_BR_SecGetShuttle_AcpTrak_0.Enable := FALSE;
				MC_BR_SecGetShuttle_AcpTrak_0.Next := FALSE;
				TrakState := TRAK_STATE_ERROR;	
			ELSIF (MC_BR_SecGetShuttle_AcpTrak_0.Valid) THEN
				TotalCountShuttle := MC_BR_SecGetShuttle_AcpTrak_0.TotalCount;
				
				IF (MC_BR_SecGetShuttle_AcpTrak_0.TotalCount = 0) THEN
					MC_BR_SecGetShuttle_AcpTrak_0.Enable := FALSE;
					TrakState := TRAK_STATE_STANDSTILL;
				ELSE
					// Abort immediately if shuttle count exceeds maximum (safety critical for real hardware)
					IF (TotalCountShuttle > TRAK_MAX_SHUTTLE) THEN
						// Set application error for user feedback and abort operation
						pTrakCtrl.Status.Error := TRUE;
						pTrakCtrl.Status.ErrorInfo.ID := TRAK_APP_ERR_SH_COUNT_MAX;
						pTrakCtrl.Status.ErrorInfo.Initiator := 'Application';
						AuxString := UINT_TO_STRING(TotalCountShuttle);
						pTrakCtrl.Status.ErrorInfo.Text := CONCAT('Detected shuttle count (',AuxString);
						pTrakCtrl.Status.ErrorInfo.Text := CONCAT(pTrakCtrl.Status.ErrorInfo.Text,') exceeds TRAK_MAX_SHUTTLE limit (');
						AuxString := UINT_TO_STRING(TRAK_MAX_SHUTTLE);
						pTrakCtrl.Status.ErrorInfo.Text := CONCAT(pTrakCtrl.Status.ErrorInfo.Text,AuxString);
						pTrakCtrl.Status.ErrorInfo.Text := CONCAT(pTrakCtrl.Status.ErrorInfo.Text,'). Operation aborted for safety.');
						// Abort shuttle detection - could be dangerous to continue with unrecognized shuttles
						MC_BR_SecGetShuttle_AcpTrak_0.Enable := FALSE;
						MC_BR_SecGetShuttle_AcpTrak_0.Next := FALSE;
						TrakState := TRAK_STATE_ERROR;
					ELSE
						// Continue with shuttle processing - all shuttles within limit
						pTrakCtrl.Status.Shuttle[Counter].Axis := MC_BR_SecGetShuttle_AcpTrak_0.Axis;
						pTrakCtrl.Status.Shuttle[Counter].ID := MC_BR_SecGetShuttle_AcpTrak_0.AdditionalInfo.ShuttleID;
						
						// All shuttles have been retreived -> proceed
						IF (MC_BR_SecGetShuttle_AcpTrak_0.RemainingCount = 0) THEN
							Counter := 0;
							MC_BR_SecGetShuttle_AcpTrak_0.Enable := FALSE;
							TrakState := TRAK_STATE_SH_RESTORE_DATA_INIT;
						ELSE
							MC_BR_SecGetShuttle_AcpTrak_0.Next := FALSE;
							TrakState := TRAK_STATE_GET_SHUTTLE;
						END_IF
					END_IF	
				END_IF
			END_IF	
			
		TRAK_STATE_SH_RESTORE_DATA_INIT:
			
			pTrakCtrl.Status.RestoreShStatus := mcACPTRAK_RESTORE_NO_STATUS;
			
			// Official restore FB matches previously known shuttles by position; an empty UserID attempts to restore all of them at once
			MC_BR_AsmRestoreShData_AcpTrak_0.AdvancedParameters.Tolerance := pTrakCtrl.Parameter.RestoreTolerance;
			// When restore is disabled, wipe the remanent store instead so a future restore never matches stale identities
			IF pTrakCtrl.Parameter.RestoreEnabled THEN
				MC_BR_AsmRestoreShData_AcpTrak_0.AdvancedParameters.Mode := mcACPTRAK_RESTORE_TRY_RESTORING;
			ELSE
				MC_BR_AsmRestoreShData_AcpTrak_0.AdvancedParameters.Mode := mcACPTRAK_RESTORE_RESET_DATA;
			END_IF
			MC_BR_AsmRestoreShData_AcpTrak_0.Execute := TRUE;
			
			TrakState := TRAK_STATE_SH_RESTORE_DATA_WAIT;
			
		TRAK_STATE_SH_RESTORE_DATA_WAIT:
			
			IF MC_BR_AsmRestoreShData_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSIF MC_BR_AsmRestoreShData_AcpTrak_0.Done THEN
				// Reset-data outcome carries no restore-status meaning, so only read Info.Status when a restore was actually attempted
				IF NOT pTrakCtrl.Parameter.RestoreEnabled THEN
					Counter := 0;
					TrakState := TRAK_STATE_SH_RESTORE_ID;
				ELSE
					pTrakCtrl.Status.RestoreShStatus := MC_BR_AsmRestoreShData_AcpTrak_0.Info.Status;
					// No match by position -> fall back to assigning IDs by shuttle discovery order
					IF (pTrakCtrl.Status.RestoreShStatus = mcACPTRAK_RESTORE_NO_SH_RESTORED) OR (pTrakCtrl.Status.RestoreShStatus = mcACPTRAK_RESTORE_IDNOTFOUND) THEN
						Counter := 0;
						TrakState := TRAK_STATE_SH_RESTORE_ID;
					ELSE
						TrakState := TRAK_STATE_STANDSTILL;
					END_IF
				END_IF
			END_IF
			
		TRAK_STATE_SH_RESTORE_ID:
			
			IF (Counter > TRAK_MAX_SHUTTLE_MINUS_ONE) THEN
				TrakState := TRAK_STATE_STANDSTILL;
			ELSIF (pTrakCtrl.Status.Shuttle[Counter].Valid) THEN
				AuxString := UINT_TO_STRING(Counter);
				AuxString := CONCAT('Sh_',AuxString);
				
				MC_BR_ShSetUserID_AcpTrak_0.Axis := ADR(pTrakCtrl.Status.Shuttle[Counter].Axis);
				MC_BR_ShSetUserID_AcpTrak_0.UserID := AuxString;
				MC_BR_ShSetUserID_AcpTrak_0.Execute := TRUE;
				
				TrakState := TRAK_STATE_SH_RESTORE_ID_WAIT;
			ELSE
				Counter := Counter + 1;
			END_IF
			
		TRAK_STATE_SH_RESTORE_ID_WAIT:
			
			IF MC_BR_ShSetUserID_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSIF MC_BR_ShSetUserID_AcpTrak_0.Done THEN
				Counter := Counter + 1;
				TrakState := TRAK_STATE_SH_RESTORE_ID;
			END_IF

		TRAK_STATE_STANDSTILL:
			
			IF NOT pTrakCtrl.Command.Power THEN
				PowerOff;
				TrakState := TRAK_STATE_SWITCHING_OFF;
			ELSIF pTrakCtrl.Command.Move.Halt THEN
				// Shuttles cannot be halted if trak is in standstill 
				pTrakCtrl.Command.Move.Halt := FALSE;
			ELSIF pTrakCtrl.Command.Move.Absolute THEN
				pTrakCtrl.Command.Move.Absolute := FALSE;
				Counter := 0;
				TrakState := TRAK_STATE_MOVE_ABS;
			ELSIF pTrakCtrl.Command.Move.Velocity THEN
				pTrakCtrl.Command.Move.Velocity := FALSE;
				Counter := 0;
				TrakState := TRAK_STATE_MOVE_VEL;
			END_IF
			
		TRAK_STATE_MOVE_ABS:
			
			IF (Counter > TRAK_MAX_SHUTTLE_MINUS_ONE) THEN
				TrakState := TRAK_STATE_IN_MOTION;
			ELSIF (pTrakCtrl.Status.Shuttle[Counter].Valid) THEN
				MoveAbsolute;
				TrakState := TRAK_STATE_MOVE_ABS_WAIT;
			ELSE 
				Counter := Counter + 1;
			END_IF

		TRAK_STATE_MOVE_ABS_WAIT:
			
			IF MC_BR_ModuloMoveAbs_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSE
				Counter := Counter + 1;
				TrakState := TRAK_STATE_MOVE_ABS;
			END_IF
			
		TRAK_STATE_MOVE_VEL:
			
			IF (Counter > TRAK_MAX_SHUTTLE_MINUS_ONE) THEN
				TrakState := TRAK_STATE_IN_MOTION;
			ELSIF (pTrakCtrl.Status.Shuttle[Counter].Valid) THEN
				MoveVelocity;
				TrakState := TRAK_STATE_MOVE_VEL_WAIT;
			ELSE
				Counter := Counter + 1;
			END_IF
			
		TRAK_STATE_MOVE_VEL_WAIT:
			
			IF MC_BR_ElasticMoveVel_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSE
				Counter := Counter + 1;
				TrakState := TRAK_STATE_MOVE_VEL;
			END_IF
			
		TRAK_STATE_HALTING:
			
			IF MC_BR_AsmStop_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSIF MC_BR_AsmStop_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_STANDSTILL;
			END_IF
			
			IF NOT pTrakCtrl.Command.Power THEN
				PowerOff;
				TrakState := TRAK_STATE_SWITCHING_OFF;
			END_IF

		TRAK_STATE_IN_MOTION:
						
			IF NOT MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.MovementDetected THEN
				TrakState := TRAK_STATE_STANDSTILL;
			END_IF
			
			IF NOT pTrakCtrl.Command.Power THEN
				PowerOff;
				TrakState := TRAK_STATE_SWITCHING_OFF;
			ELSIF pTrakCtrl.Command.Move.Halt THEN
				pTrakCtrl.Command.Move.Halt := FALSE;
				Halt;
				TrakState := TRAK_STATE_HALTING;
			ELSIF pTrakCtrl.Command.Move.Absolute THEN
				pTrakCtrl.Command.Move.Absolute := FALSE;
				Counter := 0;
				TrakState := TRAK_STATE_MOVE_ABS;
			ELSIF pTrakCtrl.Command.Move.Velocity THEN
				pTrakCtrl.Command.Move.Velocity := FALSE;
				Counter := 0;
				TrakState := TRAK_STATE_MOVE_VEL;
			END_IF
			
		TRAK_STATE_STOPPING:
			
			IF MC_BR_AsmStop_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSIF MC_BR_AsmStop_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_STANDSTILL;
			END_IF
			
			IF NOT pTrakCtrl.Command.Power THEN
				PowerOff;
				TrakState := TRAK_STATE_SWITCHING_OFF;
			END_IF

		TRAK_STATE_ERROR: 
			
			// Reset PowerON command when an error is detected
			pTrakCtrl.Command.Power := FALSE;
			
			// Deletes the convoy from the convoy master axis before the error is reset
			FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
				IF pTrakCtrl.Status.Shuttle[i].IsConvoyMaster THEN
					MC_BR_ConDelete_AcpTrak_0[i].ConvoyMaster := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
					MC_BR_ConDelete_AcpTrak_0[i].Execute := pTrakCtrl.Status.Shuttle[i].State.StatusErrorStop;
				END_IF
			END_FOR
			
			// Reset errors in assembly (using "ErrorReset command") 
			IF pTrakCtrl.Command.ErrorReset THEN
				// Assembly and segment errors can be reset using MC_BR_AsmReset_AcpTrak FB
				IF MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop OR (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.SegmentCount.InErrorStop > 0) THEN
					MC_BR_AsmReset_AcpTrak_0.Execute := NOT MC_BR_AsmReset_AcpTrak_0.Error;	
				// Shuttle errors can be reset using MC_Reset
				ELSIF (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ShuttleCount.InErrorStop > 0) THEN
					FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
						MC_Reset_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
						MC_Reset_0[i].Execute := pTrakCtrl.Status.Shuttle[i].State.StatusErrorStop;
					END_FOR
				// When there are no more active hardware errors in the system, reset the command and leave error state
				ELSE
					IF pTrakCtrl.Status.PLCopenState.Disabled THEN	
						pTrakCtrl.Command.ErrorReset := FALSE;
						ClearError;
						TrakState := TRAK_STATE_DISABLED;
					ELSIF pTrakCtrl.Status.PLCopenState.Ready THEN
						pTrakCtrl.Command.ErrorReset := FALSE;
						ClearError;
						PowerOff;
						TrakState := TRAK_STATE_SWITCHING_OFF;
					END_IF		
				END_IF
			END_IF				
		
	END_CASE
	
	//*****************************************************************************************************************
	// READ ERRORS FROM TRAK SYSTEM - Based on suggestions from AS Help Guid: 5a0083f9-675b-490c-a00b-1306522f6dd4 
	// 1. ***Deviation from regular operation***: Check if there are elements in the Trak in state "ErrorStop"
	// 2. ***Identification of the "Initiator***: Identify the trigger of an error response ("Initiator")
	// 3. ***Collect detailed information***: Read the the error entry in Logger from the "Initiator".
	//*****************************************************************************************************************
	
	CASE TrakErrorState OF
		
		TRAK_ERR_STATE_WAIT:
			
			// When there is some trak element with an active error, find the initiator
			IF MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop OR (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ShuttleCount.InErrorStop > 0)
				OR (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.SegmentCount.InErrorStop > 0) THEN
				TrakErrorState := TRAK_ERR_STATE_FIND_INIT_ASM;
			END_IF
		
		TRAK_ERR_STATE_FIND_INIT_ASM:  
		
			// Checks if the assembly is the error initiator
			IF (MC_BR_AsmReadErrorInfo_AcpTrak_0.ErrorInfo.Initiator) THEN
				AdrErrorComponent := AdrAssembly;
				pTrakCtrl.Status.ErrorInfo.Initiator := 'Assembly';
			END_IF
			
			// Check if initiator has been found
			IF (AdrErrorComponent <> 0) THEN
				TrakErrorState := TRAK_ERR_STATE_COLLECT_LOG;
			ELSE
				TrakErrorState := TRAK_ERR_STATE_FIND_INIT_SEG;
			END_IF
				
		TRAK_ERR_STATE_FIND_INIT_SEG:
		
			// Checks if some segment is the error initiator
			FOR i:=0 TO TRAK_MAX_SEGMENT_MINUS_ONE DO
				IF MC_BR_SegReadErrorInfo_AcpTrak_0[i].ErrorInfo.Initiator THEN
					AdrErrorComponent := ADR(gTrakCtrl.Status.Segment[i].Segment);
					pTrakCtrl.Status.ErrorInfo.Initiator := pTrakCtrl.Status.Segment[i].Name;
					EXIT;
				END_IF
			END_FOR
			
			// Check if initiator has been found
			IF (AdrErrorComponent <> 0) THEN
				TrakErrorState := TRAK_ERR_STATE_COLLECT_LOG;
			ELSE
				TrakErrorState := TRAK_ERR_STATE_FIND_INIT_SH;
			END_IF	
			
		TRAK_ERR_STATE_FIND_INIT_SH:
			
			// Check if some shuttle is the initiator
			FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
				IF MC_BR_ShReadErrorInfo_AcpTrak_0[i].ErrorInfo.Initiator THEN
					AdrErrorComponent := ADR(gTrakCtrl.Status.Shuttle[i].Axis);
					pTrakCtrl.Status.ErrorInfo.Initiator := pTrakCtrl.Status.Shuttle[i].Name;
					EXIT;
				END_IF
			END_FOR	
			
			// Check if initiator has been found
			IF (AdrErrorComponent <> 0) THEN
				TrakErrorState := TRAK_ERR_STATE_COLLECT_LOG;
			ELSE
				pTrakCtrl.Status.ErrorInfo.Text := 'No initiator component found.';
				TrakErrorState := TRAK_ERR_STATE_DONE;
			END_IF
			
		TRAK_ERR_STATE_COLLECT_LOG:

			MC_BR_ReadErrorText_0.Component := AdrErrorComponent;
			MC_BR_ReadErrorText_0.Enable := (AdrErrorComponent <> 0);
			MC_BR_ReadErrorText_0.ReadNext := TRUE;
			TrakErrorState := TRAK_ERR_STATE_COLLECT_LOG_WAIT;
			
		TRAK_ERR_STATE_COLLECT_LOG_WAIT:	
		
			IF MC_BR_ReadErrorText_0.ReadDone THEN
				// Important to record the very first triggered error, the rest will not be recorded.  
				pTrakCtrl.Status.ErrorInfo.Text := MC_BR_ReadErrorText_0.ErrorRecords.Record[0].Text;
				pTrakCtrl.Status.ErrorInfo.ID := MC_BR_ReadErrorText_0.ErrorRecords.Record[0].EventID;
				TrakErrorState := TRAK_ERR_STATE_DONE;
			ELSIF MC_BR_ReadErrorText_0.Error THEN
				// When FB ouputs an error is because it could not communicate with motion component
				// In that case, mark it as a generic error and output the error ID
				pTrakCtrl.Status.ErrorInfo.Text := 'Unresponsive motion component.';
				pTrakCtrl.Status.ErrorInfo.ID := MC_BR_ReadErrorText_0.ErrorID;
				TrakErrorState := TRAK_ERR_STATE_DONE;
			END_IF
			
		TRAK_ERR_STATE_DONE:
		
			// Exit error state when all hardware errors in the trak system have been resolved
			// Only exit if this is a hardware error (not application error)
			IF NOT MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop AND NOT (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ShuttleCount.InErrorStop > 0) 
				AND NOT (MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.SegmentCount.InErrorStop > 0) THEN
				AdrErrorComponent := 0;
				MC_BR_ReadErrorText_0.Enable := FALSE;
				MC_BR_ReadErrorText_0.ReadNext := FALSE;
				TrakErrorState := TRAK_ERR_STATE_WAIT;
			END_IF
		
	END_CASE
	
	
	//*****************************************************************************************************************
	// FBK CALLS for TRAK handling. EXACTLY ONE PER CYCLE                                
	//*****************************************************************************************************************
	
	//************************* ASSEMBLY ***************************
	MC_BR_AsmPowerOn_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmPowerOn_AcpTrak_0();
	MC_BR_AsmPowerOn_AcpTrak_0.Execute := FALSE;

	MC_BR_AsmPowerOff_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmPowerOff_AcpTrak_0();
	MC_BR_AsmPowerOff_AcpTrak_0.Execute := FALSE;
	
	MC_BR_AsmGetSegment_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmGetSegment_AcpTrak_0();
	
	MC_BR_AsmStop_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmStop_AcpTrak_0();
	MC_BR_AsmStop_AcpTrak_0.Execute := FALSE;
	
	MC_BR_AsmDeleteShuttle_AcpTrak_0();
	MC_BR_AsmDeleteShuttle_AcpTrak_0.Execute := FALSE;
	
	MC_BR_AsmReset_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmReset_AcpTrak_0();
	MC_BR_AsmReset_AcpTrak_0.Execute := FALSE;
	
	MC_BR_AsmRestoreShData_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmRestoreShData_AcpTrak_0();
	MC_BR_AsmRestoreShData_AcpTrak_0.Execute := FALSE;
	
	//************************* SECTOR ***************************	
	MC_BR_SecAddShuttle_AcpTrak_0();
	MC_BR_SecAddShuttle_AcpTrak_0.Execute := FALSE;
	
	MC_BR_SecGetShuttle_AcpTrak_0.Sector := AdrSector;
	MC_BR_SecGetShuttle_AcpTrak_0();
	
	//************************* SEGMENTS ***************************
	TON_0.IN := NOT TON_0.Q;
	TON_0.PT := T#5s;
	TON_0();
	
	//************************* SHUTTLES ***************************
	MC_BR_ModuloMoveAbs_AcpTrak_0();
	MC_BR_ModuloMoveAbs_AcpTrak_0.Execute := FALSE;
	
	MC_BR_ElasticMoveVel_AcpTrak_0();
	MC_BR_ElasticMoveVel_AcpTrak_0.Execute := FALSE;
	
	FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
		MC_Reset_0[i]();
		MC_Reset_0[i].Execute := FALSE;
	END_FOR
	
	MC_BR_ShSetUserID_AcpTrak_0();
	MC_BR_ShSetUserID_AcpTrak_0.Execute := FALSE;
	
	FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
		MC_BR_ConDelete_AcpTrak_0[i].AdvancedParameters.Mode := mcACPTRAK_CON_DELETE_ANY_CASE;
		MC_BR_ConDelete_AcpTrak_0[i]();
		MC_BR_ConDelete_AcpTrak_0[i].Execute := FALSE;
	END_FOR
	
	//*****************************************************************************************************************
	// PROVIDES ERROR INFORMATION                                                                  
	//*****************************************************************************************************************
	
	//************************* ASSEMBLY ***************************
	MC_BR_AsmReadErrorInfo_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmReadErrorInfo_AcpTrak_0.Enable := NOT MC_BR_AsmReadErrorInfo_AcpTrak_0.Error;
	MC_BR_AsmReadErrorInfo_AcpTrak_0();

	//************************* SEGMENTS ***************************
	FOR i:=0 TO TRAK_MAX_SEGMENT_MINUS_ONE DO
		
		MC_BR_SegReadErrorInfo_AcpTrak_0[i].Segment := ADR(pTrakCtrl.Status.Segment[i].Segment);
		MC_BR_SegReadErrorInfo_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Segment[i].Segment.controlif <> 0);
		MC_BR_SegReadErrorInfo_AcpTrak_0[i]();
		
	END_FOR
	
	//************************* SHUTTLES ***************************
	FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
		
		MC_BR_ShReadErrorInfo_AcpTrak_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
		MC_BR_ShReadErrorInfo_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Shuttle[i].Axis.controlif <> 0);
		MC_BR_ShReadErrorInfo_AcpTrak_0[i]();
		
	END_FOR
	
	//************************* GENERIC - READ LOGGER ENTRIES ***************************
	MC_BR_ReadErrorText_0();
	
	//*****************************************************************************************************************
	// PROVIDES STATUS                                                                  
	//*****************************************************************************************************************
	
	//************************* ASSEMBLY ***************************	
	
	pTrakCtrl.Status.CommunicationReady := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.CommunicationReady;
	pTrakCtrl.Status.ReadyForPowerOn := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ReadyForPowerOn;
	pTrakCtrl.Status.PowerOn := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PowerOn;
	pTrakCtrl.Status.MovementDetected := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.MovementDetected;
		
	pTrakCtrl.Status.PLCopenState.Disabled := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_DISABLED;
	pTrakCtrl.Status.PLCopenState.ErrorStop := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_ERRORSTOP;
	pTrakCtrl.Status.PLCopenState.Homing := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_HOMING;
	pTrakCtrl.Status.PLCopenState.InvalidConfigurartion := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_INVALID_CONFIGURATION;
	pTrakCtrl.Status.PLCopenState.Ready := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_READY;
	pTrakCtrl.Status.PLCopenState.StartUp := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_STARTUP; 
	pTrakCtrl.Status.PLCopenState.Stopping := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_STOPPING;
	
	//************************* SEGMENTS ***************************	
	FOR i:=0 TO TRAK_MAX_SEGMENT_MINUS_ONE DO
		
		MC_BR_SegReadStatus_AcpTrak_0[i].Segment := ADR(pTrakCtrl.Status.Segment[i].Segment);
		MC_BR_SegReadStatus_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Segment[i].Segment.controlif <> 0);
		MC_BR_SegReadStatus_AcpTrak_0[i]();
		
		pTrakCtrl.Status.Segment[i].Valid := (MC_BR_SegReadStatus_AcpTrak_0[i].Valid);
		
		IF (pTrakCtrl.Status.Segment[i].Valid) THEN
			pTrakCtrl.Status.Segment[i].State.StatusDisabled := MC_BR_SegReadStatus_AcpTrak_0[i].SegmentDisabled;
			pTrakCtrl.Status.Segment[i].State.StatusReady := MC_BR_SegReadStatus_AcpTrak_0[i].SegmentReady;
			pTrakCtrl.Status.Segment[i].State.StatusErrorStop := MC_BR_SegReadStatus_AcpTrak_0[i].SegmentErrorStop;
			pTrakCtrl.Status.Segment[i].State.InvalidConfig := MC_BR_SegReadStatus_AcpTrak_0[i].SegmentInvalidConfig;
		END_IF
		
		IF MC_BR_SegGetInfo_AcpTrak_0[i].Done THEN
			pTrakCtrl.Status.Segment[i].Name := MC_BR_SegGetInfo_AcpTrak_0[i].SegmentInfo.Name;
		END_IF
		
		MC_BR_SegGetInfo_AcpTrak_0[i].Segment := ADR(pTrakCtrl.Status.Segment[i].Segment);
		MC_BR_SegGetInfo_AcpTrak_0[i].Execute := (pTrakCtrl.Status.Segment[i].Segment.controlif <> 0) AND TON_0.Q AND pTrakCtrl.Status.PowerOn;
		MC_BR_SegGetInfo_AcpTrak_0[i]();
		MC_BR_SegGetInfo_AcpTrak_0[i].Execute := FALSE;
		
		// Segments parameters readings		
		// 1. Voltage - Should be 58V in opertation
		SegmentProcessParId[0].DataType := mcACPTRAK_SEG_PARTYPE_REAL;
		SegmentProcessParId[0].ParID := 298;
		SegmentProcessParId[0].VariableAddress := ADR(pTrakCtrl.Status.Segment[i].Info.Voltage);
		// 2. Direct Axis Current - Used to find power consumption
		SegmentProcessParId[1].DataType := mcACPTRAK_SEG_PARTYPE_REAL; 
		SegmentProcessParId[1].ParID := 218;
		SegmentProcessParId[1].VariableAddress := ADR(SegmentDCurrent[i]);
		// 3. Q-axis Current - Used to find power consumption
		SegmentProcessParId[2].DataType := mcACPTRAK_SEG_PARTYPE_REAL;
		SegmentProcessParId[2].ParID := 213;
		SegmentProcessParId[2].VariableAddress := ADR(SegmentQCurrent[i]);
		// 4. Temperature Balancer - Warning 90�C / Error at 95�C - Internal ambient temperature of segment
		SegmentProcessParId[3].DataType := mcACPTRAK_SEG_PARTYPE_REAL;
		SegmentProcessParId[3].ParID := 63648;
		SegmentProcessParId[3].VariableAddress := ADR(pTrakCtrl.Status.Segment[i].Info.TempBalancer);
		// 5. Temperature Air - Warning 75�C / Error at 80�C - CPU temperature
		SegmentProcessParId[4].DataType := mcACPTRAK_SEG_PARTYPE_REAL;
		SegmentProcessParId[4].ParID := 63647;
		SegmentProcessParId[4].VariableAddress := ADR(pTrakCtrl.Status.Segment[i].Info.TempAir);
		// 6. Tempreature Sensor - Warning 75�C / Error at 80�C - Back side of segment in the center
		SegmentProcessParId[5].DataType := mcACPTRAK_SEG_PARTYPE_REAL;
		SegmentProcessParId[5].ParID := 861;
		SegmentProcessParId[5].VariableAddress := ADR(pTrakCtrl.Status.Segment[i].Info.TempSensor);
		// 7. Power consumption
		pTrakCtrl.Status.Segment[i].Info.PowerConsumption := pTrakCtrl.Status.Segment[i].Info.Voltage * SQRT(SegmentQCurrent[i]**2 + SegmentDCurrent[i]**2);
		
		MC_BR_SegProcessParID_AcpTrak_0[i].Segment := ADR(pTrakCtrl.Status.Segment[i].Segment);
		MC_BR_SegProcessParID_AcpTrak_0[i].ChannelIndex := 0;
		MC_BR_SegProcessParID_AcpTrak_0[i].DataAddress := ADR(SegmentProcessParId);
		MC_BR_SegProcessParID_AcpTrak_0[i].NumberOfParIDs := 6;
		IF NOT InSimulation THEN
			MC_BR_SegProcessParID_AcpTrak_0[i].Execute := TON_0.Q AND pTrakCtrl.Status.PowerOn;
		END_IF
		MC_BR_SegProcessParID_AcpTrak_0[i]();
		MC_BR_SegProcessParID_AcpTrak_0[i].Execute := FALSE;
		
	END_FOR
	
	//************************* SHUTTLES ***************************	
	FOR i:=0 TO TRAK_MAX_SHUTTLE_MINUS_ONE DO
	
		MC_BR_ShReadInfo_AcpTrak_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
		MC_BR_ShReadInfo_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Shuttle[i].Axis.controlif <> 0);
		MC_BR_ShReadInfo_AcpTrak_0[i]();
		
		MC_BR_ShReadFrame_AcpTrak_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
		MC_BR_ShReadFrame_AcpTrak_0[i].CoordSystem := mcMCS;
		MC_BR_ShReadFrame_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Shuttle[i].Axis.controlif <> 0);
		MC_BR_ShReadFrame_AcpTrak_0[i]();
		
		MC_BR_ShReadSectorPos_AcpTrak_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
		MC_BR_ShReadSectorPos_AcpTrak_0[i].Sector := AdrSector;
		MC_BR_ShReadSectorPos_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Shuttle[i].Axis.controlif <> 0);
		MC_BR_ShReadSectorPos_AcpTrak_0[i]();

		MC_ReadStatus_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
		MC_ReadStatus_0[i].Enable := (pTrakCtrl.Status.Shuttle[i].Axis.controlif <> 0);
		MC_ReadStatus_0[i]();

		pTrakCtrl.Status.Shuttle[i].Valid := (MC_BR_ShReadInfo_AcpTrak_0[i].Valid AND MC_ReadStatus_0[i].Valid);
		
		IF(pTrakCtrl.Status.Shuttle[i].Valid)THEN
			pTrakCtrl.Status.Shuttle[i].Name := MC_BR_ShReadInfo_AcpTrak_0[i].ShuttleInfo.AdditionalInfo.UserID;
			pTrakCtrl.Status.Shuttle[i].ActSectorType := MC_BR_ShReadInfo_AcpTrak_0[i].ShuttleInfo.CurrentValues.SectorType;
			pTrakCtrl.Status.Shuttle[i].ActSector := MC_BR_ShReadInfo_AcpTrak_0[i].ShuttleInfo.CurrentValues.SectorName;
			// Important to use MC_BR_ShReadSectorPos to get the absolute current position within the predefined sector
			pTrakCtrl.Status.Shuttle[i].ActPosition := MC_BR_ShReadSectorPos_AcpTrak_0[i].Info.Position;
			pTrakCtrl.Status.Shuttle[i].ActVelocity := MC_BR_ShReadInfo_AcpTrak_0[i].ShuttleInfo.CurrentValues.Velocity;
			pTrakCtrl.Status.Shuttle[i].TotalMoveDistance := MC_BR_ShReadInfo_AcpTrak_0[i].ShuttleInfo.LifeCycleInfo.AbsoluteMovementDistance;
			pTrakCtrl.Status.Shuttle[i].IsConvoyMaster := MC_BR_ShReadInfo_AcpTrak_0[i].ShuttleInfo.ConvoyInfo.IsConvoyMaster;
			pTrakCtrl.Status.Shuttle[i].Pos := MC_BR_ShReadFrame_AcpTrak_0[i].Frame.Pos;
			pTrakCtrl.Status.Shuttle[i].State.StatusStandStill := MC_ReadStatus_0[i].StandStill;
			pTrakCtrl.Status.Shuttle[i].State.StatusStopping := MC_ReadStatus_0[i].Stopping;
			pTrakCtrl.Status.Shuttle[i].State.StatusErrorStop := MC_ReadStatus_0[i].ErrorStop;
			pTrakCtrl.Status.Shuttle[i].State.StatusDiscreteMotion := MC_ReadStatus_0[i].DiscreteMotion;
			pTrakCtrl.Status.Shuttle[i].State.StatusContinuousMotion := MC_ReadStatus_0[i].ContinuousMotion;
			pTrakCtrl.Status.Shuttle[i].State.StatusSynchronizedMotion := MC_ReadStatus_0[i].SynchronizedMotion;
		END_IF
		
	END_FOR
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

