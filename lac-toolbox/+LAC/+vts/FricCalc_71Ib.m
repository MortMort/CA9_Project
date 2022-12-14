clc
clear all
StaLoc = input('Enter Location of stat files: ');
LCName = '71*.sta';
Sens={'Vhub','Pi2','-Mx21r','My21r', 'Mpi21'};
addpath('w:\source\TLtoolbox\');
[data] = stareadTL(Sens,StaLoc,LCName,false,false);
Mfric0 = 9.6;
cMkip = 0.0033;
%vhub = data.Vhub.mean;
mx = data.Mx21r_neg.mean;
my = data.My21r.mean;
mpi21_mean = data.Mpi21.mean;
mpi21_min = data.Mpi21.min;
%Pi2 = data.Pi2.mean;

Mres = (mx.^2 + my.^2).^(1/2);

Mfric_all = Mfric0 + cMkip*Mres;

vhub = [4
6
8
10
12
14
16
18
20
22
24
26
28
30
32
];

pi2=[0
10
20
30
40
50
60
70
80
];

n =0;
for ii = 1:length(pi2)
    for jj= 1:length(vhub)
        n = n +1;
        Mfric(jj,ii)=Mfric_all(n);
        Mp21Mean(jj,ii) = mpi21_mean(n);
        Mp21Min(jj,ii) = mpi21_min(n);
    end
end

% Create the 3D plot
f = figure;
contourf(pi2,vhub,Mfric);
h=colorbar;
set(h,'Location','SouthOutside');

% Set the viewing angle and the axis limits
view(0,90);


% Add title and axis labels
ylabel('vhub (m/s)');
xlabel('pi2 (deg)');
%zlabel('Mp21 (kNm)');
title('Mfric Contour Plot');
saveas(f,'Mfric_V105','jpg');
close(f);


fid = fopen('pitchMoveMean_V105.txt','w');
for ii = 1:length(vhub)
    for jj= 1:length(pi2)
        if -Mp21Mean(ii,jj)>=Mfric(ii,jj)
            fprintf(fid,['Moving ']);
            mov(ii,jj) = 1;
        else
            fprintf(fid,['NotMoving ']);
            mov(ii,jj) = 0;
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);
for jj= 1:length(pi2)
    for ii = 2:length(vhub)    
        if mov(ii-1,jj)<mov(ii,jj)
            y(jj) = vhub(ii);
            x(jj) = pi2(jj);
            break
        else
            x(jj) = pi2(jj);
            y(jj) = 0;
        end
    end
end

for jj= 2:length(pi2)
    if y(jj) == 0 && mov(length(vhub),jj) == 0
        y(jj) = 32;
    elseif y(jj) == 0 && mov(length(vhub),jj) == 1
        y(jj) = 4;
    end
end
        
        

% Create the 3D plot
f = figure;
contourf(pi2,vhub,Mp21Mean);
h=colorbar;
set(h,'Location','SouthOutside');

% Set the viewing angle and the axis limits
view(0,90);


% Add title and axis labels
ylabel('vhub (m/s)');
xlabel('pi2 (deg)');
%zlabel('Mp21 (kNm)');
title('Pitch Moment on 2nd Blade');
hold on
plot(x,y,'-.k','LineWidth',2.5)
saveas(f,'Pitch_moment_V105','jpg');
close(f);
            
        
fid = fopen('pitchMoveMin_V105.txt','w');
for ii = 1:length(vhub)
    for jj= 1:length(pi2)
        if -Mp21Min(ii,jj)>=Mfric(ii,jj)
            fprintf(fid,['Moving ']);
            mov(ii,jj) = 1;
        else
            fprintf(fid,['NotMoving ']);
            mov(ii,jj) = 0;
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);


fid = fopen('MomVal_V105.txt','w');
for ii = 1:length(vhub)
    for jj= 1:length(pi2)  
        temp= strcat(num2str(Mfric(ii,jj)),{' '});
        fprintf(fid,temp{1});        
    end
    fprintf(fid,'\n');
end
fclose(fid);

for jj= 1:length(pi2)
    for ii = 2:length(vhub)    
        if mov(ii-1,jj)<mov(ii,jj)
            y(jj) = vhub(ii);
            x(jj) = pi2(jj);
            break
        else
            x(jj) = pi2(jj);
            y(jj) = 0;
        end
    end
end

for jj= 2:length(pi2)
    if y(jj) == 0 && mov(length(vhub),jj) == 0
        y(jj) = 32;
    elseif y(jj) == 0 && mov(length(vhub),jj) == 1
        y(jj) = 4;
    end
end
        
        

% Create the 3D plot
f = figure;
contourf(pi2,vhub,Mp21Min);
h=colorbar;
set(h,'Location','SouthOutside');

% Set the viewing angle and the axis limits
view(0,90);


% Add title and axis labels
ylabel('vhub (m/s)');
xlabel('pi2 (deg)');
%zlabel('Mp21 (kNm)');
title('Pitch Moment on 2nd Blade');
hold on
plot(x,y,'-.k','LineWidth',2.5)
saveas(f,'Pitch_moment_min_V105','jpg');
close(f);
clear all


            