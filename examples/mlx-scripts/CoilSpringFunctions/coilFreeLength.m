function freeLength = coilFreeLength(numCoils, wireDiameter, coilDiameter, maxLoad, modulusOfRigidity)
%COILFREELENGTH Calculate coil free length
%
%   DELTA = COILFREELENGTH(NUMCOILS, WIREDIAMETER, COILDIAMETER, MAXLOAD,
%   MODULUSOFRIGIDITY) calculates the length of the coil without any
%   applied load.

%   Copyright 2026 The MathWorks, Inc.

arguments (Input)
    numCoils (1, 1) double
    wireDiameter (1, 1) double
    coilDiameter (1, 1) double
    maxLoad (1, 1) double
    modulusOfRigidity (1, 1) double
end

arguments (Output)
    freeLength (1, 1) double
end

stiffness =  coilStiffness(numCoils, wireDiameter, coilDiameter, modulusOfRigidity);
freeLength = maxLoad/stiffness + 1.05*(numCoils + 2)*wireDiameter;

end

