function [text, message, response] = callOllamaChatAPI(model, messages, nvp)
% This function is undocumented and will change in a future release

%callOllamaChatAPI Calls the ollama chat completions API.
%
%   MESSAGES and FUNCTIONS should be structs matching the json format
%   required by the ollama Chat Completions API.
%   Ref: https://github.com/ollama/ollama/blob/main/docs/api.md
%
%   Currently, the supported NVP are, including the equivalent name in the API:
%  TODO TODO TODO
%    - Temperature (temperature)
%    - TopProbabilityMass (top_p)
%    - NumCompletions (n)
%    - StopSequences (stop)
%    - MaxNumTokens (max_tokens)
%    - PresencePenalty (presence_penalty)
%    - FrequencyPenalty (frequence_penalty)
%    - ResponseFormat (response_format)
%    - Seed (seed)
%    - ApiKey
%    - TimeOut
%    - StreamFun
%   More details on the parameters: https://platform.openai.com/docs/api-reference/chat/create
%
%   Example
%
%   % Create messages struct
%   messages = {struct("role", "system",...
%       "content", "You are a helpful assistant");
%       struct("role", "user", ...
%       "content", "What is the edit distance between hi and hello?")};
%
%   % Create functions struct
%   functions = {struct("name", "editDistance", ...
%       "description", "Find edit distance between two strings or documents.", ...
%       "parameters", struct( ...
%       "type", "object", ...
%       "properties", struct(...
%           "str1", struct(...
%               "description", "Source string.", ...
%               "type", "string"),...
%           "str2", struct(...
%               "description", "Target string.", ...
%               "type", "string")),...
%       "required", ["str1", "str2"]))};
%
%   % Define your API key
%   apiKey = "your-api-key-here"
%
%   % Send a request
%   [text, message] = llms.internal.callOpenAIChatAPI(messages, functions, ApiKey=apiKey)

%   Copyright 2023-2024 The MathWorks, Inc.

arguments
    model
    messages
    nvp.Temperature = 1
    nvp.TopProbabilityMass = 1
    nvp.NumCompletions = 1
    nvp.StopSequences = []
    nvp.MaxNumTokens = inf
    nvp.PresencePenalty = 0
    nvp.FrequencyPenalty = 0
    nvp.ResponseFormat = "text"
    nvp.Seed = []
    nvp.TimeOut = 10
    nvp.StreamFun = []
end

URL = "http://localhost:11434/api/chat"; % TODO: model parameter

parameters = buildParametersCall(model, messages, nvp);

[response, streamedText] = llms.internal.sendRequest(parameters,[],URL,nvp.TimeOut,nvp.StreamFun);

% If call errors, "choices" will not be part of response.Body.Data, instead
% we get response.Body.Data.error
if response.StatusCode=="OK"
    % Outputs the first generation
    if isempty(nvp.StreamFun)
        message = response.Body.Data.message;
    else
        message = struct("role", "assistant", ...
            "content", streamedText);
    end
    text = string(message.content);
else
    text = "";
    message = struct();
end
end

function parameters = buildParametersCall(model, messages, nvp)
% Builds a struct in the format that is expected by the API, combining
% MESSAGES, FUNCTIONS and parameters in NVP.

parameters = struct();
parameters.model = model;
parameters.messages = messages;

parameters.stream = ~isempty(nvp.StreamFun);

options = struct;
if ~isempty(nvp.Seed)
    options.seed = nvp.Seed;
end

dict = mapNVPToParameters;

nvpOptions = keys(dict);
for opt = nvpOptions.'
    if isfield(nvp, opt)
        options.(dict(opt)) = nvp.(opt);
    end
end

parameters.options = options;
end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopProbabilityMass") = "top_p";
dict("NumCompletions") = "n";
dict("StopSequences") = "stop";
dict("MaxNumTokens") = "num_predict";
end
