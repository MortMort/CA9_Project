% Root functions, basic functions, such as SI-conversion etc:
% closefile       - This function closes the file named filename.
% dir             - List files in directory. Fast for network drives.
% getFileList     - List files in directory based on filter
% findDir         - List folders in directory
% savefig         - Saves figures as emf and fig.
% figure          - Open new figure in LAC format
% rad2deg         - Converts radians to degrees
% deg2rad         - Converts degrees to radians
% rpm2rad         - Convert rpm to rad/s
% rot2fix         - Transform signal from 3 blades (e.g. pitch) to fixed system. 
% fix2rot         - Transform signal from fixed system to 3 blades (e.g. pitch).
% rounddp         - Rounds off to n decimal points
% mapablestruct   - 
% updatecallbacks - Update callbacks inside function and figures. i.e handles
% 
% 
% The LAC-package contains following sub-packages containing 
% additional functions:
%   scripts    - Scripts, which require user inputs. Scripts are copied
%                into specified folder
%   climate    - Climate related functions e.g airdensity calculator
%   signal     - Functions related to signal processing
%   codec      - Shared functions to handle read/write functions
%   statistic  - Functions related to statistical processing of data
%   timetrace  - Functions related to timetraces, e.g. dvx,int,vdf files
%   vts        - Functions related to VTS, e.g. filereader/writers
%   pyro       - Functions related to pyro, e.g. filereader/writers
%   intpostd   - Functions related to intpostd, e.g. filereader/writers
%   hawc2      - Functions related to hawc2, e.g. filereader/writers
