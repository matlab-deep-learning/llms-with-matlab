function mustBeValidTailFreeSamplingZ(value)
% This function is undocumented and will change in a future release

%   Copyright 2026 The MathWorks, Inc.
    if isequal(convertCharsToStrings(value), "auto")
        return
    end
    validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonsparse'})
end
