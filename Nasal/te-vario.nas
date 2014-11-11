# Winter Total Energy compensated variometers

io.include("Aircraft/Generic/soaring-instrumentation-sdk.nas");

var probe = TotalEnergyProbe.new();

var needle = Dampener.new(
  input: probe,
  dampening: 2.3,
  on_update: update_prop("/instrumentation/variometer/te-reading-mps"));

var instrument = Instrument.new(
  components: [probe, needle],
  enable: 1);
