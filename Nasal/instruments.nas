# set the timer for the selected function

var UPDATE_PERIOD = 0;

instrumenttimers = func {

  settimer(gmeterUpdate, UPDATE_PERIOD);
}

# =============================== end timer stuff ===========================================
# =============================== G-Meter stuff =============================================

gmeterUpdate = func {
  var GCurrent = props.globals.getNode("/accelerations/pilot-g[0]").getValue();
  var GMin = props.globals.getNode("/accelerations/pilot-gmin[0]").getValue();
  var GMax = props.globals.getNode("/accelerations/pilot-gmax[0]").getValue();

  if(GCurrent < GMin)
  { if (GCurrent > -6) 
    { setprop("/accelerations/pilot-gmin[0]", GCurrent);
          }
          else
          { setprop("/accelerations/pilot-gmin[0]", -6);
          }
  }
  elsif(GCurrent > GMax)
  { if(GCurrent < 10) 
          { setprop("/accelerations/pilot-gmax[0]", GCurrent);
          }
          else
          { setprop("/accelerations/pilot-gmax[0]", 10);
          }
  }
  instrumenttimers();
}

####################### Initialise ##############################################

initialize = func {

  ### Initialise gmeter ###
  props.globals.getNode("accelerations/pilot-g[0]", 1).setDoubleValue(1.01);
  props.globals.getNode("accelerations/pilot-gmin[0]", 1).setDoubleValue(1);
  props.globals.getNode("accelerations/pilot-gmax[0]", 1).setDoubleValue(1);

  ### Initialise electrical stuff  (move to electric system init once electrical system exists complete) ###
  props.globals.getNode("controls/circuit-breakers/start-ctrl", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/gen-ctrl", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/strobe-white", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/strobe-red", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/panel-lights", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/avionic-blower", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/pitot-heat", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/fuel-pump", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/eng-instr-2", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/gps", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/com2-nav2", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/avionic-bus-2", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/dme", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/audio-marker", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/att-indic-2", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/land-light", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/map-light", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/nav-lights", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/eng-instr-1", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/instr-lights", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/rpm-ind", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/lo-volt-warning", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/tands", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/fuel-lo-lev", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/att-indic-1", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/stall-warning", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/ess-bus", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/main-bus", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/gen", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/avionic-relay", 1).setBoolValue(1);
  props.globals.getNode("controls/circuit-breakers/flaps", 1).setBoolValue(1);

  instrumenttimers();
  # Finished Initialising
  print ("Instruments : initialised");
  var initialized = 1;

} #end func

######################### Fire it up ############################################
setlistener("/sim/signals/electrical-initialized",initialize);
