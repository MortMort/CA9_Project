function vec=interp1ep(X,V,Xq)
% this function is the interp1 from the matlab toolbox, extended with 
% limitation of interpolation values to min/max of defined range

%INTERP1 1-D interpolation (table lookup)
%
%   Vq = INTERP1(X,V,Xq) interpolates to find Vq, the values of the
%   underlying function V=F(X) at the query points Xq. 
%
%   X must be a vector. The length of X is equal to N.
%   If V is a vector, V must have length N, and Vq is the same size as Xq.
%   If V is an array of size [N,D1,D2,...,Dk], then the interpolation is
%   performed for each D1-by-D2-by-...-Dk value in V(i,:,:,...,:). If Xq
%   is a vector of length M, then Vq has size [M,D1,D2,...,Dk]. If Xq is 
%   an array of size [M1,M2,...,Mj], then Vq is of size
%   [M1,M2,...,Mj,D1,D2,...,Dk].
%
%   Interpolation is the same operation as "table lookup".  Described in
%   "table lookup" terms, the "table" is [X,V] and INTERP1 "looks-up"
%   the elements of Xq in X, and, based upon their location, returns
%   values Vq interpolated within the elements of V.
%
%   Class support for inputs X, V, Xq, EXTRAPVAL:
%      float: double, single
%
%   See also INTERPFT, SPLINE, PCHIP, INTERP2, INTERP3, INTERPN, PPVAL.

%   Copyright 1984-2015 The MathWorks, Inc.

% Determine input arguments.
% Work backwards parsing from the end argument.
xmax=max(X);
xmin=min(X);

Xq=min(xmax,Xq);
Xq=max(xmin,Xq);

vec=interp1(X,V,Xq);

end