function wahlsFactor = coilWahlsFactor(wireDiameter, coilDiameter)
%COILWAHLSFACTOR Calculate Wahl's factor
%
%   DELTA = COILWAHLSFACTOR(WIREDIAMETER, COILDIAMETER) calculates Wahl's
%   factor, a correction factor to take account of the curvature of the
%   coil.

%   Copyright 2026 The MathWorks, Inc.

arguments (Input)
    wireDiameter (1, 1) double
    coilDiameter (1, 1) double
end

arguments (Output)
    wahlsFactor (1, 1) double
end

springIndex = coilSpringIndex(coilDiameter, wireDiameter);
wahlsFactor = (4*springIndex - 1)/(4*springIndex - 4) + 0.615/springIndex;

end