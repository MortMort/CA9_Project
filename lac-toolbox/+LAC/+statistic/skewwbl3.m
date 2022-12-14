function skewy=skewwbl3(k)

skewy=(3./k.*gamma(3./k)-3*(2./k.*gamma(2./k)).*(1./k.*gamma(1./k))+2*(1./k.*gamma(1./k)).^3)./(((2./k.*gamma(2./k))-(1./k.*gamma(1./k)).^2).^(3/2));