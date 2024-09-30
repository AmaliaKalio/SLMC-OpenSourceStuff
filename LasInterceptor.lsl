integer ammo = 50;

list box;
float size = 0;

key targ;
vector targPos;
vector speed;
rotation targetrot;

vector targetvector;

float temp;

//This script is designed to rez a non-phys prim laser to intercept, scaled as a cylinder set to <0.19365,0.19365,40> with an end slice value of 0.46
PointChildAtTarget( vector pos, vector axis )
{
    targetvector = llVecNorm( pos - llGetPos() ) ;
    targetrot = llRotBetween( axis, targetvector );
}

float longestLength(vector boundingBox)
{
    temp = boundingBox.x;
    if(boundingBox.y>temp)
        temp=boundingBox.y;
    if (boundingBox.z>temp)
        temp = boundingBox.z;
    return temp;
}


default
{
    on_rez(integer i)
    {
        if(i>0) //If this wasn't rezed by hand. USE A REZ INT ABOVE 0!
            llSensorRepeat("","",SCRIPTED,20,PI,0.1); //20m sensor, check every 0.1 seconds in 360-degrees
    }
    sensor(integer a)
    {
        if (a < 0) return; //Left in out of paranoia
        while(a--)
        {
            @back; //Set a point to efficiently go back to
            if(a<0) return; //This is here because of the logic in the next line
            if(llDetectedType(a)&PASSIVE || llSameGroup(llDetectedKey(a))){a--; jump back;} //If detected object has the same group, or is considered passive, jump back up and use the next item in the list
            targPos = llDetectedPos(a);//Get the object's position
            /* Uncomment this if you want a size detection
            box = llGetBoundingBox(llDetectedKey(a));
            size = longestLength(llList2Vector(box,1)-llList2Vector(box,0));
            */
            speed = llDetectedVel(a);
            //if(llVecMag(speed)<150 && size<=1) //Alternate IF statement, to also check if the target object is <1m in all dimensions
            if(llVecMag(speed)<150) //If it's going under 150, we can PROBABLY assume this isn't a bullet
            {
                //
                PointChildAtTarget( targPos+((speed/5)), < 0, 0, -1 > ); //Aim ahead of the projectile's position, plus 1/5 of it's current speed. Z=-1 because of how the previously mentioned cylinder is scaled. Flip back to +1 if you find that the root prim is causing it to rez in the opposite direction for some reason.
                //llRezObject("Counter", llGetPos(),ZERO_VECTOR, targetrot, 1); //Rez the beam with 0 vel
                llRezObjectWithParams("Bullet",[REZ_PARAM,1,REZ_POS,(<3, 0.0, 0.0> * llGetRootRotation()),0,1,REZ_ROT,targetrot,0,REZ_VEL,ZERO_VECTOR,0,0,REZ_FLAGS,0|REZ_FLAG_TEMP|REZ_FLAG_PHYSICAL|REZ_FLAG_DIE_ON_COLLIDE|REZ_FLAG_DIE_ON_NOENTRY|REZ_FLAG_NO_COLLIDE_OWNER|REZ_FLAG_NO_COLLIDE_FAMILY|REZ_FLAG_BLOCK_GRAB_OBJECT,REZ_LOCK_AXES,<1,1,1>,REZ_DAMAGE,100]); //RezObjectWithParams variant of the above                
                ammo--;//Acknowledge that we intercepted once
                if(ammo<=0) //No more ammo
                {
                    llSensorRemove(); //Stop checking
                    llSetTimerEvent(20); //Wait 20 seonds
                }
            }
        }
    }
    no_sensor()
    {
        //DoNothing. Intentionally left (mostly) blank!
        return;
    }
    timer()
    {
        ammo=50; //Reset ammo count
        llSetTimerEvent(0); //Stop the timer
        llSensorRepeat("","",SCRIPTED,20,PI,0.1); //Reinitiate the sensor. Copy of line from on_rez
    }
}
