function damping = SDOFDamping(Res,Flow,nBlades,modes,bld,rho)
%Single Degree Of Freedom Damping Model
%Calculates the 2-dimensional damping for each blade section for the
%specified turbine modes.

%Read in BLD file used for VStab input
R=bld.SectionTable.R(2:end);%Define radial sections
beta=bld.SectionTable.beta(2:end);%Define the section twist radial distribution


if nargin<7
rho=1.225;%Air density (kg/m3)
end

% Damping Calculation

for iBLD = 1:nBlades
    for iMode=modes
%         etaVar=zeros(length(R),length(Flow.aoa));
        clear eigvec
        for i=1:length(Flow.aoa) %VStab Configuration number
            % Direction of vibration
            eigvec = Res.eigvec{1,i}(:,iMode);
            amplitude = abs(eigvec);
            phases = angle(eigvec);
            
            %Amplitude of mode
            a_flap(:,i) = amplitude(2:6:end);
            a_edge(:,i) = amplitude(1:6:end);
            %Phase of mode
            phi_flap(:,i) = phases(2:6:end)+pi;%Extra 180deg to account for the Vstab flapwise sign convention being opposite to positive direction of vibration
            phi_edge(:,i) = phases(1:6:end);
            theta_dist(:,i) = atand((a_flap(:,i)./max(a_edge(:,i))).*cos(phi_flap(:,i)-phi_edge(:,i)));
            
            for r=1:length(R) %Radial section
                c=Flow.chord(r); %Chord of blade at radius r
                W0=Flow.vel{1,i}(r,iBLD); %Magnitude of inflow velocity at radius r
                alpha = Flow.aoa{1,i}(r,iBLD); %Angle of attack
                phi = alpha + beta(r); %Direction of wind velocity relative to rotor plane
                theta = theta_dist(r); %Direction of vibration relative to rotor plane
                if isnan(theta)
                   theta = 0; 
                end
                ProfTable=Flow.ProfileTables{r,1};
                AoA=ProfTable(:,1); %Angle of Attack table lookup
                AoArad=AoA*pi/180;
                CLt=ProfTable(:,2); %CL Table lookup
                CDt=ProfTable(:,3); %CD Table lookup
                
                dCLdA = zeros(length(AoA),1);
                dCDdA = dCLdA;
                %Calculate derivative function of CL and CD using centre difference
                for a=2:(length(AoA)-1)
                    dCLdA(a)=(CLt(a+1)-CLt(a-1))/((AoArad(a)-AoArad(a-1))+(AoArad(a+1)-AoArad(a)));
                    dCDdA(a)=(CDt(a+1)-CDt(a-1))/((AoArad(a)-AoArad(a-1))+(AoArad(a+1)-AoArad(a)));
                end
                dCLdA(1)=(CLt(2)-CLt(end))/((AoArad(1)-AoArad(end))+(AoArad(2)-AoArad(1)));
                dCLdA(a+1)=(CLt(1)-CLt(a-1))/((AoArad(a)-AoArad(a-1))+(AoArad(1)-AoArad(a)));
                dCDdA(1)=(CDt(2)-CDt(end))/((AoArad(1)-AoArad(end))+(AoArad(2)-AoArad(1)));
                dCDdA(a+1)=(CDt(1)-CDt(a-1))/((AoArad(a)-AoArad(a-1))+(AoArad(1)-AoArad(a)));
                
                %Interpolate the aero polars based on local flow parameters
                CL = interp1(AoA,CLt,alpha);
                CD = interp1(AoA,CDt,alpha);
                dCL = interp1(AoA,dCLdA,alpha);
                dCD = interp1(AoA,dCDdA,alpha);
                
                
                %Calculate the radial damping distribution along the blade
                eta.lift(r,i)=(0.5*c*rho*W0)*( CL*sind(2*theta-2*phi) );
                eta.drag(r,i)=(0.5*c*rho*W0)*( CD*(3+cosd(2*theta-2*phi)));
                eta.liftslope(r,i)=(0.5*c*rho*W0)*( dCL*(1-cosd(2*theta-2*phi)) );
                eta.dragslope(r,i)=(0.5*c*rho*W0)*( dCD*sind(2*theta-2*phi) );
                eta.total(r,i) = (0.5*c*rho*W0)*( CD*(3+cosd(2*theta-2*phi)) + dCL*(1-cosd(2*theta-2*phi)) + (CL+dCD)*sind(2*theta-2*phi) );
            end
        end
        damping.(char(['MODE',num2str(iMode)])).(char(['BLD',num2str(iBLD)])).eta=eta;
    end
end


