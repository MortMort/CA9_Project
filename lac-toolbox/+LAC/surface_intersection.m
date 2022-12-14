function out_struct = surface_intersection(z1,z2,x,y,varargin)
    % Input parser.
    Parser = inputParser;
    Parser.addOptional('Color1','r'); % Color of surface 2.
    Parser.addOptional('Color2','b'); % Color of surface 2.
    Parser.addOptional('alpha2',1); % Color of surface 2.
    Parser.addOptional('DoPlot',false);

    % Parse.
    Parser.parse(varargin{:});

    % Set variables.
    Color1 = Parser.Results.('Color1');
    Color2 = Parser.Results.('Color2');
    alpha2 = Parser.Results.('alpha2');
    DoPlot = Parser.Results.('DoPlot');

    % Visualize the two surfaces
    if DoPlot;
        plot_handle1 = surface(x, y, z1, 'FaceColor', Color1, 'EdgeColor', 'none');
        plot_handle2 = surface(x, y, z2, 'FaceColor', Color2, 'EdgeColor', 'none');
        alpha(alpha2);
        view(3); camlight; axis vis3d
    end
    
    % Take the difference between the two surface heights and find the contour
    % where that surface is zero.
    zdiff = z1 - z2;
    C = contours(x, y, zdiff, [0 0]);
    % Extract the x- and y-locations from the contour matrix C.
    xL = C(1, 2:end);
    yL = C(2, 2:end);
    % Interpolate on the first surface to find z-locations for the intersection
    % line.
    zL = interp2(x, y, z1, xL, yL);
    % Visualize the line.
    if DoPlot;
        line(xL, yL, zL, 'Color', Color2, 'LineWidth', 3);
    end
    
    % Set output.
    out_struct.x_intersection = xL;
    out_struct.y_intersection = yL;
    out_struct.z_intersection = zL;
    out_struct.plot_handle1 = plot_handle1;
    out_struct.plot_handle2 = plot_handle2;
end