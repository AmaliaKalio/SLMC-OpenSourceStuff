//DO NOT use this alongside AdvancedAnims
integer holster = FALSE;
integer dual = 0;
default
{
    on_rez(integer start)
    {
        llResetScript();
    }
    state_entry()
    {
       llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION); 
    }
    run_time_permissions(integer p)
    {
        llSetTimerEvent(.5);
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if(num == 21)
            holster = TRUE;
        else if(num == 22)
            holster = FALSE;
        
        if(num == 40) //Init dual-weild
        {
            dual = 1;
             llStopAnimation("Anim - Aim VS");
             llStopAnimation("Anim - Hold VS");
        }
        else if(num == 41) //Disable dual-weild
        {
            dual = 0;
            
            llStopAnimation("gun_lr_aim");
            llStopAnimation("gun_lr_hold");
        }
                
        if(num == 34|| num==36) //Reload
        {
            if(!holster){
            

            llStartAnimation("Anim - Reload 3");}
        }
        if(num == 35) //Melee
        {
            if(!holster){
            

            llStartAnimation("Anim - Melee");}
        }
    }
    attach(key i)
    {
        if(i){}
        else
        {
            llStopAnimation("Anim - Aim VS");
            llStopAnimation("Anim - Hold VS");
            llStopAnimation("Anim - Melee");
            llStopAnimation("Anim - Reload 3");
            llStopAnimation("gun_lr_aim");
            llStopAnimation("gun_lr_hold");
        }
    }
    timer()
    {
        if(!holster)
        {
            
            integer status = llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK;
            
            if (status)   
            {
                //llOwnerSay("Hold");
                if(!dual)
                {
                    llStartAnimation("Anim - Aim VS");
                    llStopAnimation("Anim - Hold VS");
                }
                else
                    llStartAnimation("gun_lr_aim");
                llStopAnimation("gun_lr_hold");
            }        
            else
            {
                if(!dual)
                {
                    // llOwnerSay("Aim");
                    llStartAnimation("Anim - Hold VS");
                    llStopAnimation("Anim - Aim VS");
                }
                else
                {
                    llStartAnimation("gun_lr_hold");
                    llStopAnimation("gun_lr_aim"); 
                }
            }
        }
        else
        {
            if(!dual)
            {
                llStopAnimation("Anim - Hold VS");
                llStopAnimation("Anim - Aim VS");
            }
            else
            {
                llStopAnimation("gun_lr_hold");
                llStopAnimation("gun_lr_aim");
            }
        }
    }
}