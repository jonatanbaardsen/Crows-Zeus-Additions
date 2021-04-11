/*/////////////////////////////////////////////////
Author: Crowdedlight
			   
File: fn_followCam.sqf
Parameters: Hovered Entity
Return: none

Set zeus view to follow unit until spacebar is hit

*///////////////////////////////////////////////


//try and check how its done here for the smooth movement, where smoothing and the visualposition is used instead. Also use CBA onEachFrame instead of Draw3D
// https://github.com/TaktiCool/Streamator/blob/main/addons/Streamator/Spectator/fn_cameraUpdateLoop.sqf#L140-L142 
// https://cbateam.github.io/CBA_A3/docs/files/common/fnc_addPerFrameHandler-sqf.html 
// should be a better approach... but requires many key/mouse-EH to keep functionality for zeus view 
// todo, also should fix, when exiting, it corectly leaves view where you are, but normal zeus controls are not restored...






params ["_entity"];

//global vars set/reset 
crowsZA_followcam_camDistance = 100;
crowsZA_followcam_camPitch = 15;
crowsZA_followcam_camYaw = -45;
crowsZA_followcam_nightVision = false;
crowsZA_followcam_helperPos = [0, 0, 0];
crowsZA_followcam_centerUnit = _entity;

//create camera helper
crowsZA_followcam_camhelp = "Logic" createVehicleLocal [0, 0, 0];
crowsZA_followcam_camhelp attachTo [crowsZA_followcam_centerUnit, crowsZA_followcam_helperPos];

//create camera
crowsZA_followcam_cam = "camera" camCreate ASLtoAGL getPosASLVisual crowsZA_followcam_centerUnit;
crowsZA_followcam_cam cameraEffect ["internal", "back"];
crowsZA_followcam_cam camPrepareFocus [-1, -1];
crowsZA_followcam_cam camPrepareFov 0.75;
crowsZA_followcam_cam camCommitPrepared 0;
showCinemaBorder false;

//event function mouseScroll 
crowsZA_event_fnc_handleMouseScroll = {
	params ["", "_scroll"];

	// todo maybe add bounding box so we can't scroll past negative or too far out. For now just reflect the change directly
	crowsZA_followcam_camDistance = crowsZA_followcam_camDistance - (_scroll * 4);
};

//event function keyDown 
crowsZA_event_fnc_handleKeyDown = {
	params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];

	//if key == spacebar, we close follow view, set curator cam to current view and destory our removeAllEventHandlers
	// Escape == 1, spacebar == 57, n == 49
	if (_key isEqualTo 57) then 
	{
		//remove button events
		removeMissionEventHandler ["Draw3D", crowsZA_followcam_camDraw3D];
		findDisplay 312 displayRemoveEventHandler ["MouseZChanged", crowsZA_followcam_mouseZChanged];
		findDisplay 312 displayRemoveEventHandler ["keyDown", crowsZA_followcam_keyDown];

		//set zeus view to current view
		if (!isNull curatorCamera) then {
			curatorCamera setPos crowsZA_followcam_cam;
			curatorCamera setVectorDirAndUp [vectorDir crowsZA_followcam_cam, vectorUp crowsZA_followcam_cam];
		};

		//reset follow unit
		crowsZA_followcam_centerUnit = nil;

		//reset event 
		crowsZA_followcam_camDraw3D = nil;
		crowsZA_followcam_mouseZChanged = nil;
		crowsZA_followcam_keyDown = nil;

		// Delete camera helper
		deleteVehicle crowsZA_followcam_camhelp;
		crowsZA_followcam_camhelp = nil;

		// Return to zeus camera
		crowsZA_followcam_cam cameraEffect ["terminate", "back"];
		camDestroy crowsZA_followcam_cam;
		crowsZA_followcam_cam = nil;

		//reset zeus camera as it seems to doesn't work otherwise 
		openCuratorInterface;
	};
	
	if (_key isEqualTo 49) then 
	{
		//N is clicked, toggle night vision
		crowsZA_followcam_nightVision = !crowsZA_followcam_nightVision;
		camUseNVG crowsZA_followcam_nightVision;
	};

	//Intercepts the default action, eg. pressing escape won't close the dialog.
	true; 
};

//event function updateCam 
crowsZA_event_fnc_updateCam = {
	//update cam event
	[crowsZA_followcam_camhelp, [crowsZA_followcam_camYaw + 180, -crowsZA_followcam_camPitch, 0]] call BIS_fnc_setObjectRotation;
	crowsZA_followcam_camhelp attachTo [crowsZA_followcam_centerUnit, crowsZA_followcam_helperPos];

	crowsZA_followcam_cam setPos (crowsZA_followcam_camhelp modelToWorldVisual [0, -crowsZA_followcam_camDistance, 0]);
	//getPosASLVisual crowsZA_followcam_centerUnit;
	// crowsZA_followcam_cam setPos (visiblePosition crowsZA_followcam_centerUnit modelToWorld [0, -crowsZA_followcam_camDistance, 0]);
	crowsZA_followcam_cam setVectorDirAndUp [vectorDir crowsZA_followcam_camhelp, vectorUp crowsZA_followcam_camhelp];
}; 

//add eventhandlers 
crowsZA_followcam_camDraw3D = addMissionEventHandler ["Draw3D", {call crowsZA_event_fnc_updateCam}];

crowsZA_followcam_mouseZChanged = findDisplay 312 displayAddEventHandler ["MouseZChanged", {_this call crowsZA_event_fnc_handleMouseScroll}];
crowsZA_followcam_keyDown = findDisplay 312 displayAddEventHandler ["KeyDown", {_this call crowsZA_event_fnc_handleKeyDown}];


// This works quite well without jitter, but it is bound to target direction vector... We want a cam that follows a unit but ignores rotation of the unit.
//  Want to set initial position relative, and then just keep that orientation, but update the position. Any orientation update happens with the mouse event handler.
// _cpos = getpos _this; 
// _cam = "camera" camCreate _cpos; 
// _cam camSetTarget (driver _this); 
// _cam camSetRelPos [10, -15, 4]; 
// _cam cameraEffect ["internal", "BACK"]; 
// _cam camCommit 0; 
// _cam attachTo [_this];

//so create camera, at unit position. Set it to the relative position we start with and point at target. Then just update the position, not the direction.

//check for changes in target vectorDir/vectorUp, and counteract the rel position? 

















// //WIP - Not loaded or used currently

// // NOTES
// //save current curator cam, as the cam will move around if we use move around while the cam is fixed. 
// _curatorCameraData = [getPosASL curatorCamera, [vectorDir curatorCamera, vectorUp curatorCamera]];

// //when we exit with spacebar and want to go back, just set curatorCamera to the current position of the fixed camera, So we get the feeling that the zeus cam just stops following

// // Create the camera
// private _camhelp = "Logic" createVehicleLocal [0, 0, 0];
// _camhelp attachTo [_this, [0, 0, -1]];

// private _cam = "camera" camCreate ASLtoAGL getPosASL _this;
// _cam cameraEffect ["internal", "back"];
// _cam camPrepareFocus [-1, -1];
// _cam camPrepareFov 0.35;
// _cam camCommitPrepared 0;
// showCinemaBorder false;
// _cam setPos (_camhelp modelToWorld [0, -40, 0]);

// //display 312 == zeus. Can add events like this for possible override of keyboard and mouse
// findDisplay 312 displayAddEventHandler ["KeyDown", "diag_log str _this;"];

// //consider just using CBA event handlers... can do keyevents too and we can clean them up afterwards... 
// // https://cbateam.github.io/CBA_A3/docs/files/events/fnc_addKeyHandler-sqf.html

// //escape key, 
// 16:21:49 "[Display #312,57,false,false,false]"

// //mousebuttondown
// 16:24:31 "[Display #312,1,0.436869,0.8367,false,false,false]"

// //mouseZChanged
// 16:26:42 "[Display #312,-2.4]"

// //events
// onKeyDown = QUOTE(_this call FUNC(onKeyDown));
// onMouseButtonDown = QUOTE(_this call FUNC(onMouseButtonDown));
// onMouseButtonUp = QUOTE(_this call FUNC(onMouseButtonUp));

// onMouseMoving = QUOTE(_this call FUNC(handleMouse));
// onMouseHolding = QUOTE(_this call FUNC(handleMouse));
// onMouseZChanged = QUOTE(_this call FUNC(onMouseZChanged));

// // Add camera update handler
// GVAR(camDraw3D) = addMissionEventHandler ["Draw3D", {call FUNC(updateCamera)}];

// //update cam event
// [GVAR(camHelper), [GVAR(camYaw) + 180, -GVAR(camPitch), 0]] call BIS_fnc_setObjectRotation;
// GVAR(camHelper) attachTo [GVAR(center), GVAR(helperPos)];

// GVAR(camera) setPos (GVAR(camHelper) modelToWorld [0, -GVAR(camDistance), 0]);
// GVAR(camera) setVectorDirAndUp [vectorDir GVAR(camHelper), vectorUp GVAR(camHelper)];

