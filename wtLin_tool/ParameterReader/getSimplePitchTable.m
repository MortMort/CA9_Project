function tab=getSimplePitchTable(moment,table)
%Interpolate the pitch table about a specific moement

%JADGR, Mar 2012

tab.voltage=table.voltage;
tab.data=interp2(table.pitchMoment,table.voltage,table.data,moment,table.voltage);
end