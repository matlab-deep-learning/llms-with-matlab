function endpoint = getEndpointFromNvpOrEnv(nvp, type='chat')
% This function is undocumented and will change in a future release

% getEndpointFromNvpOrEnv Retrieves an API key from a Name-Value Pair struct or environment variable.
%
%   This function takes a struct nvp containing name-value pairs and checks
%   if it contains a field called "Endpoint". If the field is not found, 
%   the function attempts to retrieve the API base_url from an environment
%   variable called "OPENAI_API_BASE_URL". If both methods fail, the function 
%   throws an error.

%   Copyright 2023 The MathWorks, Inc.

    openai_api_base_url = 'https://api.openai.com/v1'
    if isfield(nvp, "Endpoint")
        endpoint = nvp.Endpoint;
    else
        if isenv("OPENAI_API_BASE_URL")
            base_url = getenv("OPENAI_API_BASE_URL");
            if ~startsWith(base_url, 'http')
                base_url = openai_api_base_url;
            end
        else
            endpoint = openai_api_base_url;
        end

        completions.chat = "/chat/completions";
        completions.embeddings = "/embeddings";
        completions.image_generate = "/images/generations";
        completions.image_edits = "/images/edits";
        completions.image_variations = "/images/variations";
        if ~isfield(completions, type)
            endpoint = strcat(base_url, completions.chat);
        else
            endpoint = strcat(base_url, completions.(type));
        end

    end
end