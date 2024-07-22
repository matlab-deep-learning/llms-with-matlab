function validateMessageSupported(message, model);
%validateMessageSupported - check that message is supported by model

%   Copyright 2024 The MathWorks, Inc.

    % only certain models support image generation
    if iscell(message.content) && any(cellfun(@(x) isfield(x,"image_url"), message.content))
        if ~ismember(model,["gpt-4-turbo","gpt-4-turbo-2024-04-09",...
            "gpt-4o-mini","gpt-4o-mini-2024-07-18",...
            "gpt-4o","gpt-4o-2024-05-13"]) 
         error("llms:invalidContentTypeForModel", ...
               llms.utils.errorMessageCatalog.getMessage("llms:invalidContentTypeForModel", "Image content", model));
        end
    end
end
