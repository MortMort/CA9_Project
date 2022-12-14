function figH = figure(a,b)
% figH = figure
if nargin ~= 2
    a=800;
    b=600;
end
figH=figure;
set(figH,'color','white'); set(figH, 'Position', [120 75 a b]);

end