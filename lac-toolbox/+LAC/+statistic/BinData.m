function varargout = BinData(varargin)
% BinData is a data binning function.
%
%   [XB, YB] = BinData(X,Y), returns Y data binned with respect to X
%
%   [XB, YB] = BinData(X,Y,Bin), data will be binned with in the specified
%   interval (default Bin = 1).
%
%   [XB, YB] = BinData(X,Y,bin,'plot') makes a barplot of the binned data
%
%   [XB, YB, N] = BinData(X,Y,...) N is the number of datapoints in each
%   bins
%
%
%   Example:
%
%      X  = [3.1 4.2 4.6 4.6 5.5 6.0 6.9 7.1 7.3 7.8]
%      Y  = [3 4 5 4 3 4 5 3 5 5]
%
%      [XB, YB, N] = BinData(X,Y,1)
%      returns
%      XB calculated as    = [2.5-3.5, 3.5-4.5,....]      
%      YB calculated as    = [sum(Y(X>=2.5 & X<3.5)),...]
%      N  calculated as    = [length(Y(X>=2.5 & X<3.5)),...]
% 
%       XB =
% 
%           3     4     5     6     7     8
% 
%       YB =
% 
%           3     4     9     7    13     5
% 
%       N =
% 
%           1     1     2     2     3     1
% 
% *Code Documentation*
%
% The software is outlined as self-documentating code: Use the MATLAB(R)
% |publish| function.
%
% § Date of release: 6th May 2014 - Version 1.0
%
% (C) Copyright 2014 by Jacob Brøchner

%% HANDLE INPUT
% Default
Bin  = 1;
Plot = 0;
% Input
if nargin >= 2
    X = varargin{1};
    Y = varargin{2};
    if length(X)>1 && length(Y)>1
        StartCalc=1;
    else
        message = 'X and Y must be data series';
        msgbox(message);
    end
end
if nargin < 2
    message = 'Insert data values X and Y';
    msgbox(message);
end
if nargin >= 3 && isnumeric(varargin{3})==1
    Bin = varargin{3};
end
if nargin >= 3 && isnumeric(varargin{3})==0
    if strcmp(varargin{3},'plot')==1 || strcmp(varargin{3},'Plot')==1 || strcmp(varargin{3},'PLOT')==1
        Plot=1;
    else
        message = 'write ''plot'' for the last input';
        msgbox(message);
    end
end
if nargin == 4
    if strcmp(varargin{4},'plot')==1 || strcmp(varargin{4},'Plot')==1 || strcmp(varargin{4},'PLOT')==1
        Plot=1;
    else
        message = 'write ''plot'' for the fourth input';
        msgbox(message);
    end
end
if nargin > 4
    message = 'Max four inputs! BinData(X,Y,bin,''plot'') Insert data values X and Y. Use the option of bin interval as third input. Use the option ''plot'' for the fourth input';
    msgbox(message);
end

%% Calc
if StartCalc == 1
    MinX  = min(X);
    MaxX  = max(X);
    Start = round(MinX/Bin)*Bin-(Bin/2);
    End   = round(MaxX/Bin)*Bin+(Bin/2);
    XB    = (Start +(Bin/2)):Bin:(End-(Bin/2));
    NBins = length(XB);
    YB    = zeros(1,NBins);
    N     = zeros(1,NBins);
    for i = 1:NBins
        A     = Y(X>=(XB(i)-(Bin/2)) & X<(XB(i)+(Bin/2)));
        YB(i) = sum(A);
        N(i)  = length(A);
    end
end
%% Plot
if Plot==1
    bar(XB,YB)
end

%% HANDLE OUTPUT
if nargout >= 1
    varargout{1} = XB;
end
if nargout >= 2
    varargout{2} = YB;
end
if nargout == 3
    varargout{3} = N;
end

if nargout > 3
    message = 'Too many output arguments';
    errordlg(message);
end
end