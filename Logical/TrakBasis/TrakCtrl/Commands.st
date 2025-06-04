
ACTION PowerOn:
	
	MC_BR_AsmPowerOn_AcpTrak_0.Execute := TRUE;
	MC_BR_AsmPowerOff_AcpTrak_0.Execute := FALSE;
	
END_ACTION

ACTION PowerOff:
	
	MC_BR_AsmPowerOn_AcpTrak_0.Execute := FALSE;
	MC_BR_AsmPowerOff_AcpTrak_0.Execute := TRUE;
	
END_ACTION
	
ACTION AddShuttles:
	
	MC_BR_SecAddShuttle_AcpTrak_0.Sector := AdrSector;
	MC_BR_SecAddShuttle_AcpTrak_0.Position := pTrakCtrl.Parameter.SimulationParameters.Position + pTrakCtrl.Parameter.SimulationParameters.Separation * Counter;
	MC_BR_SecAddShuttle_AcpTrak_0.Velocity := 0.0;
	MC_BR_SecAddShuttle_AcpTrak_0.Orientation := mcDIR_POSITIVE;
	MC_BR_SecAddShuttle_AcpTrak_0.Execute := TRUE;
	
END_ACTION

ACTION ShSwitchSector:
	
	MC_BR_ShSwitchSector_AcpTrak_0.Sector := AdrSector;
	MC_BR_ShSwitchSector_AcpTrak_0.Axis := ADR(pTrakCtrl.Status.Shuttle[Counter].Axis);
	MC_BR_ShSwitchSector_AcpTrak_0.Execute := TRUE;
	
END_ACTION

ACTION DeleteShuttles:
		
	MC_BR_AsmDeleteShuttle_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmDeleteShuttle_AcpTrak_0.Command := mcACPTRAK_SH_DELETE_ALL;
	MC_BR_AsmDeleteShuttle_AcpTrak_0.Execute := TRUE;
	
END_ACTION
	
ACTION MoveAbsolute:
	
	MC_BR_ModuloMoveAbs_AcpTrak_0.Axis := ADR(pTrakCtrl.Status.Shuttle[Counter].Axis);
	MC_BR_ModuloMoveAbs_AcpTrak_0.Position := pTrakCtrl.Parameter.Position;
	MC_BR_ModuloMoveAbs_AcpTrak_0.Velocity := pTrakCtrl.Parameter.Speed;
	MC_BR_ModuloMoveAbs_AcpTrak_0.Acceleration := pTrakCtrl.Parameter.Acceleration;
	MC_BR_ModuloMoveAbs_AcpTrak_0.Deceleration := pTrakCtrl.Parameter.Deceleration;
	MC_BR_ModuloMoveAbs_AcpTrak_0.Direction := pTrakCtrl.Parameter.Direction;
	MC_BR_ModuloMoveAbs_AcpTrak_0.Elastic := TRUE;
	MC_BR_ModuloMoveAbs_AcpTrak_0.Execute := TRUE;
	
END_ACTION

ACTION MoveVelocity:

	MC_BR_ElasticMoveVel_AcpTrak_0.Axis	:= ADR(pTrakCtrl.Status.Shuttle[Counter].Axis);
	MC_BR_ElasticMoveVel_AcpTrak_0.Velocity	:= pTrakCtrl.Parameter.Speed;
	MC_BR_ElasticMoveVel_AcpTrak_0.Acceleration	:= pTrakCtrl.Parameter.Acceleration;
	MC_BR_ElasticMoveVel_AcpTrak_0.Deceleration := pTrakCtrl.Parameter.Deceleration;
	MC_BR_ElasticMoveVel_AcpTrak_0.Direction := pTrakCtrl.Parameter.Direction;
	MC_BR_ElasticMoveVel_AcpTrak_0.Execute := TRUE;
	
END_ACTION

ACTION Halt:

	MC_BR_AsmStop_AcpTrak_0.Assembly := AdrAssembly;
	MC_BR_AsmStop_AcpTrak_0.AdvancedParameters.Deceleration := pTrakCtrl.Parameter.Deceleration;
	MC_BR_AsmStop_AcpTrak_0.AdvancedParameters.StopMode := mcSTOPMODE_JERK_LIMIT;
	MC_BR_AsmStop_AcpTrak_0.Execute := TRUE;
	
END_ACTION

ACTION ClearErrorTexts:
	
	brsmemset(ADR(pTrakCtrl.Status.ErrorText),0, SIZEOF(pTrakCtrl.Status.ErrorText));
	
END_ACTION