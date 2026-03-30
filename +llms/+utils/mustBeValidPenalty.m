function mustBeValidPenalty(value)
% This function is undocumented and will change in a future release

%   Copyright 2024-2026 The MathWorks, Inc.
    if isequal(convertCharsToStrings(value), "auto")
        return
    end
    validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonsparse', '<=', 2, '>=', -2})
end
