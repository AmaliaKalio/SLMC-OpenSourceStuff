//DO NOT use this alongside BasicAnims
//Expects 12 animation files for left hand, and 12 animation files for right hand, with a suffix ran1ge of 0 - 11. IE: "Minnow Aim 0", "Minnow Aim 11". Designed for dual-weild SMGs that do not fire at the same time.
//This file is SPECIFICALLY for if you have anims to show the user looking up/down at different angles
integer holster = TRUE;
integer noflip =1;
integer dual = 0;
vector fwd;
integer angle;
integer file =4;
integer lastFile =4;
string newAnim = "";
string lastAnim = "";
integer slingOnce = 0;

integer chooseFile() //Used to determine the file suffix based on the angle in percentage, ranging from -100 to 100
{
    if(angle<=-67)
        return 0;
    else if(angle<=-52)
        return 1;
    else if(angle<=-37)
        return 2;
    else if(angle<=-22)
        return 3;
    else if(angle<=-7)
        return 4;
    else if(angle>=7)
        return 5;
    else if(angle>=22)
        return 6;
    else if(angle>=37)
        return 7;
    else if(angle>=52)
        return 8;
    else if(angle>=67)
        return 9;
    else if(angle>=82)
        return 10;
    else if(angle>=90)
        return 11;
    else //Close enough to neutral/centre
        return 4;
}

stopAll()
{
    integer i = 12;
    while(i--)
    {
        llStopAnimation("Minnow Aim "+(string)i);
        llStopAnimation("Minnow DualL "+(string)i);
        llStopAnimation("Minnow DualR "+(string)i);
    }
    llStopAnimation("Minnow Draw L 3");
    llStopAnimation("Minnow Draw R 3");
    llStopAnimation("Minnow Hold 2");
    llStopAnimation("Minnow Hold HIgh 2.1");
    llStopAnimation("OfficerPistol DUAL Aim 2");
    llStopAnimation("OfficerPistol DUAL Hold HIgh 1");
    newAnim="";
    lastAnim="";
}

default
{
    
    on_rez(integer a)
    {
        llResetScript();
    }
    state_entry()
    {
        
        llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
        stopAll();
        llSetTimerEvent(.5);
        
    }
    changed(integer c)
    {
        if(c&CHANGED_OWNER)
        {
            llResetScript();
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if(num == 21) //Holster
        {
            holster = TRUE;
            stopAll();  
        }
        else if(num == 22) //Draw
        {
            llStartAnimation("Minnow Draw R 3");
            if(dual)
            {
                llStartAnimation("Minnow Draw L 3");
                /*llStopAnimation("Pistol_right_Ready");
                llStopAnimation("Pistol_right_Aim");*/                
            }
            holster = FALSE;
        }
        
        if(num == 40) //Init dual-wield
        {
            dual = 1;
        }
        else if(num == 41) //End dual-wield
        {
            dual = 0;
        }
        if(num == 35) //Melee
        {
            if(!holster){
            

            llStartAnimation("Anim - Melee");}
        }
        if(dual&num==36) //Used to determine if it's the left or the right gun that's firing.
        {
            noflip=(integer)msg;
        }
        if(msg == "Reset") llResetScript();
    }
    timer()
    {
        if(!holster)
        {
            
           integer status = llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK;
           slingOnce = 1;
            
            if (status) //Owner is in mouselook
            {
                fwd = llRot2Fwd(llGetRootRotation()); //Get the current rotation
                angle=llFloor(fwd.z*100); //Specifically figure out a percentage of -100% -> 100% range
                file = chooseFile();
                if(!dual)
                {
                    newAnim = "Minnow Aim "+(string)file;
                }
                else
                {
                    if(noflip)
                    {
                        newAnim = "Minnow DualR "+(string)file;
                    }
                    else
                    {
                        newAnim = "Minnow DualL "+(string)file;
                    }                            
                }
            }        
            else
            {
                if(!dual)
                {
                    newAnim = "Minnow Hold HIgh 2.1";);
                }
                else
                {                    
                    newAnim = "OfficerPistol DUAL Hold HIgh 1";
                }
             }
             if(newAnim!=lastAnim) //Do we actually NEED to change animations?
             {
                 if(lastAnim!="")
                    llStopAnimation(lastAnim);
                 llStartAnimation(newAnim);
                 lastAnim=newAnim;
             }
        }
        else
        {
            if(slingOnce)
            {
                stopAll();
                llStartAnimation("Minnow Draw R 3");
                if(dual)
                {
                    llStartAnimation("Minnow Draw L 3");          
                }
                slingOnce = 0;
            }
        }
    }
}