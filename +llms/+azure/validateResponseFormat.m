function validateResponseFormat(format,model,messages)
%validateResponseFormat - validate requested response format is available for selected API Version

%   Copyright 2024 The MathWorks, Inc.

    if ischar(format) | iscellstr(format) %#ok<ISCLSTR>
        format = string(format);
    end

    if isstring(format) && isequal(lower(format),"json")
        if nargin > 2
            % OpenAI requires that the prompt or message describing the format must contain the word `"json"` or `"JSON"`.
            if ~any(cellfun(@(s) contains(s.content,"json","IgnoreCase",true), messages))
                error("llms:warningJsonInstruction", ...
                    llms.utils.errorMessageCatalog.getMessage("llms:warningJsonInstruction"))
            end
        end
    end

    if requestsStructuredOutput(format)
        % the beauty of ISO-8601: comparing dates by string comparison
        if model.APIVersion < "2024-08-01"
            error("llms:structuredOutputRequiresAPI", ...
                llms.utils.errorMessageCatalog.getMessage("llms:structuredOutputRequiresAPI", model.APIVersion));
        end
    end
end

function tf = requestsStructuredOutput(format)
% If the response format is not "text" or "json", then the input is interpreted as structured output.
    tf = ~isequal(format, "text") & ~isequal(format, "json");
end
