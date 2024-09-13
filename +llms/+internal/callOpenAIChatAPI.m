function [text, message, response] = callOpenAIChatAPI(messages, functions, nvp)
% This function is undocumented and will change in a future release

%callOpenAIChatAPI Calls the openAI chat completions API.
%
%   MESSAGES and FUNCTIONS should be structs matching the json format
%   required by the OpenAI Chat Completions API.
%   Ref: https://platform.openai.com/docs/guides/gpt/chat-completions-api
%
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
%   [text, message] = llms.internal.callOpenAIChatAPI(messages, functions, APIKey=apiKey)

%   Copyright 2023-2024 The MathWorks, Inc.

arguments
    messages
    functions
    nvp.ToolChoice
    nvp.ModelName
    nvp.Temperature
    nvp.TopP
    nvp.NumCompletions
    nvp.StopSequences
    nvp.MaxNumTokens
    nvp.PresencePenalty
    nvp.FrequencyPenalty
    nvp.ResponseFormat
    nvp.Seed
    nvp.APIKey
    nvp.TimeOut
    nvp.StreamFun
end

END_POINT = "https://api.openai.com/v1/chat/completions";

parameters = buildParametersCall(messages, functions, nvp);

[response, streamedText] = llms.internal.sendRequestWrapper(parameters,nvp.APIKey, END_POINT, nvp.TimeOut, nvp.StreamFun);

% If call errors, "choices" will not be part of response.Body.Data, instead
% we get response.Body.Data.error
if response.StatusCode=="OK"
    % Outputs the first generation
    if isempty(nvp.StreamFun)
        message = response.Body.Data.choices(1).message;
    else
        pat = '{"' + wildcardPattern + '":';
        if contains(streamedText,pat)
            s = jsondecode(streamedText);
            if contains(s.function.arguments,pat)
                prompt = jsondecode(s.function.arguments);
                s.function.arguments = prompt;
            end
            message = struct("role", "assistant", ...
                 "content",[], ...
                 "tool_calls",jsondecode(streamedText));
        else
            message = struct("role", "assistant", ...
                "content", streamedText);
        end
    end
    if isfield(message, "tool_choice")
        text = "";
    else
        text = string(message.content);
    end
else
    text = "";
    message = struct();
end
end

function parameters = buildParametersCall(messages, functions, nvp)
% Builds a struct in the format that is expected by the API, combining
% MESSAGES, FUNCTIONS and parameters in NVP.

parameters = struct();
parameters.messages = messages;

parameters.stream = ~isempty(nvp.StreamFun);

if ~isempty(functions)
    parameters.tools = functions;
end

if ~isempty(nvp.ToolChoice)
    parameters.tool_choice = nvp.ToolChoice;
end

if strcmp(nvp.ResponseFormat,"json")
    parameters.response_format = struct('type','json_object');
end

if ~isempty(nvp.Seed)
    parameters.seed = nvp.Seed;
end

parameters.model = nvp.ModelName;

dict = mapNVPToParameters;

nvpOptions = keys(dict);

for opt = nvpOptions.'
    if isfield(nvp, opt)
        parameters.(dict(opt)) = nvp.(opt);
    end
end

if isempty(nvp.StopSequences)
    parameters = rmfield(parameters,dict("StopSequences"));
end

if nvp.MaxNumTokens == Inf
    parameters = rmfield(parameters,dict("MaxNumTokens"));
end

end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopP") = "top_p";
dict("NumCompletions") = "n";
dict("StopSequences") = "stop";
dict("MaxNumTokens") = "max_completion_tokens";
dict("PresencePenalty") = "presence_penalty";
dict("FrequencyPenalty ") = "frequency_penalty";
end