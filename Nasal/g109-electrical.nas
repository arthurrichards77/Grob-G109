##
# Grob G-115EG electrical system (based on DHC2 electrical system).
##

# Initialize internal values
#

var battery = nil;
var alternator = nil;

var last_time = 0.0;

var vbus_volts = 0.0;
var main_bus_volts = 0.0;
var ammeter_ave = 0.0;

##
# Initialize the electrical system
#

init_electrical = func {
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();

###
### Initialise electrical stuff ###
### (move to electric system init once electrical system exists complete) ###
###
    props.globals.getNode("/systems/electrical/volts", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/amps", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/alternator", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/mainbusvolts", 1).setDoubleValue(0.0);

    props.globals.getNode("instrumentation/warning-panel/starter-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("instrumentation/warning-panel/generator-norm", 1).setDoubleValue(0.0);

    props.globals.getNode("controls/circuit-breakers/main", 1).setBoolValue(1);
    props.globals.getNode("controls/circuit-breakers/generator", 1).setBoolValue(1);

    props.globals.getNode("/controls/switches/main", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/fuel", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/navlight", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/strobelight", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/landinglight", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/instrumentlight", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/ignition", 1).setIntValue(0);

    print("Nasal Electrical System : initialised");
    props.globals.getNode("/sim/signals/electrical-initialized", 1).setBoolValue(0);

    # Request that the update fuction be called next frame
    settimer(update_electrical, 0);
}

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 30.0,
            amp_hours : 12.75,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    # print( "battery percent = ", me.charge_percent);
    return me.amp_hours * me.charge_percent;
}


BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}


BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}


AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/rpm",
            rpm_threshold : 600.0,
            ideal_volts : 28.0,
            ideal_amps : 60.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}


AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}


AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}


update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;

    update_virtual_bus( dt );
    # Request that the update fuction be called again next frame
    settimer(update_electrical, 0);
}


update_virtual_bus = func( dt ) {
    battery_volts = battery.get_output_volts();
    alternator_volts = alternator.get_output_volts();
    external_volts = 0.0;
    load = 0.0;

    # switch state
    master_alt = getprop("/controls/switches/generator");

    # determine power source
    bus_volts = 0.0;
    power_source = "none";
    if ( getprop("/controls/switches/ignition")>1 ) {
        bus_volts = battery_volts;
        power_source = "battery";
    }
    if ( getprop("/controls/circuit-breakers/generator") and 
         (alternator_volts > bus_volts) ) {
        bus_volts = alternator_volts;
        power_source = "alternator";
    }
    if ( external_volts > bus_volts ) {
        bus_volts = external_volts;
        power_source = "external";
    }


    # starter
    if (getprop("/controls/switches/ignition")==4) {
	load += 20.0;
    }

    # Starter warning
    if (getprop("controls/engines/engine/starter")) {
	 setprop("instrumentation/warning-panel/starter-norm",  bus_volts/28);
    }
    else {
	 setprop("instrumentation/warning-panel/starter-norm",  0.0);
    };

    # Generator warning
    if (bus_volts<25) {
	 setprop("instrumentation/warning-panel/generator-norm",  bus_volts/28);
    }
    else {
	 setprop("instrumentation/warning-panel/generator-norm",  0.0);
    };

    # bus network (1. these must be called in the right order, 2. the
    # bus routine itself determins where it draws power from.)
    load += main_bus();

    # Generator breaker
    if (power_source=="alternator" and load>35.0) {
        setprop("/controls/circuit-breakers/generator",0);
    };

    # system loads and ammeter gauge
    ammeter = 0.0;
    if ( bus_volts > 1.0 ) {

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }
    # print( "ammeter = ", ammeter );

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    setprop("/systems/electrical/alternator", alternator_volts);
    vbus_volts = bus_volts;

    return load;
}


main_bus = func() {

    # fed from the "virtual" bus via the main bus breaker (30A)
    if ( getprop("/controls/circuit-breakers/main") and
         getprop("/controls/switches/main") ) {
    	main_bus_volts = vbus_volts;
    } else {
	main_bus_volts = 0.0;
    }	
    setprop("/systems/electrical/mainbusvolts",main_bus_volts);
    load = 0.0;

    # Radio
    load += 6.0;

    # Transponder
    load += 6.0;

    # Strobe (10A)
    if ( getprop("/controls/switches/strobelight") ) {
         setprop("/systems/electrical/outputs/strobe", main_bus_volts);
         load += 6.0;
    } else {
        setprop("/systems/electrical/outputs/strobe", 0.0);
    }

    # Landing Light (7.5A)
    if ( getprop("/controls/switches/landinglight") ) {
         setprop("/systems/electrical/outputs/land-light", main_bus_volts);
	 setprop("/controls/lighting/land-light-norm",  main_bus_volts/28);
         load += 3.5;
    } else {
        setprop("/systems/electrical/outputs/land-light", 0.0);
	 setprop("/controls/lighting/land-light-norm", 0.0);
    }

    # Nav Lights (7.5A)
    if ( getprop("/controls/switches/navlight") ) {
         setprop("/systems/electrical/outputs/nav-lights", main_bus_volts);
	 setprop("/controls/lighting/nav-lights-norm",  main_bus_volts/28);
         load += 4.0;
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0);
	setprop("/controls/lighting/nav-lights-norm", 0.0);
    }
    
    # Instrument Lights (5A)
    if ( getprop("/controls/switches/instrumentlight") ) {
        setprop("/systems/electrical/outputs/instr-lights", main_bus_volts);
        setprop("/controls/lighting/instruments-norm",  main_bus_volts/28);
	load += 3.0;
    } else {
        setprop("/systems/electrical/outputs/instr-lights", 0.0);
	setprop("/controls/lighting/instruments-norm", 0.0);
    }

    # Fuel Pump (5A)
    if ( getprop("/controls/switches/fuel") ) {
        setprop("/systems/electrical/outputs/fuel-pump", main_bus_volts);
	load += 3.0;
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    if ( getprop("systems/electrical/outputs/fuel-pump")>12 ) {
        setprop("controls/engines/engine/fuel-pump", 1);
    } else {
        setprop("controls/engines/engine/fuel-pump", 0);
    }


    setprop("/systems/electrical/outputs/turn-coordinator", main_bus_volts);

    # pop breaker if over current
    if ( load>30.0 and main_bus_volts>1.0 ) {
	setprop("/controls/circuit-breakers/main",0);
    }

    # return cumulative load
    if ( main_bus_volts>1.0 ) { 
	return load;
    } else {
	return 0.0;
    }
}

# Setup a timer based call to initialized the electrical system as
# soon as possible.
setlistener("/sim/signals/fdm-initialized",init_electrical);
