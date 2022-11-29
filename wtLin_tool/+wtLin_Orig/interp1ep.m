function vec=interp1ep(x,y,val)

xmax=max(x);
xmin=min(x);

val=min(xmax,val);
val=max(xmin,val);

vec=interp1(x,y,val);

end