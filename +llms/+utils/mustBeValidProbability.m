function mustBeValidProbability(value)
% This function is undocumented and will change in a future release

%   Copyright 2024 The MathWorks, Inc.
    validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonnegative', 'nonsparse', '<=', 1})
end
