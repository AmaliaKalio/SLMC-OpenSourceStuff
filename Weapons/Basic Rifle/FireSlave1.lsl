float spread = .5; //Baseline spread that we can always return to
float spread1 = .5; //Active spread, being modified below. This will return to the value of the float above
float maxSpread; //Placeholder for maximum spread (this is a dynamic calculation, see state_entry(). It can also be modified on the fly if you need to, IE: with attachments)
vector eye = <3.75, 0, 0>; //Outward rez offset for our round. Up/down offset is calculated below.
integer sil = FALSE; //Silencer flag
float bloom = .2; //Bloom/spread rate per shot
float tempSpread; //Intermediary spread value. This can probably be done better.
float spreadMultiplier =1; //Used for adjusting the velocity-based spread as the bullet rez velocity is updated
float  speed = 200; //Default speed
string round = "DEFAULT_BULLET_NAME_HERE";
key owner; //Who owns me?
integer rez = 1; //The integer to pass along to a rezed object.
rotation rezRot; //Rotation placeholder for our rezed object

//Most of the above is placed as a global for processing efficiency on rapidly-executed lines. Keeps variables in memory so it doesn't internally have to allocate, use, deallocate, rinse, repeat

integer posType = 0; //avPos = 0, camPos=1, velPos=2

rotation rot; //Placeholder for avatar rotation

//___________Dynamic rez height offset___________
integer status; //Used to gain avatar animation status.
vector cam; //Placeholder for our camera position. Yes, this is even used (once) for av/velPos. Trust me, it makes sense.
vector root; //Placeholder for root position
vector vel; //Placeholder for avatar's velocity
float diff; //Placeholder for difference calculation
fixOffset(integer stat, integer force) //stat = llGetAgentInfo(owner), force = whether or not we should force an override/update
{
    if(stat!=status||force) //If the supplied animation status is different from the previously-logged status, OR if the user specified a forced update
    {
        cam = llGetCameraPos(); //Current camera position
        root = llGetRootPosition(); //Current root position
        if(stat&AGENT_IN_AIR) //Is the agent off the ground? (IE: jumping/falling)
        {
            vel = llGetVel(); //Get current speed
            cam.z+= vel.z/5; //Add half of our current speed to the detected camera height
        }
        eye.z = cam.z-root.z; //Our rez offset is the calculated camera height minus our root position height.
        stat=status; //Save the current animation status
    }
}
//___________End dynamic offset___________
default{
    state_entry(){
        llSetMemoryLimit(13620);//       llOwnerSay((string)llGetMemoryLimit());
        maxSpread = spread+3; //Set our maximum spread for the rez slave here.
        owner = llGetOwner(); //Update our owner key
        llRequestPermissions(owner,PERMISSION_TRACK_CAMERA); //Get perms
        }
    link_message(integer sender, integer num, string message, key id){
        if(message == "Reset") llResetScript(); //If we're told to reset, reset
        else if(num == 50) { //LinkedMessage 50 is reserved for the main core sending this script the updated speed if it's set
            speed = (float)message; //Update rez velocity
            spreadMultiplier = speed/200; //Because we're using velocity-based spread, and the default is 200, fix the Y/Z spread so it doesn't go all over the place at lower speeds
        }
        else if(num == 51){ //LinkedMessage 51 is reserved to update the name of our rezed bullet. If you have multiple types of bullets you can rez, this is useful.
            round=message;}
        else if(num == 110) //LinkedMessage 110 is reserved to update our rez integer of our bullet
            rez = (integer)message;
        else if(message == "end") //Main core has told us we've stopped firing. Begin dynamic bloom reduction.
        {
           llSetTimerEvent(0.031); //Reduce bloom every 0.31s. Adjust as-needed
        }
        else if(message =="fire" || num==36) //Main core has told us we're firing
        {
            llSetTimerEvent(0); //Stop reducing bloom
            fixOffset(llGetAgentInfo(owner),1); //Force an update to our offset, because a mouseDown was detected
        }
        else if(num == 61) //LinkedMessage 61 is reserved to communicate our rez position type
        {
            if(message=="avPos")
                posType = 0;
            else if(message=="camPos")
                posType = 1;
            else if(message=="velPos")
                posType = 2;
        }
                
    } 
    changed(integer c) //This gun operates on a color core. This rez slave and the main core are expected to be installed into a hidden prim inside the gun at the root.
    {
        if(c&CHANGED_OWNER) //New owner? Reset
            llResetScript();
        else if(c & CHANGED_COLOR && llList2Vector(llGetLinkPrimitiveParams(LINK_ROOT,[PRIM_COLOR,ALL_SIDES]),0)==<1,0,0>){ //Prim color changed. <1,0,0> for slave 1, <0,1,0> for slave 2, <0,1,1> for slave 3, <1,1,0> for slave 4 if absolutely necessary
            llSetTimerEvent(0); //Stop reducing spread
            rot = llGetRootRotation(); //Get our current rotation. RootRot is more reliable than GetRot.
            rezRot=llEuler2Rot(<0,-PI_BY_TWO,0>); //Override for bullets scaled over Z rather than X. Set this to rezRot=rot if your bullet scales over X.
            tempSpread = spread1*spreadMultiplier; //Our actual, current spread
            fixOffset(llGetAgentInfo(owner),0); //Call this with force=0 so that if our animation state changes we can get a proper offset again
            if(posType ==0) //AvPos
            {
                //llRezAtRoot(round,llGetRootPosition() + (eye *rot), llRot2Fwd(rot)*speed +  (<0.0,llFrand(tempSpread)-llFrand(tempSpread),llFrand(tempSpread)-llFrand(tempSpread)> *rot), rezRot*rot, rez);
               llRezObjectWithParams(round,[REZ_PARAM,rez,REZ_POS,llGetRootPosition() + (eye *rot),0,1,REZ_ROT,rezRot*rot,0,REZ_VEL,llRot2Fwd(rot)*speed +  (<0.0,llFrand(tempSpread)-llFrand(tempSpread),llFrand(tempSpread)-llFrand(tempSpread)> *rot),0,0,REZ_FLAGS,0|REZ_FLAG_TEMP|REZ_FLAG_PHYSICAL|REZ_FLAG_DIE_ON_COLLIDE|REZ_FLAG_DIE_ON_NOENTRY|REZ_FLAG_NO_COLLIDE_OWNER|REZ_FLAG_NO_COLLIDE_FAMILY|REZ_FLAG_BLOCK_GRAB_OBJECT,REZ_LOCK_AXES,<1,1,1>,REZ_DAMAGE,100]); 

            }
            else if(posType ==1) //CamPos
            {
                eye.z=0;
                llRezAtRoot(round,llGetCameraPos() + (eye *rot), llRot2Fwd(rot)*speed +  (<0.0,llFrand(tempSpread)-llFrand(tempSpread),llFrand(tempSpread)-llFrand(tempSpread)> *rot), rezRot*rot, rez);
            }
            else if(posType ==2) //VelPos
            {
                llRezAtRoot(round,llGetRootPosition() + (eye *rot) - (llGetVel()/8), llRot2Fwd(rot)*speed +  (<0.0,llFrand(tempSpread)-llFrand(tempSpread),llFrand(tempSpread)-llFrand(tempSpread)> *rot),rezRot*rot, rez);
            }
            if(spread1 < maxSpread) //If we're not yet at the maximum spread...
            {
                spread1+=bloom; //Add our bloom rate to our spread
            }
            else
                spread1=maxSpread;
        }
    }
    timer()
    {
        spread1-=(bloom*3); //On tick, remove 3* our bloom rate from our current spread
        if(spread1<=spread) //If the intended value is below our baseline spread, cap it
        {
            spread1=spread;
            llSetTimerEvent(0); //Kill the timer, no bloom to remove
        }
    }
}