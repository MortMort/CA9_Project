function val=interp2ep(X,Y,V,Xq,Yq)
% this function is the interp2 from the matlab toolbox, extended with 
% limitation of interpolation values to min/max of defined range

%INTERP2 2-D interpolation (table lookup).
%
%   Some features of INTERP2 will be removed in a future release.
%   See the R2012a release notes for details.
%
%   Vq = INTERP2(X,Y,V,Xq,Yq) interpolates to find Vq, the values of the
%   underlying 2-D function V at the query points in matrices Xq and Yq.
%   Matrices X and Y specify the points at which the data V is given.
%
%   Xq can be a row vector, in which case it specifies a matrix with
%   constant columns. Similarly, Yq can be a column vector and it
%   specifies a matrix with constant rows.
%
%   All the interpolation methods require that X and Y be monotonic and
%   plaid (as if they were created using MESHGRID).  If you provide two
%   monotonic vectors, interp2 changes them to a plaid internally.
%   X and Y can be non-uniformly spaced.
%
%   For example, to generate a coarse approximation of PEAKS and
%   interpolate over a finer mesh:
%       [X,Y,V] = peaks(10); [Xq,Yq] = meshgrid(-3:.1:3,-3:.1:3);
%       Vq = interp2(X,Y,V,Xq,Yq); mesh(Xq,Yq,Vq)
%
%   Class support for inputs X, Y, V, Xq, Yq:
%      float: double, single
%
%   See also INTERP1, INTERP3, INTERPN, MESHGRID, scatteredInterpolant.

%   Copyright 1984-2014 The MathWorks, Inc.

x1max=max(X);
x1min=min(X);
Xq=min(x1max,Xq);
Xq=max(x1min,Xq);

x2max=max(Y);
x2min=min(Y);
Yq=min(x2max,Yq);
Yq=max(x2min,Yq);

val=interp2(X,Y,V,Xq,Yq);

end