function validateResponseFormat(format,model,messages)
%validateResponseFormat - Validate requested response format is available for selected model
%   Not all OpenAI models support JSON output

%   Copyright 2024 The MathWorks, Inc.

    if ischar(format) | iscellstr(format) %#ok<ISCLSTR>
        format = string(format);
    end

    if isequal(format, "json")
        if ismember(model,["gpt-4","gpt-4-0613","o1-preview","o1-mini"])
            error("llms:invalidOptionAndValueForModel", ...
                llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionAndValueForModel", "ResponseFormat", "json", model));
        elseif nargin > 2
            % OpenAI says you need to mention JSON somewhere in the input
            if ~any(cellfun(@(s) contains(s.content,"json","IgnoreCase",true), messages))
                error("llms:warningJsonInstruction", ...
                    llms.utils.errorMessageCatalog.getMessage("llms:warningJsonInstruction"))
            end
        end
    elseif requestsStructuredOutput(format)
        if ~startsWith(model,"gpt-4o")
            error("llms:noStructuredOutputForModel", ...
                llms.utils.errorMessageCatalog.getMessage("llms:noStructuredOutputForModel", model));
        end
    end
end

function tf = requestsStructuredOutput(format)
% If the response format is not "text" or "json", then the input is interpreted as structured output.
    tf = ~isequal(format, "text") & ~isequal(format, "json");
end
