(********************************************************************
 * COPYRIGHT - B&R Spain
 ********************************************************************
 * Package: TrakBasis
 * File: TrakBasis.typ
 * Author: B&R Spain
 * Created: July 22, 2024
 * Modified: July 22, 2024
 ********************************************************************
 * Data types of package TrakBasis for mapp Motion
 ********************************************************************)
(*********************************************************************
* TrakCtrl structures
*********************************************************************)

TYPE
	TrakApplicationErrorEnum : 
		(
		TRAK_APP_ERROR_NONE := 0,
		TRAK_APP_ERR_SIM_SH_COUNT_MAX := 100,
		TRAK_APP_ERR_SH_COUNT_MAX := 101,
		TRAK_APP_ERR_SEG_COUNT_MAX := 102,
		TRAK_APP_ERR_SEG_INDEX_MAX := 103,
		TRAK_APP_ERR_NO_SEGMENTS := 104
		);
	TrakCtrlType : 	STRUCT  (*Control structure*)
		Command : TrakCtrlCmdType; (*Command structure*)
		Parameter : TrakCtrlParType; (*Parameter structure*)
		Status : TrakCtrlStatusType; (*Status structure*)
	END_STRUCT;
	TrakCtrlCmdType : 	STRUCT  (*Command structure*)
		Power : BOOL; (*Switch on the controller*)
		Move : TrakCtrlCmdMoveType; (*Movement structures*)
		ErrorReset : BOOL; (*Reset the error in assembly*)
		Recover : TrakCtrlCmdRecoverType; (*Shuttle identity recovery commands*)
	END_STRUCT;
	TrakCtrlCmdMoveType : 	STRUCT  (*Movement structures*)
		Absolute : BOOL; (*Elastic move absolute of all the shuttles to a predefined position*)
		Velocity : BOOL; (*Velocity move of all the shuttles within the predefined sector*)
		Halt : BOOL; (*Stops all shuttle movements*)
	END_STRUCT;
	TrakCtrlCmdRecoverType : 	STRUCT  (*Shuttle identity recovery commands*)
		Index : UINT; (*Index in Status.Shuttle[] of the shuttle to identify*)
		UserID : STRING[32]; (*UserID supplied externally (e.g. by a camera recognition system)*)
		Execute : BOOL; (*Assigns UserID to the shuttle at Index*)
		ResetShuttleData : BOOL; (*Wipes the remanent shuttle backup/restore store (mcACPTRAK_RESTORE_RESET_DATA)*)
	END_STRUCT;
	TrakCtrlParType : 	STRUCT  (*Parameter structure*)
		Position : LREAL; (*Position of the commanded movement for the selecred shuttle*)
		Direction : McDirectionEnum; (*Direction of the commanded movement for the selecred shuttle*)
		Speed : REAL; (*Velocity of the commanded movement for the selecred shuttle*)
		Acceleration : REAL; (*Acceleration of the commanded movement for the selecred shuttle*)
		Deceleration : REAL; (*Deceleration of the commanded movement for the selecred shuttle*)
		RestoreEnabled : BOOL; (*The system try to restore shuttle positions after power on*)
		RestoreTolerance : LREAL; (*Discrepancy allowed when restoring position*)
		SimulationParameters : TrakCtrlParSimType; (*Simulation parameter for the trak system*)
		Override : TrakCtrlParOverrideType; (*Speed override parameters for the assembly*)
	END_STRUCT;
	TrakCtrlParSimType : 	STRUCT  (*Parameter for when trak is being simulated*)
		Position : LREAL; (*Position of first shuttle*)
		Separation : LREAL; (*Separation between shuttles*)
		Quantity : UINT; (*Quantity of the shuttles*)
	END_STRUCT;
	TrakCtrlParOverrideType : 	STRUCT  (*Speed override parameters for the assembly*)
		Enable : BOOL; (*Enables the velocity override on the assembly*)
		Factor : REAL; (*Override percentage (0-100) applied to shuttle velocity when Enable is TRUE*)
	END_STRUCT;
	TrakCtrlStatusType : 	STRUCT  (*Status structure*)
		CommunicationReady : BOOL; (*Communication is posible with the assembly*)
		ReadyForPowerOn : BOOL; (*Assembly can be powered on*)
		PowerOn : BOOL; (*Assembly is powered in*)
		MovementDetected : BOOL; (*There are movements in the assembly*)
		Error : BOOL; (*A hardware or application error is active*)
		ErrorInfo : TrakCtrlStatusErrorInfoType; (*Hardware or application error information*)
		AutomaticRestoreSuccess : BOOL; (*TRUE if the automatic restore matched all detected shuttles; FALSE otherwise (some need Command.Recover)*)
		PLCopenState : TrakCtrlStatusPLCopenStateType; (*PLC Open state of the assembly *)
		Segment : ARRAY[0..TRAK_MAX_SEGMENT_MINUS_ONE]OF TrakCtrlStatusSegmentType; (*Overall count of the segments*)
		Shuttle : ARRAY[0..TRAK_MAX_SHUTTLE_MINUS_ONE]OF TrakCtrlStatusShuttleType; (*Overall count of the shuttles*)
	END_STRUCT;
	TrakCtrlStatusErrorInfoType : 	STRUCT  (*Track error related information*)
		ID : DINT; (*The error id of any ocurred error*)
		Text : STRING[255]; (*Error description*)
		Initiator : STRING[32]; (*Error initiator*)
	END_STRUCT;
	TrakCtrlStatusShuttleType : 	STRUCT  (*Overrall numbers of shuttles*)
		Valid : BOOL; (*Shuttle data valid*)
		Axis : McAxisType; (*McAxis of shuttle*)
		ID : UDINT; (*User defined shuttle ID*)
		Name : STRING[32]; (*User defined name identificator*)
		ActSectorType : McAcpTrakSecTypeEnum; (*Shuttle current sector type*)
		ActSector : STRING[32]; (*Shuttle current sector*)
		ActPosition : LREAL; (*Shuttle position on sector*)
		ActVelocity : REAL; (*Shuttle velocity on sector*)
		TotalMoveDistance : LREAL; (*Shuttle total moved distance*)
		IsConvoyMaster : BOOL; (*Shuttle is a convoy master*)
		Pos : McPosType; (*Shuttle position in the coordinate system*)
		State : TrakCtrlStatusShuttleStateType; (*Shuttle state*)
	END_STRUCT;
	TrakCtrlStatusShuttleStateType : 	STRUCT  (*Shuttle PLCopen state*)
		StatusStandStill : BOOL; (*Shuttle is in state Standstill*)
		StatusStopping : BOOL; (*Shuttle is in state Stopping*)
		StatusErrorStop : BOOL; (*Shuttle is in state Errorstop*)
		StatusDiscreteMotion : BOOL; (*Shuttle is in state DiscreteMotion*)
		StatusContinuousMotion : BOOL; (*Shuttle is in state ContinuousMotion*)
		StatusSynchronizedMotion : BOOL; (*Shuttle is in state SynchronizedMotion*)
	END_STRUCT;
	TrakCtrlStatusPLCopenStateType : 	STRUCT  (*PLC Open states of the assembly*)
		Disabled : BOOL; (*Assembly in disabled state*)
		Homing : BOOL; (*Assembly in homing state*)
		Ready : BOOL; (*Assembly in ready state*)
		Stopping : BOOL; (*Assembly in stopping state*)
		ErrorStop : BOOL; (*Assembly in error state*)
		StartUp : BOOL; (*Assembly in start up state*)
		InvalidConfigurartion : BOOL; (*Assembly is invalid*)
	END_STRUCT;
	TrakCtrlStatusSegmentType : 	STRUCT  (*Overrall numbers of segments*)
		Valid : BOOL; (*Segment data valid*)
		Segment : McSegmentType; (*Segment reference*)
		Name : STRING[32]; (*Segment name (used mainly for diagnostics)*)
		State : TrakCtrlStatusSegmentState; (*Segment current PLCopen state*)
		Info : TrakCtrlStatusSegmentInfoType; (*Segment additional information (tempreature, current...etc)*)
	END_STRUCT;
	TrakCtrlStatusSegmentState : 	STRUCT  (*Segment PLCopen state*)
		StatusDisabled : BOOL; (*Segment is in state Disabled*)
		StatusReady : BOOL; (*Segment is in state Ready*)
		StatusErrorStop : BOOL; (*Segment is in state ErrorStop*)
		InvalidConfig : BOOL; (*Segment has an invalid configuration*)
	END_STRUCT;
	TrakCtrlStatusSegmentInfoType : 	STRUCT  (*Additional segment information*)
		TempBalancer : REAL; (*Internal segment temperature*)
		TempSensor : REAL; (*Backside segment temperature*)
		TempAir : REAL; (*CPU segment temperature*)
		Voltage : REAL; (*DC segment voltage*)
		PowerConsumption : REAL; (*Power consumption of the segment*)
	END_STRUCT;
END_TYPE
