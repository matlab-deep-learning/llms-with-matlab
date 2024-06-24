function mustBeNonzeroLengthTextScalar(content)
% This function is undocumented and will change in a future release

%   Simple function to check if value is empty or text scalar

%   Copyright 2024 The MathWorks, Inc.
mustBeNonzeroLengthText(content)
if iscellstr(content)
    content = string(content);
end
mustBeTextScalar(content)
end
