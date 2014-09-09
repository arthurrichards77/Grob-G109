var stepMagnetos = controls.stepMagnetos;

controls.stepMagnetos = func(change) {
    var ignition = getprop("controls/switches/ignition");
    ignition=ignition+change;
    if (ignition<0)
    	ignition=0;
    if (ignition>4)
    	ignition=4;
    if (!change and ignition==4)
	ignition=3;
    if (ignition>2)
	setprop("controls/engines/engine/magnetos",3);
    else
	setprop("controls/engines/engine/magnetos",0);
    if (ignition>3)
	setprop("controls/engines/engine/starter",'true');
    else
	setprop("controls/engines/engine/starter",'false');
    setprop("controls/switches/ignition",ignition);
}
