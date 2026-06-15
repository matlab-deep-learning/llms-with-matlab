function delta = coilDeflection(numCoils, wireDiameter, coilDiameter, load, modulusOfRigidity)
%COILDEFLECTION Calculate coil deflection
%
%   DELTA = COILDEFLECTION(NUMCOILS, WIREDIAMETER, COILDIAMETER, LOAD,
%   MODULUSOFRIGIDITY) calculates the deflection of the specified coil
%   under the applied LOAD.

%   Copyright 2026 The MathWorks, Inc.

arguments (Input)
    numCoils (1, 1) double
    wireDiameter (1, 1) double
    coilDiameter (1, 1) double
    load (1, 1) double
    modulusOfRigidity (1, 1) double
end

arguments (Output)
    delta (1, 1) double
end

delta = load/coilStiffness(numCoils, wireDiameter, coilDiameter, modulusOfRigidity);

end