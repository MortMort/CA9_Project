function val=interp2ep(x1,x2,tab,y1,y2)

x1max=max(x1);
x1min=min(x1);
y1=min(x1max,y1);
y1=max(x1min,y1);

x2max=max(x2);
x2min=min(x2);
y2=min(x2max,y2);
y2=max(x2min,y2);

val=interp2(x1,x2,tab,y1,y2);

end