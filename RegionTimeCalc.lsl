float time=0;
float num;
float dilation;
integer loop = 10;

dataUpdate()
{
    num = ((llGetRegionFPS()/45)/llGetRegionTimeDilation()); //Figure out a theoretical baseline percentage of sim physics performance
    if(num>1)
        num=1; //This should never exceed 1 in practicality.
    time=0;
    loop=10;
    while(loop--) //See how long it takes to sleep 0.1s ten times to get another idea of how scripts are actually running
    {
        llResetTime();
        llSleep(.1*llGetRegionTimeDilation());
        time += llGetTime()-.1;
    }
    time/=10; //Divide our length by ten, since we have ten samples.
    if(time<0)
        time=0; //This should never go below 0 in practicality.
    time=(1-(time/.15)); //Admittedly, a magic number. It just seems to work.
    string returnMsg="";
                    
    returnMsg="Region statistics: ";
    returnMsg+="\nFPS: "+(string)llGetRegionFPS();
    returnMsg+="\nDilation: "+(string)llGetRegionTimeDilation();
    returnMsg+="\nTheoretical Sim Physics Runtime: "+(string)(num*100)+"%";
    returnMsg+="\nTheoretical Region Script Speed: "+(string)(time*100)+"%";
    returnMsg+="\nAgents in region: "+(string)llGetRegionAgentCount();
    returnMsg+="\nRegion flags:";
    llSetText(returnMsg,<1,1,1>,1);
}
default
{
    state_entry()
    {
        dataUpdate();
        llSetTimerEvent(10);
    }
    on_rez(integer n)
    {
        llResetScript();
    }
    changed(integer change) 
    {
        if (change & CHANGED_OWNER || change & CHANGED_REGION_START || change & CHANGED_TELEPORT || change & CHANGED_REGION) 
        {
            llOwnerSay("Detected environment change, resetting..");
            llResetScript();
        } 
    }
    timer()
    {
        dataUpdate();
    }
}
