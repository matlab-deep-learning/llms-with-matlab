function key = getApiKeyFromNvpOrEnv(nvp,envVarName)
% This function is undocumented and will change in a future release

%getApiKeyFromNvpOrEnv Retrieves an API key from a Name-Value Pair struct or environment variable.
%
%   This function takes a struct nvp containing name-value pairs and checks if
%   it contains a field called "ApiKey". If the field is not found, the
%   function attempts to retrieve the API key from an environment variable
%   whose name is given as the second argument. If both methods fail, the
%   function throws an error.

%   Copyright 2023-2024 The MathWorks, Inc.

    if isfield(nvp, "ApiKey")
        key = nvp.ApiKey;
    else
        if isenv(envVarName)
            key = getenv(envVarName);
        else
            error("llms:keyMustBeSpecified", llms.utils.errorMessageCatalog.getMessage("llms:keyMustBeSpecified", envVarName));
        end
    end
end
