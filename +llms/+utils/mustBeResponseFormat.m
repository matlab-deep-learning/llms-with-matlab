function mustBeResponseFormat(format)
% This function is undocumented and will change in a future release

% Copyright 2024 The MathWorks Inc.
    if isstring(format) || ischar(format) || iscellstr(format)
        mustBeTextScalar(format);
        if ~ismember(format,["text","json"]) && ...
            ~startsWith(format,asManyOfPattern(whitespacePattern)+"{")
            error("llms:incorrectResponseFormat", ...
                llms.utils.errorMessageCatalog.getMessage("llms:incorrectResponseFormat"));
        end
    elseif ~isstruct(format)
        error("llms:incorrectResponseFormat", ...
            llms.utils.errorMessageCatalog.getMessage("llms:incorrectResponseFormat"));
    end
end
