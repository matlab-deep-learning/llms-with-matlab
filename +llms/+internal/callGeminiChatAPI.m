function [text, message, response] = callGeminiChatAPI(messages, functions, nvp)
%callGeminiChatAPI Call the Google Gemini generateContent API
%
%   [TEXT, MESSAGE, RESPONSE] = callGeminiChatAPI(MESSAGES, FUNCTIONS, NVP)
%   sends a request to the Gemini API and returns the response.
%
%   MESSAGES and FUNCTIONS should be structs matching the format expected
%   by the library (OpenAI-style), which will be converted to Gemini format.
%
%   Ref: https://ai.google.dev/api/generate-content

%   Copyright 2025 The MathWorks, Inc.

arguments
    messages
    functions
    nvp.ToolChoice
    nvp.ModelName
    nvp.Temperature
    nvp.TopP
    nvp.TopK
    nvp.StopSequences
    nvp.MaxNumTokens
    nvp.ResponseFormat
    nvp.APIKey
    nvp.TimeOut
    nvp.StreamFun
end

% Build the endpoint URL
% Format: https://generativelanguage.googleapis.com/v1beta/models/{model}:{method}
BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/";

if isempty(nvp.StreamFun)
    method = "generateContent";
else
    method = "streamGenerateContent";
end

endpoint = BASE_URL + nvp.ModelName + ":" + method;

% Build parameters in Gemini format
parameters = llms.internal.buildGeminiParameters(messages, functions, nvp);

% Send the request
[response, streamedText] = llms.internal.sendGeminiRequest(...
    parameters, nvp.APIKey, endpoint, nvp.TimeOut, nvp.StreamFun);

% Process the response
if response.StatusCode == "OK"
    if isempty(nvp.StreamFun)
        % Non-streaming response
        [text, message] = parseGeminiResponse(response.Body.Data);
    else
        % Streaming response - text already accumulated
        text = streamedText;
        message = struct("role", "assistant", "content", streamedText);

        % Check if there were tool calls during streaming
        % (would need to be tracked in the streamer)
    end
else
    text = "";
    message = struct();
end

end

function [text, message] = parseGeminiResponse(data)
%parseGeminiResponse Parse Gemini API response to OpenAI-compatible format

text = "";
message = struct("role", "assistant", "content", "");

% Handle array response (from streaming endpoint sometimes)
if iscell(data)
    data = data{end};
elseif numel(data) > 1
    data = data(end);
end

if ~isfield(data, 'candidates') || isempty(data.candidates)
    return;
end

candidate = data.candidates(1);

if ~isfield(candidate, 'content') || ~isfield(candidate.content, 'parts')
    return;
end

parts = candidate.content.parts;
textParts = {};
toolCalls = {};

for i = 1:numel(parts)
    part = parts(i);

    if isfield(part, 'text')
        textParts{end+1} = part.text; %#ok<AGROW>
    elseif isfield(part, 'functionCall')
        % Convert Gemini functionCall to OpenAI tool_calls format
        fc = part.functionCall;
        toolCall = struct(...
            'id', "call_" + string(java.util.UUID.randomUUID()), ...
            'type', 'function', ...
            'function', struct(...
                'name', fc.name, ...
                'arguments', jsonencode(fc.args)));
        toolCalls{end+1} = toolCall; %#ok<AGROW>
    end
end

% Combine text parts
if ~isempty(textParts)
    text = strjoin(textParts, "");
    message.content = text;
end

% Add tool calls if present
if ~isempty(toolCalls)
    if numel(toolCalls) == 1
        message.tool_calls = toolCalls{1};
    else
        message.tool_calls = [toolCalls{:}];
    end
    text = "";  % OpenAI convention: empty text when tool call
end

end
