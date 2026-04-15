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

%   Copyright 2023-2026 The MathWorks, Inc.

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
    nvp.sendRequestFcn
    nvp.Verbosity
    nvp.ReasoningEffort
    nvp.BaseURL
end

END_POINT = nvp.BaseURL + "/chat/completions";

parameters = llms.internal.buildOpenAIParameters(messages, functions, nvp);

[response, streamedText] = nvp.sendRequestFcn(parameters,nvp.APIKey, END_POINT, nvp.TimeOut, nvp.StreamFun);

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
    if isfield(message, "content")
        text = string(message.content);
    else
        text = "";
    end
else
    text = "";
    message = struct();
end
end
