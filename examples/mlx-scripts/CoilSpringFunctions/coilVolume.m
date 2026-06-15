function volume = coilVolume(numCoils, wireDiameter, coilDiameter)
%COILVOLUME Calculate coil volume
%
%   DELTA = COILVOLUME(NUMCOILS, WIREDIAMETER, COILDIAMETER) calculates
%   the volume of the specified coil.

%   Copyright 2026 The MathWorks, Inc.

arguments (Input)
    numCoils (1, 1) double
    wireDiameter (1, 1) double
    coilDiameter (1, 1) double
end

arguments (Output)
    volume (1, 1) double
end

volume = 0.25*pi^2*wireDiameter^2*coilDiameter*(numCoils + 2);

end