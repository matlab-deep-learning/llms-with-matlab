function [text, message, response] = callOllamaChatAPI(model, messages, functions, nvp)
% This function is undocumented and will change in a future release

%callOllamaChatAPI Calls the Ollama™ chat completions API.
%
%   MESSAGES and FUNCTIONS should be structs matching the json format
%   required by the Ollama Chat Completions API.
%   Ref: https://github.com/ollama/ollama/blob/main/docs/api.md
%
%   More details on the parameters: https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
%
%   Example
%
%   model = "mistral";
%
%   % Create messages struct
%   messages = {struct("role", "system",...
%       "content", "You are a helpful assistant");
%       struct("role", "user", ...
%       "content", "What is the edit distance between hi and hello?")};
%
%   % Send a request
%   [text, message] = llms.internal.callOllamaChatAPI(model, messages)

%   Copyright 2023-2025 The MathWorks, Inc.

arguments
    model
    messages
    functions
    nvp.ToolChoice
    nvp.Temperature
    nvp.TopP
    nvp.MinP
    nvp.TopK
    nvp.TailFreeSamplingZ
    nvp.StopSequences
    nvp.MaxNumTokens
    nvp.ResponseFormat
    nvp.Seed
    nvp.TimeOut
    nvp.StreamFun
    nvp.Endpoint
    nvp.sendRequestFcn
end

URL = nvp.Endpoint + "/api/chat";
if ~startsWith(URL,"http")
    URL = "http://" + URL;
end

% The JSON for StopSequences must have an array, and cannot say "stop": "foo".
% The easiest way to ensure that is to never pass in a scalar …
if isscalar(nvp.StopSequences)
    nvp.StopSequences = [nvp.StopSequences, nvp.StopSequences];
end

parameters = buildParametersCall(model, messages, functions, nvp);

[response, streamedText] = nvp.sendRequestFcn(parameters,[],URL,nvp.TimeOut,nvp.StreamFun);

% If call errors, "choices" will not be part of response.Body.Data, instead
% we get response.Body.Data.error
if response.StatusCode=="OK"
    % Outputs the first generation
    if isempty(nvp.StreamFun)
        if iscell(response.Body.Data)
            message = response.Body.Data{1}.message;
        else
            message = response.Body.Data.message;
        end
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

function parameters = buildParametersCall(model, messages, functions, nvp)
% Builds a struct in the format that is expected by the API, combining
% MESSAGES, FUNCTIONS and parameters in NVP.

parameters = struct();
parameters.model = model;
parameters.messages = messages;

parameters.stream = ~isempty(nvp.StreamFun);

if ~isempty(functions)
    parameters.tools = functions;
end

if isfield(nvp,"ToolChoice") && ~isempty(nvp.ToolChoice)
    parameters.tool_choice = nvp.ToolChoice;
end

options = struct;

if strcmp(nvp.ResponseFormat,"json")
    parameters.format = "json";
elseif isstruct(nvp.ResponseFormat)
    parameters.format = llms.internal.jsonSchemaFromPrototype(nvp.ResponseFormat);
elseif startsWith(string(nvp.ResponseFormat), asManyOfPattern(whitespacePattern)+"{")
    parameters.format = llms.internal.verbatimJSON(nvp.ResponseFormat);
end

if ~isempty(nvp.Seed)
    options.seed = nvp.Seed;
end

dict = mapNVPToParameters;

nvpOptions = keys(dict);
for opt = nvpOptions.'
    if isfield(nvp, opt) && ~isempty(nvp.(opt)) && ~isequaln(nvp.(opt),Inf)
        options.(dict(opt)) = nvp.(opt);
    end
end

parameters.options = options;
end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopP") = "top_p";
dict("MinP") = "min_p";
dict("TopK") = "top_k";
dict("TailFreeSamplingZ") = "tfs_z";
dict("StopSequences") = "stop";
dict("MaxNumTokens") = "num_predict";
end
