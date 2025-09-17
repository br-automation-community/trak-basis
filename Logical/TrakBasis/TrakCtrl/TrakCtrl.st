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
	IF MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop OR MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ShuttleCount.InErrorStop > 0 
		OR MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.SegmentCount.InErrorStop > 0 THEN
		TrakState := TRAK_STATE_ERROR;
	END_IF	
		
	//*****************************************************************************************************************
	// MAIN SEQUENCE                                                                    
	//*****************************************************************************************************************
	
	// Handle warning acknowledgment (can be done from any state)
	IF pTrakCtrl.Command.WarningAcknowledge THEN
		pTrakCtrl.Status.Warning := FALSE;
		pTrakCtrl.Status.WarningInfo.ID := 0;
		pTrakCtrl.Status.WarningInfo.Text := '';
		pTrakCtrl.Status.WarningInfo.TrakState := '';
		pTrakCtrl.Command.WarningAcknowledge := FALSE;
	END_IF
	
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
			// Stop recording shuttle positions before deleted and until next movement is detected
			RemShPosRequired := FALSE;
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
					// Set application warning for user feedback and abort shuttle adding
					pTrakCtrl.Status.Warning := TRUE;
					pTrakCtrl.Status.WarningInfo.ID := 100; // Warning code for shuttle quantity exceeded
					AuxString := UINT_TO_STRING(pTrakCtrl.Parameter.SimulationParameters.Quantity);
					pTrakCtrl.Status.WarningInfo.Text := CONCAT('Requested shuttle quantity (',AuxString);
					pTrakCtrl.Status.WarningInfo.Text := CONCAT(pTrakCtrl.Status.WarningInfo.Text,') exceeds TRAK_MAX_SHUTTLE limit (');
					AuxString := UINT_TO_STRING(TRAK_MAX_SHUTTLE);
					pTrakCtrl.Status.WarningInfo.Text := CONCAT(pTrakCtrl.Status.WarningInfo.Text,AuxString);
					pTrakCtrl.Status.WarningInfo.Text := CONCAT(pTrakCtrl.Status.WarningInfo.Text,'). Operation aborted.');
					pTrakCtrl.Status.WarningInfo.TrakState := 'TRAK_STATE_ADD_SHUTTLE_INIT';
					// Abort shuttle adding and go to standstill
					TrakState := TRAK_STATE_STANDSTILL;
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
						// Set application warning for user feedback and abort operation
						pTrakCtrl.Status.Warning := TRUE;
						pTrakCtrl.Status.WarningInfo.ID := 101; // Warning code for shuttle count exceeded after detection
						AuxString := UINT_TO_STRING(TotalCountShuttle);
						pTrakCtrl.Status.WarningInfo.Text := CONCAT('Detected shuttle count (',AuxString);
						pTrakCtrl.Status.WarningInfo.Text := CONCAT(pTrakCtrl.Status.WarningInfo.Text,') exceeds TRAK_MAX_SHUTTLE limit (');
						AuxString := UINT_TO_STRING(TRAK_MAX_SHUTTLE);
						pTrakCtrl.Status.WarningInfo.Text := CONCAT(pTrakCtrl.Status.WarningInfo.Text,AuxString);
						pTrakCtrl.Status.WarningInfo.Text := CONCAT(pTrakCtrl.Status.WarningInfo.Text,'). Operation aborted for safety.');
						pTrakCtrl.Status.WarningInfo.TrakState := 'TRAK_STATE_GET_SHUTTLE_WAIT';
						// Abort shuttle detection - could be dangerous to continue with unrecognized shuttles
						MC_BR_SecGetShuttle_AcpTrak_0.Enable := FALSE;
						MC_BR_SecGetShuttle_AcpTrak_0.Next := FALSE;
						TrakState := TRAK_STATE_STANDSTILL;
					ELSE
						// Continue with shuttle processing - all shuttles within limit
						Counter := Counter + 1;
						pTrakCtrl.Status.Shuttle[Counter].Axis := MC_BR_SecGetShuttle_AcpTrak_0.Axis;
						pTrakCtrl.Status.Shuttle[Counter].ID := MC_BR_SecGetShuttle_AcpTrak_0.AdditionalInfo.ShuttleID;
						
						// Define shuttle user ID (very useful with shuttle error diagnosis)
						AuxString := UINT_TO_STRING(Counter);
						AuxString := CONCAT('Sh_',AuxString);
						
						MC_BR_ShSetUserID_AcpTrak_0.Axis := ADR(MC_BR_SecGetShuttle_AcpTrak_0.Axis);
						MC_BR_ShSetUserID_AcpTrak_0.UserID := AuxString;
						MC_BR_ShSetUserID_AcpTrak_0.Execute := TRUE;
						
						// All shuttles have been retreived -> proceed
						IF (MC_BR_SecGetShuttle_AcpTrak_0.RemainingCount = 0) THEN
							Counter := 0;
							MC_BR_SecGetShuttle_AcpTrak_0.Enable := FALSE;
							IF pTrakCtrl.Parameter.RestoreEnabled THEN
								TrakState := TRAK_STATE_SH_RESTORE_ID_INIT;
							ELSE
								TrakState := TRAK_STATE_STANDSTILL;
							END_IF
						ELSE
							MC_BR_SecGetShuttle_AcpTrak_0.Next := FALSE;
							TrakState := TRAK_STATE_GET_SHUTTLE;
						END_IF
					END_IF	
				END_IF
			END_IF	
			
		TRAK_STATE_SH_RESTORE_ID_INIT:
			
			brsmemset(ADR(pTrakCtrl.Status.ShRecoveryInfo),0,SIZEOF(pTrakCtrl.Status.ShRecoveryInfo));
			// Check how many available shuttle data is stored in remanent memory
			RestoreShuttleNumber := 0;
			FOR i:=1 TO TRAK_MAX_SHUTTLE DO
				IF (RemShPosition[i] <> 0) THEN
					RestoreShuttleNumber := RestoreShuttleNumber + 1; 
				END_IF
			END_FOR
			
			// Save shuttle axis in temporary variable (used in next state for shuttle reshuffle)
			brsmemset(ADR(AuxShuttleAxis),0,SIZEOF(AuxShuttleAxis));
			FOR i:=1 TO TRAK_MAX_SHUTTLE DO
				AuxShuttleAxis[i] := pTrakCtrl.Status.Shuttle[i].Axis;
			END_FOR
			
			// Same amount of shuttles detected than available shuttle positions (try to restore IDs)
			IF TotalCountShuttle = RestoreShuttleNumber THEN
				TrakState := TRAK_STATE_SH_RESTORE_ID; 
				// Different amount of shuttles detected than available shuttle positions (ID restoration can not be performed)	
			ELSE
				IF RestoreShuttleNumber = 0 THEN
					pTrakCtrl.Status.ShRecoveryInfo.ShuttleNoData := TRUE;
				ELSIF RestoreShuttleNumber > TotalCountShuttle THEN
					brsmemset(ADR(RemShPosition),0,SIZEOF(RemShPosition));
					pTrakCtrl.Status.ShRecoveryInfo.ShuttleMissing := TRUE;
				ELSIF RestoreShuttleNumber < TotalCountShuttle THEN
					brsmemset(ADR(RemShPosition),0,SIZEOF(RemShPosition));
					pTrakCtrl.Status.ShRecoveryInfo.ShuttleExtra := TRUE;
				END_IF
				TrakState := TRAK_STATE_STANDSTILL;
			END_IF
			
		TRAK_STATE_SH_RESTORE_ID:
			
			brsmemset(ADR(EquivalentShPos),0,SIZEOF(EquivalentShPos));
			brsmemset(ADR(AuxAxisAssigned),0,SIZEOF(AuxAxisAssigned));
			
			// Find equivalent positions
			FOR i:=1 TO TRAK_MAX_SHUTTLE DO
				FOR j:=1 TO TRAK_MAX_SHUTTLE DO
					// Make sure that data can only be assigned once
					IF NOT AuxAxisAssigned[j] THEN
						// Check if there is a shuttle at some existing position within a predefine tolerance
						IF ABS(MC_BR_ShReadSectorPos_AcpTrak_0[i].Info.Position - RemShPosition[j]) < pTrakCtrl.Parameter.RestoreTolerance THEN
							EquivalentShPos[i] := j;
							AuxAxisAssigned[j] := TRUE;
							EXIT;
						END_IF
					END_IF
				END_FOR
			END_FOR
			
			// Reshuffle shuttles	
			pTrakCtrl.Status.ShRecoveryInfo.ShuttleRecovered := TRUE;
					
			FOR i:=1 TO TRAK_MAX_SHUTTLE DO
				
				// All shuttle related function blocks that use "Enable" input needs to be disabled before shuttle axis reference is updated!
				MC_BR_ShReadInfo_AcpTrak_0[i].Enable := FALSE;
				MC_BR_ShReadInfo_AcpTrak_0[i]();
		
				MC_BR_ShReadFrame_AcpTrak_0[i].Enable := FALSE;
				MC_BR_ShReadFrame_AcpTrak_0[i]();
		
				MC_BR_ShReadSectorPos_AcpTrak_0[i].Enable := FALSE;
				MC_BR_ShReadSectorPos_AcpTrak_0[i]();

				MC_ReadStatus_0[i].Enable := FALSE;
				MC_ReadStatus_0[i]();
				
				MC_BR_ShReadErrorInfo_AcpTrak_0[i].Enable := FALSE;
				MC_BR_ShReadErrorInfo_AcpTrak_0[i]();
				
				// Restore shuttle references for all matching positions
				IF (EquivalentShPos[i] <> 0) THEN
					pTrakCtrl.Status.Shuttle[EquivalentShPos[i]].Axis := AuxShuttleAxis[i];
				ELSE
					// Abort shuttle restore sequence (Some shuttle position is not matching)
					FOR j:=1 TO TRAK_MAX_SHUTTLE DO
						pTrakCtrl.Status.Shuttle[j].Axis := AuxShuttleAxis[j];
					END_FOR
					pTrakCtrl.Status.ShRecoveryInfo.ShuttleMoved := TRUE;
					pTrakCtrl.Status.ShRecoveryInfo.ShuttleRecovered := FALSE;
					EXIT;
				END_IF
			END_FOR			
			
			Counter := 0;
			TrakState := TRAK_STATE_SH_RESTORE_UID;			
			
		TRAK_STATE_SH_RESTORE_UID:
			
			Counter := Counter + 1;
			IF pTrakCtrl.Status.Shuttle[Counter].Valid THEN
				// Define shuttle user ID (very useful with shuttle error diagnosis)
				AuxString := UINT_TO_STRING(Counter);
				AuxString := CONCAT('Sh_',AuxString);
							
				MC_BR_ShSetUserID_AcpTrak_0.Axis := ADR(pTrakCtrl.Status.Shuttle[Counter].Axis);
				MC_BR_ShSetUserID_AcpTrak_0.UserID := AuxString;
				MC_BR_ShSetUserID_AcpTrak_0.Execute := TRUE;
				
				TrakState := TRAK_STATE_SH_RESTORE_UID_WAIT;
			ELSE
				TrakState := TRAK_STATE_STANDSTILL;
			END_IF
			
		TRAK_STATE_SH_RESTORE_UID_WAIT:	
			
			IF MC_BR_ShSetUserID_AcpTrak_0.Done THEN
				TrakState := TRAK_STATE_SH_RESTORE_UID;
			END_IF		

		TRAK_STATE_STANDSTILL:
			
			RemShPosRequired := TRUE;
			
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
			
			Counter := Counter + 1;
			IF (Counter > TRAK_MAX_SHUTTLE) THEN
				TrakState := TRAK_STATE_IN_MOTION;
			ELSIF (pTrakCtrl.Status.Shuttle[Counter].Valid) THEN
				MoveAbsolute;
				TrakState := TRAK_STATE_MOVE_ABS_WAIT;
			END_IF

		TRAK_STATE_MOVE_ABS_WAIT:
			
			IF MC_BR_ModuloMoveAbs_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSE
				TrakState := TRAK_STATE_MOVE_ABS;
			END_IF
			
		TRAK_STATE_MOVE_VEL:
			
			Counter := Counter + 1;
			IF (Counter > TRAK_MAX_SHUTTLE) THEN
				TrakState := TRAK_STATE_IN_MOTION;
			ELSIF (pTrakCtrl.Status.Shuttle[Counter].Valid) THEN
				MoveVelocity;
				TrakState := TRAK_STATE_MOVE_VEL_WAIT;
			END_IF
			
		TRAK_STATE_MOVE_VEL_WAIT:
			
			IF MC_BR_ElasticMoveVel_AcpTrak_0.Error THEN
				TrakState := TRAK_STATE_ERROR;
			ELSE
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
			FOR i:=1 TO TRAK_MAX_SHUTTLE DO
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
					FOR i:=1 TO TRAK_MAX_SHUTTLE DO
						MC_Reset_0[i].Axis := ADR(pTrakCtrl.Status.Shuttle[i].Axis);
						MC_Reset_0[i].Execute := pTrakCtrl.Status.Shuttle[i].State.StatusErrorStop;
					END_FOR
					// When there are no more active errors in the system, reset the command and leave error state
				ELSE
					// Wait until error has been reset
					IF pTrakCtrl.Status.PLCopenState.Disabled THEN	
						pTrakCtrl.Command.ErrorReset := FALSE;
						TrakState := TRAK_STATE_DISABLED;
					ELSIF pTrakCtrl.Status.PLCopenState.Ready THEN
						pTrakCtrl.Command.ErrorReset := FALSE;
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
			IF pTrakCtrl.Status.Error THEN
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
			FOR i:=1 TO TRAK_MAX_SEGMENT DO
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
			FOR i:=1 TO TRAK_MAX_SHUTTLE DO
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
		
			IF NOT pTrakCtrl.Status.Error THEN
				AdrErrorComponent := 0;
				pTrakCtrl.Status.ErrorInfo.Text := '';
				pTrakCtrl.Status.ErrorInfo.Initiator := '';
				pTrakCtrl.Status.ErrorInfo.ID := 0;
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
	
	FOR i:=1 TO TRAK_MAX_SHUTTLE DO
		MC_Reset_0[i]();
		MC_Reset_0[i].Execute := FALSE;
	END_FOR
	
	MC_BR_ShSetUserID_AcpTrak_0();
	MC_BR_ShSetUserID_AcpTrak_0.Execute := FALSE;
	
	FOR i:=1 TO TRAK_MAX_SHUTTLE DO
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
	FOR i:=1 TO TRAK_MAX_SEGMENT DO
		
		MC_BR_SegReadErrorInfo_AcpTrak_0[i].Segment := ADR(pTrakCtrl.Status.Segment[i].Segment);
		MC_BR_SegReadErrorInfo_AcpTrak_0[i].Enable := (pTrakCtrl.Status.Segment[i].Segment.controlif <> 0);
		MC_BR_SegReadErrorInfo_AcpTrak_0[i]();
		
	END_FOR
	
	//************************* SHUTTLES ***************************
	FOR i:=1 TO TRAK_MAX_SHUTTLE DO
		
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
	pTrakCtrl.Status.Error := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop 
							OR MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.ShuttleCount.InErrorStop > 0 
							OR MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.SegmentCount.InErrorStop > 0;
		
	pTrakCtrl.Status.PLCopenState.Disabled := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_DISABLED;
	pTrakCtrl.Status.PLCopenState.ErrorStop := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_ERRORSTOP;
	pTrakCtrl.Status.PLCopenState.Homing := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_HOMING;
	pTrakCtrl.Status.PLCopenState.InvalidConfigurartion := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_INVALID_CONFIGURATION;
	pTrakCtrl.Status.PLCopenState.Ready := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_READY;
	pTrakCtrl.Status.PLCopenState.StartUp := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_STARTUP; 
	pTrakCtrl.Status.PLCopenState.Stopping := MC_BR_AsmReadInfo_AcpTrak_0.AssemblyInfo.PLCopenState = mcACPTRAK_STOPPING;
	
	//************************* SEGMENTS ***************************	
	FOR i:=1 TO TRAK_MAX_SEGMENT DO
		
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
	FOR i:=1 TO TRAK_MAX_SHUTTLE DO
	
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
				
		// Save actual shuttle positions to remanent memory (used to recover shuttle IDs after powering up the system)
		IF RemShPosRequired AND pTrakCtrl.Status.Shuttle[i].Valid THEN 
			RemShPosition[i] := pTrakCtrl.Status.Shuttle[i].ActPosition;
		END_IF
		
	END_FOR
	
		
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

