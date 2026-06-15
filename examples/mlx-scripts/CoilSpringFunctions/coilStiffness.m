function stiffness = coilStiffness(numCoils, wireDiameter, coilDiameter, modulusOfRigidity)
%COILSTIFFNESS Calculate coil stiffness
%
%   DELTA = COILSTIFFNESS(NUMCOILS, WIREDIAMETER, COILDIAMETER,
%   MODULUSOFRIGIDITY) calculates the stiffness of the specified coil.

%   Copyright 2026 The MathWorks, Inc.

arguments (Input)
    numCoils (1, 1) double
    wireDiameter (1, 1) double
    coilDiameter (1, 1) double
    modulusOfRigidity (1, 1) double
end

arguments (Output)
    stiffness (1, 1) double
end

stiffness = modulusOfRigidity*wireDiameter^4/(8*numCoils*coilDiameter^3);

end