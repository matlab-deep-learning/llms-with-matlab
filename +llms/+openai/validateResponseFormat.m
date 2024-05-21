function validateResponseFormat(format,model)
%validateResponseFormat - validate requested response format is available for selected model
%   Not all OpenAI models support JSON output

%   Copyright 2024 The MathWorks, Inc.

    if format == "json"
        if ismember(model,["gpt-4","gpt-4-0613"])
            error("llms:invalidOptionAndValueForModel", ...
                llms.utils.errorMessageCatalog.getMessage("llms:invalidOptionAndValueForModel", "ResponseFormat", "json", model));
        else
            warning("llms:warningJsonInstruction", ...
                llms.utils.errorMessageCatalog.getMessage("llms:warningJsonInstruction"))
        end
    end
end
