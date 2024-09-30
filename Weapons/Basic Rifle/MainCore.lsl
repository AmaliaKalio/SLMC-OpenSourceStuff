//This script and its fire slaves MUST go in a separate root prim hidden in your gun.

list menuMain = ["Velocity", "Fire type", "Rez Position"]; //Main dialog menu
list menuFire = ["Single", "Burst", "Auto"]; //Fire select dialog menu
list menuVelocity = [ "v 75", "v 100", "v 125", "v 150", "v 175", "v 200","Back"]; //Basic velocity select menu, if you don't want to type it in by hand
list menuRezPos = ["avPos","camPos","velPos"]; //rezPos selec dialog menu

float speed = 200; //Default speed
integer have_permissions = FALSE; //Placeholder for permissions
string mode1 = "Auto"; //Temp
integer holster = FALSE; //Is it holstered?
integer silence = FALSE; //Is there a silencer?
string mode = "Auto"; //Actual
integer roundammo = 45; //Gun ammo
string maxammo = "45"; //String for HUD ammo display compatibility
string SoundAuto = "137e41dd-42ee-c714-066f-01cca5099820";
string SoundSemi = "e2f686cc-3791-33e2-a668-5887c851424d";
string SoundStop = "19ec792a-1e0e-6f45-c56f-6fc27da318ad";

string SilencedAuto = "a1480dab-4bd2-618e-2cc6-0109218034a1";
string SilencedSemi = "05a393b4-24d3-9215-559b-5ff57b2a343a";
string SilencedStop = "4f557023-9130-eeda-6ccc-56745604b402";
integer isReload = FALSE; //Flag for if currently reloading
string type = "avatar"; //RezPos
integer step =0; //Used to determine the next rez slave
float reloadTime = 1.5; //Length of reload
integer melee = 5; //Distance the gun can melee

integer midBurst = FALSE; //Currently in a burst fire? Used to prevent it from stacking and breaking

float rof = .07; //Current rate of fire, which can be modified (IE: With attachments)
float originalRof = .07; //Baseline rat of fire, which is saved to be reverted to

key OwnerID;
integer bChannel = -8437;


reload() //Reload sequence
{
    llSetTimerEvent(0); //Stop firing
    llStopSound(); //End sounds
    integer temp=0; //Used for chamber reload
    if(roundammo>0) //Is there ammo still?
        temp=1;
    isReload = TRUE; //Flag that we're reloading
    llMessageLinked(LINK_THIS,34,"",""); //Tell the slaves, anim core
        
    llTriggerSound("b07b2a7c-5064-5457-806e-1575ba75fb29",1); //Reload sound
    llStopSound();//Stop the sound
    llOwnerSay("Reloading"); //Callback
    llSleep(reloadTime); //Sleep for the length of the reload
         
    roundammo = (integer)maxammo; //Reset the ammo count
    if(temp) //Is this a chamber reload?
        roundammo++; //Ammo is now max+1
    llResetTime(); //Reset the internal script clock
        
    isReload = FALSE; //No longer reloading
    llOwnerSay("Reload complete.");
    llMessageLinked(LINK_THIS,36,"",""); //Tell the slaves, anim core
    llTriggerSound("d91c8e67-3565-f26d-ee77-2db5d5fef72b",1); //Reload complete sound
}

fire() //Fire sequence
{
    if(llGetTime()>.2) //If it's been at least 0.2s since the reload
    {
        if(step==0)llSetColor(<1,0,0>,ALL_SIDES); //Slave 1
        if(step==1)llSetColor(<0,1,0>,ALL_SIDES); //Slave 2
        if(step==2)llSetColor(<0,0,1>,ALL_SIDES); //Slave 3
        if(step==3)llSetColor(<1,1,0>,ALL_SIDES); //Slave 4
        ++step; //Set the next slave to use
        if(step==4) step=0; //If we've gone too high, loop back
        --roundammo; //Subtrack ammo
    
        if(roundammo<=0) //Are we out of ammo?
        {
            if(!silence) //No silencer?
                llTriggerSound(SoundStop,1); //Unsilenced fire end
            else //We have a silencer
                llTriggerSound(SilencedStop,1); //Silenced fire end
            reload(); //Init reload
        }
    }
}
detach(string s)
{
    llOwnerSay(s);
}

changePos(string posType) //To change your rezPos type
{
    integer type = 0; //current type as int
    if(posType=="avPos")
        type=0;
    else if(posType == "camPos")
        type=1;
    else //velPos
        type=2;
    llMessageLinked(LINK_THIS,61,posType,""); //Tell the rez slaves
    llOwnerSay("Rez position style set to "+posType);
}
default
{
    on_rez(integer start_param)
    {
        llRequestPermissions(llGetOwner(),PERMISSION_TAKE_CONTROLS);
    }
    state_entry()
    {
        OwnerID = llGetOwner(); //Set our owner's ID
        llSetMemoryLimit(1024*47);
        //llOwnerSay((string)llGetMemoryLimit());
        
        llMessageLinked(LINK_THIS,0,"Reset",""); //Tell the other scripts we've reset
        integer ammo = llFloor(roundammo); //Init ammo
        llListen(1,"",OwnerID,""); //Listen on channel 1 to just the owner
       
        llSetColor(<0,0,0>,ALL_SIDES); //Set the root prim color to something benign so the slaves don't go off
        llSetLinkAlpha(ALL_SIDES, 1, ALL_SIDES);
    }
        
    changed(integer change)
    {
        if (change & CHANGED_REGION) //Did we change regions?
        {
            llMessageLinked(LINK_SET,20,"",NULL_KEY); //Make sure we stop firing.
        }
        else if(change & CHANGED_OWNER) //New owner? Reset.
        {
            //llOwnerSay("owner?!");
            llResetScript();
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        string cmd = llToLower(message);
        if(channel==1)
        {
            if (llGetSubString(cmd, 0, 0) == "v" && llGetSubString(cmd,1,-1) != "elocity") //Because we're looking for "v250" or something of the like, and "velocity" will open the selector menu
            {
    
                float speedTemp = (integer) llGetSubString(cmd, 1,-1);
               
                if (speedTemp > 250)
                {  llOwnerSay( "Velocity Too High");}
                else if (speedTemp < 25)
                { llOwnerSay( "Velocity Too Low");}
                else
                { speed = speedTemp;
                llMessageLinked(LINK_THIS,50,(string)speed,"");
                        llOwnerSay( "Velocity Set");}
            }
            
            //else if(llGetSubString(cmd, 0, 6) == "rescale"){ rescaleLinkset((float)llGetSubString(cmd, 7, -1)); //I don't trust this, but putting it here for safe-keeping.
            llWhisper(-855,cmd);}
            
            else if (cmd == "reset")
            {  llResetScript();
                    have_permissions = TRUE;}
    
            else if (cmd == "r" && !isReload && roundammo < (integer) maxammo) //Reload command and we're not already at max ammo
            {
                isReload = TRUE;
                llMessageLinked(LINK_SET,0,"end",NULL_KEY);
                reload();
            }
            else if (cmd == "single" || cmd == "s" || cmd == "semi") //Set to semi-auto
            { 
                mode1 = "Single";
                if(mode != "Safe")
                    mode = "Single";
                llTriggerSound("8eae9c2b-3caa-477c-964d-c3752c23eddb",1.0);
llMessageLinked(LINK_THIS,5,"s","");
                         
                llOwnerSay("Single");
            }
            else if (cmd == "auto" || cmd == "a") //Set to full-auto
            { 
                    mode1 = "Auto";
                    if(mode != "Safe")
                        mode = "Auto";
                    llTriggerSound("8eae9c2b-3caa-477c-964d-c3752c23eddb",1.0);
                    llMessageLinked(LINK_THIS,5,"a","");
                    llOwnerSay("Auto");}
    
            else if (cmd == "burst" || cmd == "b") //Set to burst fire
            { 
                    mode1 = "Burst";
                    if(mode != "Safe")
                        mode = "Burst";
                    llTriggerSound("8eae9c2b-3caa-477c-964d-c3752c23eddb",1.0);
                    llMessageLinked(LINK_THIS,5,"b","");
    
                    llOwnerSay("Burst");
            }
            else if (cmd == "safe") //Legacy safety switch
            {
                mode = "Safe";
                llTriggerSound("35d1bd88-59d7-59d9-e2ef-4eaa1097335c",1.0);
                integer roundammo = llFloor(roundammo);    
            }
            else  if (cmd == "unsafe") //Legacy safety switch
            {  
                if(!holster)
                {
                    mode = mode1;
                    llTriggerSound("35d1bd88-59d7-59d9-e2ef-4eaa1097335c",1.0);
                    integer roundammo = llFloor(roundammo);
                }
                else
                {
                            llOwnerSay("The rifle is holstered. Unable to make unsafe.");
                }
            }
    
            if (cmd == "holster" || message=="sling") //Holster the gun
            {  
                mode = "Safe";
                llSetColor(<0,0,0>,ALL_SIDES);
                holster = TRUE;
                llWhisper(-855,"sling");
                        
                        
                        
                llMessageLinked(LINK_SET,21,"",NULL_KEY);
                llSetLinkAlpha(ALL_SIDES, 0, ALL_SIDES);
            }
    
    
            else if (cmd == "unholster"||message=="unsling"||message=="draw") //Unholster the gun
            {  
                holster = FALSE;
                llSetColor(<0,0,0>,ALL_SIDES);
                mode = mode1;
                integer roundammo = llFloor(roundammo);
                llWhisper(-855,"draw");
                        
                        
                llSetLinkAlpha(ALL_SIDES, 1, ALL_SIDES);
                llMessageLinked(LINK_SET,22,"",NULL_KEY);
                llSleep(.1);
            }
            else if( cmd == "velocity" ) //Open the velocity dialog
            {
                llDialog( llGetOwner(), "Choose a velocity setting.", menuVelocity,1 );
            }
            else  if( cmd == "fire type" ) //Open the fire select dialog
            {
                llDialog( llGetOwner(), "Choose a fire type.", menuFire,1 );
            }
            else  if( cmd == "rez position" ) //Open the rezpos dialog
            {
                llDialog( OwnerID, "Choose a rez position type.", menuRezPos,1 );
            }
            else  if( cmd == "avpos" )
            {
                changePos("avPos");
            }
            else  if( cmd == "campos" )
            {
                changePos("camPos");
            }
            else  if( cmd == "velpos" )
            {
                changePos("velPos");
            }
            else  if( cmd == "back" || cmd == "menu") //Open the main menu
            {
                llDialog( llGetOwner(), "Choose an option.", menuMain,1 );
            }
            else if(cmd == "melee"){ //Initiate a melee
                llSensor("", "", AGENT, melee, PI_BY_TWO);} //Check for agents directly ahead at the globally-defined range
            else if (cmd == "modeswitch") //Intended for a quick-switch gesture. Cycles to the next firemode in the list
            {  
                if(mode1 == "Single")
                {
                    llMessageLinked(LINK_THIS,5,"b","");
                    mode1 = "Burst";
                    if(mode != "Safe")
                    mode = "Burst";
                    llTriggerSound("8eae9c2b-3caa-477c-964d-c3752c23eddb",1.0);
                    llOwnerSay("Burst");
                }
                else if(mode1 == "Burst")
                {
                    llMessageLinked(LINK_THIS,5,"a","");
                    mode1 = "Auto";
                    if(mode != "Safe")
                    mode = "Auto";
                    llTriggerSound("8eae9c2b-3caa-477c-964d-c3752c23eddb",1.0);
                    llOwnerSay("Auto");
                }
                else if(mode1 == "Auto")
                {
                    llMessageLinked(LINK_THIS,5,"s","");
                    mode1 = "Single";
                    if(mode != "Safe")
                        mode = "Single";
                    llTriggerSound("8eae9c2b-3caa-477c-964d-c3752c23eddb",1.0);     
                    llOwnerSay("Single");
                }
            }                   
            else if(cmd == "sling/draw") //Intended for a quick draw/holster toggle gesture.
            {
                llSetColor(<0,0,0>,ALL_SIDES);
                if(!holster)
                {
                    llWhisper(-855,"sling");
                    mode = "Safe";
                    holster = TRUE;
                    llMessageLinked(LINK_SET,21,"",NULL_KEY);
                    llSetLinkAlpha(ALL_SIDES, 0, ALL_SIDES);                           
                }
                else
                {
                    llWhisper(-855,"draw");
                    holster = FALSE;
                    mode = mode1;
                    llSetLinkAlpha(ALL_SIDES, 1, ALL_SIDES);
                    llMessageLinked(LINK_SET,22,"",NULL_KEY);
                    llSleep(.1);
                    llSetColor(<0,0,0>,ALL_SIDES);
                    redundant();
                }
            }
        }
    }

    sensor(integer a) //Only used for melee
    {
        vector dir = llDetectedPos(0) - llGetPos();
        dir.z = 0.0;
        dir = llVecNorm(dir);
        rotation rot = llGetRot();
        llMessageLinked(LINK_SET,35,"",NULL_KEY);
        llRezObject("MELEE_KILL_PRIM_HERE", llDetectedPos(0), llDetectedVel(0), llDetectedRot(0), 1);
        llOwnerSay("Pwn'd " + llDetectedName(0) + " with a melee kill!");
    }
    no_sensor() //THIS MUST STAY IN. In the event the melee sensor has no results, it will auto-melee the next person that comes in range without this method here
    {
        return;
    }
    touch_start(integer total_number) //Gun is clicked 
    {       
        key id = llDetectedKey(0);
        if (id == OwnerID) //Owner clicked
        {
            llDialog( OwnerID, "Choose an option.", menuMain, 1 );
        }
    }           
    attach(key attachedAgent)
    {
        if (attachedAgent != NULL_KEY) //Is actually attached
        {
            return;
        }
        else //No longer attached
        {
            if (have_permissions) //We have permissions
            {
                llSetRot(<0,0,0,1>);
                have_permissions = FALSE;
            }
        }
    }
    run_time_permissions(integer p)
    {
        if(p & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_ML_LBUTTON,TRUE,TRUE);
        }
    }
    control(key i, integer l, integer e)
    {                       
        if(CONTROL_ML_LBUTTON&l&e && !holster && !isReload && llGetTime() > (.3*llGetRegionTimeDilation())) //MouseDown on left click, AND not holstered, AND not reloading, AND 0.3s since last reload
        {
            if(mode1 == "Auto")
            {
                if(!silence)
                    llLoopSound(SoundAuto,1);
                else
                    llLoopSound(SilencedAuto,1);
                llMessageLinked(LINK_SET,0,"fire","");
                    fire(); 
                llSetTimerEvent(rof*llGetRegionTimeDilation());
            }
            else
            {
                llMessageLinked(LINK_SET,0,"fire","");
                midBurst = TRUE;
                integer x = 0;
                @loop;
                if(!silence)
                    llTriggerSound(SoundSemi,1);
                else
                    llTriggerSound(SilencedSemi,1);
                fire();                              
                if(mode1 == "Burst"&&x<2)
                {
                    x++;
                    llSleep(rof*llGetRegionTimeDilation());
                    jump loop;
                }
                midBurst = FALSE;
            }
        }
    
        else if(CONTROL_ML_LBUTTON&~l&e && !holster &&!isReload && mode == "Auto" && llGetTime() > (.3*llGetRegionTimeDilation())) //Left mouse button has been released AND unholstered, AND auto, AND .3s since reload complete.
        {
            llSetTimerEvent(0);
            llStopSound();
            if(mode1=="Auto")
            {
                if(!silence)
                    llTriggerSound(SoundStop,1);
                else
                    llTriggerSound(SilencedStop,1);
            }
            llMessageLinked(LINK_THIS,0,"end","");
        }
    }
    timer()
    {
        fire();
    }
}
