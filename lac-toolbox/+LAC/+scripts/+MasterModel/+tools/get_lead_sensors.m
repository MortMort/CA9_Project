
function lead_sensors = get_lead_sensors(diameter,sen)

    blade_locations = num2str(diameter/2 .* [0.375 0.625 0.875]');
    
    blade_locations = [ '00' ; blade_locations(:,1:2)];

    sensors = [];
    
    sensors(end+1).Name  = ['B?Mx' blade_locations(1,:) '\d{3}'];
    sensors(end).Comment = 'Max';
        
    lead_sensors = {
        % Extreme
        ['B\dMx'  blade_locations(1,:) '1\d{2}'] 'Max' '.*' 'B?Mx_root Max'
        ['B\dMx0' blade_locations(2,:) '\d{2}'] 'Max' '.*' 'B?Mx_0.375 Max'
        ['B\dMx0' blade_locations(3,:) '\d{2}'] 'Max' '.*' 'B?Mx_0.625 Max'
        ['B\dMx0' blade_locations(4,:) '\d{2}'] 'Max' '.*' 'B?Mx_0.875 Max'
        ['B\dMx'  blade_locations(1,:) '\d{3}'] 'Min' '.*' 'B?Mx_root Min'
        ['B\dMx0' blade_locations(2,:) '\d{2}'] 'Min' '.*' 'B?Mx_0.375 Min'
        ['B\dMx0' blade_locations(3,:) '\d{2}'] 'Min' '.*' 'B?Mx_0.625 Min'
        ['B\dMx0' blade_locations(4,:) '\d{2}'] 'Min' '.*' 'B?Mx_0.875 Min'
        ['B\dMy'  blade_locations(1,:) '\d{3}'] 'Max' '.*' 'B?My_root Max'
        ['B\dMy0' blade_locations(2,:) '\d{2}'] 'Max' '.*' 'B?My_0.375 Max'
        ['B\dMy0' blade_locations(3,:) '\d{2}'] 'Max' '.*' 'B?My_0.625 Max'
        ['B\dMy0' blade_locations(4,:) '\d{2}'] 'Max' '.*' 'B?My_0.875 Max'
        ['B\dMy'  blade_locations(1,:) '\d{3}'] 'Min' '.*' 'B?My_root Min'
        ['B\dMy0' blade_locations(2,:) '\d{2}'] 'Min' '.*' 'B?My_0.375 Min'
        ['B\dMy0' blade_locations(3,:) '\d{2}'] 'Min' '.*' 'B?My_0.625 Min'
        ['B\dMy0' blade_locations(4,:) '\d{2}'] 'Min' '.*' 'B?My_0.875 Min'
        'Mr\d1r' 'Abs' '.*' 'Mr?1r Abs'
        'bldefl' 'Max' '.*' 'bldefl Max'
        '-Mx\d1h' 'Abs' '.*' 'Mx?1h Abs'
        'Fpi\d1' 'Max' '.*' 'Fpi?1 Max'
        'Fpi\d1' 'Min' '.*' 'Fpi?1 Min'
        ['Fx' sen 'f']  	'Abs'	'.*' ['Fx' sen 'f Abs']
        ['Fy' sen 'r']  	'Max'	'.*' ['Fy' sen 'r Max']
        ['Fy' sen 'r']  	'Min'	'.*' ['Fy' sen 'r Min']
        ['Fz' sen 'f']  	'Abs'	'.*' ['Fz' sen 'f Abs']
        ['Mx' sen 'f']  	'Abs'	'.*' ['Mx' sen 'f Abs']
        ['Mz' sen 'f']  	'Abs'	'.*' ['Mz' sen 'f Abs']
        ['Mx' sen 'r']  	'Abs'	'.*' ['Mx' sen 'r Abs']
        ['Mz' sen 'r']  	'Abs'	'.*' ['Mz' sen 'r Abs']
        ['Mr' sen   ]		'Max'	'.*' ['Mr' sen  ' Max']
        ['My' sen 'r']  	'Max'	'.*' ['My' sen 'r Max']
        ['My' sen 'r']  	'Min'	'.*' ['My' sen 'r Min']
        'Mxtt'	'Abs'	'.*' 'Mxtt Abs'
        'Mztt'	'Abs'	'.*' 'Mztt Abs'
        'Mbtt'	'Abs'	'.*' 'Mbtt Abs'
        'AxK'	'Abs'	'.*' 'AxK Abs'
        'AyK'	'Abs'	'.*' 'AyK Abs'
        'OMPxK'	'Abs'	'.*' 'OMPxK Abs'
        'OMPyK'	'Abs'	'.*' 'OMPyK Abs'
        'OMPzK'	'Abs'	'.*' 'OMPzK Abs'
        'Mbt\d'	'Max'	'.*' 'Mbt0 Max'
        % Fatigue
        ['B\dMx'  blade_locations(1,:) '\d{3}'] 'Rfc' '10\.00' 'B?Mx_root Rfc10.00'
        ['B\dMy'  blade_locations(1,:) '\d{3}'] 'Rfc' '10\.00' 'B?My_root Rfc10.00'
        '-Mx\d1r' 'Rfc' '4.00' '-Mx?1r Rfc4.00'
        'My\d1r' 'Rfc' '4.00' 'My?1r Rfc4.00'
        'Mr\d' 'Lrd' '3.33' 'Mr? Lrd3.33'
        'Fpi\d1' 'Rfc' '3.00' 'Fpi?1 Rfc3'
        ['Mx' sen 'f'] 'Lrd' '3.33'  ['Mx' sen 'f Lrd3.33']
        ['Mz' sen 'f'] 'Lrd' '3.33'  ['Mz' sen 'f Lrd3.33']
        ['Fx' sen 'f']	'Rfc' '4.00' ['Fx' sen 'f Rfc4.00']
        ['Fy' sen 'r']	'Rfc' '4.00' ['Fy' sen 'r Rfc4.00']
        ['Fz' sen 'f']	'Rfc' '4.00' ['Fz' sen 'f Rfc4.00']
        ['Mx' sen 'f']	'Rfc' '4.00' ['Mx' sen 'f Rfc4.00']
        ['Mz' sen 'f']	'Rfc' '4.00' ['Mz' sen 'f Rfc4.00']
        ['Mx' sen 'r']	'Rfc' '4.00' ['Mx' sen 'r Rfc4.00']
        ['My' sen 'r']	'Rfc' '4.00' ['My' sen 'r Rfc4.00']
        ['My' sen 'r']	'Rfc' '8.00' ['My' sen 'r Rfc8.00']
        ['Mz' sen 'r']	'Rfc' '4.00' ['Mz' sen 'r Rfc4.00']
        'Mxtt'	'Rfc' '4.00' 'Mxtt Rfc4.00'
        'Mztt'	'Rfc' '4.00' 'Mztt Rfc4.00'
        'AxK'	'Rfc' '4.00' 'AxK Rfc4.00'
        'AyK'	'Rfc' '4.00' 'AyK Rfc4.00'
        'OMPxK'	'Rfc' '4.00' 'OMPxK Rfc4.00'
        'OMPyK'	'Rfc' '4.00' 'OMPyK Rfc4.00'
        'OMPzK'	'Rfc' '4.00' 'OMPzK Rfc4.00'
        'Mxt\d'	'Rfc' '4.00' 'Mxt0 Rfc4.00'
    };



end
