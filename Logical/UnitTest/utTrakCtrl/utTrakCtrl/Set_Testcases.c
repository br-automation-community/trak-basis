/********************************************************************
 * COPYRIGHT --
 ********************************************************************
 * Program: -
 * Author:
 * Created: 
 ********************************************************************
 * Tests for ... 
 ********************************************************************/

#include <bur/plctypes.h>

#ifdef _DEFAULT_INCLUDES
#include <AsDefault.h>
#endif

#include "UnitTest.h"


_TEST waitForReadyForPowerOn (void)
{
	TEST_BUSY_CONDITION(0 == gTrakCtrl.Status.ReadyForPowerOn);
	TEST_ASSERT(gTrakCtrl.Status.ReadyForPowerOn);
	
	TEST_DONE;
}

_TEST waitForCommunicationReady (void)
{
	TEST_BUSY_CONDITION(0 == gTrakCtrl.Status.CommunicationReady);
	TEST_ASSERT(gTrakCtrl.Status.CommunicationReady);	
	
	TEST_DONE;
}

_TEST waitForPLCopenStateDisabled (void)
{
	TEST_ASSERT(gTrakCtrl.Status.PLCopenState.Disabled);
	
	TEST_DONE;
}

_TEST setPowerOnAndCheckStatus (void)
{
	gTrakCtrl.Command.Power = 1;	
	
	TEST_BUSY_CONDITION(0 == gTrakCtrl.Status.PowerOn);
	TEST_ASSERT(gTrakCtrl.Status.PowerOn);

	TEST_DONE;
}

_TEST waitForPLCopenStateReady (void)
{
	TEST_BUSY_CONDITION(0 == gTrakCtrl.Status.PLCopenState.Ready);	
	TEST_ASSERT(gTrakCtrl.Status.PLCopenState.Ready);
	
	TEST_DONE;
}

_TEST setCommandMoveAbsolute (void)
{
	gTrakCtrl.Command.Move.Absolute = 1;
	gTrakCtrl.Parameter.Position = 0.0;
	gTrakCtrl.Parameter.Speed = 2.0;
	gTrakCtrl.Parameter.Acceleration = 20.0;
	gTrakCtrl.Parameter.Deceleration = 20.0;
	
	TEST_DONE;
}

_TEST waitForMovementAfterCommandMoveAbsolute (void)
{
	TEST_BUSY_CONDITION(1 == gTrakCtrl.Command.Move.Absolute);
	TEST_BUSY_CONDITION(0 == gTrakCtrl.Status.MovementDetected);
	TEST_ASSERT(gTrakCtrl.Status.MovementDetected);
	
	TEST_DONE;
}

_TEST waitForMovementAbsoluteStops (void)
{
	TEST_BUSY_CONDITION(1 == gTrakCtrl.Status.MovementDetected);
	TEST_ASSERT(0 == gTrakCtrl.Status.MovementDetected);
	TEST_DONE;
}

_TEST setCommandMoveVelocity (void)
{
	gTrakCtrl.Command.Move.Velocity = 1;
	gTrakCtrl.Parameter.Position = 0.0;
	gTrakCtrl.Parameter.Speed = 2.0;
	gTrakCtrl.Parameter.Acceleration = 20.0;
	gTrakCtrl.Parameter.Deceleration = 20.0;
	
	TEST_DONE;
}

_TEST waitForMovementAfterCommandMoveVelocity (void)
{
	TEST_BUSY_CONDITION(1 == gTrakCtrl.Command.Move.Velocity);
	TEST_BUSY_CONDITION(0 == gTrakCtrl.Status.MovementDetected);
	
	TEST_ASSERT(gTrakCtrl.Status.MovementDetected);

	TEST_DONE;
}

_TEST checkActualSpeedAfterCommandMoveVelocity (void)
{
	TEST_BUSY_CONDITION(2.0 > gTrakCtrl.Status.Shuttle[1].ActVelocity);
	
	TEST_ASSERT(gTrakCtrl.Status.Shuttle[1].Valid);
	TEST_ASSERT_REAL_WITHIN(0.1, 2.0, gTrakCtrl.Status.Shuttle[1].ActVelocity);
	TEST_ASSERT_EQUAL_STRING("Sector_1", gTrakCtrl.Status.Shuttle[1].ActSector);
	
	TEST_DONE;
}

_TEST setCommandHalt (void)
{
	gTrakCtrl.Command.Move.Halt = 1;
	
	TEST_DONE;
}

_TEST waitForMovementStopsAfterCommandHalt (void)
{
	TEST_BUSY_CONDITION(1 == gTrakCtrl.Command.Move.Halt);
	TEST_BUSY_CONDITION(1 == gTrakCtrl.Status.MovementDetected);
	
	TEST_ASSERT(0 == gTrakCtrl.Status.MovementDetected);
	TEST_ASSERT(gTrakCtrl.Status.Shuttle[1].Valid);
	TEST_ASSERT_EQUAL_REAL(0.0, gTrakCtrl.Status.Shuttle[1].ActVelocity);
	TEST_ASSERT_EQUAL_STRING("Sector_1", gTrakCtrl.Status.Shuttle[1].ActSector);

	TEST_DONE;
}


/*
B+R UnitTest: This is generated code.
Do not edit! Do not move!
Description: UnitTest Testprogramm infrastructure (TestSet).
LastUpdated: 2025-09-17 11:53:31Z
By B+R UnitTest Helper Version: 2.0.0.0
*/
UNITTEST_FIXTURES(fixtures)
{
	new_TestFixture("waitForReadyForPowerOn", waitForReadyForPowerOn), 
	new_TestFixture("waitForCommunicationReady", waitForCommunicationReady), 
	new_TestFixture("waitForPLCopenStateDisabled", waitForPLCopenStateDisabled), 
	new_TestFixture("setPowerOnAndCheckStatus", setPowerOnAndCheckStatus), 
	new_TestFixture("waitForPLCopenStateReady", waitForPLCopenStateReady), 
	new_TestFixture("setCommandMoveAbsolute", setCommandMoveAbsolute), 
	new_TestFixture("waitForMovementAfterCommandMoveAbsolute", waitForMovementAfterCommandMoveAbsolute), 
	new_TestFixture("waitForMovementAbsoluteStops", waitForMovementAbsoluteStops), 
	new_TestFixture("setCommandMoveVelocity", setCommandMoveVelocity), 
	new_TestFixture("waitForMovementAfterCommandMoveVelocity", waitForMovementAfterCommandMoveVelocity), 
	new_TestFixture("checkActualSpeedAfterCommandMoveVelocity", checkActualSpeedAfterCommandMoveVelocity), 
	new_TestFixture("setCommandHalt", setCommandHalt), 
	new_TestFixture("waitForMovementStopsAfterCommandHalt", waitForMovementStopsAfterCommandHalt), 
};

UNITTEST_CALLER_COMPLETE_EXPLICIT(Set_Testcases, "Set_Testcases", 0, 0, fixtures, 0, 0, 0);

