# set the timer for the selected function

var UPDATE_PERIOD = 0;

Transponder_timer = func {

	settimer(TransponderUpdate, UPDATE_PERIOD);

}

# =============================== end timer stuff ===========================================

TransponderUpdate = func {

	var volts = props.globals.getNode("/systems/electrical/mainbusvolts").getValue();
	var lampnorm=0.036*volts;

# ======== Reply Lamp ========

	if ( getprop("instrumentation/transponder/mode")==4 or 
             ( getprop("instrumentation/transponder/mode")>1 and 
               ( getprop("instrumentation/transponder/ident") or
                 getprop("instrumentation/transponder/reply/state")
               )
             ) 
	   )
	{
		setprop("/instrumentation/transponder/reply-norm",lampnorm);
	} else {
		setprop("/instrumentation/transponder/reply-norm",0.0);
	}

	Transponder_timer();

}

####################### Initialise ##############################################

stepmsb = func(change) { 
	var msb = getprop("instrumentation/transponder/id-msb"); 
	var lsb = getprop("instrumentation/transponder/id-lsb");
	msb = msb + change;
	if (msb>63) { msb=0 };
	if (msb<0) { msb=63 };
	var idcode=sprintf("%04o",msb*64+lsb);
	setprop("instrumentation/transponder/id-msb",msb);
	setprop("instrumentation/transponder/id-code",idcode);
        setprop("instrumentation/transponder/digit1",substr(idcode,0,1));
        setprop("instrumentation/transponder/digit2",substr(idcode,1,1));
        setprop("instrumentation/transponder/digit3",substr(idcode,2,1));
        setprop("instrumentation/transponder/digit4",substr(idcode,3,1));
}

steplsb = func(change) { 
	var msb = getprop("instrumentation/transponder/id-msb"); 
	var lsb = getprop("instrumentation/transponder/id-lsb");
	lsb = lsb + change;
	if (lsb>63) { lsb=0 };
	if (lsb<0) { lsb=63 };
	var idcode=sprintf("%04o",msb*64+lsb);
	setprop("instrumentation/transponder/id-lsb",lsb);
	setprop("instrumentation/transponder/id-code",idcode);
        setprop("instrumentation/transponder/digit1",substr(idcode,0,1));
        setprop("instrumentation/transponder/digit2",substr(idcode,1,1));
        setprop("instrumentation/transponder/digit3",substr(idcode,2,1));
        setprop("instrumentation/transponder/digit4",substr(idcode,3,1));
}


initialize = func {

	### Initialise Transponder ###
	props.globals.getNode("/instrumentation/transponder/ident", 1).setBoolValue(0);
	props.globals.getNode("/instrumentation/transponder/reply", 1).setBoolValue(0);
	props.globals.getNode("/instrumentation/transponder/mode", 1).setIntValue(0);
	props.globals.getNode("/instrumentation/transponder/id-msb", 1).setIntValue(56);
	props.globals.getNode("/instrumentation/transponder/id-lsb", 1).setIntValue(0);
	props.globals.getNode("/instrumentation/transponder/id-code", 1).setValue("7000");
	props.globals.getNode("/instrumentation/transponder/digit1", 1).setIntValue("7");
	props.globals.getNode("/instrumentation/transponder/digit2", 1).setIntValue("0");
	props.globals.getNode("/instrumentation/transponder/digit3", 1).setIntValue("0");
	props.globals.getNode("/instrumentation/transponder/digit4", 1).setIntValue("0");
	props.globals.getNode("/instrumentation/transponder/reply-norm", 1).setDoubleValue(0);
	replyflash=aircraft.light.new("instrumentation/transponder/reply", [0.2, 15.0], "instrumentation/transponder/mode");

	TransponderUpdate();
	# Finished Initialising
	print ("Transponder : initialised");
	var initialized = 1;

} #end func

######################### Fire it up ############################################
setlistener("/sim/signals/electrical-initialized",initialize);
