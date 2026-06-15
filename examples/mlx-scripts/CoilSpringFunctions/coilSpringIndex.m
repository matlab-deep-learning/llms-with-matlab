function springIndex = coilSpringIndex(coilDiameter, wireDiameter)
%COILSPRINGINDEX Calculate spring index 
%
%   SPRINGINDEX = COILSPRINGINDEX(COILDIAMETER, WIREDIAMETER) calculates
%   the ratio of the coil diameter to the wire diameter.

%   Copyright 2026 The MathWorks, Inc.

arguments (Input)
    coilDiameter (1, 1) double
    wireDiameter (1, 1) double
end

arguments (Output)
    springIndex (1, 1) double
end

springIndex = coilDiameter/wireDiameter;

end