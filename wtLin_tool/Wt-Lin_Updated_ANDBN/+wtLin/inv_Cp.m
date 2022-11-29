function [ x_est status] = inv_Cp( X,Y,Z,y,z )
%Inverse CP calculation

% Version history – Responsible JADGR
% V0 - Unknown date - Unknown
% Todo:
% * Documentation

%   status=0:     Linear estimate used, all points inside the table
%   status=1:     Both lambda curves cannot reach the Cp point.     
%   status=2:     The first (lower lambda) curve cannot reach the Cp point
%   status=2:     The second (high lambda) curve cannot reach the Cp point
%   status=4:     The lower pitch (of the first pitch-Cp curve) is the maximum Cp table pitch. 
%   status=5:     The lower pitch (of the last pitch-Cp curve) is the maximum Cp table pitch.
%   status=6:     The lower pitch (of both pitch-Cp curve) is the maximum Cp table pitch.
    if(y>=Y(end))
        iY1 = length(Y);
        iY2 = iY1;
    elseif(y<=Y(1))
        iY1 = 1;
        iY2 = 1;
    else
        %Find the two X-Z curve above and below the y point.
        iY1=find(round(1000*Y)<=round(1000*y) , 1, 'last' );   % Index of nearest lower Y-value
        iY2=find(round(1000*Y)> round(1000*y)  , 1, 'first' ); % Index of nearest higher Y-value
        %Note: The use of round has been introduced to only consider the
        %first 3 decimals of the inputs (otherwise the '=' was never found
        %to be true)
    end

    if( z>=max( Z(:,iY1) ) )
        Oversurf1 = true;
     else
        Oversurf1 = false;
        %Find the first index (from the back) where the Z value of the
        %first X-Z curve is higher
        %than the z point.
        iX11 = find(Z(:,iY1) > z ,1,'last');
    end
    
    if( z>=max( Z(:,iY2) ) )
        Oversurf2 = true;
    else
        Oversurf2 = false;
        %Find the last index where the Z value of the second X-Z curve is lower
        %than the z point.
        iX21 = find(Z(:,iY2) > z ,1,'last');
    end

    if( Oversurf1 && ~Oversurf2)
        %Curve 1 does not have a curve which can 'reach' the desired z -
        %use only curve 2 for the remaining calculations.
        x_est = X(iX21) + (z-Z(iX21,iY2))* (X(iX21) - X(iX21+1)) / (Z(iX21,iY2) - Z(iX21+1,iY2));
        status=1;
    elseif( ~Oversurf1 && Oversurf2 )
        %Curve 2 does not have a curve which can 'reach' the desired z -
        %use only curve 1 for the remaining calculations.
        x_est = X(iX11) + (z-Z(iX11,iY1))* (X(iX11) - X(iX11+1)) / (Z(iX11,iY1) - Z(iX11+1,iY1));
        status=2;
    elseif( Oversurf1 && Oversurf2 )
        [Zmax1 iXmax1] = max( Z(:,iY1) );
        [Zmax2 iXmax2] = max( Z(:,iY2) );
        [Zmax iXmax] = max( [Zmax1 Zmax2] );
        iXmaxm = [iXmax1 iXmax2];
        x_est = X(iXmaxm(iXmax));
        status=3;
    else
        status = 0;
        if(iX11==length(X))
            x_val1 = X(iX11);
            status = 4;
        else
            %Estimate (linear) the x_val1 where the lower X-Z curve crosses
            %the z level
            x_val1 = X(iX11) + (z-Z(iX11,iY1)) * (X(iX11) - X(iX11+1)) / (Z(iX11,iY1) - Z(iX11+1,iY1));
        end
        
        if(iX21==length(X))
            x_val2 = X(iX21);
            
            %Update the status flag
            if(iX11==length(X))
               status = 6;
            else
               status = 5;
            end
        else
            %Estimate (linear) the x_val1 where the lower X-Z curve crosses
            %the z level
            x_val2 = X(iX21) + (z-Z(iX21,iY1))* (X(iX21) - X(iX21+1)) / (Z(iX21,iY2) - Z(iX21+1,iY2));
        end
        x_est  = x_val2 +  (y-Y(iY2))*(x_val2-x_val1) / (Y(iY2) - Y(iY1));
    end
end
