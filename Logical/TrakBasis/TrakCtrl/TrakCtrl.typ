(********************************************************************
 * COPYRIGHT - B&R Spain
 ********************************************************************
 * Program: AsmCtrl
 * File: AsmCtrl.typ
 * Author: B&R Spain
 * Created: July 22, 2024
 * Modified: July 22, 2024
 ********************************************************************
 * Local data types of program TrakCtrl
 ********************************************************************)

TYPE
	TrakStateEnum : 
		(
		TRAK_STATE_DISABLED,
		TRAK_STATE_SWITCHING_OFF,
		TRAK_STATE_SWITCHING_ON,
		TRAK_STATE_STANDSTILL,
		TRAK_STATE_DEL_SHUTTLE,
		TRAK_STATE_DEL_SHUTTLE_WAIT,
		TRAK_STATE_ADD_SHUTTLE_INIT,
		TRAK_STATE_ADD_SHUTTLE,
		TRAK_STATE_ADD_SHUTTLE_WAIT,
		TRAK_STATE_GET_SHUTTLE_INIT,
		TRAK_STATE_GET_SHUTTLE,
		TRAK_STATE_GET_SHUTTLE_WAIT,
		TRAK_STATE_SH_RESTORE_ID_INIT,
		TRAK_STATE_SH_RESTORE_ID,
		TRAK_STATE_SH_RESTORE_UID,
		TRAK_STATE_SH_RESTORE_UID_WAIT,
		TRAK_STATE_MOVE_ABS,
		TRAK_STATE_MOVE_ABS_WAIT,
		TRAK_STATE_MOVE_VEL,
		TRAK_STATE_MOVE_VEL_WAIT,
		TRAK_STATE_IN_MOTION,
		TRAK_STATE_HALTING,
		TRAK_STATE_STOPPING,
		TRAK_STATE_ERROR
		);
	InitStateEnum : 
		(
		INIT_STATE_SET_PARAMETER,
		INIT_STATE_CHECK_ASM_COMM,
		INIT_STATE_ASM_RDY_TO_POWER,
		INIT_STATE_GET_SEGMENT,
		INIT_STATE_GET_SEGMENT_WAIT,
		INIT_STATE_GET_SEGMENT_NEXT,
		INIT_STATE_DONE,
		INIT_STATE_ERROR
		);
	TrakErrorStateEnum : 
		(
		TRAK_ERR_STATE_WAIT,
		TRAK_ERR_STATE_FIND_INIT_ASM,
		TRAK_ERR_STATE_FIND_INIT_SEG,
		TRAK_ERR_STATE_FIND_INIT_SH,
		TRAK_ERR_STATE_COLLECT_LOG,
		TRAK_ERR_STATE_COLLECT_LOG_WAIT,
		TRAK_ERR_STATE_DONE
		);
END_TYPE
