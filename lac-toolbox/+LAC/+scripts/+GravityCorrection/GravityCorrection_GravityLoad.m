function [Fgrav] = GravityCorrection_GravityLoad(dat,Sensor,MAS)
% GravityCorrection_GravityLoad - Function to calculate the gravity force using simplified model
% See DMS 0012-1549
%
% Syntax:  [Fgrav] = GravityCorrection_GravityLoad(dat,Sensor,masfilename)
%
% Inputs:
%    dat 			- Time coherent values of: [ Azimuth angle of blade 1 (col 1) , Pitch angles of blade 1,2,3 (col 2,3,4) ]
%    Sensor 		- Blade sensor (e.g. "-Mx11r")
%    MAS	       - Structure populated with relevant MAS file information (see GC_ReadMas)
%
% Outputs:
%    Fgrav 			- Gravity Load
%
% Example: 
%    TBD
%    TBD
%    TBD
%
% Author: IVSON, Ivan Sønderby
% Oct. 2019; Last revision: 16-Oct-2019

%------------- BEGIN CODE --------------

% Based on the sensor name find flap or edge, sec. number, blade number
    if isempty(regexp(Sensor,'-Mx'))
        direction = 2; % edge
        output_sign = 1;
        start_ix = 3;
    else
        direction = 1; % flap
        output_sign = -1;
        start_ix = 4;
    end
    Blade_nr = str2num(Sensor(start_ix));
    secno = str2num( Sensor(start_ix+1:end-1) );
    
    nblade = MAS.nblade; coning = MAS.coning; tilt = MAS.tilt;
    g_ = -9.81; % g [m/s^2]
    coningr = (coning/180*pi); % [rad]
    tiltr=(tilt/180*pi);     % [rad]
    psi = dat(:,1);
    
    % Automatic find of the blade radius for the selected sensor
    l_m_b = length(MAS.blade);
    r = MAS.blade(1,secno);
    
    % Blade sections and blade mass increments
    dL=diff(MAS.blade(1,:));
    dL(end+1)=0;
    dm=diff(MAS.blade(2,:));
    dm(end+1)=0;
    
    %%%%%%%%%%%%%%%%%%%%% MAIN CALCULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Calculations are made for blade A/1
    % Global vestas coordinates are used
    
    % Constant Gravitational force vectors for each blade section
    fgtc=zeros(3,(length(MAS.blade)-1));

    for i=1:l_m_b-1
        fgtc(3,i)= dL(i)*(MAS.blade(2,i)+0.5*dm(i))*g_/1000; % kN
        c=(MAS.blade(2,i)+0.5*dm(i));
    end
    fgtc(3,(end+1))=0;

    % Initialisation of Local positions vectors and transformationsmatrix

    % Transformation matrix, GLOBAL to ROTORPLAN
    GtoRP=[1 0 0; 0 cos(tiltr) -sin(tiltr); 0 sin(tiltr) cos(tiltr)];

    % Local position vectors for cross sections and point
    % masses
    rml=zeros(3,l_m_b-1);
    rsl=zeros(3,l_m_b-1);
    for jj=1:l_m_b-1
        % Radial Position of blade sections
        rml(3,jj)=(MAS.blade(1,jj)+0.5*dL(jj));    % Local z-coordinate along the blade
                                                   % Radial Poaition of blade sections
        rsl(3,jj)=(MAS.blade(1,jj));               % Local z-coordinate along the blade
    end

    for i = Blade_nr
        
        Fgrav = zeros(length(dat(:,1)),length(r));
        Pit=dat(:,1+i);  % Blade pitch angles [deg]

        for k = 1:length(dat(:,1))
            
            psibn=psi(k)-120*(i-1); % [degrees], Azimuth position for blade number i

            % Transformation of local positions vectors into rotor plane coordinates
            ta(1,1)=(180+psibn)/180*pi;
            ta(2,1)=coningr;
            ta(3,1)=0;
            for m=1:l_m_b-1
                rmg(:,m)=GtoRP*(Atrans(ta)*rml(:,m));
                rsg(:,m)=GtoRP*(Atrans(ta)*rsl(:,m));
            end

            % Static Global massmoment at each cross section, Calculated by cross product
            mgtc=zeros(3,(l_m_b-1));
            n=0;
            len = l_m_b - 1;
            for ii=1:l_m_b-1
                mgtc(:,ii) = sum(cross(rmg(:,ii:len),fgtc(:,ii:len)),2) -cross(rsg(:,ii),sum(fgtc(:,ii:len),2));
            end

            % Mass moment and twist at output sensors inintialisation
            bmgtc=mgtc(:,[secno]);
            btw= MAS.blade(3,[secno]);
            bmgl=zeros(3,(length(MAS.blade)-1));

            % Transformation of global mass moments into blade profil coordinate system
            for m=1:length(secno)
                ta(1,1)=(180+psibn)/180*pi;
                ta(2,1)=coningr;
                ta(3,1)=(-btw(m)-Pit(k,1))/180*pi;
                bmgl(:,m)=Atrans(ta)'*(GtoRP'*bmgtc(:,m));
            end

            %%%%%%%%%%%%%%%%%% Extracting the gravity force for output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for l=1:length(r)
                Fgrav(k,1) = output_sign*bmgl(direction,l);
            end
            
        end
    end
    
    %------------- END OF CODE --------------
    
end

function A = Atrans(b)

    A=zeros(3,3);

    A(1,1) = cos(b(1))*cos(b(3))+sin(b(1))*sin(b(2))*sin(b(3));
    A(2,1) = cos(b(2))*sin(b(3));
    A(3,1) = -sin(b(1))*cos(b(3))+cos(b(1))*sin(b(2))*sin(b(3));

    A(1,2) = -cos(b(1))*sin(b(3))+sin(b(1))*sin(b(2))*cos(b(3));
    A(2,2) = cos(b(2))*cos(b(3));
    A(3,2) = sin(b(1))*sin(b(3))+cos(b(1))*sin(b(2))*cos(b(3));

    A(1,3) = sin(b(1))*cos(b(2));
    A(2,3) = -sin(b(2));
    A(3,3) = cos(b(1))*cos(b(2));

end

