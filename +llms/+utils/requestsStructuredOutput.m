function tf = requestsStructuredOutput(format)
% This function is undocumented and will change in a future release

% Simple function to check if requested format triggers structured output

%   Copyright 2024 The MathWorks, Inc.
tf =  isstruct(format) || startsWith(format,asManyOfPattern(whitespacePattern)+"{");
end

